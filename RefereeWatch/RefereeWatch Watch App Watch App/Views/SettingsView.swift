//
//  SettingsView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 30/11/25.
//


import SwiftUI

struct SettingsView: View {
    @ObservedObject var matchManager: MatchManager

    // 创建一个绑定，将 Stepper 的整数分钟值 转换为 MatchManager 的秒数
    private var halfDurationMinutes: Binding<Int> {
        Binding<Int>(
            get: { Int(self.matchManager.halfDuration / 60) },
            set: { self.matchManager.halfDuration = TimeInterval($0 * 60) }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 半场时长设置
                VStack(alignment: .leading) {
                    Text("Match Rules")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 2)
                    
                    // 修复：将 Stepper 拆分为文本和控件，以自定义字体大小
                    HStack {
                        Text("Half Duration: \(halfDurationMinutes.wrappedValue) min")
                            .font(.body) // 将字体缩小到标准大小
                        Spacer()
                        Stepper("", value: halfDurationMinutes, in: 5...60, step: 5)
                            .labelsHidden() // 隐藏 Stepper 自身的标签
                    }
                }

                Divider()

                // 球队名称设置
                VStack(alignment: .leading) {
                    Text("Team Names")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Home Team", text: $matchManager.homeTeamName)
                    TextField("Away Team", text: $matchManager.awayTeamName)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Settings") // 为可访问性添加标题
    }
}

// MARK: - 预览
#Preview {
    SettingsView(matchManager: MatchManager())
}
