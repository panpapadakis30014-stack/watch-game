import SwiftUI

/// Compact (34 pt button, tight spacing, caption-size hint) so everything fits
/// at 40mm; "‹ Games" sits in the top-left status-bar row.
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
            }
            .padding(.horizontal, 4)
        }
        .overlay(alignment: .topLeading) {
            if model.exitToPicker != nil {
                GamesBackButton(accent: Theme.lanternfallAccent) { model.leaveToPicker() }
                    .ignoresSafeArea(edges: .top)
            }
        }
    }
}
