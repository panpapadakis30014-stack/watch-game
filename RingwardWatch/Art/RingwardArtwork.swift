import SwiftUI

/// Ringward's picker illustration: the core, the shield arc blocking a shard,
/// and a few shards on their way in. 10 draw calls, 1 gradient.
enum RingwardArtwork: GameArtwork {
    static func draw(in context: inout GraphicsContext, size: CGSize) {
        let u = size.height
        let c = CGPoint(x: 0.5 * size.width, y: 0.5 * u)
        func at(_ degrees: CGFloat, _ d: CGFloat) -> CGPoint {
            let a = degrees * .pi / 180
            return CGPoint(x: c.x + sin(a) * d, y: c.y - cos(a) * d)
        }

        // Spawn ring
        var ring = Path()
        GlowPath.addCircle(&ring, c, 0.46 * u)
        context.stroke(ring, with: .color(Theme.ring), lineWidth: 1)

        // Core glow and core
        let glowR = 0.2 * u
        context.fill(Path(ellipseIn: CGRect(x: c.x - glowR, y: c.y - glowR, width: 2 * glowR, height: 2 * glowR)),
                     with: .radialGradient(Theme.coreGlowGradient, center: c, startRadius: 0, endRadius: glowR))
        var core = Path()
        GlowPath.addCircle(&core, c, 0.085 * u)
        context.fill(core, with: .color(Theme.core))

        // Shield arc
        var shield = Path()
        for i in 0...16 {
            let p = at(285 + 70 * CGFloat(i) / 16, 0.30 * u)
            if i == 0 { shield.move(to: p) } else { shield.addLine(to: p) }
        }
        GlowPath.stroke(shield, in: &context, color: Theme.ringwardAccent, width: 0.065 * u, style: Theme.glowStrong)

        // Shards with tails pointing back out
        let shards: [(CGFloat, CGFloat)] = [(320, 0.40), (75, 0.95), (110, 1.35), (250, 1.15)]
        var heads = Path(), halos = Path(), tails = Path()
        let r = 0.04 * u
        for (angle, d) in shards {
            let p = at(angle, d * u)
            GlowPath.addCircle(&heads, p, r)
            GlowPath.addCircle(&halos, p, r * Theme.glowSoft.haloWidth)
            tails.move(to: p)
            tails.addLine(to: at(angle, d * u + 0.12 * u))
        }
        context.stroke(tails, with: .color(Theme.shard.opacity(0.45)), style: StrokeStyle(lineWidth: 0.04 * u, lineCap: .round))
        GlowPath.fill(core: heads, halo: halos, in: &context, color: Theme.shard, style: Theme.glowSoft)

        // Block sparks off the shield
        var sparks = Path()
        for (angle, d) in [(300, 0.37), (312, 0.42), (324, 0.44), (334, 0.41), (344, 0.37)] as [(CGFloat, CGFloat)] {
            GlowPath.addCircle(&sparks, at(angle, d * u), 0.018 * u)
        }
        context.fill(sparks, with: .color(Theme.shield))
    }
}
