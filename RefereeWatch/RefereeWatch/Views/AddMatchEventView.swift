//
//  AddMatchEventView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 29/10/25.
//

/// 在手机app里添加事件，一般用于场上场下遗漏的情况，手动更正。


import SwiftUI

struct AddMatchEventView: View {
    @Binding var report: MatchReport
    @Environment(\.dismiss) var dismiss

    @State private var selectedType: EventType = .goal
    @State private var team: String = "home"
    @State private var half: Int = 1
    @State private var playerNumber: String = ""
    @State private var goalType: GoalType = .normal
    @State private var cardType: CardType = .yellow
    @State private var playerOut: String = ""
    @State private var playerIn: String = ""
    @State private var minuteInput: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Type")) {
                    Picker("Type", selection: $selectedType) {
                        Text("Goal").tag(EventType.goal)
                        Text("Card").tag(EventType.card)
                        Text("Substitution").tag(EventType.substitution)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Team")) {
                    Picker("Team", selection: $team) {
                        Text("Home").tag("home")
                        Text("Away").tag("away")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Minute")) {
                    TextField("Minute (0-120)", text: $minuteInput)
                        .keyboardType(.numberPad)
                }


                if selectedType == .goal {
                    Section(header: Text("Goal Info")) {
                        TextField("Player Number", text: $playerNumber)
                            .keyboardType(.numberPad)
                        Picker("Goal Type", selection: $goalType) {
                            ForEach(GoalType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                }

                if selectedType == .card {
                    Section(header: Text("Card Info")) {
                        TextField("Player Number", text: $playerNumber)
                            .keyboardType(.numberPad)
                        Picker("Card Type", selection: $cardType) {
                            ForEach(CardType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                }

                if selectedType == .substitution {
                    Section(header: Text("Substitution Info")) {
                        TextField("Player Out Number", text: $playerOut)
                            .keyboardType(.numberPad)
                        TextField("Player In Number", text: $playerIn)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("Add Event")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addEvent()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addEvent() {
        
        // 解析分钟输入，支持 "90+2" 格式
        let components = minuteInput.split(separator: "+").map { String($0) }
        let mainMinutes = Double(components.first ?? "0") ?? 0.0
        let stoppageMinutes = components.count > 1 ? (Double(components.last ?? "0") ?? 0.0) : 0.0
        let totalMinutes = mainMinutes + stoppageMinutes
        let timestampSeconds = totalMinutes * 60.0

        let playerNum = Int(playerNumber)
        let playerOutNum = Int(playerOut)
        let playerInNum = Int(playerIn)

        // 根据分钟数自动判断是哪个半场
        let halfForEvent = totalMinutes <= 45 ? 1 : 2

        let newEvent = MatchEvent(
            type: selectedType,
            team: team,
            half: halfForEvent,
            playerNumber: selectedType == .goal || selectedType == .card ? playerNum : nil,
            goalType: selectedType == .goal ? goalType : nil,
            cardType: selectedType == .card ? cardType : nil,
            playerOut: selectedType == .substitution ? playerOutNum : nil,
            playerIn: selectedType == .substitution ? playerInNum : nil,
            timestamp: timestampSeconds
        )

        report.events.append(newEvent)
        
        // 如果是进球事件，自动更新比分
        if newEvent.type == .goal {
            if newEvent.team == "home" {
                report.homeScore += 1
            } else {
                report.awayScore += 1
            }
        }
    }
}

#Preview {
    let sampleReport = MatchReport(
        date: Date(),
        homeTeam: "Team A",
        awayTeam: "Team B",
        homeScore: 2,
        awayScore: 1,
        firstHalfDuration: 45,
        secondHalfDuration: 45,
        events: []
    )
    AddMatchEventView(report: .constant(sampleReport))
}

