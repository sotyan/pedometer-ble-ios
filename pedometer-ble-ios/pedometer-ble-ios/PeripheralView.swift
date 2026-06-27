//
//  PeripheralView.swift
//  pedometer-ble-ios
//
//  Created by k24098kk on 2026/06/24.
//
import SwiftUI

struct PeripheralView: View{
    @StateObject private var peripheral = PeripheralManager()
    
    var body: some View{
        VStack(spacing: 24){
            StatusBadge(label: peripheral.connectionState.rawValue,
                        isActive: peripheral.connectionState.isActive)
            
            if peripheral.isSubscribed{
                Label("親機へ送信中", systemImage: "wave.3right")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("加速度（送信値）")
                    .font(.caption)
                    .foregroundColor(.secondary)
                AccelerationDisplay(acceleration:peripheral.currentAcceleration)
            }
            Spacer()
            
            actionButton
        }
        .padding()
        .navigationTitle("子機")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var actionButton: some View{
        switch peripheral.connectionState{
        case .idle, .stopped:
            VStack(spacing: 8){
                Button("アドバタイズ開始") { peripheral.startAdvertising()}
                    .buttonStyle(.borderedProminent)
                if !peripheral.isBluetoothReady{
                    Text("Bluetoothが無効です．設定を確認してください")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        case .advertising, .streaming:
            Button("停止") { peripheral.stopAdvertising()}
                .foregroundColor(.red)
        }
    }
}
