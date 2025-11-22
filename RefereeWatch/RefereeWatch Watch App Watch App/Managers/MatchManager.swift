//
//  MatchManager.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 22/10/25.
//

// 文件: RefereeWatch/RefereeWatch Watch App Watch App/Managers/MatchManager.swift (最终专业版)

import Foundation
import Combine
import WatchKit
import HealthKit

class MatchManager: ObservableObject {
    
    var workoutManager = WorkoutManager.shared
    
    @Published private(set) var timeAtEndOfFirstHalf: TimeInterval = 0
    @Published private(set) var timeAtEndOfSecondHalf: TimeInterval = 0
    @Published private(set) var timeAtEndOfETFirstHalf: TimeInterval = 0
    
    // MARK: - Teams
    @Published var homeTeamName = "HOME"
    @Published var awayTeamName = "AWAY"

    // MARK: - Scores and state
    @Published var homeScore = 0
    @Published var awayScore = 0
    @Published var homePenaltyScore: Int? = nil
    @Published var awayPenaltyScore: Int? = nil
    
    @Published var isRunning = false
    @Published var isStoppageRecording = false
    @Published var isHalftime = false
    @Published var events: [MatchEvent] = []
    
    // MARK: - Red Card Count
    @Published var homeRedCards: Int = 0
    @Published var awayRedCards: Int = 0
    
    // MARK: - Match control
    @Published var currentHalf: Int = 1
    @Published var halfDuration: TimeInterval = 45 * 60 // 45 minutes
    @Published var extraTimeHalfDuration: TimeInterval = 15 * 60
    
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

    @Published var isShowingEndGameOptions = false
    @Published var isShowingPenaltyShootout = false

    // MARK: - Match control: 左键 (Kick-off)
    func startMatch() {
        guard !isRunning else { return }
        workoutManager.startWorkout()
        isRunning = true
        isHalftime = false
        WKInterfaceDevice.current().play(.success)
        startRecommendationTimer()
        criticalFeedbackMessage = nil
    }

    // MARK: - Stoppage Logic: 中键 (Record Stoppage)
    func recordStoppageTime() {
        guard !isHalftime else {
            WKInterfaceDevice.current().play(.failure)
            return
        }

        if isStoppageRecording {
            isStoppageRecording = false
            if let start = stoppageTimeStart {
                totalStoppageTime += Date().timeIntervalSince(start)
                stoppageTimeStart = nil
            }
            WKInterfaceDevice.current().play(.success)
        } else {
            isStoppageRecording = true
            if stoppageTimeStart == nil {
                stoppageTimeStart = Date()
            }
            WKInterfaceDevice.current().play(.click)
        }
    }
    
    // MARK: - End Half/Match Logic: 右键 (End Half/End Match)
    func endHalf() {
        guard !isHalftime else {
            WKInterfaceDevice.current().play(.failure)
            return
        }

        stopRecommendationTimer()

        if isStoppageRecording, let start = stoppageTimeStart {
            totalStoppageTime += Date().timeIntervalSince(start)
            stoppageTimeStart = nil
            isStoppageRecording = false
        }
        
        WKInterfaceDevice.current().play(.notification)
        workoutManager.endWorkout()

        if currentHalf == 1 {
            timeAtEndOfFirstHalf = workoutManager.elapsedTime
            print("First Half Stoppage Time: \(Int(totalStoppageTime/60)) minutes.")
            currentHalf = 2
            isHalftime = true
        } else if currentHalf == 3 {
            timeAtEndOfETFirstHalf = workoutManager.elapsedTime
            currentHalf = 4
            isHalftime = true
        }
        
        totalStoppageTime = 0
        recommendedStoppageTime = 0
        isRunning = false
    }
    
    func endMatch() {
        guard currentHalf == 2 || currentHalf == 4 else {
            WKInterfaceDevice.current().play(.failure)
            return
        }
        isShowingEndGameOptions = true
    }
    
    func finishMatchAndReset() {
        isShowingEndGameOptions = false
        WKInterfaceDevice.current().play(.failure)
        workoutManager.endWorkout()
        let report = generateMatchReport()
        WatchConnectivityManager.shared.sendMatchReport(report)
        resetMatch()
    }
    
    func startExtraTime() {
        isShowingEndGameOptions = false
        if workoutManager.running {
            workoutManager.endWorkout()
        }
        timeAtEndOfSecondHalf = workoutManager.elapsedTime
        currentHalf = 3
        isHalftime = false
        isRunning = false
        totalStoppageTime = 0
        print("✅ Ready to start Extra Time.")
        WKInterfaceDevice.current().play(.start)
    }
    
    func startPenaltyShootout() {
        isShowingEndGameOptions = false
        if workoutManager.running {
            workoutManager.endWorkout()
        }
        isShowingPenaltyShootout = true
    }

    func resetMatch() {
        if workoutManager.running {
             workoutManager.endWorkout()
        }
        homeScore = 0
        awayScore = 0
        homePenaltyScore = nil
        awayPenaltyScore = nil
        timeAtEndOfFirstHalf = 0
        timeAtEndOfSecondHalf = 0
        timeAtEndOfETFirstHalf = 0
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
        homeRedCards = 0
        awayRedCards = 0
    }

    // MARK: - Events
    func addEvent(_ event: MatchEvent) {
        events.append(event)
        switch event.type {
        case .goal:
            if event.team == "home" { homeScore += 1 }
            else if event.team == "away" { awayScore += 1 }
        case .card:
            if event.cardType == .red {
                if event.team == "home" { homeRedCards += 1 }
                else { awayRedCards += 1 }
            }
        default: break
        }
    }
    
    func addGoal(team: String, playerNumber: Int, goalType: GoalType) {
        let event = MatchEvent(
            type: .goal, 
            team: team, 
            half: currentHalf, // ✅ 传递当前阶段
            playerNumber: playerNumber, 
            goalType: goalType, 
            cardType: nil, 
            playerOut: nil, 
            playerIn: nil, 
            timestamp: workoutManager.elapsedTime
        )
        addEvent(event)
    }
    
    func addCard(team: String, playerNumber: Int, cardType: CardType) {
        let event = MatchEvent(
            type: .card, 
            team: team, 
            half: currentHalf, // ✅ 传递当前阶段
            playerNumber: playerNumber, 
            goalType: nil, 
            cardType: cardType, 
            playerOut: nil, 
            playerIn: nil, 
            timestamp: workoutManager.elapsedTime
        )
        addEvent(event)
        
        if cardType == .yellow {
            let yellowCount = events.filter { $0.team == team && $0.playerNumber == playerNumber && $0.cardType == .yellow }.count
            
            if yellowCount == 2 {
                let redEvent = MatchEvent(
                    type: .card, 
                    team: team, 
                    half: currentHalf, // ✅ 传递当前阶段
                    playerNumber: playerNumber, 
                    goalType: nil, 
                    cardType: .red, 
                    playerOut: nil, 
                    playerIn: nil, 
                    timestamp: workoutManager.elapsedTime
                )
                addEvent(redEvent)
                WKInterfaceDevice.current().play(.failure)
                criticalFeedbackMessage = "2 YELLOWS = EXPULSION (RED)! Player #\(playerNumber)"
            }
        }
    }
    
    func addSubstitution(team: String, playerOut: Int, playerIn: Int) {
        let event = MatchEvent(
            type: .substitution, 
            team: team, 
            half: currentHalf, // ✅ 传递当前阶段
            playerNumber: nil, 
            goalType: nil, 
            cardType: nil, 
            playerOut: playerOut, 
            playerIn: playerIn, 
            timestamp: workoutManager.elapsedTime
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

    // MARK: - MatchReport
    func generateMatchReport() -> MatchReport {
        let finalFirstHalfTime = timeAtEndOfFirstHalf
        let finalSecondHalfTime = workoutManager.elapsedTime
        
        return MatchReport(
            id: UUID(), date: Date(), homeTeam: homeTeamName, awayTeam: awayTeamName, homeScore: homeScore, awayScore: awayScore,
            firstHalfDuration: finalFirstHalfTime,
            secondHalfDuration: finalSecondHalfTime,
            events: events,
            homePenaltyScore: homePenaltyScore,
            awayPenaltyScore: awayPenaltyScore
        )
    }
}
