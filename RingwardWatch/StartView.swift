import SwiftUI

struct StartView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        CenteredScroll {
            VStack(spacing: 8) {
                Text("Ringward")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.shield)
                Text("Best \(model.best)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.white)
                    .accessibilityLabel("Best score \(model.best)")
                Button {
                    model.startRound()
                } label: {
                    Text("Tap to play")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.shield)
                .accessibilityLabel("Tap to play")
                if !model.hasPlayed {
                    Text("Turn the Crown to swing your shield.")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                }
                if model.exitToPicker != nil {
                    Button {
                        model.leaveToPicker()
                    } label: {
                        Text("Games")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Back to games")
                }
            }
            .padding(.horizontal, 4)
        }
    }
}
