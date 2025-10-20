//
//  ContentView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 14/10/25.
//

import SwiftUI
import UIKit
import Combine


// MARK: - Color Codable 包装
struct ColorData: Codable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat

    init(_ color: Color) {
        let uiColor = UIColor(color)
        var r: CGFloat=0, g: CGFloat=0, b: CGFloat=0, a: CGFloat=0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        red=r; green=g; blue=b; alpha=a
    }

    func toColor() -> Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}

// MARK: - 数据模型
struct MatchEvent: Identifiable, Codable {
    var id: UUID = UUID()
    var time: String
    var type: String
    var team: String
    var number: String?
    var subOut: String?
    var subIn: String?
}

struct Match: Identifiable, Codable {
    var id: UUID = UUID()
    var homeTeam: String
    var homeColor: ColorData
    var awayTeam: String
    var awayColor: ColorData
    var homeScore: Int
    var awayScore: Int
    var events: [MatchEvent]
}

// MARK: - 数据存储
class MatchData: ObservableObject {
    @Published var matches: [Match] = []
    
    // JSON 保存
    func saveToFile() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(matches) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("matches.json")
            try? data.write(to: url)
        }
    }
    
    // JSON 读取
    func loadFromFile() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("matches.json")
        if let data = try? Data(contentsOf: url) {
            let decoder = JSONDecoder()
            if let arr = try? decoder.decode([Match].self, from: data) {
                DispatchQueue.main.async { self.matches = arr }
            }
        }
    }
}

// MARK: - 首页：比赛列表
struct MatchListView: View {
    @StateObject var data = MatchData()
    @State private var showNewMatch = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(data.matches) { match in
                    NavigationLink(destination: MatchDetailView(match: match)) {
                        HStack {
                            Text("\(match.homeTeam) vs \(match.awayTeam)")
                            Spacer()
                            Text("\(match.homeScore)-\(match.awayScore)")
                        }
                    }
                }
            }
            .navigationTitle("我的比赛")
            .toolbar {
                Button(action: { showNewMatch = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showNewMatch) {
                NewMatchView(data: data)
            }
            .onAppear {
                data.loadFromFile()
            }
        }
    }
}

// MARK: - 新建比赛页
struct NewMatchView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var data: MatchData
    
    @State private var homeTeam = ""
    @State private var awayTeam = ""
    @State private var homeColor = Color.red
    @State private var awayColor = Color.blue
    
    var body: some View {
        NavigationView {
            Form {
                Section("主队") {
                    TextField("名称", text: $homeTeam)
                    ColorPicker("队服颜色", selection: $homeColor)
                }
                Section("客队") {
                    TextField("名称", text: $awayTeam)
                    ColorPicker("队服颜色", selection: $awayColor)
                }
            }
            .navigationTitle("新建比赛")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let match = Match(homeTeam: homeTeam,
                                          homeColor: ColorData(homeColor),
                                          awayTeam: awayTeam,
                                          awayColor: ColorData(awayColor),
                                          homeScore: 0,
                                          awayScore: 0,
                                          events: [])
                        data.matches.append(match)
                        data.saveToFile()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 比赛详情页
struct MatchDetailView: View {
    var match: Match
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text(match.homeTeam)
                        .font(.headline)
                        .foregroundColor(match.homeColor.toColor())
                    Text("\(match.homeScore)").font(.largeTitle)
                }
                Text(" - ").font(.title)
                VStack {
                    Text(match.awayTeam)
                        .font(.headline)
                        .foregroundColor(match.awayColor.toColor())
                    Text("\(match.awayScore)").font(.largeTitle)
                }
            }
            .padding()
            
            List {
                Section("事件列表") {
                    ForEach(match.events) { e in
                        if e.type == "换人",
                           let out = e.subOut,
                           let inn = e.subIn {
                            Text("[\(e.time)] \(e.team) \(out)号 ↔ \(inn)号 换人")
                        } else if let num = e.number {
                            Text("[\(e.time)] \(e.team) \(num)号 \(e.type)")
                        } else {
                            Text("[\(e.time)] \(e.team) \(e.type)")
                        }
                    }
                }
            }
            
            HStack {
                Button("导出 JSON") { exportJSON(match: match) }
                Button("导出 PDF") { exportPDF(match: match) }
            }
            .padding()
        }
        .navigationTitle("比赛详情")
    }
    
    // MARK: - 导出 JSON
    func exportJSON(match: Match) {
        if let data = try? JSONEncoder().encode(match) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("match.json")
            try? data.write(to: url)
            shareFile(url: url)
        }
    }
    
    // MARK: - 导出 PDF（简化版）
    func exportPDF(match: Match) {
        let pdfURL = FileManager.default.temporaryDirectory.appendingPathComponent("match.pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 350, height: 600))
        try? renderer.writePDF(to: pdfURL) { ctx in
            ctx.beginPage()
            let title = "\(match.homeTeam) \(match.homeScore)-\(match.awayScore) \(match.awayTeam)\n\n"
            title.draw(at: CGPoint(x: 10, y: 10), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16)])
            
            for (i, e) in match.events.enumerated() {
                let line: String
                if e.type == "换人", let out = e.subOut, let inn = e.subIn {
                    line = "[\(e.time)] \(e.team) \(out)号 ↔ \(inn)号 换人"
                } else {
                    line = "[\(e.time)] \(e.team) \(e.number ?? "") \(e.type)"
                }
                line.draw(at: CGPoint(x: 10, y: 40 + i*15), withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
            }
        }
        shareFile(url: pdfURL)
    }
    
    func shareFile(url: URL) {
        let vc = UIApplication.shared.windows.first?.rootViewController
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        vc?.present(activity, animated: true)
    }
}

// MARK: - 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MatchListView()
    }
}
