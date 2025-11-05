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
                    Stepper("First Half: \(Int(editedReport.firstHalfDuration))", value: $editedReport.firstHalfDuration, in: 1...120)
                    Stepper("Second Half: \(Int(editedReport.secondHalfDuration))", value: $editedReport.secondHalfDuration, in: 1...120)
                } else {
                    Text("Total: \(Int(report.firstHalfDuration + report.secondHalfDuration)) mins")
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

            // ✅ PDF Export Section
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

    // MARK: - PDF Export
    private func exportPDF() {
        let url = PDFReportGenerator.shared.generatePDF(for: report)
        generatedPDF = url
        showingShareSheet = true
    }

    // MARK: - Helper Methods
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

// MARK: - ActivityView (Share Sheet)
struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
#Preview {
    MatchReportDetailView(
        connectivityManager: iPhoneConnectivityManager.shared,
        report: MatchReport(
            date: Date(),
            homeTeam: "Team A",
            awayTeam: "Team B",
            homeScore: 2,
            awayScore: 1,
            firstHalfDuration: 45,
            secondHalfDuration: 45,
            events: []
        )
    )
}

