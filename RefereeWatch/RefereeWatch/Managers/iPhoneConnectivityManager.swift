//
//  iPhoneConnectivityManager.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 28/10/25.
//

///  本类负责 iPhone 端与 Apple Watch 的通信。
///  功能：
///  - 接收来自手表的比赛报告 (MatchReport)
///  - 自动解码并保存到本地列表 (allReports)
///  - 通过 @Published 通知 SwiftUI 界面更新
///
///  通信机制基于 WatchConnectivity (WCSession)
///  支持 sendMessage 实时传输 与 transferUserInfo 离线传输。

import Foundation
import WatchConnectivity
import Combine
import SwiftUI
import UserNotifications

final class iPhoneConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = iPhoneConnectivityManager()

    @Published var allReports: [MatchReport] = []
    private var session: WCSession?

    private override init() {
        super.init()
        /*
        // 🚨 【临时代码 1/2】: 强制清除 UserDefaults 中的旧报告，只执行一次即可
        UserDefaults.standard.removeObject(forKey: "savedReports")
        print("🗑️ Force clearing old reports.")
        */
        activateSession()
        loadReports()
        requestNotificationPermission()
    }

    // MARK: - Activate WCSession
    private func activateSession() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            print("✅ iPhone WCSession activated and ready.")
        } else {
            print("⚠️ WCSession not supported on this device.")
        }
    }

    // MARK: - Request Notification Permission
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("🔔 Notification permission granted.")
            } else {
                print("⚠️ Notification permission denied.")
            }
        }
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let data = message["matchReport"] as? Data {
            handleIncomingReportData(data)
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any]) {
        if let data = userInfo["matchReport"] as? Data {
            handleIncomingReportData(data)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let data = applicationContext["matchReport"] as? Data {
            handleIncomingReportData(data)
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ WCSession activation failed: \(error)")
        } else {
            print("✅ WCSession activated: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    func sessionReachabilityDidChange(_ session: WCSession) {}

    // MARK: - Handle Incoming Match Report
    private func handleIncomingReportData(_ data: Data) {
        do {
            let report = try JSONDecoder().decode(MatchReport.self, from: data)
            DispatchQueue.main.async {
                if !self.isReportAlreadySaved(report) {
                    self.allReports.append(report)
                    self.saveReports()
                    self.showSyncNotification(for: report)
                    print("✅ Received match from Watch: \(report.homeTeam) vs \(report.awayTeam)")
                } else {
                    print("ℹ️ Duplicate match ignored: \(report.id)")
                }
            }
        } catch {
            print("❌ Failed to decode match report: \(error)")
        }
    }

    private func isReportAlreadySaved(_ report: MatchReport) -> Bool {
        return allReports.contains { $0.id == report.id }
    }

    // MARK: - Persistence
    func saveReports() {
        do {
            let data = try JSONEncoder().encode(allReports)
            UserDefaults.standard.set(data, forKey: "savedReports")
            print("💾 Reports saved (\(allReports.count) total)")
        } catch {
            print("❌ Failed to save reports: \(error)")
        }
    }

    private func loadReports() {
        guard let data = UserDefaults.standard.data(forKey: "savedReports") else {
            
            // ========== 👇 【添加的测试回退代码块】 👇 ==========
            print("📂 No saved reports found. Injecting 3-1 sample data for testing.")
            let sampleEvents = [
                // HOME GOALS (3 total)
                MatchEvent(type: .goal, team: "home", playerNumber: 9, goalType: .normal, cardType: nil, playerOut: nil, playerIn: nil, timestamp: 15 * 60),
                MatchEvent(type: .goal, team: "home", playerNumber: 7, goalType: .normal, cardType: nil, playerOut: nil, playerIn: nil, timestamp: 48 * 60),
                MatchEvent(type: .goal, team: "home", playerNumber: 9, goalType: .normal, cardType: nil, playerOut: nil, playerIn: nil, timestamp: 75 * 60),
                        
                // AWAY GOAL (1 total)
                MatchEvent(type: .goal, team: "away", playerNumber: 11, goalType: .penalty, cardType: nil, playerOut: nil, playerIn: nil, timestamp: 90 * 60 + 20),

                // 其他事件
                MatchEvent(type: .card, team: "away", playerNumber: 4, goalType: nil, cardType: .yellow, playerOut: nil, playerIn: nil, timestamp: 32 * 60),
                MatchEvent(type: .substitution, team: "home", playerNumber: nil, goalType: nil, cardType: nil, playerOut: 10, playerIn: 18, timestamp: 60 * 60),
                MatchEvent(type: .card, team: "away", playerNumber: 4, goalType: nil, cardType: .red, playerOut: nil, playerIn: nil, timestamp: 65 * 60)
            ]

            let testReport = MatchReport(
                id: UUID(),
                date: Date().addingTimeInterval(-86400 * 3),
                homeTeam: "Dragons FC",
                awayTeam: "Eagles Utd",
                homeScore: 3,
                awayScore: 1,
                firstHalfDuration: 45 * 60,
                secondHalfDuration: 45 * 60,
                events: sampleEvents
            )
            // 覆盖旧数据并保存新数据
            self.allReports = [testReport]
            self.saveReports()

            // ========== 👆 【添加的测试回退代码块】 👆 ==========
            
            return
        }
        do {
            allReports = try JSONDecoder().decode([MatchReport].self, from: data)
            print("📂 Loaded \(allReports.count) reports from storage")
        } catch {
            print("❌ Failed to load reports: \(error)")
        }
    }
    
    // MARK: - Notification
    private func showSyncNotification(for report: MatchReport) {
        let content = UNMutableNotificationContent()
        content.title = "📥 New Match Synced"
        content.body = "\(report.homeTeam) vs \(report.awayTeam) (\(report.homeScore)-\(report.awayScore))"
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
