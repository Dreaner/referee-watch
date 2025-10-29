//
//  StatsView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 29/10/25.
//

import SwiftUI

struct StatsView: View {
    @ObservedObject var connectivityManager: iPhoneConnectivityManager

    var body: some View {
        VStack(spacing: 20) {
            Text("Match Statistics")
                .font(.title)
                .bold()
            
            Text("Total Matches: \(connectivityManager.allReports.count)")
            
            let totalGoals = connectivityManager.allReports.reduce(0) { $0 + $1.homeScore + $1.awayScore }
            Text("Total Goals: \(totalGoals)")
            
            let totalEvents = connectivityManager.allReports.reduce(0) { $0 + $1.events.count }
            Text("Total Events Recorded: \(totalEvents)")
            
            Spacer()
        }
        .padding()
        .navigationTitle("Stats")
    }
}

#Preview {
    StatsView(connectivityManager: iPhoneConnectivityManager.shared)
}
