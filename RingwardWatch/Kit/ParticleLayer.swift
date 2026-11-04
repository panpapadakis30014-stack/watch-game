import SwiftUI
import FXCore

/// Draws a ParticleSystem inside a Canvas with a fixed number of calls:
/// particles are batched per palette colour into 3 opacity buckets, and the
/// brightest bucket gets one additive (.plusLighter) halo Path. At most 4
/// calls per palette colour, whatever the particle count. Styles outside the
/// palette are skipped.
enum ParticleLayer {
    private static let bucketOpacity: [Double] = [1, 0.6, 0.3]
    private static let haloScale: CGFloat = 2.0
    private static let haloOpacity = 0.22

    static func draw(_ system: ParticleSystem, in context: inout GraphicsContext, palette: [Color],
                     scale: CGFloat, map: (FXVec) -> CGPoint) {
        guard system.count > 0, !palette.isEmpty else { return }
        var cores = Array(repeating: Path(), count: palette.count * 3)
        var halos = Array(repeating: Path(), count: palette.count)
        for particle in system.particles {
            guard particle.style >= 0 && particle.style < palette.count else { continue }
            let centre = map(particle.position)
            let radius = CGFloat(particle.radius) * scale
            let opacity = particle.opacity
            let bucket = opacity > 0.66 ? 0 : (opacity > 0.33 ? 1 : 2)
            GlowPath.addCircle(&cores[particle.style * 3 + bucket], centre, radius)
            if bucket == 0 {
                GlowPath.addCircle(&halos[particle.style], centre, radius * haloScale)
            }
        }
        context.blendMode = .plusLighter
        for (i, colour) in palette.enumerated() where !halos[i].isEmpty {
            context.fill(halos[i], with: .color(colour.opacity(haloOpacity)))
        }
        context.blendMode = .normal
        for (i, colour) in palette.enumerated() {
            for b in 0..<3 where !cores[i * 3 + b].isEmpty {
                context.fill(cores[i * 3 + b], with: .color(colour.opacity(bucketOpacity[b])))
            }
        }
    }
}
