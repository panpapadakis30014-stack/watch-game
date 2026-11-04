import SwiftUI

/// One game's accent: `base` for titles, primary buttons and key glows;
/// `deep` only for gradient borders and art shading, never for text.
struct GameAccent {
    let base: Color
    let deep: Color

    var border: LinearGradient {
        LinearGradient(colors: [base, deep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// Glow without blur filters. Strokes: up to two additive (plusLighter)
/// halos under the crisp core, plus an optional thin white "hot" line.
/// Small fills: one tight additive halo. Point lights use GlowSprite instead.
struct GlowStyle {
    let haloWidth: CGFloat      // stroke inner halo, × the core width
    let haloOpacity: Double
    let outerWidth: CGFloat     // stroke outer halo, × the core width; 0 = no outer layer
    let outerOpacity: Double
    let hotWidth: CGFloat       // × the core width; 0 = no hot line
    let hotOpacity: Double
    let fillHaloWidth: CGFloat  // fill halo, × the disc radius
    let fillHaloOpacity: Double
}

/// Theme v2: the night palette, game accents, glow styles, type roles and
/// motion values for the whole app. Every raw colour lives here, one per line
/// (scripts/contrast.py parses them); every size is a ratio or a fixed token.
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

    // Night background: a radial gradient from deep navy to black
    static let nightCenter = Color(red: 0.055, green: 0.086, blue: 0.180)
    static let nightMid = Color(red: 0.024, green: 0.035, blue: 0.078)
    static let nightEdge = Color.black
    static let nightGradient = Gradient(stops: [
        .init(color: nightCenter, location: 0),
        .init(color: nightMid, location: 0.55),
        .init(color: nightEdge, location: 1)
    ])
    static let nightCenterPoint = UnitPoint(x: 0.5, y: 0.4)
    static let nightRadiusRatio: CGFloat = 0.85      // × the longer side

    // Text and surfaces
    static let hudPrimary = Color.white
    static let onAccent = Color.black
    static let hudPlate = Color.black.opacity(0.6)
    static let hudTrack = ring
    static let glowHot = Color.white

    // Layout ratios (of the GeometryReader size)
    static let arenaScale: CGFloat = 0.92
    static let pauseButtonRatio: CGFloat = 0.17
    static let shieldLineRatio: CGFloat = 0.075
    static let shardDrawScale: CGFloat = 1.7         // drawn shards vs. Tuning.shardVisualRadius (visual only)
    static let minTapTarget: CGFloat = 34

    // Timing
    static let retryArmDelay: Double = 0.8   // seconds before "Tap to retry" accepts taps

    // Shared UI (game picker, cards)
    static let cardFill = Color(red: 0.086, green: 0.114, blue: 0.200)
    static let cardCornerRadius: CGFloat = 12
    static let pickerRowMinHeight: CGFloat = 56
    static let cardBorderWidth: CGFloat = 1.5
    static let cardPadding: CGFloat = 8
    static let cardSpacing: CGFloat = 6
    static let cardArtAspect: CGFloat = 2.8          // width ÷ height
    static let cardArtCornerRadius: CGFloat = 8
    static let cardEdgeScale: CGFloat = 0.9
    static let cardEdgeOpacity: Double = 0.55
    static let cardPressedScale: CGFloat = 0.97
    static let cardPressedOpacity: Double = 0.75
    static let pickerSpacing: CGFloat = 8
    static let pickerHorizontalPadding: CGFloat = 4

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
    static let lfStone = Color(red: 0.22, green: 0.26, blue: 0.36)
    static let lfMoon = Color(red: 0.88, green: 0.91, blue: 0.97)

    // Game accents (after the colours they alias, so scripts/contrast.py resolves them)
    static let ringwardAccent = shield
    static let ringwardDeep = Color(red: 0.08, green: 0.36, blue: 0.55)
    static let lanternfallAccent = lfLantern
    static let lanternfallDeep = Color(red: 0.55, green: 0.32, blue: 0.08)
    static let driftlineAccent = Color(red: 0.72, green: 0.58, blue: 1.00)
    static let driftlineDeep = Color(red: 0.34, green: 0.20, blue: 0.66)
    static let moonputtAccent = Color(red: 0.74, green: 0.96, blue: 0.78)
    static let moonputtDeep = Color(red: 0.22, green: 0.42, blue: 0.30)
    static let glowgridAccent = Color(red: 0.20, green: 0.95, blue: 0.70)
    static let glowgridDeep = Color(red: 0.06, green: 0.40, blue: 0.32)
    static let ringward = GameAccent(base: ringwardAccent, deep: ringwardDeep)
    static let lanternfall = GameAccent(base: lanternfallAccent, deep: lanternfallDeep)
    static let driftline = GameAccent(base: driftlineAccent, deep: driftlineDeep)
    static let moonputt = GameAccent(base: moonputtAccent, deep: moonputtDeep)
    static let glowgrid = GameAccent(base: glowgridAccent, deep: glowgridDeep)

    // Lanternfall layout and timing
    static let lfOfferArmDelay: Double = 0.6       // seconds before upgrade choices accept taps
    static let lfBannerDuration: Double = 3.0
    static let lfXPBarWidthRatio: CGFloat = 0.30
    static let lfBossBarWidthRatio: CGFloat = 0.34
    static let lfBarHeightRatio: CGFloat = 0.022

    // Glow
    static let glowSoft = GlowStyle(haloWidth: 1.8, haloOpacity: 0.28, outerWidth: 0, outerOpacity: 0,
                                    hotWidth: 0, hotOpacity: 0, fillHaloWidth: 1.35, fillHaloOpacity: 0.35)
    static let glowStandard = GlowStyle(haloWidth: 1.8, haloOpacity: 0.30, outerWidth: 2.8, outerOpacity: 0.10,
                                        hotWidth: 0, hotOpacity: 0, fillHaloWidth: 1.35, fillHaloOpacity: 0.35)
    static let glowStrong = GlowStyle(haloWidth: 1.9, haloOpacity: 0.34, outerWidth: 3.0, outerOpacity: 0.12,
                                      hotWidth: 0.35, hotOpacity: 0.6, fillHaloWidth: 1.35, fillHaloOpacity: 0.35)
    static let spriteGlowRatio: CGFloat = 2.6        // GlowSprite radius × the core radius
    static let maxSpritesPerFrame = 16
    static let coreGlowGradient = Gradient(colors: [shield.opacity(0.45), shield.opacity(0)])
    static let lanternGlowGradient = Gradient(colors: [lfLantern.opacity(0.22), lfLantern.opacity(0)])

    // Type roles (used with .fontDesign(.rounded))
    static let titleFont = Font.title3.weight(.semibold)
    static let cardTitleFont = Font.headline.weight(.semibold)
    static let bodyFont = Font.footnote.weight(.medium)
    static let hintFont = Font.caption2.weight(.medium)  // first-run hints: compact so "Games" fits at 40mm
    static let buttonFont = Font.headline.weight(.semibold)
    static let resultFont = Font.title2.weight(.bold).monospacedDigit()
    static let hudScoreFont = Font.title3.weight(.semibold).monospacedDigit()
    static let hudValueFont = Font.headline.weight(.semibold).monospacedDigit()
    static let hudDetailFont = Font.footnote.weight(.semibold).monospacedDigit()
    static let hudCaptionFont = Font.caption2.weight(.semibold).monospacedDigit()

    // HUD layout
    static let hudPlatePaddingH: CGFloat = 5
    static let hudPlatePaddingV: CGFloat = 1
    static let hudMinScale: CGFloat = 0.6
    static let hudScoreMaxRatio: CGFloat = 0.24      // × GeometryReader width
    static let hudCornerTextMaxRatio: CGFloat = 0.22

    // Motion
    static let screenTransitionDuration: Double = 0.25
    static let screenTransitionScale: CGFloat = 0.96
    static let numberAnimation = Animation.snappy(duration: 0.25)
    static let hudBarAnimation = Animation.easeOut(duration: 0.2)
    static let disabledOpacity: Double = 0.45
}
