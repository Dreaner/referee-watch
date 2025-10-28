//
//  iPhoneConnectivityManager.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 28/10/25.
//

/*
| 功能                        | 说明                        |
| ------------------------- | ------------------------- |
| **自动激活 WCSession**        | iPhone 打开 App 时即准备接收      |
| **接收手表发来的 `MatchReport`** | 自动解码为 Swift 对象            |
| **本地存储 JSON**             | 保存所有比赛记录到 Documents 目录    |
| **可多次保存**                 | 每次接收新报告都会追加到历史数组          |
| **自动加载历史记录**              | 启动时加载 `MatchReports.json` |
*/

import Foundation
import WatchConnectivity
import Combine

class iPhoneConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = iPhoneConnectivityManager()
    
    @Published var lastReceivedReport: MatchReport? = nil
    @Published var allReports: [MatchReport] = []
    
    private override init() {
        super.init()
        activateSession()
        loadSavedReports()
    }
    
    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }
    
    // MARK: - 激活 Session
    private func activateSession() {
        guard let session = session else { return }
        session.delegate = self
        session.activate()
        print("✅ iPhoneConnectivityManager activated.")
    }
    
    // MARK: - 接收来自手表的比赛报告
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let data = message["matchReport"] as? Data {
            do {
                let report = try JSONDecoder().decode(MatchReport.self, from: data)
                DispatchQueue.main.async {
                    self.lastReceivedReport = report
                    self.allReports.append(report)
                    self.saveReports()
                    print("✅ Received match report from Watch at \(report.date)")
                }
            } catch {
                print("❌ Failed to decode match report: \(error)")
            }
        }
    }
    
    // MARK: - 保存与加载报告
    private func reportsFileURL() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("MatchReports.json")
    }
    
    func saveReports() {
        do {
            let data = try JSONEncoder().encode(allReports)
            try data.write(to: reportsFileURL())
            print("💾 Saved \(allReports.count) reports locally.")
        } catch {
            print("❌ Failed to save reports: \(error)")
        }
    }
    
    private func loadSavedReports() {
        let url = reportsFileURL()
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let data = try Data(contentsOf: url)
            allReports = try JSONDecoder().decode([MatchReport].self, from: data)
            print("📂 Loaded \(allReports.count) saved reports.")
        } catch {
            print("❌ Failed to load saved reports: \(error)")
        }
    }
    
    // MARK: - WCSessionDelegate requirements
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ iPhone WCSession activation failed: \(error)")
        } else {
            print("✅ iPhone WCSession activated with state: \(activationState.rawValue)")
        }
    }
}

