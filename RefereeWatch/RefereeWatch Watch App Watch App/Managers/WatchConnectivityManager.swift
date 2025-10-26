//
//  WatchConnectivityManager.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 25/10/25.
//

// Watch ↔ iPhone 传输

import WatchConnectivity
import Foundation

class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func sendFileToPhone(_ fileURL: URL) {
        guard WCSession.default.isReachable else {
            print("📵 iPhone 不可达")
            return
        }
        WCSession.default.transferFile(fileURL, metadata: ["type": "matchReport"])
        print("📤 报告已发送到 iPhone")
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}

