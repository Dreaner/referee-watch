//
//  MatchManager.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 22/10/25.
//

// 文件: RefereeWatch/RefereeWatch Watch App Watch App/Managers/MatchManager.swift (简洁版)

import Foundation
import Combine
import WatchKit
import HealthKit

class MatchManager: ObservableObject {
    
    // 假设 WorkoutManager.swift 文件已存在并包含 HealthKit 逻辑
    var workoutManager = WorkoutManager.shared
    
    @Published private(set) var timeAtEndOfFirstHalf: TimeInterval = 0
    
    // MARK: - Teams
    @Published var homeTeamName = "HOME"
    @Published var awayTeamName = "AWAY"

    // MARK: - Scores and state
    @Published var homeScore = 0
    @Published var awayScore = 0
    // isRunning: 指示比赛是否在 "活动" 状态 (未记录中断)
    @Published var isRunning = false
    @Published var events: [MatchEvent] = []
    
    // MARK: - Match control
    @Published var currentHalf: Int = 1
    @Published var halfDuration: TimeInterval = 45 * 60 // 45 minutes
    
    // MARK: - Stoppage Time
    @Published private(set) var totalStoppageTime: TimeInterval = 0 // 当前半场累计中断时长
    private var stoppageTimeStart: Date? // 中断开始的绝对时间戳
    @Published private(set) var recommendedStoppageTime: TimeInterval = 0 // 推荐补时值 (显示用)
    private var recommendationTimer: AnyCancellable? // 用于实时检查推荐补时的计时器
    
    // MARK: - Sheet Presentation (使用标准 Bool 类型)
    @Published var isGoalSheetPresented = false
    @Published var isCardSheetPresented = false
    @Published var isSubstitutionSheetPresented = false
    
    // MARK: - Match control
    func startMatch() {
        guard !isRunning else { return }
        
        if currentHalf == 1 {
            // 第一半：启动 HealthKit Session
            workoutManager.startWorkout()
        } else {
            // 第二半：恢复 HealthKit Session
            workoutManager.resumeWorkout()
        }

        // 累计中断时间（如果裁判是从中断状态恢复）
        if let start = stoppageTimeStart {
            let interruptionDuration = Date().timeIntervalSince(start)
            totalStoppageTime += interruptionDuration
            stoppageTimeStart = nil // 清除中断开始标记
        }
        
        isRunning = true
        WKInterfaceDevice.current().play(.success)
        startRecommendationTimer() // 启动补时推荐计算
    }
    
    // 记录中断时间（Stop Time）
    func stopTime() {
        guard isRunning else { return }
        
        isRunning = false // 状态标记为中断中
        
        // 开始追踪中断时间
        if stoppageTimeStart == nil {
            stoppageTimeStart = Date()
        }
        WKInterfaceDevice.current().play(.click)
    }

    func endHalf() {
        isRunning = false // 状态标记为 Halftime/Full Time
        stopRecommendationTimer() // 停止补时推荐计算

        // 最终累计中断时间（如果当前处于中断状态）
        if let start = stoppageTimeStart {
            totalStoppageTime += Date().timeIntervalSince(start)
            stoppageTimeStart = nil
        }
        
        WKInterfaceDevice.current().play(.notification)

        if currentHalf == 1 {
            timeAtEndOfFirstHalf = workoutManager.elapsedTime
            
            print("First Half Stoppage Time: \(Int(totalStoppageTime/60)) minutes.")
            
            currentHalf = 2
            totalStoppageTime = 0
            recommendedStoppageTime = 0
        } else {
            // 比赛结束 (Full Time)
            WKInterfaceDevice.current().play(.failure)
            
            // 真正结束 HealthKit Session
            workoutManager.endWorkout()

            let report = generateMatchReport()
            WatchConnectivityManager.shared.sendMatchReport(report)
            print("📤 Match report automatically sent to iPhone: \(report.homeTeam) vs \(report.awayTeam)")
        }
    }
    
    func resetMatch() {
        workoutManager.endWorkout()
        
        homeScore = 0
        awayScore = 0
        timeAtEndOfFirstHalf = 0
        events.removeAll()
        currentHalf = 1
        isRunning = false
        totalStoppageTime = 0
        recommendedStoppageTime = 0
        stoppageTimeStart = nil
        stopRecommendationTimer()
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
            type: .goal, team: team, playerNumber: playerNumber, goalType: goalType, cardType: nil, playerOut: nil, playerIn: nil, timestamp: workoutManager.elapsedTime
        )
        addEvent(event)
    }
    
    func addCard(team: String, playerNumber: Int, cardType: CardType) {
        let event = MatchEvent(
            type: .card, team: team, playerNumber: playerNumber, goalType: nil, cardType: cardType, playerOut: nil, playerIn: nil, timestamp: workoutManager.elapsedTime
        )
        addEvent(event)
        
        // 两黄变红逻辑
        if cardType == .yellow {
            let yellowCount = events.filter { $0.team == team && $0.playerNumber == playerNumber && $0.cardType == .yellow }.count
            
            if yellowCount == 2 {
                let redEvent = MatchEvent(
                    type: .card, team: team, playerNumber: playerNumber, goalType: nil, cardType: .red, playerOut: nil, playerIn: nil, timestamp: workoutManager.elapsedTime
                )
                addEvent(redEvent)
                WKInterfaceDevice.current().play(.failure)
            }
        }
    }
    
    func addSubstitution(team: String, playerOut: Int, playerIn: Int) {
        let event = MatchEvent(
            type: .substitution, team: team, playerNumber: nil, goalType: nil, cardType: nil, playerOut: playerOut, playerIn: playerIn, timestamp: workoutManager.elapsedTime
        )
        addEvent(event)
    }

    // MARK: - Recommendation Logic
    private func startRecommendationTimer() {
        recommendationTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkStoppageRecommendation()
            }
    }
    
    private func stopRecommendationTimer() {
        recommendationTimer?.cancel()
        recommendedStoppageTime = 0
    }
    
    private func checkStoppageRecommendation() {
        let referenceDuration: TimeInterval = halfDuration // 45 * 60
        let totalElapsedTime = workoutManager.elapsedTime
        let elapsedTimeInHalf: TimeInterval
        
        if currentHalf == 1 {
            elapsedTimeInHalf = totalElapsedTime
        } else {
            elapsedTimeInHalf = totalElapsedTime - timeAtEndOfFirstHalf
        }
        
        // 1. 如果当前处于中断状态，实时计算当前的累计补时
        var currentAccumulation = totalStoppageTime
        if let start = stoppageTimeStart {
            currentAccumulation += Date().timeIntervalSince(start)
        }
        
        // 2. 检查是否达到提醒阈值 (提前 30 秒提醒)
        let alertThreshold: TimeInterval = 30
        
        if elapsedTimeInHalf >= referenceDuration - alertThreshold {
            // 将累计补时四舍五入到分钟，作为推荐值
            let roundedMinutes = (currentAccumulation / 60.0).rounded()
            recommendedStoppageTime = roundedMinutes * 60 // 存储为秒，但在 UI 中显示为分钟
        } else {
            // 在阈值之前，不显示推荐值
            recommendedStoppageTime = 0
        }
    }

    // MARK: - MatchReport
    func generateMatchReport() -> MatchReport {
        let finalFirstHalfTime = timeAtEndOfFirstHalf
        let finalSecondHalfTime = workoutManager.elapsedTime - finalFirstHalfTime
        
        return MatchReport(
            id: UUID(), date: Date(), homeTeam: homeTeamName, awayTeam: awayTeamName, homeScore: homeScore, awayScore: awayScore, firstHalfDuration: finalFirstHalfTime, secondHalfDuration: finalSecondHalfTime, events: events
        )
    }
}
