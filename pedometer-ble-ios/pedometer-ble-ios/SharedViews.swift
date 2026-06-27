//
//  SharedViews.swift
//  pedometer-ble-ios
//
//  Created by k24098kk on 2026/06/25.
//
import SwiftUI

struct StatusBadge: View{
    let label: String
    let isActive: Bool
    
    var body: some View{
        HStack(spacing: 6){
            Circle()
                .fill(isActive ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color(.systemGray6))
        .cornerRadius(20)
    }
}

struct AccelerationDisplay: View{
    let acceleration: AccelerationData
    
    var body: some View{
        VStack(spacing: 14){
            axisRow(label: "X", value: acceleration.x, color: .red)
            axisRow(label: "Y", value: acceleration.y, color: .green)
            axisRow(label: "Z", value: acceleration.z, color: .blue)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(14)
    }
    
    private func axisRow(label: String, value: Float, color: Color) -> some View{
        HStack(spacing: 12){
            Text(label)
                .font(.headline)
                .foregroundColor(color)
                .frame(width: 18)
            ProgressView(value: Double(min(max(value + 1, 0), 2) / 2))
                .tint(color)
            Text(String(format: "% .4f g", value))
                .font(.system(.body, design: .monospaced))
                .frame(width: 96, alignment: .trailing)
        }
    }
}

struct ModeCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .cornerRadius(14)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}
