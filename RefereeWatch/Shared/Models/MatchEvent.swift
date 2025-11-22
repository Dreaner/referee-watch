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
    
    // ✅ 新增：记录事件发生的比赛阶段
    var half: Int // 1=H1, 2=H2, 3=ET1, 4=ET2

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
    // ✅ 修改：重写 description 以支持专业的补时格式
    var description: String {
        let timeString: String
        let minute = Int(ceil(timestamp / 60))
        
        // 根据比赛阶段，智能格式化时间字符串
        switch half {
        case 1: // 上半场
            if timestamp > 45 * 60 {
                let stoppageMinute = Int(ceil((timestamp - 45 * 60) / 60))
                timeString = "45+\(stoppageMinute)'"
            } else {
                timeString = "\(minute)'"
            }
        case 2: // 下半场
            if timestamp > 90 * 60 {
                let stoppageMinute = Int(ceil((timestamp - 90 * 60) / 60))
                timeString = "90+\(stoppageMinute)'"
            } else {
                timeString = "\(minute)'"
            }
        case 3: // 加时赛上半场
            if timestamp > 105 * 60 {
                let stoppageMinute = Int(ceil((timestamp - 105 * 60) / 60))
                timeString = "105+\(stoppageMinute)'"
            } else {
                timeString = "\(minute)'"
            }
        case 4: // 加时赛下半场
            if timestamp > 120 * 60 {
                let stoppageMinute = Int(ceil((timestamp - 120 * 60) / 60))
                timeString = "120+\(stoppageMinute)'"
            } else {
                timeString = "\(minute)'"
            }
        default:
            timeString = "\(minute)'"
        }
        
        // 拼接事件的具体描述
        var eventDetail: String
        switch type {
        case .goal:
            let goalDesc = goalType?.rawValue ?? "Goal"
            let player = playerNumber != nil ? "Player \(playerNumber!)" : ""
            eventDetail = "\(team.capitalized) - \(goalDesc) \(player)".trimmingCharacters(in: .whitespaces)
        case .card:
            let cardDesc = cardType?.rawValue ?? "Card"
            let player = playerNumber != nil ? "Player \(playerNumber!)" : ""
            eventDetail = "\(team.capitalized) - \(cardDesc) \(player)".trimmingCharacters(in: .whitespaces)
        case .substitution:
            let outPlayer = playerOut != nil ? "Player \(playerOut!)" : "Unknown"
            let inPlayer = playerIn != nil ? "Player \(playerIn!)" : "Unknown"
            eventDetail = "\(team.capitalized) - Substitution \(outPlayer) → \(inPlayer)"
        }
        
        return "\(timeString) \(eventDetail)"
    }
}
