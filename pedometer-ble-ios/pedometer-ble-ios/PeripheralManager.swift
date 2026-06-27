import CoreBluetooth
import CoreMotion
import Combine

enum PeripheralConnectionState: String {
    case idle        = "待機中"
    case advertising = "アドバタイズ中..."
    case streaming   = "送信中（接続済み）"
    case stopped     = "停止"

    var isActive: Bool { self == .streaming }
}

class PeripheralManager: NSObject, ObservableObject {
    @Published var connectionState: PeripheralConnectionState = .idle
    @Published var currentAcceleration: AccelerationData = .zero
    @Published var isBluetoothReady: Bool = false
    @Published var isSubscribed: Bool = false

    private var peripheralManager: CBPeripheralManager!
    private var accelerometerCharacteristic: CBMutableCharacteristic?
    private let motionManager = CMMotionManager()
    private var sendTimer: Timer?

    // updateValueが失敗したときに再送するためのバッファ
    private var pendingData: Data?
    private var isGATTReady = false
    private var pendingAdvertise = false

    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    // アドバタイジングする
    func startAdvertising() {
        // Bluetooth未準備のときは保留し、poweredOn後に自動再開
        guard peripheralManager.state == .poweredOn, isGATTReady else {
            pendingAdvertise = true
            return
        }
        pendingAdvertise = false
        peripheralManager.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [BLEConstants.serviceUUID],
            CBAdvertisementDataLocalNameKey: "SensorSync"
        ])
        connectionState = .advertising
        startMotion()
    }

    func stopAdvertising() {
        peripheralManager.stopAdvertising()
        stopMotion()
        connectionState = .stopped
        isSubscribed = false
    }

    // MARK: - GATT Setup

    private func setupGATT() {
        guard !isGATTReady else { return }
        // キャラクタリスティックを作成
        let characteristic = CBMutableCharacteristic(
            type: BLEConstants.accelerometerCharacteristicUUID,
            properties: [.notify],   // CentralからのReadは不要なのでNotifyのみ
            value: nil,
            permissions: .readable
        )
        accelerometerCharacteristic = characteristic
        // サービスを作成
        let service = CBMutableService(type: BLEConstants.serviceUUID, primary: true)
        service.characteristics = [characteristic]
        // peripheralManagerにserviceを登録
        // これでアドバタイズでセントラルに情報公開できる
        peripheralManager.add(service)
        isGATTReady = true
    }

    // MARK: - CoreMotion

    private func startMotion() {
        guard motionManager.isAccelerometerAvailable else { return }
        // CoreMotionの更新間隔はBLE送信間隔より細かく設定し、最新値を送る
        motionManager.accelerometerUpdateInterval = BLEConstants.notifyInterval / 2
        motionManager.startAccelerometerUpdates()

        sendTimer = Timer.scheduledTimer(withTimeInterval: BLEConstants.notifyInterval,
                                         repeats: true) { [weak self] _ in
            self?.sendAccelerationUpdate()
        }
    }

    private func stopMotion() {
        sendTimer?.invalidate()
        sendTimer = nil
        motionManager.stopAccelerometerUpdates()
    }

    private func sendAccelerationUpdate() {
        guard let rawData = motionManager.accelerometerData else { return }

        let accel = AccelerationData(
            x: Float(rawData.acceleration.x),
            y: Float(rawData.acceleration.y),
            z: Float(rawData.acceleration.z)
        )
        currentAcceleration = accel

        guard isSubscribed, let characteristic = accelerometerCharacteristic else { return }

        let payload = accel.toData()
        // updateValueはBLE送信キューが満杯のときfalseを返す
        // falseのときはperipheralManagerIsReadyで再送する
        if !peripheralManager.updateValue(payload, for: characteristic, onSubscribedCentrals: nil) {
            pendingData = payload
        }
    }
}

// MARK: - CBPeripheralManagerDelegate

extension PeripheralManager: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        // bluetoothがオンでペリフェラルとして動作可能
        isBluetoothReady = peripheral.state == .poweredOn
        if peripheral.state == .poweredOn {
            setupGATT()
            if pendingAdvertise {
                startAdvertising()
            }
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error {
            print("[Peripheral] アドバタイズ開始エラー: \(error.localizedDescription)")
            connectionState = .idle
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didSubscribeTo characteristic: CBCharacteristic) {
        // CentralがNotify購読を開始したタイミング
        isSubscribed = true
        connectionState = .streaming
    }

    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didUnsubscribeFrom characteristic: CBCharacteristic) {
        isSubscribed = false
        connectionState = .advertising
    }

    // BLE送信キューに空きができたときに呼ばれる → 失敗したデータを再送
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        guard let data = pendingData, let characteristic = accelerometerCharacteristic else { return }
        if peripheralManager.updateValue(data, for: characteristic, onSubscribedCentrals: nil) {
            pendingData = nil
        }
    }
}
