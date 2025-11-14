//
//  GoalTypeSheet.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 22/10/25.
//

import SwiftUI

struct GoalTypeSheet: View {
    @ObservedObject var matchManager: MatchManager
    @State private var selectedGoalType: GoalType? = nil
    @State private var selectedPlayer: Int? = nil
    @State private var selectedTeam: String? = nil
    @State private var step = 1

    var body: some View {
        VStack {
            if step == 1 {
                Text("Choose Goal Type")
                ForEach(GoalType.allCases, id: \.self) { type in
                    Button(type.rawValue) {
                        selectedGoalType = type
                        step = 2
                    }
                }
            } else if step == 2 {
                TeamSelectSheet(selectedTeam: $selectedTeam) {
                    step = 3
                }
            } else if step == 3 {
                KeypadNumberInputSheet(selectedNumber: $selectedPlayer) {
                    if let team = selectedTeam, let number = selectedPlayer, let goalType = selectedGoalType {
                        matchManager.addGoal(team: team, playerNumber: number, goalType: goalType)
                    }
                    matchManager.isGoalSheetPresented = false
                }
            }
        }
    }
}
