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
            Text("选择队伍")
            HStack {
                Button("主队") {
                    selectedTeam = "home"
                    onNext()
                }
                Button("客队") {
                    selectedTeam = "away"
                    onNext()
                }
            }
        }
    }
}


struct NumberInputSheet: View {
    @Binding var selectedNumber: Int?
    var onConfirm: () -> Void
    @State private var input: Int = 0

    var body: some View {
        VStack {
            Text("选择球员号码")
                .font(.headline)

            Picker("号码", selection: $input) {
                ForEach(0..<100) { num in
                    Text("\(num)").tag(num)
                }
            }
            .labelsHidden()
            .frame(height: 80)

            Button("确定") {
                selectedNumber = input
                onConfirm()
            }
            .padding(.top, 5)
        }
    }
}
