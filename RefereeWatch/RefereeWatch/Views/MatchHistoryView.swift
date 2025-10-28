//
//  MatchHistoryView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 28/10/25.
//

//
//  MatchHistoryView.swift
//  RefereeWatch
//

import SwiftUI

struct MatchHistoryView: View {
    @ObservedObject var connectivityManager: iPhoneConnectivityManager
    @State private var showingNewMatchView = false

    var body: some View {
        NavigationView {
            List {
                if connectivityManager.allReports.isEmpty {
                    Text("No match reports yet.")
                        .foregroundColor(.gray)
                        .font(.footnote)
                        .padding()
                } else {
                    // 使用 date 作为唯一 id
                    ForEach(connectivityManager.allReports, id: \.date) { report in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(report.homeTeam) vs \(report.awayTeam)")
                                    .font(.headline)
                                Spacer()
                                Text("\(report.homeScore) - \(report.awayScore)")
                                    .font(.subheadline)
                                    .bold()
                            }
                            Text("Date: \(formatDate(report.date))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Duration: \(Int(report.firstHalfDuration + report.secondHalfDuration)) mins")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Match History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewMatchView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewMatchView) {
                NewMatchView(connectivityManager: connectivityManager)
            }
        }
    }

    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    MatchHistoryView(connectivityManager: iPhoneConnectivityManager.shared)
}
