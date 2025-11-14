//
//  TeamSelectSheet.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 22/10/25.
//

import SwiftUI

struct TeamSelectSheet: View {
    @Binding var selectedTeam: String?
    var onNext: () -> Void

    var body: some View {
        VStack {
            Text("Choose Team")
            HStack {
                Button("Home") {
                    selectedTeam = "home"
                    onNext()
                }
                Button("Away") {
                    selectedTeam = "away"
                    onNext()
                }
            }
        }
    }
}

