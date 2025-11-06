//
//  MatchHistoryView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 28/10/25.
//

import SwiftUI

struct MatchHistoryView: View {
    @ObservedObject var connectivityManager: iPhoneConnectivityManager
    @State private var showingNewMatchView = false
    @State private var searchText = ""
    @State private var startDate: Date? = nil
    @State private var endDate: Date? = nil

    // MARK: - 过滤后的比赛列表
    private var filteredReports: [MatchReport] {
        connectivityManager.allReports.filter { report in
            // 日期范围筛选
            let dateMatch: Bool = {
                if let start = startDate, let end = endDate {
                    return report.date >= start && report.date <= end
                } else if let start = startDate {
                    return report.date >= start
                } else if let end = endDate {
                    return report.date <= end
                } else {
                    return true
                }
            }()

            // 搜索筛选
            let searchMatch: Bool = {
                if searchText.isEmpty { return true }
                return report.homeTeam.localizedCaseInsensitiveContains(searchText) ||
                    report.awayTeam.localizedCaseInsensitiveContains(searchText) ||
                    "\(report.homeScore)-\(report.awayScore)".contains(searchText)
            }()

            return dateMatch && searchMatch
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 10) {
                // MARK: - 日期筛选栏
                HStack {
                    Text("Date:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    DatePicker(
                        "",
                        selection: Binding(
                            get: { startDate ?? Date() },
                            set: { startDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .labelsHidden()

                    Text("–")

                    DatePicker(
                        "",
                        selection: Binding(
                            get: { endDate ?? Date() },
                            set: { endDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                }
                .padding(.horizontal)

                // MARK: - 比赛列表
                List {
                    if filteredReports.isEmpty {
                        Text("No match reports found.")
                            .foregroundColor(.gray)
                            .font(.footnote)
                            .padding()
                    } else {
                        ForEach(filteredReports, id: \.date) { report in
                            // ✅ 修复点：使用 NavigationLink 包装 VStack
                            NavigationLink(destination: MatchReportDetailView(connectivityManager: connectivityManager, report: report)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("\(report.homeTeam) vs \(report.awayTeam)")
                                            .font(.headline)
                                        Spacer()
                                        Text("\(report.homeScore) - \(report.awayScore)")
                                            .font(.subheadline)
                                            .bold()
                                    }
                                    Text("Date: \(formatDate(report.date))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    // 注意：这里将时长改为分钟，符合您的计算逻辑
                                    Text("Duration: \(Int((report.firstHalfDuration + report.secondHalfDuration) / 60)) mins")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            } // 结束 NavigationLink
                        }
                    }
                }
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            }
            .navigationTitle("Match History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewMatchView = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewMatchView) {
                NewMatchView(connectivityManager: connectivityManager)
            }
        }
    }

    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    MatchHistoryView(connectivityManager: iPhoneConnectivityManager.shared)
}

