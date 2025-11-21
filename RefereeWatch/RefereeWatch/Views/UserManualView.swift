import SwiftUI

struct UserManualView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    InstructionSection(
                        title: "Starting a Match",
                        steps: [
                            "On your Apple Watch, open the app to the main `MatchView`.",
                            "Press the green play button to start the first half.",
                            "The timer will begin, and HealthKit workout tracking will start automatically."
                        ]
                    )

                    InstructionSection(
                        title: "Recording Events",
                        steps: [
                            "During the match, tap the appropriate icon: ⚽️ for Goal, 🟨 for Yellow Card, 🟥 for Red Card, 🔄 for Substitution.",
                            "Follow the on-screen prompts to select the team, player number, and other details using the keypad.",
                            "All events are automatically logged with a timestamp."
                        ]
                    )

                    InstructionSection(
                        title: "Managing the Halves",
                        steps: [
                            "Use the orange hourglass button to start/stop recording stoppage time.",
                            "Press the red pause button to end the first half. The timer will stop, and the half-time break will begin.",
                            "To start the second half, press the green play button again.",
                            "At the end of the match, press the red stop button to finish the workout and save the match report."
                        ]
                    )
                    
                    InstructionSection(
                        title: "Syncing & Viewing Data",
                        steps: [
                            "On your Apple Watch, navigate to the `EventLogView` (swipe left from the main view).",
                            "Tap 'Export to iPhone' to send the match report to your phone.",
                            "On your iPhone, the report will appear in the 'Current Match' or 'Match History' tab.",
                            "Your workout data (distance, heart rate, calories, route) will be available in the Fitness and Health apps on your iPhone."
                        ]
                    )
                    
                }
                .padding()
            }
            .navigationTitle("User Manual")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Helper View for Instructions
struct InstructionSection: View {
    let title: String
    let steps: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 4)
            
            ForEach(steps.indices, id: \.self) { index in
                HStack(alignment: .top) {
                    Text("\(index + 1).")
                        .fontWeight(.bold)
                    Text(steps[index])
                }
                .font(.body)
            }
        }
    }
}


// MARK: - Preview
#Preview {
    UserManualView()
}
