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
    @Published var events: [MatchEvent] = []
    
    // MARK: - Match control
    @Published var currentHalf: Int = 1
    @Published var halfDuration: TimeInterval = 45 * 60 // 45 minutes
    
    // MARK: - Stoppage Time
    @Published private(set) var totalStoppageTime: TimeInterval = 0
    private var stoppageTimeStart: Date?
    @Published private(set) var recommendedStoppageTime: TimeInterval = 0
    private var recommendationTimer: AnyCancellable?
    
    // MARK: - Sheet Presentation
    @Published var isGoalSheetPresented = false
    @Published var isCardSheetPresented = false
    @Published var isSubstitutionSheetPresented = false

    @Published var criticalFeedbackMessage: String? = nil
    
    // MARK: - Match control
    func startMatch() {
        guard !isRunning else { return }
        
        if currentHalf == 1 {
            workoutManager.startWorkout()
        } else {
            workoutManager.resumeWorkout()
        }

        if let start = stoppageTimeStart {
            let interruptionDuration = Date().timeIntervalSince(start)
            totalStoppageTime += interruptionDuration
            stoppageTimeStart = nil
        }
        
        isRunning = true
        WKInterfaceDevice.current().play(.success)
        startRecommendationTimer()
        criticalFeedbackMessage = nil
    }
    
    func stopTime() {
        guard isRunning else { return }
        
        isRunning = false
        
        if stoppageTimeStart == nil {
            stoppageTimeStart = Date()
        }
        WKInterfaceDevice.current().play(.click)
        criticalFeedbackMessage = nil
    }

    func endHalf() {
        isRunning = false
        stopRecommendationTimer()

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
            WKInterfaceDevice.current().play(.failure)
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
        criticalFeedbackMessage = nil
    }

    // ⚠️ 移除：adjustStoppageTime(by seconds: TimeInterval) 函数

    // MARK: - Events (保持不变)
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
            elapsedTimeInHalf = totalElapsedTime - timeAtEndOfFirstHalf
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
        let finalSecondHalfTime = workoutManager.elapsedTime - finalFirstHalfTime
        
        return MatchReport(
            id: UUID(), date: Date(), homeTeam: homeTeamName, awayTeam: awayTeamName, homeScore: homeScore, awayScore: awayScore, firstHalfDuration: finalFirstHalfTime, secondHalfDuration: finalSecondHalfTime, events: events
        )
    }
}
