//
//  MainView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 26/10/25.
//


import SwiftUI

struct MainView: View {
    @StateObject private var matchManager = MatchManager()
    @State private var selectedTab = 1 // 默认选中计时器页面

    var body: some View {
        TabView(selection: $selectedTab) {
            // 📄 第0页：赛前设置
            SettingsView(matchManager: matchManager)
                .tag(0)

            // 📄 第1页：计时器 + 操作面板
            MatchView(matchManager: matchManager)
                .tag(1)

            // 📄 第2页：事件记录（只读）
            EventLogView(matchManager: matchManager)
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
    }
}

// MARK: Preview
#Preview {
    MainView()
}
