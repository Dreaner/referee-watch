//
//  ContentView.swift
//  RefereeWatch Watch App Watch App
//
//  Created by Xingnan Zhu on 14/10/25.
//

import SwiftUI
import Combine
import WatchKit

// MARK: - 模型
struct MatchEvent: Identifiable {
    let id = UUID()
    let icon: String
    let time: String
    let team: String
    let type: String
    let number: String?
    let subOut: String?
    let subIn: String?
}

struct ContentView: View {
    // MARK: - 计时
    @State private var isRunning = false
    @State private var elapsed: TimeInterval = 0
    @State private var timerCancellable: AnyCancellable?
    
    // MARK: - 球队与比分
    @State private var homeTeam = "主队"
    @State private var awayTeam = "客队"
    @State private var homeScore = 0
    @State private var awayScore = 0
    
    // MARK: - 事件
    @State private var events: [MatchEvent] = []
    
    // MARK: - 流程控制
    @State private var selectedType = ""
    @State private var showTeamSelect = false
    @State private var showNumberSheet = false
    @State private var showSubSheet = false
    
    // MARK: - 输入状态
    @State private var selectedTeam = ""
    @State private var pickerNumber = 1
    @State private var subOutNumber = 1
    @State private var subInNumber = 2
    
    var body: some View {
        VStack(spacing: 8) {
            // 时间显示
            Text(formatTime(elapsed))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .padding(.top, 6)
            
            // 比分
            HStack {
                VStack {
                    Text(homeTeam).font(.caption2)
                    Text("\(homeScore)").font(.title2).bold()
                }
                Text(" - ").font(.title3).bold()
                VStack {
                    Text(awayTeam).font(.caption2)
                    Text("\(awayScore)").font(.title2).bold()
                }
            }
            
            // 控制按钮
            HStack {
                Button(isRunning ? "暂停" : "开始") {
                    isRunning ? stopTimer() : startTimer()
                }
                .tint(isRunning ? .orange : .green)
                
                Button("重置", role: .destructive) {
                    resetMatch()
                }
            }
            .font(.footnote)
            
            // 事件按钮
            HStack(spacing: 6) {
                Button("⚽") { beginEvent(type: "进球") }
                Button("🟨") { beginEvent(type: "黄牌") }
                Button("🟥") { beginEvent(type: "红牌") }
                Button("🔄") { beginEvent(type: "换人") }
            }
            .font(.title3)
            .padding(.top, 4)
            
            // 事件列表
            ScrollView {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(events) { ev in
                        if ev.type == "换人",
                           let out = ev.subOut,
                           let inn = ev.subIn {
                            Text("[\(ev.time)] \(ev.team) \(out)号 ↔️ \(inn)号 换人")
                                .font(.system(size: 11))
                        } else if let num = ev.number {
                            Text("[\(ev.time)] \(ev.icon) \(ev.team) \(num)号：\(ev.type)")
                                .font(.system(size: 11))
                        } else {
                            Text("[\(ev.time)] \(ev.icon) \(ev.team)：\(ev.type)")
                                .font(.system(size: 11))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .alert("选择球队", isPresented: $showTeamSelect) {
            Button(homeTeam) {
                selectedTeam = homeTeam
                afterTeamSelected()
            }
            Button(awayTeam) {
                selectedTeam = awayTeam
                afterTeamSelected()
            }
            Button("取消", role: .cancel) {}
        }
        .sheet(isPresented: $showNumberSheet) {
            NumberInputSheet(
                title: "\(selectedType) — \(selectedTeam)",
                initialNumber: pickerNumber,
                onPickChange: { pickerNumber = $0 },
                onConfirm: {
                    recordSimpleEvent(type: selectedType, team: selectedTeam, number: "\(pickerNumber)")
                    showNumberSheet = false
                },
                onVoiceTap: {
                    presentDictation { result in
                        if let s = result,
                           let intVal = Int(s.trimmingCharacters(in: .whitespacesAndNewlines)) {
                            pickerNumber = max(0, min(99, intVal))
                            recordSimpleEvent(type: selectedType, team: selectedTeam, number: "\(pickerNumber)")
                            showNumberSheet = false
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showSubSheet) {
            SubInputSheet(
                title: "换人 — \(selectedTeam)",
                outInitial: subOutNumber,
                inInitial: subInNumber,
                onOutChange: { subOutNumber = $0 },
                onInChange: { subInNumber = $0 },
                onConfirm: {
                    recordSubEvent(team: selectedTeam,
                                   outNum: "\(subOutNumber)",
                                   inNum: "\(subInNumber)")
                    showSubSheet = false
                },
                onVoiceOutTap: {
                    presentDictation { result in
                        if let s = result,
                           let intVal = Int(s.trimmingCharacters(in: .whitespacesAndNewlines)) {
                            subOutNumber = max(0, min(99, intVal))
                        }
                    }
                },
                onVoiceInTap: {
                    presentDictation { result in
                        if let s = result,
                           let intVal = Int(s.trimmingCharacters(in: .whitespacesAndNewlines)) {
                            subInNumber = max(0, min(99, intVal))
                        }
                    }
                }
            )
        }
    }
    
    // MARK: - 计时
    private func startTimer() {
        isRunning = true
        timerCancellable = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                elapsed += 0.01
            }
    }
    private func stopTimer() {
        isRunning = false
        timerCancellable?.cancel()
    }
    private func resetMatch() {
        stopTimer()
        elapsed = 0
        homeScore = 0
        awayScore = 0
        events.removeAll()
    }
    
    // MARK: - 事件逻辑
    private func beginEvent(type: String) {
        selectedType = type
        showTeamSelect = true
    }
    private func afterTeamSelected() {
        if selectedType == "换人" {
            subOutNumber = 1
            subInNumber = 2
            showSubSheet = true
        } else {
            pickerNumber = 1
            showNumberSheet = true
        }
    }
    private func recordSimpleEvent(type: String, team: String, number: String) {
        let icon = iconForType(type)
        let timestamp = formatTime(elapsed)
        if type == "进球" {
            if team == homeTeam { homeScore += 1 } else { awayScore += 1 }
        }
        let ev = MatchEvent(icon: icon, time: timestamp, team: team, type: type, number: number, subOut: nil, subIn: nil)
        events.insert(ev, at: 0)
    }
    private func recordSubEvent(team: String, outNum: String, inNum: String) {
        let ev = MatchEvent(icon: "🔄", time: formatTime(elapsed), team: team, type: "换人", number: nil, subOut: outNum, subIn: inNum)
        events.insert(ev, at: 0)
    }
    
    // MARK: - 辅助
    private func iconForType(_ type: String) -> String {
        switch type {
        case "进球": return "⚽"
        case "黄牌": return "🟨"
        case "红牌": return "🟥"
        default: return ""
        }
    }
    private func formatTime(_ t: TimeInterval) -> String {
        let hundredths = Int((t * 100).rounded())
        let minutes = hundredths / 6000
        let seconds = (hundredths / 100) % 60
        let centi = hundredths % 100
        return String(format: "%02d:%02d.%02d", minutes, seconds, centi)
    }
    
    private func presentDictation(completion: @escaping (String?) -> Void) {
        guard let controller = WKExtension.shared().rootInterfaceController else {
            completion(nil)
            return
        }
        controller.presentTextInputController(withSuggestions: nil, allowedInputMode: .plain) { results in
            completion(results?.first as? String)
        }
    }
}

// MARK: - 输入界面
struct NumberInputSheet: View {
    var title: String
    @State var numberLocal: Int
    var onPickChange: (Int) -> Void
    var onConfirm: () -> Void
    var onVoiceTap: () -> Void
    
    init(title: String,
         initialNumber: Int,
         onPickChange: @escaping (Int)->Void,
         onConfirm: @escaping ()->Void,
         onVoiceTap: @escaping ()->Void) {
        self.title = title
        self._numberLocal = State(initialValue: initialNumber)
        self.onPickChange = onPickChange
        self.onConfirm = onConfirm
        self.onVoiceTap = onVoiceTap
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(.headline)
            Picker("", selection: $numberLocal) {
                ForEach(0..<100) { Text("\($0)").tag($0) }
            }
            .labelsHidden()
            .frame(height: 90)
            .onChange(of: numberLocal) { newValue in
                onPickChange(newValue)
            }
            
            HStack {
                Button("语音输入") { onVoiceTap() }
                Button("确定") { onConfirm() }
            }
        }
    }
}

struct SubInputSheet: View {
    var title: String
    @State var outLocal: Int
    @State var inLocal: Int
    var onOutChange: (Int) -> Void
    var onInChange: (Int) -> Void
    var onConfirm: () -> Void
    var onVoiceOutTap: () -> Void
    var onVoiceInTap: () -> Void
    
    init(title: String,
         outInitial: Int,
         inInitial: Int,
         onOutChange: @escaping (Int)->Void,
         onInChange: @escaping (Int)->Void,
         onConfirm: @escaping ()->Void,
         onVoiceOutTap: @escaping ()->Void,
         onVoiceInTap: @escaping ()->Void) {
        self.title = title
        self._outLocal = State(initialValue: outInitial)
        self._inLocal = State(initialValue: inInitial)
        self.onOutChange = onOutChange
        self.onInChange = onInChange
        self.onConfirm = onConfirm
        self.onVoiceOutTap = onVoiceOutTap
        self.onVoiceInTap = onVoiceInTap
    }
    
    var body: some View {
        VStack(spacing: 6) {
            Text(title).font(.headline)
            HStack {
                VStack {
                    Text("下场")
                    Picker("", selection: $outLocal) {
                        ForEach(0..<100) { Text("\($0)").tag($0) }
                    }
                    .labelsHidden()
                    .frame(height: 80)
                    .onChange(of: outLocal) { newVal in onOutChange(newVal) }
                    Button("语音↓", action: onVoiceOutTap).font(.caption2)
                }
                VStack {
                    Text("上场")
                    Picker("", selection: $inLocal) {
                        ForEach(0..<100) { Text("\($0)").tag($0) }
                    }
                    .labelsHidden()
                    .frame(height: 80)
                    .onChange(of: inLocal) { newVal in onInChange(newVal) }
                    Button("语音↑", action: onVoiceInTap).font(.caption2)
                }
            }
            Button("确定", action: onConfirm).padding(.top, 6)
        }
    }
}

#Preview {
    ContentView()
}

