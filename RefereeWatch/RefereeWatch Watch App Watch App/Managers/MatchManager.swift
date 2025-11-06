//
//  MatchManager.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 22/10/25.
//

import Foundation
import Combine
import WatchKit
import HealthKit

/// 👇 MatchManager
/// 手表端比赛管理类：
/// - 控制计时、比分、事件
/// - 生成 MatchReport
/// - 比赛结束后自动通过 WatchConnectivity 发送到 iPhone

class MatchManager: ObservableObject {
    
    // MARK: - HealthKit 依赖
    // ✅ 修正：ObservableObject 内部不能使用 @ObservedObject，直接使用 var 引用单例。
    var workoutManager = WorkoutManager.shared
    
    // MARK: - 计时状态
    // ✅ 记录第一半结束时的 HealthKit 精确时间
    @Published private(set) var timeAtEndOfFirstHalf: TimeInterval = 0

    // MARK: - Teams
    @Published var homeTeamName = "HOME"
    @Published var awayTeamName = "AWAY"

    // MARK: - Scores and state
    @Published var homeScore = 0
    @Published var awayScore = 0
    @Published var isRunning = false
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
    
    // MARK: - Match control
    func startMatch() {
        guard !isRunning else { return }
        
        if currentHalf == 1 {
            // 第一半：启动 HealthKit 会话
            workoutManager.startWorkout()
        } else {
            // 第二半：恢复 HealthKit 会话
            workoutManager.resumeWorkout()
        }
        
        isRunning = true
        isPaused = false
        WKInterfaceDevice.current().play(.success)
    }
    
    func pauseMatch() {
        // ✅ 暂停 HealthKit 会话
        workoutManager.pauseWorkout()
        
        isRunning = false
        isPaused = true
    }

    /// ⚽ 结束半场或整场
    func endHalf() {
        pauseMatch()
        WKInterfaceDevice.current().play(.notification) // 中场震动

        if currentHalf == 1 {
            // ✅ 记录第一半的精确结束时间
            timeAtEndOfFirstHalf = workoutManager.elapsedTime
            
            // 切换到下半场
            currentHalf = 2
        } else {
            // ✅ 比赛结束
            isRunning = false
            WKInterfaceDevice.current().play(.failure) // 终场震动
            
            // 结束 HealthKit 会话
            workoutManager.endWorkout()

            // ⬇️ 自动生成比赛报告并同步到 iPhone
            let report = generateMatchReport()
            WatchConnectivityManager.shared.sendMatchReport(report)
            print("📤 Match report automatically sent to iPhone: \(report.homeTeam) vs \(report.awayTeam)")
        }
    }
    
    func resetMatch() {
        // 结束 HealthKit 会话并清理状态
        workoutManager.endWorkout()
        
        // 重置 MatchManager 内部状态
        homeScore = 0
        awayScore = 0
        timeAtEndOfFirstHalf = 0
        events.removeAll()
        currentHalf = 1
        isRunning = false
        isPaused = false
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
            // ✅ 使用 HealthKit 的当前总时间
            timestamp: workoutManager.elapsedTime
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
            // ✅ 使用 HealthKit 的当前总时间
            timestamp: workoutManager.elapsedTime
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
                    // ✅ 使用 HealthKit 的当前总时间
                    timestamp: workoutManager.elapsedTime
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
            // ✅ 使用 HealthKit 的当前总时间
            timestamp: workoutManager.elapsedTime
        )
        addEvent(event)
    }
    
    // MARK: - MatchReport
    func generateMatchReport() -> MatchReport {
        // 计算第一半和第二半的精确时长
        let finalFirstHalfTime = timeAtEndOfFirstHalf
        // 如果比赛结束，计算第二半的时长；如果还在第一半（调用 endHalf 时），则第二半时长为 0
        let finalSecondHalfTime = workoutManager.elapsedTime - finalFirstHalfTime
        
        return MatchReport(
            id: UUID(),
            date: Date(),
            homeTeam: homeTeamName,
            awayTeam: awayTeamName,
            homeScore: homeScore,
            awayScore: awayScore,
            // ✅ 记录 HealthKit 测量的精确时长
            firstHalfDuration: finalFirstHalfTime,
            secondHalfDuration: finalSecondHalfTime,
            events: events
        )
    }
}
