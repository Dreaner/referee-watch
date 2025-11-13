//
//  MatchView.swift
//  RefereeWatch Watch App Watch App
//
//  Created by Xingnan Zhu on 14/10/25.
//

// 文件: RefereeWatch/RefereeWatch Watch App Watch App/Views/MatchView.swift

import SwiftUI
import WatchKit
import HealthKit

struct MatchView: View {
    @StateObject var matchManager = MatchManager()
    @ObservedObject var connectivity = WatchConnectivityManager.shared
    @State private var feedbackMessage: String = ""
    @State private var showFeedback: Bool = false
    
    // 计时器显示逻辑
    private var currentDisplayTime: TimeInterval {
        let currentSessionTime = matchManager.workoutManager.elapsedTime
        let halfDuration: TimeInterval = matchManager.halfDuration // 45 minutes (2700秒)

        if matchManager.currentHalf == 1 {
            // H1: Timer 永不停，直接显示 Session 时间
            return currentSessionTime
        } else {
            // H2:
            
            if matchManager.isHalftime {
                // 关键：H2 中场休息时，固定显示 45:00
                return halfDuration
            } else {
                // H2 运行中：45:00 + 新 Session 流逝时间
                return halfDuration + currentSessionTime
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 5) {
            Spacer()
            
            // MARK: Status Point
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
            
            // 补时推荐显示 / 严重警告 / Feedback
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
            } else if let criticalMessage = matchManager.criticalFeedbackMessage {
                Text(criticalMessage)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .transition(.opacity)
                    .padding(.top, 2)
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


            // MARK: Timer (只显示 MM:SS)
            Text(formatTime(currentDisplayTime))
                .font(.system(size: 38, weight: .bold, design: .monospaced))
            
            
            // MARK: Scoreboard
            HStack {
                VStack {
                    Text(matchManager.homeTeamName).font(.caption2)
                    // 主队红牌标记
                    HStack(spacing: 0) { // 紧密排列
                        ForEach(0..<matchManager.homeRedCards, id: \.self) { _ in
                            Text("🟥").font(.callout)
                                .foregroundColor(.red)
                        }
                        Text("\(matchManager.homeScore)").font(.title2)
                    }
                }
                Text("-").font(.title2)
                VStack {
                    Text(matchManager.awayTeamName).font(.caption2)
                    // 客队红牌标记
                    HStack(spacing: 0) { // 紧密排列
                        Text("\(matchManager.awayScore)").font(.title2)
                        ForEach(0..<matchManager.awayRedCards, id: \.self) { _ in
                            Text("🟥").font(.callout)
                                .foregroundColor(.red)
                        }
                    }
                }
            }

            // MARK: Event Buttons
            HStack(spacing: 8) {
                Button { matchManager.isGoalSheetPresented = true } label: {
                    Image(systemName: "soccerball")
                }
                .disabled(!matchManager.isRunning)
                
                Button { matchManager.isCardSheetPresented = true } label: {
                    Image(systemName: "rectangle.fill.on.rectangle.fill")
                }
                .disabled(!matchManager.isRunning)
                
                Button { matchManager.isSubstitutionSheetPresented = true } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
                .disabled(!matchManager.isRunning)
            }
            .font(.title3)

            // MARK: Control Buttons
            HStack(spacing: 8) {
                // 左键：Kick-off (固定功能，只在未运行时启动)
                Button {
                    matchManager.startMatch()
                    triggerFeedback("Kick-off / Resume")
                } label: {
                    Image(systemName: "play.circle.fill") // 播放圆圈填充图标
                        .font(.title2)
                }
                .tint(.green) // 绿色：开始
                .disabled(matchManager.isRunning) // 运行时禁用
                
                // 中键：记录补时开始/结束
                Button {
                    matchManager.recordStoppageTime()
                    triggerFeedback(matchManager.isStoppageRecording ? "Stoppage Recording Started" : "Stoppage Recording Ended")
                } label: {
                    Image(systemName: matchManager.isStoppageRecording ? "hourglass.bottomhalf.fill" : "hourglass.tophalf.fill")
                        .font(.title2)
                }
                .tint(.orange) // 橙色：补时记录
                .disabled(matchManager.isHalftime) // 半场休息时禁用
                
                // 右键：结束半场 / 结束全场
                Button {
                    if matchManager.currentHalf == 1 {
                        matchManager.endHalf()
                        triggerFeedback("Halftime")
                    } else {
                        matchManager.endMatch()
                        triggerFeedback("Match Ended")
                    }
                } label: {
                    Image(systemName: matchManager.currentHalf == 1 ? "pause.circle.fill" : "stop.circle.fill")
                        .font(.title2)
                }
                .tint(.red)
            }
        }
        .padding(.horizontal, 10) // 左右增加 10pt 间隙
        .padding(.bottom, 20)     // 底部增加 20pt 间隙 (WatchOS 默认顶部有间隙)
        
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
    
    // MARK: - 时间格式化 (只显示 MM:SS)
    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time.rounded(.down))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        return String(format: "%02d:%02d", minutes, seconds)
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

// MARK: Preview
#Preview {
    MatchView()
}
