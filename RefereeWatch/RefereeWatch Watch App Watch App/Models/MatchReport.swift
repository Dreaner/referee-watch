//
//  MatchReport.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 24/10/25.
//

// “数据模型层”，负责保存整场比赛的数据结构。


import Foundation

struct MatchReport: Identifiable, Codable {
    let id = UUID()
    let homeTeam: String
    let awayTeam: String
    let homeScore: Int
    let awayScore: Int
    let events: [MatchEvent]
}

