import SwiftUI

struct LanternfallResultsView: View {
    @Environment(LanternfallModel.self) private var model
    let result: LanternfallModel.RunResult

    /// Buttons ignore taps for a moment so a dash tap from the last second of
    /// the run can't start the next one.
    @State private var armed = false

    var body: some View {
        let summary = result.summary
        CenteredScroll {
            VStack(spacing: 4) {
                Text(LanternfallCopy.outcomeTitle(result.outcome))
                    .font(Theme.titleFont)
                    .foregroundStyle(result.outcome == .dawn ? Theme.lanternfallAccent : Theme.hudPrimary)
                    .multilineTextAlignment(.center)
                Text("Time \(LanternfallCopy.clock(summary.seconds))")
                    .font(Theme.resultFont)
                    .foregroundStyle(Theme.hudPrimary)
                    .accessibilityLabel("Time \(LanternfallCopy.spokenTime(summary.seconds))")
                Text(LanternfallCopy.resultsLine(summary))
                    .font(Theme.hudValueFont)
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityLabel(LanternfallCopy.resultsAccessibility(summary))
                if result.update.newBestTime {
                    Text("New best time!")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.lanternfallAccent)
                        .accessibilityLabel("New best time")
                }
                if result.update.newMostKills {
                    Text("New most kills!")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.lanternfallAccent)
                        .accessibilityLabel("New most kills")
                }
                if result.outcome == .dawn {
                    Text("Dawns reached: \(result.records.dawns)")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.secondaryText)
                        .accessibilityLabel("Dawns reached \(result.records.dawns)")
                }
                Button {
                    model.playAgain()
                } label: {
                    Text("Play again")
                }
                .buttonStyle(PrimaryButtonStyle(accent: Theme.lanternfallAccent))
                .disabled(!armed)
                .accessibilityLabel("Play again")
                if model.exitToPicker != nil {
                    Button {
                        model.leaveToPicker()
                    } label: {
                        Text("Games")
                    }
                    .buttonStyle(SecondaryButtonStyle(accent: Theme.lanternfallAccent))
                    .disabled(!armed)
                    .accessibilityLabel("Back to games")
                }
            }
            .padding(.horizontal, 4)
        }
        .task {
            try? await Task.sleep(for: .seconds(Theme.retryArmDelay))
            armed = true
        }
    }
}
