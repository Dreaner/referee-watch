//
//  MatchManager.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 22/10/25.
//

// 文件: RefereeWatch/RefereeWatch Watch App Watch App/Managers/MatchManager.swift (修复 Kick-off 逻辑)

import Foundation
import Combine
import WatchKit
import HealthKit

class MatchManager: ObservableObject {
    
    var workoutManager = WorkoutManager.shared
    
    @Published private(set) var timeAtEndOfFirstHalf: TimeInterval = 0
    
    // MARK: - Teams
    @Published var homeTeamName = "HOME"
    @Published var awayTeamName = "AWAY"

    // MARK: - Scores and state
    @Published var homeScore = 0
    @Published var awayScore = 0
    @Published var isRunning = false
    @Published var isStoppageRecording = false
    @Published var isHalftime = false
    @Published var events: [MatchEvent] = []
    
    // MARK: - Match control
    @Published var currentHalf: Int = 1
    @Published var halfDuration: TimeInterval = 45 * 60 // 45 minutes
    
    // MARK: - Stoppage Time
    @Published private(set) var totalStoppageTime: TimeInterval = 0 // 当前半场累计中断时长
    private var stoppageTimeStart: Date? // 中断开始的绝对时间戳
    @Published private(set) var recommendedStoppageTime: TimeInterval = 0
    private var recommendationTimer: AnyCancellable?
    
    // MARK: - Sheet Presentation
    @Published var isGoalSheetPresented = false
    @Published var isCardSheetPresented = false
    @Published var isSubstitutionSheetPresented = false

    @Published var criticalFeedbackMessage: String? = nil
    
    // MARK: - Match control: 左键 (Kick-off)
    func startMatch() {
        // ✅ 修复：只检查是否已经在运行。允许在 isHalftime = true 时启动第二半场。
        guard !isRunning else {
             return
        }
        
        // H1 Kick-off 或 H2 Kick-off：启动 HealthKit Session
        workoutManager.startWorkout()
        
        isRunning = true
        isHalftime = false // 清除半场休息状态，允许 UI 恢复走秒
        WKInterfaceDevice.current().play(.success)
        startRecommendationTimer()
        criticalFeedbackMessage = nil
    }

    // MARK: - Stoppage Logic: 中键 (Record Stoppage)
    func recordStoppageTime() {
        guard isRunning || isStoppageRecording else {
            // 如果 Timer 还没开始，补时记录无意义
            WKInterfaceDevice.current().play(.failure)
            return
        }

        if isStoppageRecording {
            // 结束记录
            isStoppageRecording = false
            
            // 累加中断时间
            if let start = stoppageTimeStart {
                totalStoppageTime += Date().timeIntervalSince(start)
                stoppageTimeStart = nil
            }
            WKInterfaceDevice.current().play(.success)
            // Note: triggerFeedback removed, MatchView handles it now
        } else {
            // 开始记录
            isStoppageRecording = true
            
            if stoppageTimeStart == nil {
                stoppageTimeStart = Date()
            }
            WKInterfaceDevice.current().play(.click)
            // Note: triggerFeedback removed, MatchView handles it now
        }
    }
    
    // MARK: - End Half/Match Logic: 右键 (End Half/End Match)
    func endHalf() {
        guard isRunning || isHalftime else {
            // 比赛未启动，不能结束半场
            WKInterfaceDevice.current().play(.failure)
            return
        }

        stopRecommendationTimer()

        // 如果在记录补时状态下结束半场，最终累计中断时间
        if isStoppageRecording, let start = stoppageTimeStart {
            totalStoppageTime += Date().timeIntervalSince(start)
            stoppageTimeStart = nil
            isStoppageRecording = false
        }
        
        WKInterfaceDevice.current().play(.notification)

        if currentHalf == 1 {
            // H1 结束：记录时间并结束 HealthKit Session (冻结 Timer)
            workoutManager.endWorkout()
            
            timeAtEndOfFirstHalf = workoutManager.elapsedTime
            
            print("First Half Stoppage Time: \(Int(totalStoppageTime/60)) minutes.")
            currentHalf = 2
            totalStoppageTime = 0
            recommendedStoppageTime = 0
            isHalftime = true // 切换到半场休息状态，UI将冻结在 45:00
            isRunning = false
        } else {
            // End Match 逻辑现在由 EndMatch 按钮处理
        }
    }
    
    func endMatch() {
        guard currentHalf == 2 else {
            WKInterfaceDevice.current().play(.failure)
            // Note: Feedback should be handled by the MatchView button.
            return
        }
        
        WKInterfaceDevice.current().play(.failure)
        workoutManager.endWorkout()
        let report = generateMatchReport()
        WatchConnectivityManager.shared.sendMatchReport(report)
        
        // 重置所有状态
        resetMatch()
        // Note: Feedback should be handled by the MatchView button.
    }

    func resetMatch() {
        workoutManager.endWorkout()
        
        homeScore = 0
        awayScore = 0
        timeAtEndOfFirstHalf = 0
        events.removeAll()
        currentHalf = 1
        isRunning = false
        isHalftime = false
        isStoppageRecording = false
        totalStoppageTime = 0
        recommendedStoppageTime = 0
        stoppageTimeStart = nil
        stopRecommendationTimer()
        criticalFeedbackMessage = nil
    }
    
    // MARK: - Helper (保持不变)
    private func triggerFeedback(_ message: String) {
        // MatchManager now relies on MatchView for all user feedback strings.
    }

    // ... (Events, Recommendation Logic, MatchReport 保持不变)
    
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
                criticalFeedbackMessage = "2 YELLOWS = EXPULSION (RED)! Player #\(playerNumber)"
            }
        }
    }
    
    func addSubstitution(team: String, playerOut: Int, playerIn: Int) {
        let event = MatchEvent(
            type: .substitution, team: team, playerNumber: nil, goalType: nil, cardType: nil, playerOut: playerOut, playerIn: playerIn, timestamp: workoutManager.elapsedTime
        )
        addEvent(event)
    }

    // MARK: - Recommendation Logic (保持不变)
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
        let referenceDuration: TimeInterval = halfDuration
        let totalElapsedTime = workoutManager.elapsedTime
        let elapsedTimeInHalf: TimeInterval
        
        if currentHalf == 1 {
            elapsedTimeInHalf = totalElapsedTime
        } else {
            elapsedTimeInHalf = totalElapsedTime
        }
        
        var currentAccumulation = totalStoppageTime
        if let start = stoppageTimeStart {
            currentAccumulation += Date().timeIntervalSince(start)
        }
        
        let alertThreshold: TimeInterval = 30
        
        if elapsedTimeInHalf >= referenceDuration - alertThreshold {
            let roundedMinutes = (currentAccumulation / 60.0).rounded()
            recommendedStoppageTime = roundedMinutes * 60
        } else {
            recommendedStoppageTime = 0
        }
    }

    // MARK: - MatchReport (保持不变)
    func generateMatchReport() -> MatchReport {
        let finalFirstHalfTime = timeAtEndOfFirstHalf
        let finalSecondHalfTime = workoutManager.elapsedTime
        
        return MatchReport(
            id: UUID(), date: Date(), homeTeam: homeTeamName, awayTeam: awayTeamName, homeScore: homeScore, awayScore: awayScore,
            firstHalfDuration: finalFirstHalfTime,
            secondHalfDuration: finalSecondHalfTime,
            events: events
        )
    }
}
