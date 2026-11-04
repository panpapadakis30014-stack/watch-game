import SwiftUI

struct GameOverView: View {
    @Environment(AppModel.self) private var model
    let result: AppModel.RoundResult

    /// The retry button ignores taps for a moment so leftover Pulse taps
    /// from the last second of the round can't start a new one.
    @State private var armed = false

    var body: some View {
        CenteredScroll {
            VStack(spacing: 6) {
                Text("Game over")
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.hudPrimary)
                Text("Score \(result.score)")
                    .font(Theme.resultFont)
                    .foregroundStyle(Theme.hudPrimary)
                    .accessibilityLabel("Score \(result.score)")
                Text("Best \(result.best)")
                    .font(Theme.hudValueFont)
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityLabel("Best score \(result.best)")
                if result.isNewBest {
                    Text("New best!")
                        .font(Theme.hudValueFont)
                        .foregroundStyle(Theme.pulse)
                        .accessibilityLabel("New best score")
                }
                Button {
                    model.retry()
                } label: {
                    Text("Tap to retry")
                }
                .buttonStyle(PrimaryButtonStyle(accent: Theme.ringwardAccent))
                .disabled(!armed)
                .accessibilityLabel("Tap to retry")
            }
            .padding(.horizontal, 4)
        }
        .overlay(alignment: .topLeading) {
            if model.exitToPicker != nil {
                GamesBackButton(accent: Theme.ringwardAccent) { model.leaveToPicker() }
                    .disabled(!armed)
                    .ignoresSafeArea(edges: .top)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(Theme.retryArmDelay))
            armed = true
        }
    }
}
