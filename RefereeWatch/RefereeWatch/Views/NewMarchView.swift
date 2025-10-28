//
//  NewMatchView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 28/10/25.
//


import SwiftUI

struct NewMatchView: View {
    @ObservedObject var connectivityManager: iPhoneConnectivityManager
    @Environment(\.dismiss) var dismiss

    @State private var homeTeam = ""
    @State private var awayTeam = ""
    @State private var homeScore = 0
    @State private var awayScore = 0
    @State private var firstHalfDuration: Double = 45.0
    @State private var secondHalfDuration: Double = 45.0
    @State private var matchDate = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Teams")) {
                    TextField("Home Team", text: $homeTeam)
                    TextField("Away Team", text: $awayTeam)
                }
                
                Section(header: Text("Score")) {
                    Stepper("Home Score: \(homeScore)", value: $homeScore, in: 0...20)
                    Stepper("Away Score: \(awayScore)", value: $awayScore, in: 0...20)
                }
                
                Section(header: Text("Half Durations (mins)")) {
                    Stepper("First Half: \(Int(firstHalfDuration))", value: $firstHalfDuration, in: 1...120, step: 1)
                    Stepper("Second Half: \(Int(secondHalfDuration))", value: $secondHalfDuration, in: 1...120, step: 1)
                }
                
                Section(header: Text("Date")) {
                    DatePicker("Match Date", selection: $matchDate, displayedComponents: .date)
                }
            }
            .navigationTitle("New Match")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveMatch()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveMatch() {
        let newReport = MatchReport(
            date: matchDate,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeScore: homeScore,
            awayScore: awayScore,
            firstHalfDuration: firstHalfDuration,
            secondHalfDuration: secondHalfDuration,
            events: []
        )
        
        connectivityManager.allReports.append(newReport)
        connectivityManager.saveReports()
    }
}

#Preview {
    NewMatchView(connectivityManager: iPhoneConnectivityManager.shared)
}

