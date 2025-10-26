//
//  MatchReportView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 24/10/25.
//


// ✅ 用途：
// 这是一个通用的数据展示模板，用来展示某场比赛的详细统计（进球、红黄牌、换人、裁判留言等）。

// ✅ 当前功能：
// 1.静态演示数据（Team A / Team B）。
// 2.可以导出 CSV 文件到 Watch 临时目录。
// 3.没有与比赛流程或按钮跳转连接。

// ✅ 适用场景：
// 查看历史比赛报告 / 读取已保存的报告 / 测试数据导出功能。


import SwiftUI

struct MatchReportView: View {
    let report: MatchReport
    @State private var refereeNote: String = ""   // 裁判留言（本地输入）
    @State private var isNoteInputPresented = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {

                // 标题
                Text("Match Details")
                    .font(.headline)
                    .padding(.bottom, 4)

                // 比分
                HStack {
                    Text(report.homeTeam)
                        .font(.title3)
                    Spacer()
                    Text("\(report.homeScore) - \(report.awayScore)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Text(report.awayTeam)
                        .font(.title3)
                }
                Divider()

                // ⚽️ 进球事件
                Section(header: Text("Goals").font(.subheadline).bold()) {
                    if report.events.filter({ $0.type == .goal }).isEmpty {
                        Text("No goals recorded.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    } else {
                        ForEach(report.events.filter { $0.type == .goal }) { event in
                            HStack {
                                Text(goalDescription(event))
                                    .font(.footnote)
                                Spacer()
                                Text(formatTime(event.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // 🟥🟨 红黄牌
                Section(header: Text("Cards").font(.subheadline).bold().padding(.top, 6)) {
                    if report.events.filter({ $0.type == .card }).isEmpty {
                        Text("No cards recorded.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    } else {
                        ForEach(report.events.filter { $0.type == .card }) { event in
                            HStack {
                                Text(cardDescription(event))
                                    .font(.footnote)
                                Spacer()
                                Text(formatTime(event.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // 🔄 换人
                Section(header: Text("Substitutions").font(.subheadline).bold().padding(.top, 6)) {
                    if report.events.filter({ $0.type == .substitution }).isEmpty {
                        Text("No substitutions recorded.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    } else {
                        ForEach(report.events.filter { $0.type == .substitution }) { event in
                            HStack {
                                Text(substitutionDescription(event))
                                    .font(.footnote)
                                Spacer()
                                Text(formatTime(event.timestamp))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // 🧾 裁判留言
                Section(header: Text("Referee Notes").font(.subheadline).bold().padding(.top, 6)) {
                    Button(action: {
                        isNoteInputPresented = true
                    }) {
                        HStack {
                            Text(refereeNote.isEmpty ? "Add a note..." : refereeNote)
                                .font(.footnote)
                                .lineLimit(2)
                            Spacer()
                            Image(systemName: "pencil")
                        }
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $isNoteInputPresented) {
                        NoteInputView(refereeNote: $refereeNote)
                    }
                }

                // 📤 导出按钮
                Button("Export to iPhone") {
                    // 未来整合 WatchConnectivityManager 导出功能
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .navigationTitle("Match Report")
    }

    // MARK: - Event Descriptions

    private func goalDescription(_ event: MatchEvent) -> String {
        let player = event.playerNumber.map { "#\($0)" } ?? ""
        let goalType = event.goalType?.rawValue ?? "Goal"
        return "\(event.team.capitalized) \(goalType) \(player)"
    }

    private func cardDescription(_ event: MatchEvent) -> String {
        let player = event.playerNumber.map { "#\($0)" } ?? ""
        let card = event.cardType?.rawValue ?? "Card"
        return "\(event.team.capitalized) \(card) \(player)"
    }

    private func substitutionDescription(_ event: MatchEvent) -> String {
        if let out = event.playerOut, let `in` = event.playerIn {
            return "\(event.team.capitalized) Sub: #\(out) → #\(`in`)"
        } else {
            return "\(event.team.capitalized) Substitution"
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}


