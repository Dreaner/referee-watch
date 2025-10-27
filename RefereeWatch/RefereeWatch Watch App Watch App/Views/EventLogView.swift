//
//  EventLogView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 26/10/25.
//


import SwiftUI

struct EventLogView: View {
    @ObservedObject var matchManager: MatchManager
    
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
                // Export Button
                Button(action: {
                    exportToiPhone()
                }) {
                    HStack {
                        Spacer()
                        Text("Export to iPhone")
                            .font(.footnote)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(6)
                }
                .padding(.top, 8)
            }
            .padding()
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
        WatchConnectivityManager.shared.sendWatchReport(report)
        // Optional feedback
        WKInterfaceDevice.current().play(.click)
    }
}


#Preview {
    EventLogView(matchManager: MatchManager())
}

