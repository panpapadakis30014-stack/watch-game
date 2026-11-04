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
                    .font(.title3)
                    .foregroundStyle(result.outcome == .dawn ? Theme.lfLantern : .white)
                    .multilineTextAlignment(.center)
                Text("Time \(LanternfallCopy.clock(summary.seconds))")
                    .font(.title2.monospacedDigit())
                    .foregroundStyle(.white)
                    .accessibilityLabel("Time \(LanternfallCopy.spokenTime(summary.seconds))")
                Text(LanternfallCopy.resultsLine(summary))
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityLabel(LanternfallCopy.resultsAccessibility(summary))
                if result.update.newBestTime {
                    Text("New best time!")
                        .font(.footnote)
                        .foregroundStyle(Theme.lfLantern)
                        .accessibilityLabel("New best time")
                }
                if result.update.newMostKills {
                    Text("New most kills!")
                        .font(.footnote)
                        .foregroundStyle(Theme.lfLantern)
                        .accessibilityLabel("New most kills")
                }
                if result.outcome == .dawn {
                    Text("Dawns reached: \(result.records.dawns)")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                        .accessibilityLabel("Dawns reached \(result.records.dawns)")
                }
                Button {
                    model.playAgain()
                } label: {
                    Text("Play again")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.lfLantern)
                .disabled(!armed)
                .accessibilityLabel("Play again")
                if model.exitToPicker != nil {
                    Button {
                        model.leaveToPicker()
                    } label: {
                        Text("Games")
                    }
                    .buttonStyle(.bordered)
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
