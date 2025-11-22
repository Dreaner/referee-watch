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
    
    private var phaseText: String {
        switch matchManager.currentHalf {
        case 1:
            return "Half 1"
        case 2:
            return matchManager.isHalftime ? "Halftime" : "Half 2"
        case 3:
            return "Extra Time 1"
        case 4:
            return matchManager.isHalftime ? "ET Halftime" : "Extra Time 2"
        default:
            return "Match"
        }
    }

    // 使用标准的半场时长作为计时基准，而不是实际结束时间
    private var currentDisplayTime: TimeInterval {
        let currentSessionTime = matchManager.workoutManager.elapsedTime
        
        switch matchManager.currentHalf {
        case 1:
            // 上半场进行中
            return currentSessionTime
        case 2:
            // 进入中场休息，固定显示45:00
            if matchManager.isHalftime {
                return matchManager.halfDuration
            }
            // 下半场进行中，从45:00开始累加
            return matchManager.halfDuration + currentSessionTime
        case 3:
            // 准备开始加时赛，固定显示90:00
            if !matchManager.isRunning {
                return matchManager.halfDuration * 2
            }
            // 加时赛上半场进行中，从90:00开始累加
            return (matchManager.halfDuration * 2) + currentSessionTime
        case 4:
            // 加时赛中场休息，固定显示105:00
            if matchManager.isHalftime {
                return (matchManager.halfDuration * 2) + matchManager.extraTimeHalfDuration
            }
            // 加时赛下半场进行中，从105:00开始累加
            return (matchManager.halfDuration * 2) + matchManager.extraTimeHalfDuration + currentSessionTime
        default:
            return 0
        }
    }
    
    var body: some View {
        VStack(spacing: 5) {
            Spacer()
            
            ZStack {
                HStack {
                    Circle()
                        .fill(connectivity.isReachable ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                        .padding(.leading, 4)
                        .animation(.easeInOut(duration: 0.3), value: connectivity.isReachable)
                    Spacer()
                }
                
                Text(phaseText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
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
                if showFeedback {
                    Text(feedbackMessage)
                        .font(.caption2)
                        .foregroundColor(.green)
                        .transition(.opacity)
                        .padding(.top, 2)
                }
            }

            Text(formatTime(currentDisplayTime))
                .font(.system(size: 38, weight: .bold, design: .monospaced))
            
            HStack {
                VStack {
                    Text(matchManager.homeTeamName).font(.caption2)
                    HStack(spacing: 0) {
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
                    HStack(spacing: 0) {
                        Text("\(matchManager.awayScore)").font(.title2)
                        ForEach(0..<matchManager.awayRedCards, id: \.self) { _ in
                            Text("🟥").font(.callout)
                                .foregroundColor(.red)
                        }
                    }
                }
            }

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
                Button {
                    matchManager.startMatch()
                    triggerFeedback("Kick-off")
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                }
                .tint(.green)
                .disabled(matchManager.isRunning)
                
                Button {
                    matchManager.recordStoppageTime()
                    triggerFeedback(matchManager.isStoppageRecording ? "Stoppage Recording Started" : "Stoppage Recording Ended")
                } label: {
                    Image(systemName: matchManager.isStoppageRecording ? "hourglass.bottomhalf.fill" : "hourglass.tophalf.fill")
                        .font(.title2)
                }
                .tint(.orange)
                .disabled(matchManager.isHalftime)
                
                Button {
                    if matchManager.currentHalf == 1 || matchManager.currentHalf == 3 {
                        matchManager.endHalf()
                        triggerFeedback("Half End")
                    } else {
                        matchManager.endMatch()
                        triggerFeedback("Full Time")
                    }
                } label: {
                    let isFinalPeriod = (matchManager.currentHalf == 2 || matchManager.currentHalf == 4)
                    Image(systemName: isFinalPeriod ? "stop.circle.fill" : "pause.circle.fill")
                        .font(.title2)
                }
                .tint(.red)
                .disabled(matchManager.isHalftime || !matchManager.isRunning)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 20)
        
        .sheet(isPresented: $matchManager.isGoalSheetPresented) {
            GoalTypeSheet(matchManager: matchManager)
        }
        .sheet(isPresented: $matchManager.isCardSheetPresented) {
            CardTypeSheet(matchManager: matchManager)
        }
        .sheet(isPresented: $matchManager.isSubstitutionSheetPresented) {
            SubstitutionSheet(matchManager: matchManager)
        }
        .sheet(isPresented: $matchManager.isShowingPenaltyShootout) {
            PenaltyShootoutView(
                homeTeamName: matchManager.homeTeamName,
                awayTeamName: matchManager.awayTeamName
            ) { homePenaltyScore, awayPenaltyScore in
                matchManager.homePenaltyScore = homePenaltyScore
                matchManager.awayPenaltyScore = awayPenaltyScore
                matchManager.finishMatchAndReset()
            }
        }
        .animation(.easeInOut, value: matchManager.recommendedStoppageTime)
        .confirmationDialog("Regulation Time End", isPresented: $matchManager.isShowingEndGameOptions) {
            Button("Finish Match") {
                matchManager.finishMatchAndReset()
            }
            Button("Extra Time") {
                matchManager.startExtraTime()
            }
            Button("Penalties") {
                matchManager.startPenaltyShootout()
            }
            Button("Cancel", role: .cancel) {
            }
        }
    }
    
    // MARK: - 时间格式化
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
