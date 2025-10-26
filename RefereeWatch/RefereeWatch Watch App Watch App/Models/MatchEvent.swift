//
//  MatchEvent.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 22/10/25.
//

import Foundation

// MARK: - Type of Goal
enum GoalType: String, Codable, CaseIterable {
    case normal = "Goal"
    case penalty = "Goal(Penalty)"
    case ownGoal = "Own Goal"
}

// MARK: - Red Card or Yellow Card?
enum CardType: String, Codable, CaseIterable {
    case yellow = "Yellow"
    case red = "Red"
}

// MARK: - Three events
enum EventType: String, Codable {
    case goal
    case card
    case substitution
}

// MARK: - Match Event Detail
struct MatchEvent: Identifiable, Codable {
    var id = UUID()
    var type: EventType
    var team: String // "home" 或 "away"
    var playerNumber: Int?
    var goalType: GoalType?
    var cardType: CardType?
    var playerOut: Int?
    var playerIn: Int?
    var timestamp: TimeInterval
}

