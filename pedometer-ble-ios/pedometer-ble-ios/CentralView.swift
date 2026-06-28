//
//  CentralView.swift
//  pedometer-ble-ios
//
//  Created by k24098kk on 2026/06/24.
//
import SwiftUI

struct CentralView: View {
    @StateObject private var central = CentralManager()
    @State private var shareURL: URL?
    @State private var showingShareSheet = false

    var body: some View {
        VStack(spacing: 24) {
            StatusBadge(label: central.connectionState.rawValue,
                        isActive: central.connectionState.isActive)

            if central.connectionState == .ready {
                Text("接続デバイス: \(central.connectedDeviceName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if central.csvExporter.isLogging {
                StatusBadge(label: "記録中", isActive: true)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("加速度（受信値）・合成加速度 (Norm)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                AccelerationDisplay(acceleration: central.acceleration)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("合成加速度 Norm（EMAフィルタ後）")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.4f g", central.filteredNorm))
                    .font(.system(.body, design: .monospaced))
                    .padding(.bottom, 4)

                Text("歩数")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(central.stepCount) 歩")
                    .font(.title2)
                    .bold()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(14)

            Spacer()

            actionButton
        }
        .padding()
        .navigationTitle("親機（Central）")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareURL {
                ShareSheet(url: url)
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch central.connectionState {
        case .idle, .disconnected:
            VStack(spacing: 8) {
                Button("スキャン開始") { central.startScanning() }
                    .buttonStyle(.borderedProminent)
                if !central.isBluetoothReady {
                    Text("Bluetoothが無効です。設定を確認してください。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        case .scanning:
            HStack(spacing: 12) {
                ProgressView()
                Button("停止") { central.stopScanning() }
                    .foregroundColor(.red)
            }
        case .connecting, .discovering:
            HStack(spacing: 12) {
                ProgressView()
                Text(central.connectionState.rawValue)
                    .foregroundColor(.secondary)
            }
        case .ready:
            VStack(spacing: 12) {
                if central.csvExporter.isLogging {
                    Button("計測停止") {
                        if let url = central.csvExporter.stopLogging() {
                            shareURL = url
                            showingShareSheet = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button("計測開始") { central.csvExporter.startLogging() }
                        .buttonStyle(.borderedProminent)
                }
                Button("切断") { central.disconnect() }
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
