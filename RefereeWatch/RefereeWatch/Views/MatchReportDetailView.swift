//
//  MatchReportDetailView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 28/10/25.
//

import SwiftUI

struct MatchReportDetailView: View {
    let report: MatchReport
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(report.homeTeam) vs \(report.awayTeam)")
                    .font(.title2)
                    .bold()
                
                Text("Final Score: \(report.homeScore) - \(report.awayScore)")
                    .font(.headline)
                
                Divider()
                
                Text("Match Date: \(report.date.formatted(.dateTime.month().day().hour().minute()))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("First Half Duration: \(Int(report.firstHalfDuration))s")
                    .font(.caption)
                Text("Second Half Duration: \(Int(report.secondHalfDuration))s")
                    .font(.caption)
                
                Divider()
                
                Text("Events")
                    .font(.headline)
                if report.events.isEmpty {
                    Text("No events recorded.")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    ForEach(report.events) { event in
                        HStack {
                            Text(eventSummary(event))
                                .font(.caption)
                            Spacer()
                            Text(formatTime(event.timestamp))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Divider()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Match Report")
    }
    
    private func eventSummary(_ event: MatchEvent) -> String {
        switch event.type {
        case .goal:
            return "⚽️ \(event.team.capitalized) Goal #\(event.playerNumber ?? 0)"
        case .card:
            return "🟥/🟨 \(event.team.capitalized) \(event.cardType?.rawValue ?? "") #\(event.playerNumber ?? 0)"
        case .substitution:
            return "🔁 \(event.team.capitalized): #\(event.playerOut ?? 0) → #\(event.playerIn ?? 0)"
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
