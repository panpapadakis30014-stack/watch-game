import SwiftUI

/// The launch screen: one large row per game with its best result. It is a
/// scroll view, so the Crown scrolls it if the rows don't fit.
struct GamePickerView: View {
    @Environment(HubModel.self) private var hub

    var body: some View {
        let best = hub.ringward.best
        let records = hub.lanternfall.records
        CenteredScroll {
            VStack(spacing: 8) {
                row(name: "Ringward", colour: Theme.shield,
                    line: "Best \(best)",
                    label: "Ringward. Best score \(best)",
                    hint: "Opens Ringward") {
                    hub.open(.ringward)
                }
                row(name: "Lanternfall", colour: Theme.lfLantern,
                    line: LanternfallCopy.pickerLine(records),
                    label: LanternfallCopy.pickerAccessibility(records),
                    hint: "Opens Lanternfall") {
                    hub.open(.lanternfall)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func row(name: String, colour: Color, line: String, label: String, hint: String,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(colour)
                Text(line)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: Theme.pickerRowMinHeight, alignment: .leading)
            .padding(.horizontal, 10)
            .background(RoundedRectangle(cornerRadius: Theme.cardCornerRadius).fill(Theme.cardFill))
            .contentShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityHint(hint)
        .accessibilityAddTraits(.isButton)
    }
}
