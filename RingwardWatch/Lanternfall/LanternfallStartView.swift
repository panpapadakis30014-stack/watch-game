import SwiftUI

struct LanternfallStartView: View {
    @Environment(LanternfallModel.self) private var model

    var body: some View {
        let records = model.records
        CenteredScroll {
            VStack(spacing: 6) {
                Text("Lanternfall")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.lfLantern)
                Text(LanternfallCopy.startRecordsLine(records))
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .accessibilityLabel(LanternfallCopy.startRecordsAccessibility(records))
                if records.dawns > 0 {
                    Text("Dawns reached: \(records.dawns)")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                        .accessibilityLabel("Dawns reached \(records.dawns)")
                }
                Button {
                    model.startRun()
                } label: {
                    Text("Tap to play")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.lfLantern)
                .accessibilityLabel("Tap to play")
                if !model.hasPlayed {
                    Text("Turn the Crown to steer. Tap to dash. Last until dawn.")
                        .font(.footnote)
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
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Back to games")
                }
            }
            .padding(.horizontal, 4)
        }
    }
}
