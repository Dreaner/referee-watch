//
//  MatchManager.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 22/10/25.
//

import Foundation
import Combine

class MatchManager: ObservableObject {
    @Published var homeScore = 0
    @Published var awayScore = 0
    @Published var isRunning = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var events: [MatchEvent] = []
    @Published var selectedTeam: String? = nil
    @Published var selectedPlayerNumber: Int? = nil
    @Published var isGoalSheetPresented = false
    @Published var isCardSheetPresented = false
    @Published var isSubstitutionSheetPresented = false

    private var timer: Timer?

    func startMatch() {
        guard !isRunning else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            self.elapsedTime += 0.01
        }
    }
    
    func pauseMatch() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func resetMatch() {
        pauseMatch()
        homeScore = 0
        awayScore = 0
        elapsedTime = 0
        events.removeAll()
    }

    func addEvent(_ event: MatchEvent) {
        events.append(event)
        if event.type == .goal {
            if event.team == "home" {
                homeScore += 1
            } else if event.team == "away" {
                awayScore += 1
            }
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
}
