//
//  SubstitutionSheet.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 22/10/25.
//

import SwiftUI

struct SubstitutionSheet: View {
    @ObservedObject var matchManager: MatchManager
    @State private var selectedTeam: String? = nil
    @State private var playerOut: Int? = nil
    @State private var playerIn: Int? = nil
    @State private var step = 1

    var body: some View {
        VStack {
            if step == 1 {
                TeamSelectSheet(selectedTeam: $selectedTeam) {
                    step = 2
                }
            } else if step == 2 {
                Text("Player Out")
                NumberInputSheet(selectedNumber: $playerOut) {
                    step = 3
                }
            } else if step == 3 {
                Text("Player In")
                NumberInputSheet(selectedNumber: $playerIn) {
                    if let team = selectedTeam, let out = playerOut, let inn = playerIn {
                        matchManager.addSubstitution(team: team, playerOut: out, playerIn: inn)
                    }
                    matchManager.isSubstitutionSheetPresented = false
                }
            }
        }
    }
}

