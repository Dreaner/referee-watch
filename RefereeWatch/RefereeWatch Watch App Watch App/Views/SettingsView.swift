//
//  SettingsView.swift
//  RefereeWatch
//
//  Created by Xingnan Zhu on 30/11/25.
//


import SwiftUI

struct SettingsView: View {
    @ObservedObject var matchManager: MatchManager
    
    @State private var isShowingHomeColorPicker = false
    @State private var isShowingAwayColorPicker = false

    private var halfDurationMinutes: Binding<Int> {
        Binding<Int>(
            get: { Int(self.matchManager.halfDuration / 60) },
            set: { self.matchManager.halfDuration = TimeInterval($0 * 60) }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 半场时长设置
                VStack(alignment: .leading) {
                    Text("Half Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 2)
                    
                    HStack {
                        Text("\(halfDurationMinutes.wrappedValue) min")
                            .font(.body)
                        Spacer()
                        Stepper("", value: halfDurationMinutes, in: 5...60, step: 5)
                            .labelsHidden()
                    }
                }

                Divider()

                // 球队设置
                VStack(alignment: .leading) {
                    Text("Teams")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Home
                    HStack {
                        Button(action: { isShowingHomeColorPicker = true }) {
                            Circle()
                                .fill(matchManager.homeTeamColor.color)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle().stroke(Color.gray, lineWidth: matchManager.homeTeamColor == .white ? 1 : 0)
                                )
                        }
                        .buttonStyle(.plain)
                        
                        TextField("Home Team", text: $matchManager.homeTeamName)
                    }
                    
                    // Away
                    HStack {
                        Button(action: { isShowingAwayColorPicker = true }) {
                            Circle()
                                .fill(matchManager.awayTeamColor.color)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle().stroke(Color.gray, lineWidth: matchManager.awayTeamColor == .white ? 1 : 0)
                                )
                        }
                        .buttonStyle(.plain)

                        TextField("Away Team", text: $matchManager.awayTeamName)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $isShowingHomeColorPicker) {
            NavigationView {
                ColorPaletteView(
                    selectedColor: $matchManager.homeTeamColor,
                    title: "Home Color"
                )
            }
        }
        .sheet(isPresented: $isShowingAwayColorPicker) {
            NavigationView {
                ColorPaletteView(
                    selectedColor: $matchManager.awayTeamColor,
                    title: "Away Color"
                )
            }
        }
    }
}

// MARK: - 预览
#Preview {
    SettingsView(matchManager: MatchManager())
}
