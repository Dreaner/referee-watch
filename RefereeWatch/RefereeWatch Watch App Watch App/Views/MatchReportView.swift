//
//  MatchReportView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 24/10/25.
//

// 在 Apple Watch 上显示比赛统计数据


import SwiftUI

struct MatchReportView: View {
    
    // 模拟一场比赛
    @State private var report = MatchReport(
        homeTeam: "Team A",
        awayTeam: "Team B",
        homeScore: 2,
        awayScore: 1,
        goals: [
            GoalEvent(minute: 12, team: "Team A", number: 2, player: "Player 9", type: "普通进球"),
            GoalEvent(minute: 45, team: "Team A", number: 2, player: "Player 10", type: "点球"),
            GoalEvent(minute: 68, team: "Team B", number: 2, player: "Player 7", type: "普通进球")
        ],
        cards: [
            CardEvent(minute: 30, team: "Team A", number: 2, player: "Player 6", cardType: "黄牌", reason: "拖延时间"),
            CardEvent(minute: 75, team: "Team B", number: 2, player: "Player 4", cardType: "红牌", reason: "暴力行为")
        ],
        substitutions: [
            SubstitutionEvent(minute: 60, team: "Team A", numberOut: 3, playerOut: "Player 8", numberIn: 4, playerIn: "Player 11")
        ],
        refereeNote: "场地良好，比赛顺利进行。"
    )
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(report.homeTeam) \(report.homeScore) : \(report.awayScore) \(report.awayTeam)")
                    .font(.headline)
                
                Section(header: Text("⚽ 进球")) {
                    ForEach(report.goals) { goal in
                        Text("\(goal.minute)' \(goal.team) - # \(goal.number) \(goal.player) (\(goal.type))")
                            .font(.footnote)
                    }
                }
                
                Section(header: Text("🟥🟨 红黄牌")) {
                    ForEach(report.cards) { card in
                        Text("\(card.minute)' \(card.team) - # \(card.number) \(card.player) \(card.cardType)")
                            .font(.footnote)
                    }
                }
                
                Section(header: Text("🔁 换人")) {
                    ForEach(report.substitutions) { sub in
                        Text("\(sub.minute)' \(sub.team): # \(sub.numberOut) \(sub.playerOut) → # \(sub.numberIn) \(sub.playerIn)")
                            .font(.footnote)
                    }
                }
                
                if let note = report.refereeNote, !note.isEmpty {
                    Section(header: Text("🗒️ 裁判留言")) {
                        Text(note).font(.footnote)
                    }
                }
                
                Button("📤 导出 CSV") {
                    exportCSV(report: report)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            .padding()
        }
    }
    
    func exportCSV(report: MatchReport) {
        let csvString = generateCSV(from: report)
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("MatchReport.csv")
        do {
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ CSV 已保存：\(fileURL)")
        } catch {
            print("❌ 导出失败：\(error)")
        }
    }
    
    func generateCSV(from report: MatchReport) -> String {
        var csv = "项目,内容\n"
        csv += "球队,\(report.homeTeam) vs \(report.awayTeam)\n"
        csv += "比分,\(report.homeScore):\(report.awayScore)\n\n"
        
        csv += "进球记录\n时间,球队,号码,球员,类型\n"
        for g in report.goals {
            csv += "\(g.minute),\(g.team),\(g.number),\(g.player),\(g.type)\n"
        }
        csv += "\n红黄牌记录\n时间,球队,号码,球员,牌,原因\n"
        for c in report.cards {
            csv += "\(c.minute),\(c.team),\(c.number),\(c.player),\(c.cardType),\(c.reason ?? "-")\n"
        }
        csv += "\n换人记录\n时间,球队,下场号码,下场球员,上场号码,上场球员\n"
        for s in report.substitutions {
            csv += "\(s.minute),\(s.team),\(s.numberOut),\(s.playerOut),\(s.numberIn),\(s.playerIn)\n"
        }
        if let note = report.refereeNote {
            csv += "\n裁判留言,\(note)\n"
        }
        return csv
    }
}


