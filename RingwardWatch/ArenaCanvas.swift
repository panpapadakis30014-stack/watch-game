import SwiftUI
import GameCore
import FXCore

/// Draws the arena from a `Game` snapshot. Stateless: everything it shows is
/// passed in, and effect timing uses game time so it freezes with the game.
///
/// Budget: ≤ 36 calls, 1 per-frame gradient (worst case 33: ring 2, shield
/// track 1, reduce-motion pulse fill 1, core glow 1, core 1, tails 1, shard
/// sprites ≤ 6 + shard cores 1, shield 4, pulse ring 3, particles ≤ 12).
/// Shard glows are GlowSprite symbols (rendered once, not per frame); halos
/// are additive (.plusLighter); no blur, shadow or filters.
struct ArenaCanvas: View {
    let game: Game
    let effects: [GameController.Effect]
    let particles: ParticleSystem
    let reduceMotion: Bool
    let now: Double
    let lastHitTime: Double?

    // Visual-only values (gameplay values live in GameCore.Tuning).
    private static let pulseRingDuration = 0.4
    private static let shakeDuration = 0.35
    private static let shakeAmplitude = 0.03        // of the arena side
    private static let hitFlashDuration = 0.3
    private static let pulseFillDuration = 0.2
    private static let shieldSegments = 16
    private static let tailLength = 0.06            // arena radii
    private static let ringWidth: CGFloat = 1.5
    private static let ringOpacity = 0.35
    private static let trackOpacity = 0.12
    private static let coreGlowScale = 2.4          // × coreRadius
    private static let pulseRingWidth = 0.04        // × arena radius
    private static let shardSprite = 0              // GlowSprite symbol tag

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        } symbols: {
            GlowSprite.view(Theme.shard).tag(Self.shardSprite)
        }
        .accessibilityElement()
        .accessibilityLabel("Arena")
        .accessibilityHint("Turn the Digital Crown to move the shield. Tap to fire Pulse when it is charged.")
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let tuning = game.tuning
        let side = Double(min(size.width, size.height))
        // Drawn shards are bigger than the gameplay radius (visual only);
        // shrink the arena so one drawn on the spawn ring is never cropped.
        let shardScale = tuning.shardVisualRadius * Double(Theme.shardDrawScale)
        let radius = side / 2 / (1 + shardScale)
        var cx = Double(size.width) / 2
        let cy = Double(size.height) / 2

        if !reduceMotion, let hit = lastHitTime {
            let age = now - hit
            if age >= 0 && age < Self.shakeDuration {
                cx += sin(age * 60) * side * Self.shakeAmplitude * (1 - age / Self.shakeDuration)
            }
        }

        let centreX = cx
        let centre = CGPoint(x: centreX, y: cy)
        func point(_ degrees: Double, _ r: Double) -> CGPoint {
            let a = degrees * .pi / 180
            return CGPoint(x: centreX + r * radius * sin(a), y: cy - r * radius * cos(a))
        }
        func circle(_ r: Double) -> Path {
            Path(ellipseIn: CGRect(x: centreX - r * radius, y: cy - r * radius,
                                   width: 2 * r * radius, height: 2 * r * radius))
        }

        // 1. Spawn ring, softly glowing, and the static shield track
        GlowPath.stroke(circle(tuning.spawnRadius), in: &context, color: Theme.ringwardAccent.opacity(Self.ringOpacity),
                        width: Self.ringWidth, style: Theme.glowSoft)
        context.stroke(circle(tuning.shieldRadius), with: .color(Theme.ringwardAccent.opacity(Self.trackOpacity)), lineWidth: 1)

        // 2. Reduce motion: a short static arena fill instead of the expanding Pulse ring
        if reduceMotion, effects.contains(where: { if case .pulseRing = $0.kind { return now - $0.start < Self.pulseFillDuration } else { return false } }) {
            context.fill(circle(tuning.spawnRadius), with: .color(Theme.pulse.opacity(0.25)))
        }

        // 3. Core glow (the frame's only gradient) and core
        let glowR = Self.coreGlowScale * tuning.coreRadius * radius
        context.fill(circle(Self.coreGlowScale * tuning.coreRadius),
                     with: .radialGradient(Theme.coreGlowGradient, center: centre, startRadius: 0, endRadius: glowR))
        var coreColor = Theme.core
        if reduceMotion, effects.contains(where: { if case .hitFlash = $0.kind { return now - $0.start < Self.hitFlashDuration } else { return false } }) {
            coreColor = Theme.danger
        }
        context.fill(circle(tuning.coreRadius), with: .color(coreColor))

        // 4. Shards with a tail pointing back the way they came, glowing
        let shardR = shardScale * radius
        var tails = Path()
        var heads: [CGPoint] = []
        for shard in game.shards {
            let p = point(shard.angle, shard.distance)
            tails.move(to: p)
            tails.addLine(to: point(shard.angle, min(shard.distance + Self.tailLength, tuning.spawnRadius)))
            heads.append(p)
        }
        let spriteR = CGFloat(shardR) * Theme.spriteGlowRatio
        for p in heads.prefix(Theme.maxSpritesPerFrame) {
            GlowSprite.draw(Self.shardSprite, at: p, radius: spriteR, in: &context)
        }
        context.stroke(tails, with: .color(Theme.shard.opacity(0.5)), style: StrokeStyle(lineWidth: shardR, lineCap: .round))
        var shardCores = Path()
        for p in heads {
            GlowPath.addCircle(&shardCores, p, CGFloat(shardR))
        }
        context.fill(shardCores, with: .color(Theme.shard))

        // 5. Shield: a polyline rather than addArc, which avoids the clockwise
        // flag being inverted in SwiftUI's y-down coordinates.
        var shield = Path()
        let width = tuning.shieldArcWidth
        for i in 0...Self.shieldSegments {
            let a = game.shieldAngle - width / 2 + width * Double(i) / Double(Self.shieldSegments)
            let p = point(a, tuning.shieldRadius)
            if i == 0 {
                shield.move(to: p)
            } else {
                shield.addLine(to: p)
            }
        }
        GlowPath.stroke(shield, in: &context, color: Theme.ringwardAccent,
                        width: radius * Double(Theme.shieldLineRatio), style: Theme.glowStrong)

        // 6. Motion effects: the newest Pulse ring, then particles
        guard !reduceMotion else { return }
        if let ring = effects.last(where: { if case .pulseRing = $0.kind { return true } else { return false } }) {
            let age = now - ring.start
            if age >= 0 && age < Self.pulseRingDuration {
                let t = age / Self.pulseRingDuration
                let r = tuning.coreRadius + (tuning.spawnRadius - tuning.coreRadius) * t
                GlowPath.stroke(circle(r), in: &context, color: Theme.pulse.opacity(1 - t),
                                width: radius * Self.pulseRingWidth, style: Theme.glowStandard)
            }
        }
        ParticleLayer.draw(particles, in: &context, palette: [Theme.shield, Theme.shard, Theme.pulse],
                           scale: radius) { v in
            CGPoint(x: centreX + v.x * radius, y: cy + v.y * radius)
        }
    }
}
