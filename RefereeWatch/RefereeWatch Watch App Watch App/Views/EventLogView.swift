//
//  EventLogView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 26/10/25.
//


import SwiftUI
import WatchKit

struct EventLogView: View {
    @ObservedObject var matchManager: MatchManager
    @State private var showSyncSuccess = false // ✅ 新增：控制提示动画显示
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Match Events")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                if matchManager.events.isEmpty {
                    Text("No events recorded yet.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                } else {
                    ForEach(matchManager.events) { event in
                        HStack {
                            Text(eventDescription(event))
                                .font(.footnote)
                            Spacer()
                            Text(formatTime(event.timestamp))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Divider()
                    }
                }

                // MARK: - Export Button
                Button(action: {
                    exportToiPhone()
                }) {
                    HStack {
                        Spacer()
                        Label("Export to iPhone", systemImage: "arrow.up.iphone")
                            .font(.footnote)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(6)
                }
                .padding(.top, 8)
            }
            .padding()
            // ✅ 同步成功提示动画
            .overlay(
                Group {
                    if showSyncSuccess {
                        VStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.green)
                                .transition(.scale)
                            Text("Synced to iPhone")
                                .font(.footnote)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .shadow(radius: 4)
                    }
                }
            )
            .animation(.easeInOut(duration: 0.3), value: showSyncSuccess)
        }
    }
    
    // MARK: - Helper Methods
    private func eventDescription(_ event: MatchEvent) -> String {
        switch event.type {
        case .goal:
            return "\(event.team.capitalized) \(event.goalType?.rawValue ?? "") - #\(event.playerNumber ?? 0)"
        case .card:
            return "\(event.team.capitalized) \(event.cardType?.rawValue ?? "") Card - #\(event.playerNumber ?? 0)"
        case .substitution:
            return "\(event.team.capitalized) Sub: #\(event.playerOut ?? 0) → #\(event.playerIn ?? 0)"
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Export Function
    private func exportToiPhone() {
        let report = matchManager.generateMatchReport()
        WatchConnectivityManager.shared.sendMatchReport(report)
        
        // ✅ 震动 + 显示成功提示
        WKInterfaceDevice.current().play(.success)
        withAnimation {
            showSyncSuccess = true
        }
        
        // 2 秒后自动隐藏提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSyncSuccess = false
            }
        }
    }
}

#Preview {
    EventLogView(matchManager: MatchManager())
}
