//
//  CentralManager.swift
//  pedometer-ble-ios
//
//  Created by k24098kk on 2026/06/27.
//

import CoreBluetooth
import Combine

enum CentralConnectionState: String {
    case idle        = "待機中"
    case scanning    = "スキャン中..."
    case connecting  = "接続中..."
    case discovering = "サービス検索中..."
    case ready       = "接続済み・受信中"
    case disconnected = "切断済み"

    var isActive: Bool { self == .ready }
}

class CentralManager: NSObject, ObservableObject {
    @Published var connectionState: CentralConnectionState = .idle
    @Published var acceleration: AccelerationData = .zero
    @Published var connectedDeviceName: String = "-"
    @Published var isBluetoothReady: Bool = false

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var accelerometerCharacteristic: CBCharacteristic?
    private var pendingScan = false

    override init() {
        super.init()
        // queue: nil → メインキューを使用（UIへの反映が容易）
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        // Bluetooth未準備のときはスキャン開始を保留し、poweredOn後に自動再開
        guard centralManager.state == .poweredOn else {
            pendingScan = true
            return
        }
        pendingScan = false
        connectionState = .scanning
        // serviceUUIDを指定することで、そのサービスをアドバタイズしている端末のみを発見
        centralManager.scanForPeripherals(withServices: [BLEConstants.serviceUUID], options: nil)
    }

    func stopScanning() {
        centralManager.stopScan()
        connectionState = .idle
    }

    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
}

// MARK: - CBCentralManagerDelegate

extension CentralManager: CBCentralManagerDelegate {
    // bluetoothがオンになってたらスキャン開始
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isBluetoothReady = central.state == .poweredOn
        if central.state == .poweredOn, pendingScan {
            startScanning()
        }
    }
    // ペリフェラルデバイスが見つかるたびに下のメソッドが呼び出される
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        // 最初に見つかった対象デバイスに接続
        centralManager.stopScan()
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        connectionState = .connecting
        centralManager.connect(peripheral, options: nil)
    }
    // 接続に成功すると下のメソッドが呼び出される．
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedDeviceName = peripheral.name ?? "不明なデバイス"
        connectionState = .discovering
        peripheral.discoverServices([BLEConstants.serviceUUID])
    }
    // 接続に失敗すると下のメソッドが呼び出される
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        connectionState = .disconnected
        connectedPeripheral = nil
    }

    func centralManager(_ central: CBCentralManager,
                        didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        connectionState = .disconnected
        connectedPeripheral = nil
        accelerometerCharacteristic = nil
        connectedDeviceName = "-"
    }
}

// MARK: - CBPeripheralDelegate

extension CentralManager: CBPeripheralDelegate {
    // 接続に成功したメソッドが呼び出されて探索が完了すると
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = peripheral.services else { return }
        for service in services where service.uuid == BLEConstants.serviceUUID {
            // 特定のuuidが見つかったらサービス検出して，その中のキャラクタリスティック探索
            peripheral.discoverCharacteristics([BLEConstants.accelerometerCharacteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard error == nil, let characteristics = service.characteristics else { return }
        for characteristic in characteristics where characteristic.uuid == BLEConstants.accelerometerCharacteristicUUID {
            accelerometerCharacteristic = characteristic
            // Notify購読を有効化 → 子機がupdateValueするたびにdidUpdateValueForが呼ばれる
            peripheral.setNotifyValue(true, for: characteristic)
            connectionState = .ready
        }
    }

    // キャラクタリスティックの値を読み取
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard characteristic.uuid == BLEConstants.accelerometerCharacteristicUUID,
              let data = characteristic.value,
              let accel = AccelerationData.fromData(data) else { return }
        // CoreBluetoothのコールバックはバックグラウンドスレッドの可能性があるため明示的にMain切替
        DispatchQueue.main.async { self.acceleration = accel }
    }

    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        if let error {
            print("[Central] Notify有効化エラー: \(error.localizedDescription)")
        }
    }
}
