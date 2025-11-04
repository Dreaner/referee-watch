//
//  WatchConnectivityManager.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 25/10/25.
//

///  本类负责 Apple Watch 与 iPhone 的数据通信。
///  功能：
///  - 发送比赛报告 (MatchReport) 到 iPhone
///  - 自动检测 iPhone 是否在线 (isReachable)。
///  - 优先使用 sendMessage 实时发送
///  - 若 iPhone 不可达，则使用 transferUserInfo 离线传输


import Foundation
import WatchConnectivity
import Combine


final class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    @Published var isReachable: Bool = false
    private var session: WCSession?
    
    override init() {
        super.init()
        activateSession()
    }
    
    // MARK: - Activate WCSession
    private func activateSession() {
        guard WCSession.isSupported() else {
            print("⚠️ WCSession not supported on this device.")
            return
        }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        print("✅ WatchConnectivity session activated.")
    }
    
    // MARK: - Send Match Report
    func sendMatchReport(_ report: MatchReport) {
        guard let session = session else { return }
        
        do {
            let data = try JSONEncoder().encode(report)
            let message: [String: Any] = ["matchReport": data]
            
            if session.isReachable {
                // ✅ 实时传输
                session.sendMessage(message, replyHandler: { reply in
                    print("✅ Match report sent successfully, reply: \(reply)")
                }, errorHandler: { error in
                    print("⚠️ sendMessage failed (\(error.localizedDescription)), fallback to transferUserInfo.")
                    self.transferReportBackup(report)
                })
            } else {
                // 📦 离线队列传输
                transferReportBackup(report)
            }
            
        } catch {
            print("❌ Encoding match report failed: \(error)")
        }
    }
    
    // MARK: - Reliable Background Transfer
    private func transferReportBackup(_ report: MatchReport) {
        do {
            let info = try JSONEncoder().encode(report)
            session?.transferUserInfo(["matchReport": info])
            print("📤 transferUserInfo queued for delivery when connected.")
        } catch {
            print("❌ transferUserInfo encoding failed: \(error)")
        }
    }
    
    // MARK: - WCSessionDelegate
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("🔄 iPhone Reachability changed: \(self.isReachable)")
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("✅ WCSession activated with state: \(activationState.rawValue)")
            self.isReachable = session.isReachable
        }
    }
}
