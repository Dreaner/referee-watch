//
//  PenaltyShootoutView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 22/11/2025
//

import SwiftUI
import WatchKit

struct PenaltyShootoutView: View {
    // 外部传入的参数
    let homeTeamName: String
    let awayTeamName: String
    var onFinish: (_ homePenaltyScore: Int, _ awayPenaltyScore: Int) -> Void

    @Environment(\.dismiss) private var dismiss

    // 内部状态
    private enum Kicker { case home, away }
    @State private var homeScore = 0
    @State private var awayScore = 0
    @State private var homeKicks = 0
    @State private var awayKicks = 0
    @State private var currentKicker: Kicker = .home
    @State private var winner: String? = nil

    private var statusText: String {
        if let winnerName = winner {
            return "\(winnerName) wins!"
        }
        
        let round = (homeKicks == awayKicks) ? homeKicks + 1 : max(homeKicks, awayKicks)
        let kickerName = (currentKicker == .home) ? homeTeamName : awayTeamName
        
        if round <= 5 {
            return "Round \(round)/5: \(kickerName) kicking"
        } else {
            return "Sudden Death (\(round)): \(kickerName) kicking"
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            // 将比分和状态文字组合在一起，以确保布局稳定
            VStack {
                // 比分显示
                Text("\(homeTeamName) \(homeScore) - \(awayScore) \(awayTeamName)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.8)

                // 状态文字
                Text(statusText)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center) // 允许文本居中换行
            }
            .fixedSize(horizontal: false, vertical: true) // 允许垂直方向扩展以容纳换行文本

            Spacer()

            if winner == nil {
                // 操作按钮
                HStack(spacing: 8) {
                    Button("Goal") {
                        recordKick(didScore: true)
                    }
                    .tint(.green)
                    
                    Button("Miss") {
                        recordKick(didScore: false)
                    }
                    .tint(.red)
                }
                .font(.title3)
            } else {
                // 结束按钮
                Button("Finish & Save") {
                    onFinish(homeScore, awayScore)
                    dismiss()
                }
            }
        }
        .padding()
    }

    private func recordKick(didScore: Bool) {
        if currentKicker == .home {
            homeKicks += 1
            if didScore { homeScore += 1 }
        } else {
            awayKicks += 1
            if didScore { awayScore += 1 }
        }
        
        WKInterfaceDevice.current().play(.click)
        checkForWinner()
        
        if winner == nil {
            // 切换罚球方
            currentKicker = (currentKicker == .home) ? .away : .home
        }
    }

    private func checkForWinner() {
        // 检查前5轮内是否出现必胜情况
        if homeKicks <= 5 && awayKicks <= 5 {
            let homeRemaining = 5 - homeKicks
            if homeScore > awayScore + (5 - awayKicks) {
                winner = homeTeamName
                return
            }
            if awayScore > homeScore + homeRemaining {
                winner = awayTeamName
                return
            }
        }
        
        // 5轮罚完后判断胜负
        if homeKicks == 5 && awayKicks == 5 {
            if homeScore > awayScore {
                winner = homeTeamName
            } else if awayScore > homeScore {
                winner = awayTeamName
            }
            // 如果打平，则自动进入突然死亡，无需额外操作
        }
        
        // 突然死亡阶段判断 (每轮结束后)
        if homeKicks > 5 && homeKicks == awayKicks {
            if homeScore > awayScore {
                winner = homeTeamName
            } else if awayScore > homeScore {
                winner = awayTeamName
            }
        }
    }
}

// MARK: Preview
#Preview {
    PenaltyShootoutView(homeTeamName: "HOME", awayTeamName: "AWAY") { home, away in
        print("Final Penalty Score: \(home) - \(away)")
    }
}
