//
//  LaunchView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 25/11/25.
//

import SwiftUI

struct LaunchView: View {
    // 1. 数据源：你提供的足球竞赛规则
    private let footballRules = [
        "Law 3: The minimum number of players required for a team to continue a match is seven (7).",
        "Law 5: A player is sent off if they receive a second caution (yellow card) in the same match.",
        "Law 10: A goal is scored when the whole of the ball passes over the goal line.",
        "Law 12: A challenge for the ball that endangers the safety of an opponent must be sanctioned as serious foul play.",
        "Law 12: A player is cautioned (yellow card) for delaying the restart of play.",
        "Law 11: A player is in an offside position if any part of the head, body or feet is nearer to the opponents' goal line than both the ball and the second-last opponent.",
        "Law 14: A penalty kick must be taken from the penalty mark and the kicker must be clearly identified."
    ]

    // 2. 用于动画和规则选择的状态变量
    @State private var selectedRule: String = ""
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var flagScale: CGFloat = 0.8

    var body: some View {
        ZStack {
            // 背景颜色：请替换成你的 App 的品牌绿色
            Color(red: 0.05, green: 0.8, blue: 0.15).ignoresSafeArea()

            VStack {
                Spacer()

                // Logo 图片，带有动画效果
                // 假设：你的 Logo 图片在 Assets 中名为 "CornerFlagLogo"
                // 如果没有这个图片，可以暂时用 Image(systemName: "flag.fill") 作为占位符
                Image("CornerFlagLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150) // 你可以根据需要调整 Logo 大小
                    .scaleEffect(flagScale)
                    .opacity(logoOpacity)

                Spacer()

                // 规则文本，带有动画效果
                Text(selectedRule)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .opacity(textOpacity)
                
                Spacer()
            }
        }
        .onAppear {
            // 当视图出现时，随机选择一条规则
            selectedRule = footballRules.randomElement() ?? "Welcome, Referee!"
            
            // 依次触发动画
            // Logo 动画：带有弹簧效果的放大和淡入
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                logoOpacity = 1
                flagScale = 1.0
            }

            // 文本动画：在 Logo 动画之后缓缓淡入
            withAnimation(.easeIn(duration: 0.8).delay(0.8)) {
                textOpacity = 1
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LaunchView()
}
