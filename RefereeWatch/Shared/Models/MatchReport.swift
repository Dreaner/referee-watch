//
//  MatchReport.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 24/10/25.
//

// “数据模型层”，负责保存整场比赛的数据结构。


import Foundation

struct MatchReport: Codable {
    var id: UUID = UUID()   // 唯一标识每场比赛
    var date: Date
    var homeTeam: String
    var awayTeam: String
    var homeScore: Int
    var awayScore: Int
    var firstHalfDuration: TimeInterval
    var secondHalfDuration: TimeInterval
    var events: [MatchEvent]
}

