//
//  PDFReportGenerator.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 5/11/25.
//

import Foundation
import PDFKit
import UIKit

final class PDFReportGenerator {
    static let shared = PDFReportGenerator()
    
    func generatePDF(for report: MatchReport) -> URL {
        let fileName = "\(report.homeTeam)_vs_\(report.awayTeam)_Report.pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        
        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                let title = "\(report.homeTeam) vs \(report.awayTeam)"
                title.draw(at: CGPoint(x: 40, y: 40),
                           withAttributes: [.font: UIFont.boldSystemFont(ofSize: 20)])
                
                let score = "\(report.homeScore) - \(report.awayScore)"
                score.draw(at: CGPoint(x: 40, y: 70),
                           withAttributes: [.font: UIFont.systemFont(ofSize: 16)])
                
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                let dateStr = formatter.string(from: report.date)
                dateStr.draw(at: CGPoint(x: 40, y: 100),
                             withAttributes: [.font: UIFont.systemFont(ofSize: 14)])
                
                var y = 140.0
                for event in report.events {
                    let text = format(event)
                    text.draw(at: CGPoint(x: 40, y: y),
                              withAttributes: [.font: UIFont.systemFont(ofSize: 12)])
                    y += 18
                }
            }
        } catch {
            print("❌ PDF generation failed: \(error)")
        }
        return url
    }
    
    private func format(_ event: MatchEvent) -> String {
        switch event.type {
        case .goal:
            return "[\(time(event.timestamp))] \(event.team.capitalized) ⚽️ Goal - #\(event.playerNumber ?? 0)"
        case .card:
            let color = event.cardType == .yellow ? "🟨" : "🟥"
            return "[\(time(event.timestamp))] \(event.team.capitalized) \(color) Card - #\(event.playerNumber ?? 0)"
        case .substitution:
            return "[\(time(event.timestamp))] \(event.team.capitalized) 🔄 Sub: #\(event.playerOut ?? 0) → #\(event.playerIn ?? 0)"
        }
    }
    
    private func time(_ t: TimeInterval) -> String {
        String(format: "%02d:%02d", Int(t) / 60, Int(t) % 60)
    }
}
