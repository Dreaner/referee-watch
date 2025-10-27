//
//  WatchConnectivityManager.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 25/10/25.
//

// Watch ↔ iPhone 传输

import WatchConnectivity
import SwiftUI
import Combine

class WatchConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    // Optional: 发布上次发送的报告，可供界面刷新
    @Published var lastSentReport: MatchReport? = nil
    
    private override init() {}
    
    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }
    
    // MARK: - 激活 Session
    func activate() {
        guard let session = session else { return }
        session.delegate = self
        session.activate()
    }
    
    // MARK: - 发送完整 MatchReport
    func sendWatchReport(_ report: MatchReport) {
        guard let session = session, session.isReachable else {
            print("❌ iPhone not reachable")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(report)
            let message: [String: Any] = ["matchReport": data]
            
            session.sendMessage(message, replyHandler: { _ in
                print("✅ Match report sent successfully")
            }, errorHandler: { error in
                print("❌ Failed to send match report: \(error)")
            })
            
            // 更新发布属性
            lastSentReport = report
        } catch {
            print("❌ Encoding error: \(error)")
        }
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ WCSession activation failed: \(error)")
        } else {
            print("✅ WCSession activated with state: \(activationState.rawValue)")
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("📡 Reachability changed: \(session.isReachable)")
    }
    
    // Optional: 其他 delegate 方法可根据需要实现
}


