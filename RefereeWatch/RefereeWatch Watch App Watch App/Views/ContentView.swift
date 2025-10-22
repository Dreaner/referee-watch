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
            Text(formatTime(matchManager.elapsedTime))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .padding(.top, 10)

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

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}

