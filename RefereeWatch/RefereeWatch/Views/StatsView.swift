//
//  StatsView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 29/10/25.
//

import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject var connectivityManager: iPhoneConnectivityManager

    // MARK: - 数据计算

    private var allReports: [MatchReport] {
        connectivityManager.allReports
    }

    private var totalMatches: Int { allReports.count }

    private var totalGoals: Int {
        allReports.flatMap { $0.events }.filter { $0.type == .goal }.count
    }

    private var totalYellows: Int {
        allReports.flatMap { $0.events }.filter { $0.cardType == .yellow }.count
    }

    private var totalReds: Int {
        allReports.flatMap { $0.events }.filter { $0.cardType == .red }.count
    }

    private var avgDuration: Int {
        guard totalMatches > 0 else { return 0 }
        let total = allReports.reduce(0.0) { $0 + ($1.firstHalfDuration + $1.secondHalfDuration) }
        return Int(total / Double(totalMatches) / 60) // 秒转分钟
    }

    // 球队进球统计
    private var teamGoals: [(String, Int)] {
        var dict: [String: Int] = [:]
        for report in allReports {
            dict[report.homeTeam, default: 0] += report.events.filter { $0.team == "home" && $0.type == .goal }.count
            dict[report.awayTeam, default: 0] += report.events.filter { $0.team == "away" && $0.type == .goal }.count
        }
        return dict.sorted { $0.value > $1.value }
    }

    // 球员事件统计
    private var playerStats: [(String, (goals: Int, yellows: Int, reds: Int))] {
        var dict: [String: (goals: Int, yellows: Int, reds: Int)] = [:]
        for event in allReports.flatMap({ $0.events }) {
            guard let num = event.playerNumber else { continue }
            let id = "#\(num)"
            var current = dict[id] ?? (0, 0, 0)
            switch event.type {
            case .goal:
                current.goals += 1
            case .card:
                if event.cardType == .yellow {
                    current.yellows += 1
                } else if event.cardType == .red {
                    current.reds += 1
                }
            default:
                break
            }
            dict[id] = current
        }
        return dict.sorted { $0.value.goals > $1.value.goals }
    }

    // 每场比赛的总进球，用于折线图
    private var goalsOverTime: [(Date, Int)] {
        allReports.map { report in
            let goals = report.events.filter { $0.type == .goal }.count
            return (report.date, goals)
        }
    }

    // MARK: - 主视图
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Summary 卡片
                    Text("Summary")
                        .font(.headline)
                        .padding(.horizontal)

                    HStack {
                        StatCard(title: "Matches", value: "\(totalMatches)")
                        StatCard(title: "Goals", value: "\(totalGoals)")
                        StatCard(title: "Yellow", value: "\(totalYellows)")
                        StatCard(title: "Red", value: "\(totalReds)")
                    }
                    .padding(.horizontal)

                    Text("Average Duration: \(avgDuration) min")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    Divider()

                    // 球队进球柱状图
                    if !teamGoals.isEmpty {
                        Text("Goals by Team")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart(teamGoals, id: \.0) { team, goals in
                            BarMark(
                                x: .value("Team", team),
                                y: .value("Goals", goals)
                            )
                            .foregroundStyle(.blue)
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }

                    // 时间趋势折线图
                    if !goalsOverTime.isEmpty {
                        Text("Goals Over Time")
                            .font(.headline)
                            .padding(.horizontal)

                        Chart(goalsOverTime, id: \.0) { date, goals in
                            LineMark(
                                x: .value("Date", date),
                                y: .value("Goals", goals)
                            )
                            .foregroundStyle(.red)
                            .symbol(Circle())
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }

                    Divider()

                    // 球队统计列表
                    Text("Team Stats")
                        .font(.headline)
                        .padding(.horizontal)

                    if teamGoals.isEmpty {
                        Text("No team data available.")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    } else {
                        ForEach(teamGoals, id: \.0) { team, goals in
                            HStack {
                                Text(team)
                                Spacer()
                                Text("\(goals) goals")
                            }
                            .padding(.horizontal)
                            .font(.body)
                        }
                    }

                    Divider()

                    // 球员统计列表
                    Text("Player Stats")
                        .font(.headline)
                        .padding(.horizontal)

                    if playerStats.isEmpty {
                        Text("No player data available.")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    } else {
                        ForEach(playerStats, id: \.0) { player, stats in
                            HStack {
                                Text(player)
                                Spacer()
                                Text("⚽️ \(stats.goals)  🟨 \(stats.yellows)  🟥 \(stats.reds)")
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle("Statistics")
        }
    }
}

// MARK: - 简单卡片组件
struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - 预览
#Preview {
    let manager = iPhoneConnectivityManager.shared

    let events = [
        MatchEvent(type: .goal, team: "home", playerNumber: 9, goalType: .normal, cardType: nil, playerOut: nil, playerIn: nil, timestamp: 600),
        MatchEvent(type: .goal, team: "away", playerNumber: 10, goalType: .normal, cardType: nil, playerOut: nil, playerIn: nil, timestamp: 1200),
        MatchEvent(type: .card, team: "home", playerNumber: 5, goalType: nil, cardType: .yellow, playerOut: nil, playerIn: nil, timestamp: 1500),
        MatchEvent(type: .card, team: "away", playerNumber: 4, goalType: nil, cardType: .red, playerOut: nil, playerIn: nil, timestamp: 2000)
    ]

    let match = MatchReport(
        date: Date(),
        homeTeam: "Real Madrid",
        awayTeam: "Barcelona",
        homeScore: 2,
        awayScore: 1,
        firstHalfDuration: 45 * 60,
        secondHalfDuration: 45 * 60,
        events: events
    )

    manager.allReports = [match]
    return StatsView(connectivityManager: manager)
}
