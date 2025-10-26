//
//  CardTypeSheet.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 22/10/25.
//

import SwiftUI

struct CardTypeSheet: View {
    @ObservedObject var matchManager: MatchManager
    @State private var selectedCardType: CardType? = nil
    @State private var selectedPlayer: Int? = nil
    @State private var selectedTeam: String? = nil
    @State private var step = 1

    var body: some View {
        VStack {
            if step == 1 {
                Text("Choose Card Type")
                ForEach(CardType.allCases, id: \.self) { type in
                    Button(type.rawValue) {
                        selectedCardType = type
                        step = 2
                    }
                }
            } else if step == 2 {
                TeamSelectSheet(selectedTeam: $selectedTeam) {
                    step = 3
                }
            } else if step == 3 {
                NumberInputSheet(selectedNumber: $selectedPlayer) {
                    if let team = selectedTeam, let number = selectedPlayer, let cardType = selectedCardType {
                        matchManager.addCard(team: team, playerNumber: number, cardType: cardType)
                    }
                    matchManager.isCardSheetPresented = false
                }
            }
        }
    }
}
