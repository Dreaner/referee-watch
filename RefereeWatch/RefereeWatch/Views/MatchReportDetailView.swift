//
//  MatchReportDetailView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 28/10/25.
//

import SwiftUI

struct MatchReportDetailView: View {
    @ObservedObject var connectivityManager: iPhoneConnectivityManager
    var report: MatchReport

    @State private var isEditing = false
    @State private var editedReport: MatchReport
    @State private var showingAddEvent = false
    @State private var showingShareSheet = false
    @State private var generatedPDF: URL?

    init(connectivityManager: iPhoneConnectivityManager, report: MatchReport) {
        self.connectivityManager = connectivityManager
        self.report = report
        _editedReport = State(initialValue: report)
    }

    var body: some View {
        Form {
            Section(header: Text("Teams")) {
                if isEditing {
                    TextField("Home Team", text: $editedReport.homeTeam)
                    TextField("Away Team", text: $editedReport.awayTeam)
                } else {
                    Text("\(report.homeTeam) vs \(report.awayTeam)")
                }
            }

            Section(header: Text("Score")) {
                if isEditing {
                    Stepper("Home Score: \(editedReport.homeScore)", value: $editedReport.homeScore, in: 0...20)
                    Stepper("Away Score: \(editedReport.awayScore)", value: $editedReport.awayScore, in: 0...20)
                } else {
                    Text("\(report.homeScore) - \(report.awayScore)")
                        .font(.headline)
                }
            }

            Section(header: Text("Duration")) {
                if isEditing {
                    Stepper("First Half: \(Int(editedReport.firstHalfDuration / 60.0)) mins",
                            value: Binding(
                                get: { editedReport.firstHalfDuration / 60.0 },
                                set: { editedReport.firstHalfDuration = $0 * 60.0 }
                            ),
                            in: 1...120)
                                    
                    Stepper("Second Half: \(Int(editedReport.secondHalfDuration / 60.0)) mins",
                            value: Binding(
                                get: { editedReport.secondHalfDuration / 60.0 },
                                set: { editedReport.secondHalfDuration = $0 * 60.0 }
                            ),
                            in: 1...120)
                } else {
                    let totalMinutes = (report.firstHalfDuration + report.secondHalfDuration) / 60.0
                    Text("Total: \(Int(totalMinutes.rounded())) mins")
                }
            }

            Section(header: Text("Date")) {
                if isEditing {
                    DatePicker("Match Date", selection: $editedReport.date, displayedComponents: .date)
                } else {
                    Text(formatDate(report.date))
                }
            }

            Section(header: Text("Events")) {
                if editedReport.events.isEmpty {
                    Text("No events recorded.")
                        .foregroundColor(.gray)
                        .font(.footnote)
                } else {
                    ForEach(Array(editedReport.events.enumerated()), id: \.offset) { index, event in
                        HStack {
                            Text(event.description)
                            Spacer()
                            if isEditing {
                                Button(role: .destructive) {
                                    editedReport.events.remove(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                    }
                }

                if isEditing {
                    Button("Add Event") {
                        showingAddEvent = true
                    }
                }
            }

            Section {
                Button {
                    exportPDF()
                } label: {
                    HStack {
                        Image(systemName: "doc.richtext")
                        Text("Export PDF Report")
                    }
                }
            }
        }
        .navigationTitle("Match Detail")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            AddMatchEventView(report: $editedReport)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let generatedPDF {
                ActivityView(activityItems: [generatedPDF])
            }
        }
    }

    private func exportPDF() {
        let url = PDFReportGenerator.shared.generatePDF(for: report)
        generatedPDF = url
        showingShareSheet = true
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func saveChanges() {
        if let index = connectivityManager.allReports.firstIndex(where: {
            $0.id == report.id
        }) {
            connectivityManager.allReports[index] = editedReport
            connectivityManager.saveReports()
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

#Preview {
    let sampleEvents = [
        MatchEvent(
            type: .goal,
            team: "home",
            half: 1,
            playerNumber: 9,
            goalType: .normal,
            cardType: nil,
            playerOut: nil,
            playerIn: nil,
            timestamp: 15 * 60
        ),
        MatchEvent(
            type: .goal,
            team: "home",
            half: 2,
            playerNumber: 7,
            goalType: .normal,
            cardType: nil,
            playerOut: nil,
            playerIn: nil,
            timestamp: 48 * 60
        ),
        MatchEvent(
            type: .goal,
            team: "home",
            half: 2,
            playerNumber: 9,
            goalType: .normal,
            cardType: nil,
            playerOut: nil,
            playerIn: nil,
            timestamp: 75 * 60
        ),
        
        MatchEvent(
            type: .goal,
            team: "away",
            half: 2,
            playerNumber: 11,
            goalType: .penalty,
            cardType: nil,
            playerOut: nil,
            playerIn: nil,
            timestamp: 90 * 60 + 20
        ),

        MatchEvent(
            type: .card,
            team: "away",
            half: 1,
            playerNumber: 4,
            goalType: nil,
            cardType: .yellow,
            playerOut: nil,
            playerIn: nil,
            timestamp: 32 * 60
        ),
        MatchEvent(
            type: .substitution,
            team: "home",
            half: 2,
            playerNumber: nil,
            goalType: nil,
            cardType: nil,
            playerOut: 10,
            playerIn: 18,
            timestamp: 60 * 60
        ),
        MatchEvent(
            type: .card,
            team: "away",
            half: 2,
            playerNumber: 4,
            goalType: nil,
            cardType: .red,
            playerOut: nil,
            playerIn: nil,
            timestamp: 65 * 60
        )
    ]

    let testReport = MatchReport(
        date: Date().addingTimeInterval(-86400 * 3),
        homeTeam: "Dragons FC",
        awayTeam: "Eagles Utd",
        homeScore: 3,
        awayScore: 1,
        firstHalfDuration: 45 * 60,
        secondHalfDuration: 45 * 60,
        events: sampleEvents
    )

    return MatchReportDetailView(
        connectivityManager: iPhoneConnectivityManager.shared,
        report: testReport
    )
}
