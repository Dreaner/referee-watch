//
//  ContentView.swift
//  RefereeWatch Watch App Watch App
//
//  Created by Xingnan Zhu on 14/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var matchManager = MatchManager()

    var body: some View {
        VStack(spacing: 10) {
            
            // Timer
            Text(formatTime(matchManager.elapsedTime))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .padding(.top, 6)
            
            // Board
            HStack {
                VStack {
                    Text("HOME")
                        .font(.caption2)
                    Text("\(matchManager.homeScore)")
                        .font(.title2)
                }
                Text("-")
                    .font(.title2)
                VStack {
                    Text("AWAY")
                        .font(.caption2)
                    Text("\(matchManager.awayScore)")
                        .font(.title2)
                }
            }

            // Three events: goal, card, exchange
            HStack(spacing: 8) {
                Button(action: { matchManager.isGoalSheetPresented = true }) {
                    Image(systemName: "soccerball")
                }
                Button(action: { matchManager.isCardSheetPresented = true }) {
                    Image(systemName: "rectangle.fill.on.rectangle.fill")
                }
                Button(action: { matchManager.isSubstitutionSheetPresented = true }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                }
            }
            .font(.title3)

            // Start and End
            HStack(spacing: 10) {
                Button(matchManager.isRunning ? "Pause" : "Start") {
                    matchManager.isRunning ? matchManager.pauseMatch() : matchManager.startMatch()
                }
                Button("End") {
                    matchManager.resetMatch()
                }
            }
            .padding(.top, 5)
        }
        .sheet(isPresented: $matchManager.isGoalSheetPresented) {
            GoalTypeSheet(matchManager: matchManager)
        }
        .sheet(isPresented: $matchManager.isCardSheetPresented) {
            CardTypeSheet(matchManager: matchManager)
        }
        .sheet(isPresented: $matchManager.isSubstitutionSheetPresented) {
            SubstitutionSheet(matchManager: matchManager)
        }
    }
    
    // Format of Timer: 00:00.00
    private func formatTime(_ time: TimeInterval) -> String {
        let hundredths = Int((time * 100).rounded())
        let minutes = hundredths / 6000
        let seconds = (hundredths / 100) % 60
        let centi = hundredths % 100
        return String(format: "%02d:%02d.%02d", minutes, seconds, centi)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}

