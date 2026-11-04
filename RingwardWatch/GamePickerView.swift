import SwiftUI

/// The launch screen: a header and one card per game, each with its artwork
/// and best result. The Crown scrolls the list.
struct GamePickerView: View {
    @Environment(HubModel.self) private var hub

    var body: some View {
        let best = hub.ringward.best
        let records = hub.lanternfall.records
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.pickerSpacing) {
                Text("Games")
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.hudPrimary)
                    .accessibilityAddTraits(.isHeader)
                GameCard(title: "Ringward", detail: "Best \(best)", accent: Theme.ringward, art: RingwardArtwork.self,
                         accessibilityText: "Ringward. Best score \(best)", accessibilityHint: "Opens Ringward") {
                    hub.open(.ringward)
                }
                GameCard(title: "Lanternfall", detail: LanternfallCopy.pickerLine(records), accent: Theme.lanternfall,
                         art: LanternfallArtwork.self,
                         accessibilityText: LanternfallCopy.pickerAccessibility(records),
                         accessibilityHint: "Opens Lanternfall") {
                    hub.open(.lanternfall)
                }
            }
            .padding(.horizontal, Theme.pickerHorizontalPadding)
        }
        .defaultScrollAnchor(hub.pickerStartsAtBottom ? .bottom : .top)
    }
}
