//
//  RefereeWatchApp.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 14/10/25.
//

import SwiftUI

@main
struct RefereeWatchApp: App {
    // 1. 添加一个状态变量，用来控制启动画面的显示状态
    @State private var showLaunchScreen = true

    var body: some Scene {
        WindowGroup {
            // 2. 使用 ZStack 将主视图和启动画面叠在一起
            ZStack {
                // MainView 作为底层视图，一直在后台准备就绪
                MainView()

                // 如果 showLaunchScreen 为 true，就在上层显示 LaunchView
                if showLaunchScreen {
                    LaunchView()
                        .transition(.opacity) // 为消失动画设置一个平滑的淡出效果
                }
            }
            .onAppear {
                // 3. 设置一个定时器，在 3 秒后执行操作
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    // 使用 withAnimation 来让状态改变产生动画效果
                    withAnimation {
                        // 将 showLaunchScreen 设为 false，从而触发 LaunchView 的消失
                        self.showLaunchScreen = false
                    }
                }
            }
        }
    }
}
