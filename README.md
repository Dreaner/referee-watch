# ⚽️ Referee Watch

**Referee Watch** is a companion app system for football referees, designed for both **Apple Watch** and **iPhone**.  
It helps referees record, manage, and analyze match data — from live in-game events to post-match statistics.

---

## 📱 Features Overview

### 🕒 Apple Watch App
- **Live Match Control**
  - Start, pause, and end each half with vibration feedback.
  - Track elapsed time with millisecond precision.
- **Event Logging**
  - Record **goals**, **cards**, and **substitutions** in real-time.
  - Automatically detects “two yellow cards = red card”.
- **Match Reports**
  - Automatically generate structured match reports (`MatchReport` model).
  - Manually export or auto-sync reports to the iPhone app.
- **iPhone Connection Status**
  - Real-time green/red dot indicator showing connectivity with the iPhone.

---

### 📲 iPhone App
- **Current Match View**
  - Review and edit the latest match data from the Watch.
  - Modify scores, team names, and recorded events.
- **Match History**
  - View a list of all saved matches with date, duration, and results.
  - Add or edit reports manually.
- **Statistics Dashboard**
  - Track total matches, goals, cards, and player stats.
  - Provides averages and team-based summaries.
- **Profile Page**
  - User info, app version, and data sync options.

---

## 🔗 Watch ↔️ iPhone Connectivity

Referee Watch uses **WatchConnectivity (WCSession)** to synchronize data between devices:

- **`sendMessage`** → Instant delivery when both devices are connected.
- **`transferUserInfo`** → Reliable background transfer when offline.
- Every match report is uniquely identified using a `UUID` to prevent duplicates.

### Key Files
- `WatchConnectivityManager.swift` – Handles outbound communication from Watch.
- `iPhoneConnectivityManager.swift` – Receives, decodes, and stores reports on iPhone.
- `MatchManager.swift` – Manages in-match state, timing, and event logic.
- `MatchReport.swift` – Data model representing each recorded match.

---

## 🧠 Architecture Overview
| Layer | Role |
|-------|------|
| **Data Models** | `MatchReport`, `MatchEvent`, `GoalType`, `CardType` |
| **Managers** | Handle state (`MatchManager`) and connectivity (`ConnectivityManager`) |
| **Views (Watch)** | `MatchView`, `EventLogView`, `GoalTypeSheet`, `CardTypeSheet`, etc. |
| **Views (iPhone)** | `CurrentMatchView`, `MatchHistoryView`, `StatsView`, `ProfileView` |

---

## 🧩 Future Development
- [ ] iCloud sync for cross-device backup  
- [ ] CSV/JSON export of match data  
- [ ] Visual charts for team and player statistics  
- [ ] Multi-match management  
- [ ] Notification & reminder system for upcoming games  

---

## 🏗️ Tech Stack
- **SwiftUI** – UI for both iPhone & Watch apps  
- **WatchConnectivity** – Device communication framework  
- **Combine** – Real-time data binding  
- **UserDefaults** – Lightweight local data persistence  

---

## 🧾 License
This project is licensed under the MIT License.  
© 2025 **Xingnan Zhu** – Referee Watch Project

