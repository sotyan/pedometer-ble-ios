//
//  ContentView.swift
//  pedometer-ble-ios
//
//  Created by k24098kk on 2026/06/24.
//

import SwiftUI

enum AppMode {
    case selector, central, peripheral
}

struct ContentView: View {
    @State private var selectedMode: AppMode = .selector
    
    var body: some View {
        switch selectedMode {
        case .selector:
            ModeSelector(onSelect: { selectedMode = $0 })
        case .central:
            NavigationStack {
                CentralView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading){
                            Button("戻る") { selectedMode = .selector}
                        }
                    }
            }
        case .peripheral:
            NavigationStack {
                PeripheralView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading){
                            Button("戻る") { selectedMode = .selector}
                        }
                    }
            }
        }
    }
}

struct ModeSelector: View {
    let onSelect: (AppMode) -> Void
    
    var body: some View {
        VStack(spacing: 40){
            Spacer()
            VStack(spacing: 8){
                Text("万歩計")
                    .font(.largeTitle.bold())
                Text("モードを選択してください")
                    .foregroundColor(.secondary)
            }
            VStack(spacing: 16){
                Button{ onSelect(.central) } label:{
                    ModeCard(icon: "antenna.radiowaves.left.and.right",
                             title: "親機",
                             description: "加速度データを受信・歩数を表示")
                }
                Button{ onSelect(.peripheral) } label:{
                    ModeCard(icon: "iphone.radiowaves.left.and.right",
                             title: "子機",
                             description: "加速度データを送信")
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

#Preview{
    ContentView();
}
