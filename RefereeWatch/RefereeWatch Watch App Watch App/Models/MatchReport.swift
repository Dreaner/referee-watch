//
//  MatchReport.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 24/10/25.
//

// “数据模型层”，负责保存整场比赛的数据结构。


import Foundation

// 比赛报告内的数据
struct MatchReport: Identifiable, Codable {
    var id = UUID()
    var homeTeam: String
    var awayTeam: String
    var homeScore: Int
    var awayScore: Int
    var goals: [GoalEvent]
    var cards: [CardEvent]
    var substitutions: [SubstitutionEvent]
    var refereeNote: String?
}

struct GoalEvent: Identifiable, Codable {
    var id = UUID()
    var minute: Int
    var team: String
    var number: Int
    var player: String
    var type: String // 普通进球、点球、乌龙等
}

struct CardEvent: Identifiable, Codable {
    var id = UUID()
    var minute: Int
    var team: String
    var number: Int
    var player: String
    var cardType: String // 黄牌、红牌
    var reason: String?
}

struct SubstitutionEvent: Identifiable, Codable {
    var id = UUID()
    var minute: Int
    var team: String
    var numberOut: Int
    var playerOut: String
    var numberIn: Int
    var playerIn: String
}

