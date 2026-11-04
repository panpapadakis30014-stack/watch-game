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

    // Shared UI (game picker, cards)
    static let cardFill = Color.white.opacity(0.14)
    static let cardCornerRadius: CGFloat = 10
    static let pickerRowMinHeight: CGFloat = 56

    // Lanternfall colours: a night palette with one colour per enemy kind
    static let lfGround = Color(red: 0.04, green: 0.05, blue: 0.08)
    static let lfGridDot = Color.white.opacity(0.12)
    static let lfLantern = Color(red: 1.00, green: 0.78, blue: 0.35)
    static let lfHero = core
    static let lfShambler = Color(red: 0.55, green: 0.78, blue: 0.45)
    static let lfSprinter = Color(red: 0.78, green: 0.52, blue: 1.00)
    static let lfBloat = Color(red: 0.95, green: 0.55, blue: 0.72)
    static let lfWarden = Color(red: 0.70, green: 0.85, blue: 1.00)
    static let lfEnraged = danger
    static let lfEmber = shard
    static let lfBolt = pulse
    static let lfSalt = Color(red: 0.92, green: 0.95, blue: 1.00)
    static let lfSpark = shield
    static let lfGemSmall = Color(red: 0.35, green: 0.90, blue: 0.85)
    static let lfGemMedium = Color(red: 0.45, green: 0.65, blue: 1.00)
    static let lfGemLarge = pulse
    static let lfXP = lfGemSmall
    static let lfPuff = secondaryText

    // Lanternfall layout and timing
    static let lfOfferArmDelay: Double = 0.6       // seconds before upgrade choices accept taps
    static let lfBannerDuration: Double = 3.0
    static let lfXPBarWidthRatio: CGFloat = 0.30
    static let lfBossBarWidthRatio: CGFloat = 0.34
    static let lfBarHeightRatio: CGFloat = 0.022
}
