import SwiftUI

/// Filled accent capsule with a black label (contrast checked in scripts/contrast.py).
struct PrimaryButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.buttonFont)
            .foregroundStyle(Theme.onAccent)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
            .background(Capsule().fill(accent))
            .contentShape(Capsule())
            .modifier(PressFeedback(isPressed: configuration.isPressed, pressedOpacity: 0.8))
    }
}

/// Dark capsule with a thin accent outline and a white label.
struct SecondaryButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.buttonFont)
            .foregroundStyle(Theme.hudPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, minHeight: Theme.minTapTarget)
            .background(Capsule().fill(Theme.cardFill))
            .overlay(Capsule().strokeBorder(accent.opacity(0.7), lineWidth: 1))
            .contentShape(Capsule())
            .modifier(PressFeedback(isPressed: configuration.isPressed, pressedOpacity: 0.8))
    }
}

/// Passes the card's own look through; only adds press and disabled feedback.
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .modifier(PressFeedback(isPressed: configuration.isPressed, pressedOpacity: Theme.cardPressedOpacity))
    }
}

/// Disabled: dimmed. Pressed: dimmed, and slightly smaller unless Reduce Motion is on.
private struct PressFeedback: ViewModifier {
    let isPressed: Bool
    let pressedOpacity: Double

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(!isEnabled ? Theme.disabledOpacity : (isPressed ? pressedOpacity : 1))
            .scaleEffect(isPressed && !reduceMotion ? Theme.cardPressedScale : 1)
    }
}
