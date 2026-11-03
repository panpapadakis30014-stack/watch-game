import SwiftUI

/// Colours and layout ratios for the watch app. Saturated or light colours on
/// pure black for high contrast; every size is a ratio of the available space.
enum Theme {
    // Colours
    static let background = Color.black
    static let shield = Color(red: 0.30, green: 0.85, blue: 1.00)
    static let core = Color.white
    static let shard = Color(red: 1.00, green: 0.55, blue: 0.20)
    static let pulse = Color(red: 1.00, green: 0.85, blue: 0.20)
    static let danger = Color(red: 1.00, green: 0.30, blue: 0.35)
    static let ring = Color.white.opacity(0.18)
    static let secondaryText = Color.white.opacity(0.75)

    // Layout ratios (of the GeometryReader size)
    static let arenaScale: CGFloat = 0.92
    static let pauseButtonRatio: CGFloat = 0.17
    static let shieldLineRatio: CGFloat = 0.055
    static let minTapTarget: CGFloat = 34

    // Timing
    static let retryArmDelay: Double = 0.8   // seconds before "Tap to retry" accepts taps
}
