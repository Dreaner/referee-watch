//
//  MainView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 26/10/25.
//


import SwiftUI

struct MainView: View {
    @StateObject private var matchManager = MatchManager()

    var body: some View {
        TabView {
            // 📄 第1页：计时器 + 操作面板
            MatchView(matchManager: matchManager)
                .tag(0)

            // 📄 第2页：事件记录（只读）
            EventLogView(matchManager: matchManager)
                .tag(1)
        }
        // ✅ 设置页面滚动模式（用表冠上下切换页面）
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
    }
}

// MARK: - 预览
#Preview {
    MainView()
}
