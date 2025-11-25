//
//  RefereeWatchApp.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 14/10/25.
//

import SwiftUI

@main
struct RefereeWatchApp: App {
    // 1. 添加一个状态变量来控制启动画面的显示
    @State private var showLaunchScreen = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                // 你的 App 主视图，一直在底层准备好
                MainView()

                // 启动画面，覆盖在最上层
                if showLaunchScreen {
                    LaunchView()
                        .transition(.opacity) // 设置一个平滑的淡出动画
                }
            }
            .onAppear {
                // 2. 设置一个定时器，在 3 秒后隐藏启动画面
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        self.showLaunchScreen = false
                    }
                }
            }
        }
    }
}
