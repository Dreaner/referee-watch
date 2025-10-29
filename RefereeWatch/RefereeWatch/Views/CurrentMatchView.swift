//
//  CurrentMatchView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 29/10/25.
//

import SwiftUI

struct CurrentMatchView: View {
    @ObservedObject var connectivityManager: iPhoneConnectivityManager

    var body: some View {
        VStack(spacing: 20) {
            if let lastMatch = connectivityManager.allReports.last {
                Text("\(lastMatch.homeTeam) vs \(lastMatch.awayTeam)")
                    .font(.title)
                    .bold()
                Text("\(lastMatch.homeScore) - \(lastMatch.awayScore)")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                Text("Total Duration: \(Int(lastMatch.firstHalfDuration + lastMatch.secondHalfDuration)) mins")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                NavigationLink("View Details") {
                    MatchReportDetailView(connectivityManager: connectivityManager, report: lastMatch)
                }
                .padding(.top)
            } else {
                Text("No current match data")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .navigationTitle("Current Match")
    }
}

#Preview {
    CurrentMatchView(connectivityManager: iPhoneConnectivityManager.shared)
}
