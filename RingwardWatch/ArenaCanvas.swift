import SwiftUI
import GameCore

/// Draws the arena from a `Game` snapshot. Stateless: everything it shows is
/// passed in, and effect timing uses game time so it freezes with the game.
struct ArenaCanvas: View {
    let game: Game
    let effects: [GameController.Effect]
    let reduceMotion: Bool
    let now: Double
    let lastHitTime: Double?

    // Visual-only timings (gameplay timing lives in GameCore.Tuning).
    private static let sparkDuration = 0.35
    private static let sparkSpeed = 0.6             // arena radii per second
    private static let sparkOffsets: [Double] = [-50, -30, -10, 10, 30, 50]
    private static let pulseRingDuration = 0.4
    private static let shakeDuration = 0.35
    private static let shakeAmplitude = 0.03        // of the arena side
    private static let hitFlashDuration = 0.3
    private static let pulseFillDuration = 0.2
    private static let shieldSegments = 16
    private static let tailLength = 0.06            // arena radii

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
        .accessibilityElement()
        .accessibilityLabel("Arena")
        .accessibilityHint("Turn the Digital Crown to move the shield. Tap to fire Pulse when it is charged.")
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let tuning = game.tuning
        let side = Double(min(size.width, size.height))
        // Shrink slightly so a shard drawn on the spawn ring is never cropped.
        let radius = side / 2 / (1 + tuning.shardVisualRadius)
        var cx = Double(size.width) / 2
        let cy = Double(size.height) / 2

        if !reduceMotion, let hit = lastHitTime {
            let age = now - hit
            if age >= 0 && age < Self.shakeDuration {
                cx += sin(age * 60) * side * Self.shakeAmplitude * (1 - age / Self.shakeDuration)
            }
        }

        let centreX = cx
        func point(_ degrees: Double, _ r: Double) -> CGPoint {
            let a = degrees * .pi / 180
            return CGPoint(x: centreX + r * radius * sin(a), y: cy - r * radius * cos(a))
        }
        func circle(_ r: Double) -> Path {
            Path(ellipseIn: CGRect(x: centreX - r * radius, y: cy - r * radius,
                                   width: 2 * r * radius, height: 2 * r * radius))
        }

        // Spawn ring
        context.stroke(circle(tuning.spawnRadius), with: .color(Theme.ring), lineWidth: 1)

        // Reduce motion: a short static arena fill instead of the expanding Pulse ring.
        if reduceMotion {
            for effect in effects {
                if case .pulseRing = effect.kind, now - effect.start < Self.pulseFillDuration {
                    context.fill(circle(tuning.spawnRadius), with: .color(Theme.pulse.opacity(0.25)))
                }
            }
        }

        // Core
        context.fill(circle(1.6 * tuning.coreRadius), with: .color(Theme.shield.opacity(0.25)))
        var coreColor = Theme.core
        if reduceMotion {
            for effect in effects {
                if case .hitFlash = effect.kind, now - effect.start < Self.hitFlashDuration {
                    coreColor = Theme.danger
                }
            }
        }
        context.fill(circle(tuning.coreRadius), with: .color(coreColor))

        // Shards, each with a short tail pointing back the way it came
        let shardR = tuning.shardVisualRadius * radius
        for shard in game.shards {
            let p = point(shard.angle, shard.distance)
            let tailEnd = point(shard.angle, min(shard.distance + Self.tailLength, tuning.spawnRadius))
            var tail = Path()
            tail.move(to: p)
            tail.addLine(to: tailEnd)
            context.stroke(tail, with: .color(Theme.shard.opacity(0.5)),
                           style: StrokeStyle(lineWidth: shardR, lineCap: .round))
            context.fill(Path(ellipseIn: CGRect(x: Double(p.x) - shardR, y: Double(p.y) - shardR,
                                                width: 2 * shardR, height: 2 * shardR)),
                         with: .color(Theme.shard))
        }

        // Shield: a polyline rather than addArc, which avoids the clockwise
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
        context.stroke(shield, with: .color(Theme.shield),
                       style: StrokeStyle(lineWidth: radius * Double(Theme.shieldLineRatio),
                                          lineCap: .round, lineJoin: .round))

        // Motion effects
        guard !reduceMotion else { return }
        for effect in effects {
            let age = now - effect.start
            guard age >= 0 else { continue }
            switch effect.kind {
            case .spark(let angle):
                guard age < Self.sparkDuration else { continue }
                let fade = 1 - age / Self.sparkDuration
                let r = tuning.shieldRadius + Self.sparkSpeed * age
                let dotR = shardR * 0.6
                for offset in Self.sparkOffsets {
                    let p = point(angle + offset, r)
                    context.fill(Path(ellipseIn: CGRect(x: Double(p.x) - dotR, y: Double(p.y) - dotR,
                                                        width: 2 * dotR, height: 2 * dotR)),
                                 with: .color(Theme.shield.opacity(fade)))
                }
            case .pulseRing:
                guard age < Self.pulseRingDuration else { continue }
                let t = age / Self.pulseRingDuration
                let r = tuning.coreRadius + (tuning.spawnRadius - tuning.coreRadius) * t
                context.stroke(circle(r), with: .color(Theme.pulse.opacity(1 - t)),
                               lineWidth: radius * 0.04)
            case .hitFlash:
                break   // shown as the screen shake above; the core flash is the reduce-motion form
            }
        }
    }
}
