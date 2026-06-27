//
//  BLEConstants.swift
//  pedometer-ble-ios
//
//  Created by k24098kk on 2026/06/27.
//

import CoreBluetooth

enum BLEConstants {
    // 両端末で共通のカスタムUUID（uuidgenコマンドで生成）
    static let serviceUUID = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")
    static let accelerometerCharacteristicUUID = CBUUID(string: "A1B2C3D4-E5F6-7890-ABCD-EF1234567891")

    // BLE Notify送信間隔（秒）
    // BLEのコネクションインターバルは通常15〜30msのため、0.05s(20Hz)以下は実質意味がない
    // 省電力を優先するなら0.2s(5Hz)、リアルタイム性重視なら0.05s(20Hz)
    static let notifyInterval: TimeInterval = 0.1  // 10Hz
}
