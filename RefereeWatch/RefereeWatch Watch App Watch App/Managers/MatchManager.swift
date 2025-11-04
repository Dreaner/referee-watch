//
//  MatchManager.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 22/10/25.
//


import Foundation
import Combine
import WatchKit

/// 👇 MatchManager
/// 手表端比赛管理类：
/// - 控制计时、比分、事件
/// - 生成 MatchReport
/// - 比赛结束后自动通过 WatchConnectivity 发送到 iPhone

class MatchManager: ObservableObject {
    // MARK: - Teams
    @Published var homeTeamName = "HOME"
    @Published var awayTeamName = "AWAY"

    // MARK: - Scores and state
    @Published var homeScore = 0
    @Published var awayScore = 0
    @Published var isRunning = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var events: [MatchEvent] = []
    
    // MARK: - Selection & sheets
    @Published var selectedTeam: String? = nil
    @Published var selectedPlayerNumber: Int? = nil
    @Published var isGoalSheetPresented = false
    @Published var isCardSheetPresented = false
    @Published var isSubstitutionSheetPresented = false

    // MARK: - Match control
    @Published var currentHalf: Int = 1       // 1 = first half, 2 = second half
    @Published var halfDuration: TimeInterval = 45 * 60
    @Published var isPaused: Bool = false
    
    private var timer: Timer?

    // MARK: - Match control
    func startMatch() {
        guard !isRunning else { return }
        isRunning = true
        isPaused = false
        WKInterfaceDevice.current().play(.success) // 开始震动
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            self.elapsedTime += 0.01
        }
    }
    
    func pauseMatch() {
        isRunning = false
        isPaused = true
        timer?.invalidate()
        timer = nil
    }

    /// ⚽ 结束半场或整场
    func endHalf() {
        pauseMatch()
        WKInterfaceDevice.current().play(.notification) // 中场震动

        if currentHalf == 1 {
            // 切换到下半场
            currentHalf = 2
            elapsedTime = 0
        } else {
            // ✅ 比赛结束
            isRunning = false
            WKInterfaceDevice.current().play(.failure) // 终场震动

            // ⬇️ 自动生成比赛报告并同步到 iPhone
            let report = generateMatchReport()
            WatchConnectivityManager.shared.sendMatchReport(report)
            print("📤 Match report automatically sent to iPhone: \(report.homeTeam) vs \(report.awayTeam)")
        }
    }
    
    func resetMatch() {
        pauseMatch()
        homeScore = 0
        awayScore = 0
        elapsedTime = 0
        events.removeAll()
        currentHalf = 1
    }

    // MARK: - Events
    func addEvent(_ event: MatchEvent) {
        events.append(event)
        switch event.type {
        case .goal:
            if event.team == "home" { homeScore += 1 }
            else if event.team == "away" { awayScore += 1 }
        default: break
        }
    }
    
    func addGoal(team: String, playerNumber: Int, goalType: GoalType) {
        let event = MatchEvent(
            type: .goal,
            team: team,
            playerNumber: playerNumber,
            goalType: goalType,
            cardType: nil,
            playerOut: nil,
            playerIn: nil,
            timestamp: elapsedTime
        )
        addEvent(event)
    }
    
    func addCard(team: String, playerNumber: Int, cardType: CardType) {
        let event = MatchEvent(
            type: .card,
            team: team,
            playerNumber: playerNumber,
            goalType: nil,
            cardType: cardType,
            playerOut: nil,
            playerIn: nil,
            timestamp: elapsedTime
        )
        addEvent(event)
        
        // 两黄变红逻辑
        if cardType == .yellow {
            let yellowCount = events.filter {
                $0.team == team && $0.playerNumber == playerNumber && $0.cardType == .yellow
            }.count
            
            if yellowCount == 2 {
                let redEvent = MatchEvent(
                    type: .card,
                    team: team,
                    playerNumber: playerNumber,
                    goalType: nil,
                    cardType: .red,
                    playerOut: nil,
                    playerIn: nil,
                    timestamp: elapsedTime
                )
                addEvent(redEvent)
                WKInterfaceDevice.current().play(.failure)
            }
        }
    }
    
    func addSubstitution(team: String, playerOut: Int, playerIn: Int) {
        let event = MatchEvent(
            type: .substitution,
            team: team,
            playerNumber: nil,
            goalType: nil,
            cardType: nil,
            playerOut: playerOut,
            playerIn: playerIn,
            timestamp: elapsedTime
        )
        addEvent(event)
    }
    
    // MARK: - MatchReport
    func generateMatchReport() -> MatchReport {
        let firstHalfTime = currentHalf == 1 ? elapsedTime : halfDuration
        let secondHalfTime = currentHalf == 2 ? elapsedTime : 0
        return MatchReport(
            id: UUID(),
            date: Date(),
            homeTeam: homeTeamName,
            awayTeam: awayTeamName,
            homeScore: homeScore,
            awayScore: awayScore,
            firstHalfDuration: firstHalfTime,
            secondHalfDuration: secondHalfTime,
            events: events
        )
    }
}
