//
//  ProfileView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 29/10/25.
//

// 个人信息页面

import SwiftUI

struct ProfileView: View {
    @ObservedObject var connectivityManager: iPhoneConnectivityManager
    @State private var syncStatus: String = "Not Synced"
    @State private var showingExportAlert = false
    @State private var showingNotificationSettings = false
    @State private var showingUserManual = false // ✅ 1. 添加新的状态变量
    @State private var exportMessage: String = ""

    var body: some View {
        NavigationView {
            ScrollView { // ✅ 2. 将 VStack 放入 ScrollView，以防内容过多
                VStack(spacing: 20) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)

                    Text("Referee User")
                        .font(.title)
                        .bold()

                    Text("Certification: Level 1")
                        .foregroundColor(.secondary)

                    Text("Matches Managed: \(connectivityManager.allReports.count)")
                        .foregroundColor(.secondary)

                    Divider()

                    // 数据同步
                    Button {
                        syncData()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Sync Data")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    }

                    Text("Sync Status: \(syncStatus)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // 数据导出
                    Button {
                        exportData()
                        showingExportAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Data")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .alert(exportMessage, isPresented: $showingExportAlert) {
                        Button("OK", role: .cancel) {}
                    }

                    // 通知设置
                    Button {
                        showingNotificationSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "bell")
                            Text("Notifications")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .sheet(isPresented: $showingNotificationSettings) {
                        NotificationSettingsView()
                    }
                    
                    // 用户手册
                    Button {
                        showingUserManual = true
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle")
                            Text("User Manual")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .sheet(isPresented: $showingUserManual) {
                        UserManualView()
                    }

                    Spacer()

                    Text("App Version: 1.0.0")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle("Profile")
        }
    }

    // MARK: - Methods

    private func syncData() {
        syncStatus = "Syncing..."
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            syncStatus = "Synced"
        }
    }

    private func exportData() {
        do {
            // JSON 导出
            let jsonData = try JSONEncoder().encode(connectivityManager.allReports)
            let jsonUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("MatchReports.json")
            try jsonData.write(to: jsonUrl)
            
            // CSV 导出
            let csvString = createCSV(from: connectivityManager.allReports)
            let csvUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("MatchReports.csv")
            try csvString.write(to: csvUrl, atomically: true, encoding: .utf8)
            
            exportMessage = "Exported successfully!\nJSON: \(jsonUrl.lastPathComponent)\nCSV: \(csvUrl.lastPathComponent)"
            print("Exported JSON: \(jsonUrl)")
            print("Exported CSV: \(csvUrl)")
        } catch {
            exportMessage = "Export failed: \(error.localizedDescription)"
            print(error)
        }
    }

    private func createCSV(from reports: [MatchReport]) -> String {
        var csv = "Date,Home Team,Away Team,Home Score,Away Score,First Half,Second Half,Events\n"
        for report in reports {
            let dateStr = DateFormatter.localizedString(from: report.date, dateStyle: .short, timeStyle: .none)
            let eventsStr = report.events.map { $0.description.replacingOccurrences(of: ",", with: ";") }.joined(separator: " | ")
            csv += "\(dateStr),\(report.homeTeam),\(report.awayTeam),\(report.homeScore),\(report.awayScore),\(Int(report.firstHalfDuration)),\(Int(report.secondHalfDuration)),\(eventsStr)\n"
        }
        return csv
    }
}


// 简单的通知设置页面
struct NotificationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var matchReminder = true
    @State private var criticalEventAlert = true

    var body: some View {
        NavigationView {
            Form {
                Toggle("Match Reminder", isOn: $matchReminder)
                Toggle("Critical Event Alert", isOn: $criticalEventAlert)
            }
            .navigationTitle("Notification Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView(connectivityManager: iPhoneConnectivityManager.shared)
}
