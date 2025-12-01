//
//  TeamColor.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 1/12/25.
//


import SwiftUI

// Expanded color enumeration to provide more choices
enum TeamColor: String, Codable, CaseIterable, Identifiable {
    case red, blue, green, yellow, white, black, orange, purple,
         cyan, mint, indigo, pink, brown, gray, teal

    var id: String { self.rawValue }

    var color: Color {
        switch self {
        case .red:      return .red
        case .blue:     return .blue
        case .green:    return .green
        case .yellow:   return .yellow
        case .white:    return .white
        case .black:    return .black
        case .orange:   return .orange
        case .purple:   return .purple
        case .cyan:     return .cyan
        case .mint:     return .mint
        case .indigo:   return .indigo
        case .pink:     return .pink
        case .brown:    return .brown
        case .gray:     return .gray
        case .teal:     return .teal
        }
    }

    var displayName: String {
        self.rawValue.capitalized
    }
}
