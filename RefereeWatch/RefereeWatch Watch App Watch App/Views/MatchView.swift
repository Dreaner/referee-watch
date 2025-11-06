//
//  MatchView.swift
//  RefereeWatch Watch App Watch App
//
//  Created by Xingnan Zhu on 14/10/25.
//

import SwiftUI
import WatchKit
import HealthKit

struct MatchView: View {
    // 假设 MatchManager 中的 isGoalSheetPresented 等属性已恢复为 @Published var
    @StateObject var matchManager = MatchManager()
    @ObservedObject var connectivity = WatchConnectivityManager.shared
    @State private var feedbackMessage: String = ""
    @State private var showFeedback: Bool = false
    
    // 计时器显示逻辑：下半场从 45:00.00 开始
    private var currentDisplayTime: TimeInterval {
        let totalElapsedTime = matchManager.workoutManager.elapsedTime

        if matchManager.currentHalf == 1 {
            return totalElapsedTime
        } else {
            let baseTime: TimeInterval = matchManager.halfDuration
            let timeInSecondHalf = totalElapsedTime - matchManager.timeAtEndOfFirstHalf
            return baseTime + timeInSecondHalf
        }
    }
    
    var body: some View {
        VStack(spacing: 5) {
            Spacer()
            
            // 顶部状态行
            ZStack {
                HStack {
                    Circle()
                        .fill(connectivity.isReachable ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                        .padding(.leading, 4)
                        .animation(.easeInOut(duration: 0.3), value: connectivity.isReachable)
                    Spacer()
                }
                
                Text("Half \(matchManager.currentHalf)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 补时推荐显示
            if matchManager.recommendedStoppageTime > 0 {
                VStack(spacing: 2) {
                    Text("Recommended Stoppage:")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("+\(formatStoppageTime(matchManager.recommendedStoppageTime))")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
                .transition(.opacity)
            } else {
                // Feedback 提示
                if showFeedback {
                    Text(feedbackMessage)
                        .font(.caption2)
                        .foregroundColor(.green)
                        .transition(.opacity)
                        .padding(.top, 2)
                }
            }


            // Timer (高精度显示)
            Text(formatTime(currentDisplayTime))
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
                // ✅ 恢复：使用最简洁的语法 (依赖于 DerivedData 的清理)
                Button { matchManager.isGoalSheetPresented = true } label: {
                    Image(systemName: "soccerball")
                }
                .disabled(!matchManager.isRunning)
                
                // ✅ 恢复：使用最简洁的语法
                Button { matchManager.isCardSheetPresented = true } label: {
                    Image(systemName: "rectangle.fill.on.rectangle.fill")
                }
                .disabled(!matchManager.isRunning)
                
                // ✅ 恢复：使用最简洁的语法
                Button { matchManager.isSubstitutionSheetPresented = true } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .disabled(!matchManager.isRunning)
            }
            .font(.title3)

            // Control Buttons
            HStack(spacing: 8) {
                
                // 控制键：Kick-off / Stop Time
                Button(matchManager.isRunning ? "Stop Time" : "Kick-off") {
                    if matchManager.isRunning {
                        matchManager.stopTime()
                        triggerFeedback("Interruption Recorded")
                    } else {
                        matchManager.startMatch()
                        triggerFeedback("Kick-off / Resume")
                    }
                }
                
                Button("End Half") {
                    matchManager.endHalf()
                    triggerFeedback(matchManager.currentHalf == 1 ? "Halftime" : "Full Time")
                }
                
                Button("End Match") {
                    let report = matchManager.generateMatchReport()
                    WatchConnectivityManager.shared.sendMatchReport(report)
                    matchManager.resetMatch()
                    triggerFeedback("Match Ended, Report Sent")
                }
                .disabled(matchManager.currentHalf == 1 && matchManager.isRunning)
            }
            Spacer()
        }
        // Sheets: isPresented 保持 $ 访问 Binding
        .sheet(isPresented: $matchManager.isGoalSheetPresented) {
            GoalTypeSheet(matchManager: matchManager)
        }
        .sheet(isPresented: $matchManager.isCardSheetPresented) {
            CardTypeSheet(matchManager: matchManager)
        }
        .sheet(isPresented: $matchManager.isSubstitutionSheetPresented) {
            SubstitutionSheet(matchManager: matchManager)
        }
        .animation(.easeInOut, value: matchManager.recommendedStoppageTime)
    }
    
    // MARK: - 时间格式化
    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time.rounded(.down))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let centi = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        
        return String(format: "%02d:%02d.%02d", minutes, seconds, centi)
    }
    
    private func formatStoppageTime(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60.0)
        return "\(minutes) min"
    }
    
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
