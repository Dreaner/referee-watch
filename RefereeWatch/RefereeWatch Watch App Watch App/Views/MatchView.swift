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
    @StateObject var matchManager = MatchManager()
    @ObservedObject var connectivity = WatchConnectivityManager.shared
    @State private var feedbackMessage: String = ""
    @State private var showFeedback: Bool = false
    
    // MARK: - 计算属性：显示当前比赛时间
    private var currentDisplayTime: TimeInterval {
        let totalElapsedTime = matchManager.workoutManager.elapsedTime // HealthKit 记录的总时间

        if matchManager.currentHalf == 1 {
            // 第一半：直接显示总时间
            return totalElapsedTime
        } else {
            // 第二半：显示时间 = 总时间 - 第一半结束时的记录时间
            let timeBase = matchManager.timeAtEndOfFirstHalf
            return totalElapsedTime - timeBase
        }
    }
    
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
                        // ✅ 使用 workoutManager.running 结合 Reachability 来判断活动状态
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
            // ✅ 使用计算属性 currentDisplayTime 显示时间
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
                        // 确保只有当 WorkoutManager 处于非运行状态时才调用 startMatch (避免重复启动)
                        if !matchManager.workoutManager.running {
                             matchManager.startMatch()
                        } else if matchManager.isPaused {
                             // 如果是暂停状态，则调用 startMatch/resume
                             matchManager.startMatch()
                        }
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
        // Sheets (保持不变)
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
        // 使用更精确的 TimeInterval 计算
        let totalSeconds = Int(time.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let centi = Int((time.truncatingRemainder(dividingBy: 1)) * 100) // 获取小数部分
        return String(format: "%02d:%02d.%02d", minutes, seconds, centi)
    }
    
    // MARK: - 提示反馈 (保持不变)
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
