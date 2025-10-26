//
//  MatchSummaryView..swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 25/10/25.
//

// 长按“结束”按钮，生成比赛报告。

import SwiftUI

struct MatchSummaryView: View {
    let report: MatchReport

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Match Report")
                    .font(.headline)

                Text("\(report.homeTeam) \(report.homeScore) - \(report.awayScore) \(report.awayTeam)")
                    .font(.title3)
                    .padding(.bottom, 4)

                if report.events.isEmpty {
                    Text("No events recorded.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                } else {
                    ForEach(report.events) { event in
                        HStack {
                            Text(eventDescription(event))
                                .font(.footnote)
                            Spacer()
                            Text(formatTime(event.timestamp))
                                .font(.caption2)
                        }
                        Divider()
                    }
                }

                Button("Export to iPhone") {
                    // 🧩 未来版本将添加导出功能
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }

    // MARK: - Event Description
    private func eventDescription(_ event: MatchEvent) -> String {
        switch event.type {
        case .goal:
            let playerText = event.playerNumber != nil ? "#\(event.playerNumber!)" : ""
            let goalText = event.goalType != nil ? "(\(event.goalType!.rawValue))" : ""
            return "\(event.team.capitalized) Goal \(playerText) \(goalText)"
        case .card:
            let cardText = event.cardType != nil ? event.cardType!.rawValue : "Card"
            let playerText = event.playerNumber != nil ? "#\(event.playerNumber!)" : ""
            return "\(event.team.capitalized) \(cardText) \(playerText)"
        case .substitution:
            if let out = event.playerOut, let `in` = event.playerIn {
                return "\(event.team.capitalized) Sub: #\(out) → #\(`in`)"
            } else {
                return "\(event.team.capitalized) Substitution"
            }
        }
    }

    // MARK: - Time Formatting
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}


