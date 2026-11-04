import SwiftUI

/// Lanternfall's picker illustration: the lantern-keeper in its glow among
/// gravestones, a few Risen closing in, a bolt in flight and a crescent moon.
/// 18 draw calls, 1 gradient.
enum LanternfallArtwork: GameArtwork {
    static func draw(in context: inout GraphicsContext, size: CGSize) {
        let u = size.height, w = size.width
        let hero = CGPoint(x: 0.5 * w, y: 0.58 * u)
        func disc(_ c: CGPoint, _ r: CGFloat) -> CGRect {
            CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)
        }

        // Ground dots
        var dots = Path()
        for y in [0.70 * u, 0.86 * u] {
            var x: CGFloat = 0.09 * u
            while x < w {
                dots.addRect(CGRect(x: x - 1, y: y - 1, width: 2, height: 2))
                x += 0.18 * u
            }
        }
        context.fill(dots, with: .color(Theme.lfGridDot))

        // Crescent moon: a disc with a smaller offset disc cut out
        let moonCentre = CGPoint(x: 0.86 * w, y: 0.24 * u)
        let moon = Path(ellipseIn: disc(moonCentre, 0.13 * u))
        let bite = Path(ellipseIn: disc(CGPoint(x: moonCentre.x + 0.06 * u, y: moonCentre.y - 0.03 * u), 0.12 * u))
        context.drawLayer { layer in
            layer.clip(to: bite, options: .inverse)
            layer.fill(moon, with: .color(Theme.lfMoon))
        }

        // Gravestones (bottom centre given)
        var stones = Path()
        for (x, bottom) in [(0.18 * w, 0.80 * u), (0.70 * w, 0.78 * u)] {
            stones.addPath(Path(roundedRect: CGRect(x: x - 0.06 * u, y: bottom - 0.20 * u, width: 0.12 * u, height: 0.20 * u),
                                cornerRadius: 0.05 * u))
        }
        context.fill(stones, with: .color(Theme.lfStone))

        // Lantern glow around the hero
        let glowR = 0.55 * u
        context.fill(Path(ellipseIn: disc(hero, glowR)),
                     with: .radialGradient(Theme.lanternGlowGradient, center: hero, startRadius: 0, endRadius: glowR))

        // Gems
        var gems = Path(), gemHalos = Path()
        for p in [CGPoint(x: 0.38 * w, y: 0.75 * u), CGPoint(x: 0.42 * w, y: 0.80 * u), CGPoint(x: 0.56 * w, y: 0.82 * u)] {
            GlowPath.addCircle(&gems, p, 0.02 * u)
            GlowPath.addCircle(&gemHalos, p, 0.02 * u * Theme.glowSoft.haloWidth)
        }
        GlowPath.fill(core: gems, halo: gemHalos, in: &context, color: Theme.lfGemSmall, style: Theme.glowSoft)

        // The Risen, one Path per colour, plus their eyes
        var shamblers = Path(), sprinters = Path(), bloats = Path(), eyes = Path()
        let risen: [(CGPoint, CGFloat, Int)] = [
            (CGPoint(x: 0.30 * w, y: 0.62 * u), 0.065 * u, 0),
            (CGPoint(x: 0.82 * w, y: 0.66 * u), 0.065 * u, 0),
            (CGPoint(x: 0.10 * w, y: 0.48 * u), 0.05 * u, 1),
            (CGPoint(x: 0.66 * w, y: 0.40 * u), 0.10 * u, 2)
        ]
        for (p, r, kind) in risen {
            switch kind {
            case 0: GlowPath.addCircle(&shamblers, p, r)
            case 1: GlowPath.addCircle(&sprinters, p, r)
            default: GlowPath.addCircle(&bloats, p, r)
            }
            for side: CGFloat in [-1, 1] {
                GlowPath.addCircle(&eyes, CGPoint(x: p.x + side * 0.35 * r, y: p.y - 0.2 * r), 0.012 * u)
            }
        }
        context.fill(shamblers, with: .color(Theme.lfShambler))
        context.fill(sprinters, with: .color(Theme.lfSprinter))
        context.fill(bloats, with: .color(Theme.lfBloat))
        context.fill(eyes, with: .color(Theme.lfGround))

        // A bolt flying out from the hero, with its trail
        let bolt = CGPoint(x: 0.60 * w, y: 0.47 * u)
        let dx = hero.x - bolt.x, dy = hero.y - bolt.y
        let len = max((dx * dx + dy * dy).squareRoot(), 0.001)
        var trail = Path()
        trail.move(to: bolt)
        trail.addLine(to: CGPoint(x: bolt.x + dx / len * 0.12 * u, y: bolt.y + dy / len * 0.12 * u))
        context.stroke(trail, with: .color(Theme.lfBolt.opacity(0.5)), style: StrokeStyle(lineWidth: 0.025 * u, lineCap: .round))
        var boltCore = Path(), boltHalo = Path()
        GlowPath.addCircle(&boltCore, bolt, 0.025 * u)
        GlowPath.addCircle(&boltHalo, bolt, 0.025 * u * Theme.glowSoft.haloWidth)
        GlowPath.fill(core: boltCore, halo: boltHalo, in: &context, color: Theme.lfBolt, style: Theme.glowSoft)

        // The hero with its lantern halo and heading tick
        var heroCore = Path(), heroHalo = Path()
        GlowPath.addCircle(&heroCore, hero, 0.07 * u)
        GlowPath.addCircle(&heroHalo, hero, 0.07 * u * Theme.glowStandard.haloWidth)
        GlowPath.fill(core: heroCore, halo: heroHalo, in: &context, color: Theme.lfHero,
                      haloColor: Theme.lanternfallAccent, style: Theme.glowStandard)
        var tick = Path()
        tick.move(to: CGPoint(x: hero.x + 0.07 * u, y: hero.y))
        tick.addLine(to: CGPoint(x: hero.x + 0.13 * u, y: hero.y))
        context.stroke(tick, with: .color(Theme.lanternfallAccent), style: StrokeStyle(lineWidth: 0.025 * u, lineCap: .round))
    }
}
