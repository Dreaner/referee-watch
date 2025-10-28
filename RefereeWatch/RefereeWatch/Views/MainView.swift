//
//  MainView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 28/10/25.
//

import SwiftUI

struct MainView: View {
    @StateObject private var connectivityManager = iPhoneConnectivityManager.shared
    @State private var showingHistory = false
    @State private var showingNewMatch = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Button("Show Match History") {
                    showingHistory = true
                }

                Button("Add New Match") {
                    showingNewMatch = true
                }
            }
            .navigationTitle("Referee Watch")
            .sheet(isPresented: $showingHistory) {
                MatchHistoryView(connectivityManager: connectivityManager)
            }
            .sheet(isPresented: $showingNewMatch) {
                NewMatchView(connectivityManager: connectivityManager)
            }
        }
    }
}

#Preview {
    MainView()
}
