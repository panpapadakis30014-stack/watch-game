import SwiftUI
import HordeCore

/// The upgrade choice: three stacked full-width rows over the frozen game.
/// The rows accept taps only after a short delay, so a dash tap that lands
/// just as the offer opens can't pick one by accident.
struct LevelUpView: View {
    let offer: UpgradeOffer
    let onChoose: (Int) -> Void

    @State private var armed = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {}
            ViewThatFits(in: .vertical) {
                content
                ScrollView { content }
            }
            .padding(.horizontal, 2)
        }
        .task(id: offer.serial) {
            armed = false
            try? await Task.sleep(for: .seconds(Theme.lfOfferArmDelay))
            armed = true
        }
    }

    private var content: some View {
        VStack(spacing: 4) {
            Text(LanternfallCopy.levelUpTitle(offer.heroLevel))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.lfLantern)
                .accessibilityLabel(LanternfallCopy.levelUpAccessibility(offer.heroLevel))
            ForEach(offer.options.indices, id: \.self) { i in
                optionButton(offer.options[i], index: i)
            }
        }
    }

    private func optionButton(_ option: UpgradeOption, index: Int) -> some View {
        Button {
            onChoose(index)
        } label: {
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(LanternfallCopy.name(option.kind))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Spacer(minLength: 2)
                    Text(LanternfallCopy.levelLine(option))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(Theme.lfLantern)
                }
                Text(LanternfallCopy.effect(option.kind, toLevel: option.toLevel))
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Theme.cardCornerRadius).fill(Theme.cardFill))
            .contentShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(!armed)
        .opacity(armed ? 1 : 0.55)
        .accessibilityLabel(LanternfallCopy.optionAccessibility(option))
        .accessibilityHint("Choose this upgrade")
    }
}
