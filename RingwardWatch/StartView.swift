import SwiftUI

struct StartView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        CenteredScroll {
            VStack(spacing: 6) {
                Text("Ringward")
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.ringwardAccent)
                Text("Best \(model.best)")
                    .font(Theme.hudValueFont)
                    .foregroundStyle(Theme.hudPrimary)
                    .accessibilityLabel("Best score \(model.best)")
                Button {
                    model.startRound()
                } label: {
                    Text("Tap to play")
                }
                .buttonStyle(PrimaryButtonStyle(accent: Theme.ringwardAccent))
                .accessibilityLabel("Tap to play")
                if !model.hasPlayed {
                    Text("Turn the Crown to swing your shield. Tap when the Pulse is full.")
                        .font(Theme.hintFont)
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 4)
        }
        .overlay(alignment: .topLeading) {
            if model.exitToPicker != nil {
                GamesBackButton(accent: Theme.ringwardAccent) { model.leaveToPicker() }
                    .ignoresSafeArea(edges: .top)
            }
        }
    }
}
