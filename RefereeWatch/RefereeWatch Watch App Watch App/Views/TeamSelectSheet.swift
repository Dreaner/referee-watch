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


struct NumberInputSheet: View {
    @Binding var selectedNumber: Int?
    var onConfirm: () -> Void
    @State private var input: Int = 0

    var body: some View {
        VStack {
            Text("Choose Player No.")
                .font(.headline)

            Picker("No.", selection: $input) {
                ForEach(0..<100) { num in
                    Text("\(num)").tag(num)
                }
            }
            .labelsHidden()
            .frame(height: 80)

            Button("Enter") {
                selectedNumber = input
                onConfirm()
            }
            .padding(.top, 5)
        }
    }
}
