//
//  WatchConnectivityManager.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 25/10/25.
//

// Watch ↔ iPhone 传输

import WatchConnectivity
import Foundation


final class WatchConnectivityManager: NSObject, WCSessionDelegate {

    static let shared = WatchConnectivityManager()
    private override init() {
        super.init()
        activateSession()
    }

    private let session: WCSession = WCSession.default

    // MARK: - Activate WatchConnectivity Session
    private func activateSession() {
        guard WCSession.isSupported() else { return }
        session.delegate = self
        session.activate()
    }

    // MARK: - Send Match Events to iPhone
    func sendMatchEvents(_ events: [MatchEvent]) {
        // Convert events to a dictionary array
        let eventDicts = events.map { event in
            return [
                "id": event.id.uuidString,
                "type": event.type.rawValue,
                "team": event.team,
                "playerNumber": event.playerNumber ?? 0,
                "goalType": event.goalType?.rawValue ?? "",
                "cardType": event.cardType?.rawValue ?? "",
                "playerOut": event.playerOut ?? 0,
                "playerIn": event.playerIn ?? 0,
                "timestamp": event.timestamp
            ] as [String : Any]
        }

        let payload: [String: Any] = [
            "matchEvents": eventDicts,
            "timestamp": Date().timeIntervalSince1970
        ]

        // Send data to iPhone
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { error in
                print("Error sending match events: \(error.localizedDescription)")
            }
        } else {
            print("iPhone is not reachable")
        }
    }

    // MARK: - WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated successfully: \(activationState.rawValue)")
        }
    }

    // Required for iOS <-> watchOS message handling
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("iPhone reachability changed: \(session.isReachable)")
    }
}

