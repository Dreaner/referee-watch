//
//  CurrentMatchView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 29/10/25.
//


import SwiftUI

struct CurrentMatchView: View {
    @ObservedObject var connectivityManager: iPhoneConnectivityManager
    @State private var showingAddEventView = false
    @State private var editingHomeTeam = false
    @State private var editingAwayTeam = false
    @State private var selectedReport: MatchReport?
    
    // ✅ 修复 3: 计算红牌数
    private func getRedCardCount(for team: String, in report: MatchReport) -> Int {
        return report.events.filter { $0.type == .card && $0.cardType == .red && $0.team.lowercased() == team.lowercased() }.count
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 15) {
                if let match = connectivityManager.allReports.last {
                    // MARK: - 队伍名称 (保持不变)
                    HStack {
                        if editingHomeTeam {
                            TextField("Home Team", text: Binding(
                                get: { match.homeTeam },
                                set: { updateTeamName(for: match, team: "home", newName: $0) }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            Text(match.homeTeam)
                                .font(.headline)
                                .onTapGesture { editingHomeTeam.toggle() }
                        }

                        Spacer()

                        Text("vs")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Spacer()

                        if editingAwayTeam {
                            TextField("Away Team", text: Binding(
                                get: { match.awayTeam },
                                set: { updateTeamName(for: match, team: "away", newName: $0) }
                            ))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        } else {
                            Text(match.awayTeam)
                                .font(.headline)
                                .onTapGesture { editingAwayTeam.toggle() }
                        }
                    }

                    // MARK: - 比分编辑 (同时显示红牌)
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Stepper("Home: \(match.homeScore)", value: Binding(
                                get: { match.homeScore },
                                set: { updateScore(for: match, team: "home", newValue: $0) }
                            ), in: 0...99)
                            // ✅ 修复 3: 主队红牌标注
                            if getRedCardCount(for: "home", in: match) > 0 {
                                HStack {
                                    Image(systemName: "square.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Text("\(getRedCardCount(for: "home", in: match)) Red Card(s)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Stepper("Away: \(match.awayScore)", value: Binding(
                                get: { match.awayScore },
                                set: { updateScore(for: match, team: "away", newValue: $0) }
                            ), in: 0...99)
                            // ✅ 修复 3: 客队红牌标注
                            if getRedCardCount(for: "away", in: match) > 0 {
                                HStack {
                                    Image(systemName: "square.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    Text("\(getRedCardCount(for: "away", in: match)) Red Card(s)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    Text("Duration: \(Int((match.firstHalfDuration + match.secondHalfDuration) / 60)) mins")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Divider()

                    // MARK: - 快速添加事件 (已移除，符合修复 6)

                    // MARK: - 事件列表 (保持不变)
                    List {
                        if match.events.isEmpty {
                            Text("No events yet.")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(match.events) { event in
                                HStack {
                                    eventIcon(for: event)
                                    Text(event.description)
                                        .foregroundColor(eventColor(for: event))
                                }
                            }
                            .onDelete { deleteEvent(at: $0, in: match) }
                        }
                    }

                    Button {
                        selectedReport = match
                        showingAddEventView = true
                    } label: {
                        Label("Add Event", systemImage: "plus")
                    }
                    .buttonStyle(.bordered)
                    .padding(.top)
                } else {
                    Text("No current match data.")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .navigationTitle("Current Match")
            .sheet(isPresented: $showingAddEventView) {
                if let match = selectedReport {
                    AddMatchEventView(report: binding(for: match))
                }
            }
        }
    }

    // MARK: - Helper Functions (已移除 addQuickEvent)
    // ... (其他 helper functions 保持不变)
    
    private func binding(for report: MatchReport) -> Binding<MatchReport> {
        guard let index = connectivityManager.allReports.firstIndex(where: { $0.date == report.date }) else {
            fatalError("Match not found")
        }
        return $connectivityManager.allReports[index]
    }

    private func updateTeamName(for report: MatchReport, team: String, newName: String) {
        guard let index = connectivityManager.allReports.firstIndex(where: { $0.date == report.date }) else { return }
        if team == "home" {
            connectivityManager.allReports[index].homeTeam = newName
        } else {
            connectivityManager.allReports[index].awayTeam = newName
        }
        connectivityManager.saveReports()
    }

    private func updateScore(for report: MatchReport, team: String, newValue: Int) {
        guard let index = connectivityManager.allReports.firstIndex(where: { $0.date == report.date }) else { return }
        if team == "home" {
            connectivityManager.allReports[index].homeScore = newValue
        } else {
            connectivityManager.allReports[index].awayScore = newValue
        }
        connectivityManager.saveReports()
    }

    private func deleteEvent(at offsets: IndexSet, in report: MatchReport) {
        guard let index = connectivityManager.allReports.firstIndex(where: { $0.date == report.date }) else { return }
        connectivityManager.allReports[index].events.remove(atOffsets: offsets)
        connectivityManager.saveReports()
    }

    private func eventIcon(for event: MatchEvent) -> some View {
        let symbolName: String
        let color: Color

        switch event.type {
        case .goal:
            symbolName = "soccerball"
            color = .primary
        case .card:
            symbolName = "rectangle.fill"
            color = event.cardType == .red ? .red : .yellow
        case .substitution:
            symbolName = "arrow.left.arrow.right"
            color = .primary
        }

        return Image(systemName: symbolName)
            .foregroundColor(color)
    }

    private func eventColor(for event: MatchEvent) -> Color {
        switch event.type {
        case .goal: return .blue
        case .card:
            return event.cardType == .red ? .red : .yellow
        case .substitution: return .gray
        }
    }
}

#Preview {
    // ... (Preview code remains unchanged)
    let manager = iPhoneConnectivityManager.shared

    let sampleEvents = [
        MatchEvent(
            type: .goal,
            team: "Home",
            playerNumber: 9,
            goalType: .normal,
            cardType: nil,
            playerOut: nil,
            playerIn: nil,
            timestamp: 12 * 60 // 12 分钟 → 720 秒
        ),
        MatchEvent(
            type: .card,
            team: "Away",
            playerNumber: 4,
            goalType: nil,
            cardType: .yellow,
            playerOut: nil,
            playerIn: nil,
            timestamp: 30 * 60 // 30 分钟 → 1800 秒
        ),
        MatchEvent(
            type: .substitution,
            team: "Home",
            playerNumber: nil,
            goalType: nil,
            cardType: nil,
            playerOut: 10,
            playerIn: 18,
            timestamp: 65 * 60 // 65 分钟 → 3900 秒
        )
    ]

    let sampleMatch = MatchReport(
        date: Date(),
        homeTeam: "Real Madrid",
        awayTeam: "Barcelona",
        homeScore: 2,
        awayScore: 1,
        firstHalfDuration: 45 * 60,
        secondHalfDuration: 45 * 60,
        events: sampleEvents
    )

    manager.allReports = [sampleMatch]

    return CurrentMatchView(connectivityManager: manager)
}

