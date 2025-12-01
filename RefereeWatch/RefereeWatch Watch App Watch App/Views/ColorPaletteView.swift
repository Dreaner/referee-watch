//
//  ColorPaletteView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 1/12/25.
//


import SwiftUI

struct ColorPaletteView: View {
    @Binding var selectedColor: TeamColor
    @Environment(\.dismiss) var dismiss
    let title: String
    
    // Define the grid layout, with 5 colors per row
    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 5)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(TeamColor.allCases) { color in
                    Button(action: {
                        selectedColor = color
                        dismiss()
                    }) {
                        Circle()
                            .fill(color.color)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                            )
                            .overlay(
                                Circle().stroke(Color.gray, lineWidth: color == .white ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle(title)
    }
}
