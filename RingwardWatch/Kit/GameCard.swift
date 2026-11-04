import SwiftUI

/// A game's small static illustration for its picker card. Rules for every
/// artwork: static Canvas drawing only, Theme colours only, coordinates as
/// fractions of the size, no text, at most 24 draw calls and 1 gradient.
protocol GameArtwork {
    static func draw(in context: inout GraphicsContext, size: CGSize)
}

struct GameArtView<A: GameArtwork>: View {
    var body: some View {
        Canvas { context, size in
            A.draw(in: &context, size: size)
        }
        .accessibilityHidden(true)
    }
}

/// One picker row: artwork, name in the game's accent and its best result,
/// on a dark card with an accent gradient border. Adding a game is one
/// `GameCard(...)` in GamePickerView plus one `GameArtwork` type.
struct GameCard<A: GameArtwork>: View {
    let title: String
    let detail: String
    let accent: GameAccent
    let art: A.Type
    let accessibilityText: String
    let accessibilityHint: String
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let staticEdges = self.reduceMotion     // captured for the @Sendable scroll closure
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.cardSpacing) {
                GameArtView<A>()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(Theme.cardArtAspect, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardArtCornerRadius))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(Theme.cardTitleFont)
                        .foregroundStyle(accent.base)
                    Text(detail)
                        .font(Theme.bodyFont.monospacedDigit())
                        .foregroundStyle(Theme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(Theme.cardPadding)
            .frame(maxWidth: .infinity, minHeight: Theme.pickerRowMinHeight, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Theme.cardCornerRadius).fill(Theme.cardFill))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .strokeBorder(accent.border, lineWidth: Theme.cardBorderWidth))
            .contentShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        }
        .buttonStyle(CardButtonStyle())
        .scrollTransition(.interactive, axis: .vertical) { content, phase in
            let k: Double = staticEdges ? 0 : abs(phase.value)
            return content
                .scaleEffect(1 - (1 - Theme.cardEdgeScale) * CGFloat(k))
                .opacity(1 - (1 - Theme.cardEdgeOpacity) * k)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(.isButton)
    }
}
