//
//  MatchEvent.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 22/10/25.
//

import Foundation

// MARK: - 进球类型
enum GoalType: String, Codable, CaseIterable {
    case normal = "普通进球"
    case penalty = "点球"
    case ownGoal = "乌龙球"
}

// MARK: - 红黄牌类型
enum CardType: String, Codable, CaseIterable {
    case yellow = "黄牌"
    case red = "红牌"
}

// MARK: - 事件类型
enum EventType: String, Codable {
    case goal
    case card
    case substitution
}

// MARK: - 比赛事件结构
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

