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
                    .font(.title3)
                    .foregroundStyle(.white)
                Text("Score \(result.score)")
                    .font(.title2.monospacedDigit())
                    .foregroundStyle(.white)
                    .accessibilityLabel("Score \(result.score)")
                Text("Best \(result.best)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityLabel("Best score \(result.best)")
                if result.isNewBest {
                    Text("New best!")
                        .font(.headline)
                        .foregroundStyle(Theme.pulse)
                        .accessibilityLabel("New best score")
                }
                Button {
                    model.retry()
                } label: {
                    Text("Tap to retry")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.shield)
                .disabled(!armed)
                .accessibilityLabel("Tap to retry")
            }
            .padding(.horizontal, 4)
        }
        .task {
            try? await Task.sleep(for: .seconds(Theme.retryArmDelay))
            armed = true
        }
    }
}
