//
//  PDFReportGenerator.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 5/11/25.
//

/// 重构版 - 模仿纸质表格

import Foundation
import PDFKit
import UIKit

// MARK: - 辅助结构体 (用于解决 Hashable 错误)
private struct GoalGroupKey: Hashable {
    let team: String
    let playerNumber: Int
}


final class PDFReportGenerator {
    static let shared = PDFReportGenerator()
    
    // 页面布局常量
    private let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 大小
    private let margin: CGFloat = 40
    private var cursorY: CGFloat = 0
    
    // 样式常量
    private let titleFont = UIFont.boldSystemFont(ofSize: 20)
    private let headerFont = UIFont.boldSystemFont(ofSize: 14)
    private let bodyFont = UIFont.systemFont(ofSize: 10)
    private let cellPadding: CGFloat = 5
    
    // 样式改进：使用深灰色细线
    private let lineColor = UIColor.darkGray
    private let lightGrayColor = UIColor(white: 0.95, alpha: 1.0)
    private let sectionBackgroundColor = UIColor(white: 0.9, alpha: 1.0)
    private let thinLineWidth: CGFloat = 0.3
    
    // MARK: - 主生成方法
    func generatePDF(for report: MatchReport, refereeNote: String? = nil) -> URL {
        let fileName = "\(report.homeTeam)_vs_\(report.awayTeam)_Official_Report.pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        do {
            try renderer.writePDF(to: url) { context in
                self.cursorY = self.margin
                context.beginPage()
                
                // 1. 绘制报告头部 (Header)
                self.drawTitle(report: report)
                
                // 2. 绘制比分/摘要区块 (Summary Box)
                self.drawSummaryBox(report: report)
                
                // 3. 绘制事件分类区块
                self.drawEventsSection(title: "SUBSTITUTIONS", events: report.events.filter { $0.type == .substitution }, report: report)
                self.drawEventsSection(title: "CAUTIONS / WARNINGS", events: report.events.filter { $0.type == .card && $0.cardType == .yellow }, report: report)
                self.drawEventsSection(title: "EXPULSIONS / RED CARDS", events: report.events.filter { $0.type == .card && $0.cardType == .red }, report: report)
                self.drawGoalSection(report: report) // 专用进球区块
                
                // 4. 绘制裁判和官员信息 (Placeholder)
                self.drawOfficialsSection()
            }
            print("✅ PDF generated at: \(url.path)")
        } catch {
            print("❌ PDF generation failed: \(error)")
        }
        return url
    }
    
    // MARK: - 绘制组件
    
    private func drawTitle(report: MatchReport) {
        let title = "OFFICIAL MATCH REPORT"
        let subtitle = "\(report.homeTeam) vs \(report.awayTeam)"
        
        let centerParagraphStyle = NSMutableParagraphStyle()
        centerParagraphStyle.alignment = .center
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .paragraphStyle: centerParagraphStyle
        ]
        
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: headerFont.withSize(16),
            .paragraphStyle: centerParagraphStyle
        ]

        let titleRect = CGRect(x: margin, y: cursorY, width: pageRect.width - 2 * margin, height: 25)
        
        (title as NSString).draw(in: titleRect, withAttributes: titleAttributes)
        cursorY += 20
        
        (subtitle as NSString).draw(in: CGRect(x: margin, y: cursorY, width: pageRect.width - 2 * margin, height: 20), withAttributes: subtitleAttributes)
        cursorY += 30
    }
    
    private func drawSummaryBox(report: MatchReport) {
        let boxHeight: CGFloat = 50
        let boxRect = CGRect(x: margin, y: cursorY, width: pageRect.width - 2 * margin, height: boxHeight)
        
        // 绘制边框
        let path = UIBezierPath(rect: boxRect)
        lineColor.setStroke() // ✅ 边框颜色变浅
        path.lineWidth = thinLineWidth // ✅ 边框变细
        path.stroke()
        
        // 内容
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateStr = "Date: \(formatter.string(from: report.date))"
        let scoreStr = "FINAL SCORE: \(report.homeScore) - \(report.awayScore)"
        let durationStr = "Total Duration: \(Int((report.firstHalfDuration + report.secondHalfDuration) / 60)) min"
        
        (dateStr as NSString).draw(at: CGPoint(x: margin + cellPadding, y: cursorY + cellPadding), withAttributes: [.font: bodyFont])
        (scoreStr as NSString).draw(at: CGPoint(x: margin + cellPadding, y: cursorY + cellPadding + 20), withAttributes: [.font: headerFont.withSize(12)])
        (durationStr as NSString).draw(at: CGPoint(x: pageRect.width - margin - 150, y: cursorY + cellPadding + 20), withAttributes: [.font: bodyFont])
        
        cursorY += boxHeight + 20
    }
    
    private func drawEventsSection(title: String, events: [MatchEvent], report: MatchReport) {
        guard !events.isEmpty else { return }
        
        let sectionTitleHeight: CGFloat = 20
        let rowHeight: CGFloat = 18
        let columnWidth = (pageRect.width - 2 * margin) / 2
        
        // 检查换页
        if cursorY + sectionTitleHeight + rowHeight * CGFloat(events.count) + 40 > pageRect.height - margin {
            UIGraphicsBeginPDFPage()
            cursorY = margin
        }
        
        // 绘制标题背景
        let titleRect = CGRect(x: margin, y: cursorY, width: pageRect.width - 2 * margin, height: sectionTitleHeight)
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        sectionBackgroundColor.setFill() // ✅ 标题背景色
        UIRectFill(titleRect)
        context?.restoreGState()

        // 绘制标题文本
        (title as NSString).draw(at: CGPoint(x: margin + cellPadding, y: cursorY + cellPadding / 2), withAttributes: [.font: headerFont])
        cursorY += sectionTitleHeight
        
        // 绘制事件表格 (两列：主队/客队)
        let headerRect = CGRect(x: margin, y: cursorY, width: pageRect.width - 2 * margin, height: rowHeight)
        let path = UIBezierPath(rect: headerRect)
        lineColor.setStroke()
        path.lineWidth = thinLineWidth
        path.stroke()
        
        // 主队/客队标题
        (report.homeTeam as NSString).draw(in: CGRect(x: margin + cellPadding, y: cursorY + cellPadding, width: columnWidth - cellPadding, height: rowHeight), withAttributes: [.font: headerFont.withSize(10)])
        (report.awayTeam as NSString).draw(in: CGRect(x: margin + columnWidth + cellPadding, y: cursorY + cellPadding, width: columnWidth - cellPadding, height: rowHeight), withAttributes: [.font: headerFont.withSize(10)])
        
        // 绘制中线分割线
        let separator = UIBezierPath()
        separator.move(to: CGPoint(x: pageRect.midX, y: cursorY))
        separator.addLine(to: CGPoint(x: pageRect.midX, y: cursorY + rowHeight))
        separator.lineWidth = thinLineWidth
        separator.stroke()
        
        cursorY += rowHeight
        
        // 绘制事件行
        let homeEvents = events.filter { $0.team.lowercased() == "home" }
        let awayEvents = events.filter { $0.team.lowercased() == "away" }
        let maxRows = max(homeEvents.count, awayEvents.count)
        
        for i in 0..<maxRows {
            // ✅ 绘制浅色背景条纹，增强可读性
            if i % 2 == 1 {
                let stripeRect = CGRect(x: margin, y: cursorY, width: pageRect.width - 2 * margin, height: rowHeight)
                context?.saveGState()
                lightGrayColor.setFill()
                UIRectFill(stripeRect)
                context?.restoreGState()
            }
            
            // 绘制行
            // ⚠️ 不再绘制每行之间的水平分隔线，仅绘制外部和中线
            
            // 绘制中线
            let separator = UIBezierPath()
            separator.move(to: CGPoint(x: pageRect.midX, y: cursorY))
            separator.addLine(to: CGPoint(x: pageRect.midX, y: cursorY + rowHeight))
            separator.lineWidth = thinLineWidth
            separator.stroke()
            
            // 主队事件
            if i < homeEvents.count {
                let event = homeEvents[i]
                let desc = formatEventDescription(event)
                (desc as NSString).draw(in: CGRect(x: margin + cellPadding, y: cursorY + cellPadding, width: columnWidth - cellPadding, height: rowHeight), withAttributes: [.font: bodyFont])
            }
            
            // 客队事件
            if i < awayEvents.count {
                let event = awayEvents[i]
                let desc = formatEventDescription(event)
                (desc as NSString).draw(in: CGRect(x: margin + columnWidth + cellPadding, y: cursorY + cellPadding, width: columnWidth - cellPadding, height: rowHeight), withAttributes: [.font: bodyFont])
            }
            
            cursorY += rowHeight
        }
        
        // 绘制底部线
        let bottomLine = UIBezierPath()
        bottomLine.move(to: CGPoint(x: margin, y: cursorY))
        bottomLine.addLine(to: CGPoint(x: pageRect.width - margin, y: cursorY))
        bottomLine.lineWidth = thinLineWidth
        lineColor.setStroke()
        bottomLine.stroke()

        cursorY += 20
    }
    
    // MARK: - 进球专用区块
    private func drawGoalSection(report: MatchReport) {
        let title = "GOALS SCORED"
        let sectionTitleHeight: CGFloat = 20
        let rowHeight: CGFloat = 18
        let columnWidth = (pageRect.width - 2 * margin) / 2
        
        // 检查换页
        if cursorY + sectionTitleHeight + rowHeight * 10 > pageRect.height - margin {
            UIGraphicsBeginPDFPage()
            cursorY = margin
        }

        let context = UIGraphicsGetCurrentContext()
        
        // 绘制标题背景
        let titleRect = CGRect(x: margin, y: cursorY, width: pageRect.width - 2 * margin, height: sectionTitleHeight)
        context?.saveGState()
        sectionBackgroundColor.setFill()
        UIRectFill(titleRect)
        context?.restoreGState()

        // 绘制标题文本
        (title as NSString).draw(at: CGPoint(x: margin + cellPadding, y: cursorY + cellPadding / 2), withAttributes: [.font: headerFont])
        cursorY += sectionTitleHeight
        
        // 绘制事件表格 (两列：主队/客队)
        let headerRect = CGRect(x: margin, y: cursorY, width: pageRect.width - 2 * margin, height: rowHeight)
        let path = UIBezierPath(rect: headerRect)
        lineColor.setStroke()
        path.lineWidth = thinLineWidth
        path.stroke()
        
        // 主队/客队标题
        (report.homeTeam as NSString).draw(in: CGRect(x: margin + cellPadding, y: cursorY + cellPadding, width: columnWidth - cellPadding, height: rowHeight), withAttributes: [.font: headerFont.withSize(10)])
        (report.awayTeam as NSString).draw(in: CGRect(x: margin + columnWidth + cellPadding, y: cursorY + cellPadding, width: columnWidth - cellPadding, height: rowHeight), withAttributes: [.font: headerFont.withSize(10)])
        
        // 绘制分割线
        let separator = UIBezierPath()
        separator.move(to: CGPoint(x: pageRect.midX, y: cursorY))
        separator.addLine(to: CGPoint(x: pageRect.midX, y: cursorY + rowHeight))
        separator.lineWidth = thinLineWidth
        separator.stroke()
        
        cursorY += rowHeight
        
        // 对进球事件进行分组
        let groupedGoals = Dictionary(grouping: report.events.filter { $0.type == .goal }, by: { event in
            GoalGroupKey(team: event.team, playerNumber: event.playerNumber ?? 0)
        })
        
        let homeGoals = groupedGoals.filter { $0.key.team.lowercased() == "home" }.sorted { $0.key.playerNumber < $1.key.playerNumber }
        let awayGoals = groupedGoals.filter { $0.key.team.lowercased() == "away" }.sorted { $0.key.playerNumber < $1.key.playerNumber }

        let maxRows = max(homeGoals.count, awayGoals.count)
        
        for i in 0..<maxRows {
            // ✅ 绘制浅色背景条纹
            if i % 2 == 1 {
                let stripeRect = CGRect(x: margin, y: cursorY, width: pageRect.width - 2 * margin, height: rowHeight)
                context?.saveGState()
                lightGrayColor.setFill()
                UIRectFill(stripeRect)
                context?.restoreGState()
            }
            
            // 绘制中线
            let separator = UIBezierPath()
            separator.move(to: CGPoint(x: pageRect.midX, y: cursorY))
            separator.addLine(to: CGPoint(x: pageRect.midX, y: cursorY + rowHeight))
            separator.lineWidth = thinLineWidth
            separator.stroke()
            
            // 主队进球
            if i < homeGoals.count {
                let (key, events) = homeGoals[i]
                let playerNo = key.playerNumber == 0 ? "Unknown" : "#\(key.playerNumber)"
                let times = events.map { time($0.timestamp) }.joined(separator: ", ")
                
                // No.
                (playerNo as NSString).draw(in: CGRect(x: margin + cellPadding, y: cursorY + cellPadding, width: 40, height: rowHeight), withAttributes: [.font: bodyFont])
                // Time
                (times as NSString).draw(in: CGRect(x: margin + 40 + cellPadding, y: cursorY + cellPadding, width: columnWidth - 40 - cellPadding, height: rowHeight), withAttributes: [.font: bodyFont])
            }
            
            // 客队进球
            if i < awayGoals.count {
                let (key, events) = awayGoals[i]
                let playerNo = key.playerNumber == 0 ? "Unknown" : "#\(key.playerNumber)"
                let times = events.map { time($0.timestamp) }.joined(separator: ", ")
                
                // No.
                (playerNo as NSString).draw(in: CGRect(x: pageRect.midX + cellPadding, y: cursorY + cellPadding, width: 40, height: rowHeight), withAttributes: [.font: bodyFont])
                // Time
                (times as NSString).draw(in: CGRect(x: pageRect.midX + 40 + cellPadding, y: cursorY + cellPadding, width: columnWidth - 40 - cellPadding, height: rowHeight), withAttributes: [.font: bodyFont])
            }
            
            cursorY += rowHeight
        }

        // 绘制底部线
        let bottomLine = UIBezierPath()
        bottomLine.move(to: CGPoint(x: margin, y: cursorY))
        bottomLine.addLine(to: CGPoint(x: pageRect.width - margin, y: cursorY))
        bottomLine.lineWidth = thinLineWidth
        lineColor.setStroke()
        bottomLine.stroke()

        cursorY += 20
    }
    
    private func drawOfficialsSection() {
        let sectionHeight: CGFloat = 120 // 增大区块高度以容纳两行签名
        if cursorY + sectionHeight > pageRect.height - margin {
            UIGraphicsBeginPDFPage()
            cursorY = margin
        }
            
        let subTitleFont = UIFont.boldSystemFont(ofSize: 10)
            
        ("MATCH OFFICIALS" as NSString).draw(at: CGPoint(x: margin, y: cursorY), withAttributes: [.font: headerFont])
        cursorY += 35
            
        // --- 签名区块 第一行 (主裁 & 第四官员) ---
        let lineY1 = cursorY
        
        // 裁判签名
        ("Referee Signature:" as NSString).draw(at: CGPoint(x: margin, y: lineY1), withAttributes: [.font: subTitleFont])
        // ✅ 第四官员签名
        ("Fourth Official Signature:" as NSString).draw(at: CGPoint(x: margin + 300, y: lineY1), withAttributes: [.font: subTitleFont])

        // 绘制签名线 (第一行)
        lineColor.setStroke()
        let path1 = UIBezierPath()
        path1.lineWidth = 0.5
            
        // 裁判签名线
        path1.move(to: CGPoint(x: margin, y: lineY1 + 15))
        path1.addLine(to: CGPoint(x: margin + 200, y: lineY1 + 15)) // 稍微加长签名线
            
        // 第四官员签名线
        path1.move(to: CGPoint(x: margin + 300, y: lineY1 + 15))
        path1.addLine(to: CGPoint(x: margin + 500, y: lineY1 + 15))
            
        path1.stroke()
        cursorY += 40
            
        // --- 签名区块 第二行 (两个助理裁判) ---
        let lineY2 = cursorY

        // 1st 助理裁判签名
        ("1st Assistant Referee:" as NSString).draw(at: CGPoint(x: margin, y: lineY2), withAttributes: [.font: subTitleFont])
        // 2nd 助理裁判签名
        ("2nd Assistant Referee:" as NSString).draw(at: CGPoint(x: margin + 300, y: lineY2), withAttributes: [.font: subTitleFont])
            
        // 绘制签名线 (第二行)
        let path2 = UIBezierPath()
        path2.lineWidth = 0.5
            
        // 1st 助理裁判签名线
        path2.move(to: CGPoint(x: margin, y: lineY2 + 15))
        path2.addLine(to: CGPoint(x: margin + 200, y: lineY2 + 15))
            
        // 2nd 助理裁判签名线
        path2.move(to: CGPoint(x: margin + 300, y: lineY2 + 15))
        path2.addLine(to: CGPoint(x: margin + 500, y: lineY2 + 15))
            
        path2.stroke()
            
        cursorY += sectionHeight // 更新 Y 轴游标
    }

    // MARK: - 辅助格式化方法
    
    private func time(_ t: TimeInterval) -> String {
        let minutes = Int((t / 60).rounded())
        return "\(minutes)'"
    }
    
    private func formatEventDescription(_ event: MatchEvent) -> String {
        let playerNo = event.playerNumber.map { "#\($0)" } ?? ""
        let minute = time(event.timestamp)

        switch event.type {
        case .card:
            let type = event.cardType == .yellow ? "Caution" : "Expulsion"
            return "\(minute) | No. \(playerNo) (\(type))"
        case .substitution:
            let outPlayer = event.playerOut.map { "#\($0)" } ?? ""
            let inPlayer = event.playerIn.map { "#\($0)" } ?? ""
            return "\(minute) | Sub: \(outPlayer) OUT, \(inPlayer) IN"
        default:
            return ""
        }
    }
}
