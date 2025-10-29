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
    case penalty = "Goal (Penalty)"
    case ownGoal = "Own Goal"
}

// MARK: - Card Type
enum CardType: String, Codable, CaseIterable {
    case yellow = "Yellow"
    case red = "Red"
}

// MARK: - Event Type
enum EventType: String, Codable {
    case goal
    case card
    case substitution
}

// MARK: - Match Event
struct MatchEvent: Identifiable, Codable {
    var id = UUID()
    
    var type: EventType
    var team: String           // "home" 或 "away"
    

    // Goal info
    var playerNumber: Int?
    var goalType: GoalType?

    // Card info
    var cardType: CardType?

    // Substitution info
    var playerOut: Int?
    var playerIn: Int?
    
    var timestamp: TimeInterval
}

// MARK: - Readable description
extension MatchEvent {
    var description: String {
        let minute = Int(timestamp / 60)
        switch type {
        case .goal:
            let goalDesc = goalType?.rawValue ?? "Goal"
            let player = playerNumber != nil ? "Player \(playerNumber!)" : ""
            return "\(minute)' \(team.capitalized) - \(goalDesc) \(player)".trimmingCharacters(in: .whitespaces)
        case .card:
            let cardDesc = cardType?.rawValue ?? "Card"
            let player = playerNumber != nil ? "Player \(playerNumber!)" : ""
            return "\(minute)' \(team.capitalized) - \(cardDesc) \(player)".trimmingCharacters(in: .whitespaces)
        case .substitution:
            let outPlayer = playerOut != nil ? "Player \(playerOut!)" : "Unknown"
            let inPlayer = playerIn != nil ? "Player \(playerIn!)" : "Unknown"
            return "\(minute)' \(team.capitalized) - Substitution: \(outPlayer) → \(inPlayer)"
        }
    }
}


