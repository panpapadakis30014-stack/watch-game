import SwiftUI

/// Kept compact (34 pt buttons, tight spacing, caption-size hint) so the
/// "Games" button is on screen at 40mm.
struct LanternfallStartView: View {
    @Environment(LanternfallModel.self) private var model

    var body: some View {
        let records = model.records
        CenteredScroll {
            VStack(spacing: 4) {
                Text("Lanternfall")
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.lanternfallAccent)
                Text(LanternfallCopy.startRecordsLine(records))
                    .font(Theme.bodyFont.monospacedDigit())
                    .foregroundStyle(Theme.hudPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityLabel(LanternfallCopy.startRecordsAccessibility(records))
                if records.dawns > 0 {
                    Text("Dawns reached: \(records.dawns)")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.secondaryText)
                        .accessibilityLabel("Dawns reached \(records.dawns)")
                }
                Button {
                    model.startRun()
                } label: {
                    Text("Tap to play")
                }
                .buttonStyle(PrimaryButtonStyle(accent: Theme.lanternfallAccent))
                .accessibilityLabel("Tap to play")
                if !model.hasPlayed {
                    Text("Turn the Crown to steer. Tap to dash. Last until dawn.")
                        .font(Theme.hintFont)
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                        .multilineTextAlignment(.center)
                }
                if model.exitToPicker != nil {
                    Button {
                        model.leaveToPicker()
                    } label: {
                        Text("Games")
                    }
                    .buttonStyle(SecondaryButtonStyle(accent: Theme.lanternfallAccent))
                    .accessibilityLabel("Back to games")
                }
            }
            .padding(.horizontal, 4)
        }
    }
}
