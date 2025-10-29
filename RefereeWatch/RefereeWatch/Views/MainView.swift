//
//  MainView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 28/10/25.
//

// 应用程序入口


import SwiftUI

struct MainView: View {
    @StateObject private var connectivityManager = iPhoneConnectivityManager.shared

    var body: some View {
        TabView {
            // 📍 本场比赛
            CurrentMatchView(connectivityManager: connectivityManager)
                .tabItem {
                    Label("Current", systemImage: "sportscourt.fill")
                }

            // 📋 比赛历史
            MatchHistoryView(connectivityManager: connectivityManager)
                .tabItem {
                    Label("History", systemImage: "list.bullet.rectangle")
                }

            // 📊 统计分析
            StatsView(connectivityManager: connectivityManager)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            // 👤 用户中心
            ProfileView(connectivityManager: connectivityManager)
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
        }
    }
}

#Preview {
    MainView()
}
