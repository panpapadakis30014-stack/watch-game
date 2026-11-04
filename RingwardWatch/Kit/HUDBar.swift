import SwiftUI

/// A capsule meter: track, fill, and an optional soft glow behind it.
/// The fill animates briefly, except under Reduce Motion.
struct HUDBar: View {
    let fraction: Double
    let width: CGFloat
    let height: CGFloat
    let tint: Color
    var glow: Bool = false
    let accessibilityText: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let filled = width * CGFloat(min(max(fraction, 0), 1))
        Capsule()
            .fill(Theme.hudTrack)
            .frame(width: width, height: height)
            .overlay(alignment: .leading) {
                Capsule()
                    .fill(tint)
                    .frame(width: filled, height: height)
            }
            .background {
                if glow {
                    Capsule()
                        .fill(tint.opacity(Theme.glowStandard.haloOpacity))
                        .frame(width: width + 2 * height, height: 3 * height)
                }
            }
            .animation(reduceMotion ? nil : Theme.hudBarAnimation, value: fraction)
            .accessibilityElement()
            .accessibilityLabel(accessibilityText)
    }
}
