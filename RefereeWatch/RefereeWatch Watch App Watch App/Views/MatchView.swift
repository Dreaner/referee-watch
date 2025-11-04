//
//  MatchView.swift
//  RefereeWatch Watch App Watch App
//
//  Created by Xingnan Zhu on 14/10/25.
//

import SwiftUI
import WatchKit

struct MatchView: View {
    @StateObject var matchManager = MatchManager()
    @ObservedObject var connectivity = WatchConnectivityManager.shared  // ✅ 用于红/绿点状态
    @State private var feedbackMessage: String = ""
    @State private var showFeedback: Bool = false
    
    var body: some View {
        VStack(spacing: 5) {
            Spacer()
            
            // 顶部状态行：左侧红绿点 + 中间Half文字
            ZStack {
                // 左上角红绿点
                HStack {
                    Circle()
                        .fill(connectivity.isReachable ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                        .padding(.leading, 4)
                        .animation(.easeInOut(duration: 0.3), value: connectivity.isReachable)
                    Spacer()
                }
                
                // 中间 Half 标签
                Text("Half \(matchManager.currentHalf)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Feedback 提示
            if showFeedback {
                Text(feedbackMessage)
                    .font(.caption2)
                    .foregroundColor(.green)
                    .transition(.opacity)
                    .padding(.top, 2)
            }

            // Timer
            Text(formatTime(matchManager.elapsedTime))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
            
            // Scoreboard
            HStack {
                VStack {
                    Text(matchManager.homeTeamName).font(.caption2)
                    Text("\(matchManager.homeScore)").font(.title2)
                }
                Text("-").font(.title2)
                VStack {
                    Text(matchManager.awayTeamName).font(.caption2)
                    Text("\(matchManager.awayScore)").font(.title2)
                }
            }

            // Event Buttons
            HStack(spacing: 8) {
                Button { matchManager.isGoalSheetPresented = true } label: {
                    Image(systemName: "soccerball")
                }
                Button { matchManager.isCardSheetPresented = true } label: {
                    Image(systemName: "rectangle.fill.on.rectangle.fill")
                }
                Button { matchManager.isSubstitutionSheetPresented = true } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
            }
            .font(.title3)

            // Control Buttons
            HStack(spacing: 8) {
                Button(matchManager.isRunning ? "Pause" : "Start") {
                    if matchManager.isRunning {
                        matchManager.pauseMatch()
                        WKInterfaceDevice.current().play(.click)
                    } else {
                        matchManager.startMatch()
                        triggerFeedback("Kick-off")
                    }
                }
                
                Button("End Half") {
                    matchManager.endHalf()
                    triggerFeedback("Halftime")
                }
                
                Button("End") {
                    let report = matchManager.generateMatchReport()
                    WatchConnectivityManager.shared.sendMatchReport(report)
                    matchManager.resetMatch()
                    triggerFeedback("Full Time")
                }
            }
            Spacer()
        }
        // Sheets
        .sheet(isPresented: $matchManager.isGoalSheetPresented) {
            GoalTypeSheet(matchManager: matchManager)
        }
        .sheet(isPresented: $matchManager.isCardSheetPresented) {
            CardTypeSheet(matchManager: matchManager)
        }
        .sheet(isPresented: $matchManager.isSubstitutionSheetPresented) {
            SubstitutionSheet(matchManager: matchManager)
        }
        .animation(.easeInOut, value: showFeedback)
    }
    
    // MARK: - 时间格式化
    private func formatTime(_ time: TimeInterval) -> String {
        let hundredths = Int((time * 100).rounded())
        let minutes = hundredths / 6000
        let seconds = (hundredths / 100) % 60
        let centi = hundredths % 100
        return String(format: "%02d:%02d.%02d", minutes, seconds, centi)
    }
    
    // MARK: - 提示反馈
    private func triggerFeedback(_ message: String) {
        feedbackMessage = message
        showFeedback = true
        WKInterfaceDevice.current().play(.click)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showFeedback = false }
        }
    }
}

#Preview {
    MatchView()
}

