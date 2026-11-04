import SwiftUI
import HordeCore

/// Draws the graveyard from a `HordeGame` snapshot in one Canvas. Stateless:
/// everything comes from the game, and effect timing uses game time so it
/// freezes with the game. The hero is always drawn at the centre; the world
/// scrolls under it. One Path per colour keeps the draw calls few.
struct LanternfallCanvas: View {
    let game: HordeGame
    let reduceMotion: Bool

    // Visual-only sizes, in world units (1.0 = half the shorter side).
    private static let gridSpacing = 0.25
    private static let glowRadius = 0.9
    private static let headingTick = 0.07
    private static let dashRingGap = 0.035
    private static let dashRingSegments = 24
    private static let arrowSize = 0.07
    private static let arrowInset = 0.85
    private static let shakeAmplitude = 0.02        // of the shorter side
    private static let iFrameBlink = 0.1
    private static let projectileTrail = 0.04       // seconds of travel behind the bolt
    private static let reducedSaltDuration = 0.2

    var body: some View {
        Canvas { context, size in
            draw(in: &context, size: size)
        }
        .accessibilityElement()
        .accessibilityLabel("Graveyard")
        .accessibilityHint("Turn the Digital Crown to steer. Tap to dash.")
        .accessibilityValue(Text(game.dashReadyFraction >= 1 ? "Dash ready" : "Dash recharging"))
    }

    private static func gemRadius(_ value: Int) -> Double {
        value >= 5 ? 0.036 : (value >= 2 ? 0.028 : 0.022)
    }

    private func draw(in context: inout GraphicsContext, size: CGSize) {
        let w = Double(size.width), h = Double(size.height)
        let unit = min(w, h) / 2
        let cx = w / 2, cy = h / 2
        let tuning = game.tuning
        let now = game.elapsed
        let heroPos = game.hero.position
        let halfW = w / (2 * unit), halfH = h / (2 * unit)

        // Screen shake on the newest hit, world layers only (never under Reduce Motion).
        var shakeX = 0.0
        let latestHurt = game.effects.last { $0.kind == .hurt }
        if !reduceMotion, let hurt = latestHurt {
            let age = now - hurt.start
            if age >= 0 && age < hurt.duration {
                shakeX = sin(age * 60) * min(w, h) * Self.shakeAmplitude * (1 - age / hurt.duration)
            }
        }

        func screen(_ p: Vec2) -> CGPoint {
            CGPoint(x: cx + (p.x - heroPos.x) * unit + shakeX, y: cy + (p.y - heroPos.y) * unit)
        }
        func disc(_ c: CGPoint, _ r: Double) -> CGRect {
            CGRect(x: Double(c.x) - r, y: Double(c.y) - r, width: 2 * r, height: 2 * r)
        }
        func visible(_ p: Vec2, margin: Double) -> Bool {
            abs(p.x - heroPos.x) <= halfW + margin && abs(p.y - heroPos.y) <= halfH + margin
        }
        let centre = CGPoint(x: cx, y: cy)

        // 1. Ground
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.lfGround))

        // 2. Dot grid, fixed to the world so it shows movement
        let spacing = Self.gridSpacing
        let dot = max(1, unit * 0.012)
        var grid = Path()
        var gx = ((heroPos.x - halfW) / spacing).rounded(.down) * spacing
        while gx <= heroPos.x + halfW + spacing {
            var gy = ((heroPos.y - halfH) / spacing).rounded(.down) * spacing
            while gy <= heroPos.y + halfH + spacing {
                let p = screen(Vec2(x: gx, y: gy))
                grid.addRect(CGRect(x: Double(p.x) - dot / 2, y: Double(p.y) - dot / 2, width: dot, height: dot))
                gy += spacing
            }
            gx += spacing
        }
        context.fill(grid, with: .color(Theme.lfGridDot))

        // 3. Lantern glow around the hero
        let glowR = Self.glowRadius * unit
        context.fill(Path(ellipseIn: disc(centre, glowR)),
                     with: .radialGradient(Gradient(colors: [Theme.lfLantern.opacity(0.22), Theme.lfLantern.opacity(0)]),
                                           center: centre, startRadius: 0, endRadius: glowR))

        // 4. Gems in three tiers
        var gemSmall = Path(), gemMedium = Path(), gemLarge = Path()
        for gem in game.gems where visible(gem.position, margin: 0.1) {
            let r = disc(screen(gem.position), Self.gemRadius(gem.value) * unit)
            if gem.value >= 5 {
                gemLarge.addEllipse(in: r)
            } else if gem.value >= 2 {
                gemMedium.addEllipse(in: r)
            } else {
                gemSmall.addEllipse(in: r)
            }
        }
        context.fill(gemSmall, with: .color(Theme.lfGemSmall))
        context.fill(gemMedium, with: .color(Theme.lfGemMedium))
        context.fill(gemLarge, with: .color(Theme.lfGemLarge))

        // 5. Salt rings (static fill under Reduce Motion)
        for effect in game.effects {
            guard case .saltRing(let radius) = effect.kind else { continue }
            let age = now - effect.start
            guard age >= 0 else { continue }
            let p = screen(effect.position)
            if reduceMotion {
                if age < Self.reducedSaltDuration {
                    context.fill(Path(ellipseIn: disc(p, radius * unit)), with: .color(Theme.lfSalt.opacity(0.18)))
                }
            } else {
                let t = min(age / effect.duration, 1)
                context.stroke(Path(ellipseIn: disc(p, radius * unit * (0.4 + 0.6 * t))),
                               with: .color(Theme.lfSalt.opacity(1 - t)), lineWidth: unit * 0.02)
            }
        }

        // 6. Enemies by kind, white while just hit, plus a pair of eyes each
        var shamblers = Path(), sprinters = Path(), bloats = Path(), wardens = Path(), flashed = Path(), eyes = Path()
        for e in game.enemies where visible(e.position, margin: 0.3) {
            let r = e.radius(tuning) * unit
            let p = screen(e.position)
            let shape = Path(ellipseIn: disc(p, r))
            if e.hitFlash > 0 && !reduceMotion {
                flashed.addPath(shape)
            } else {
                switch e.kind {
                case .shambler: shamblers.addPath(shape)
                case .sprinter: sprinters.addPath(shape)
                case .bloat: bloats.addPath(shape)
                case .warden: wardens.addPath(shape)
                }
            }
            for side in [-1.0, 1.0] {
                let eye = CGPoint(x: Double(p.x) + side * 0.32 * r, y: Double(p.y) - 0.2 * r)
                eyes.addEllipse(in: disc(eye, max(1, 0.14 * r)))
            }
        }
        context.fill(shamblers, with: .color(Theme.lfShambler))
        context.fill(sprinters, with: .color(Theme.lfSprinter))
        context.fill(bloats, with: .color(Theme.lfBloat))
        context.fill(wardens, with: .color(game.isEnraged ? Theme.lfEnraged : Theme.lfWarden))
        context.fill(flashed, with: .color(.white))
        context.fill(eyes, with: .color(Theme.lfGround))

        // 7. Embers
        let stats = game.stats
        var embers = Path()
        for i in 0..<stats.emberCount {
            embers.addEllipse(in: disc(screen(game.emberPosition(i)), tuning.emberRadius * unit))
        }
        context.fill(embers, with: .color(Theme.lfEmber))

        // 8. Lantern bolts with a short trail
        var trails = Path(), bolts = Path()
        for proj in game.projectiles where visible(proj.position, margin: 0.2) {
            let p = screen(proj.position)
            trails.move(to: p)
            trails.addLine(to: screen(proj.position - proj.velocity * Self.projectileTrail))
            bolts.addEllipse(in: disc(p, tuning.projectileRadius * unit))
        }
        context.stroke(trails, with: .color(Theme.lfBolt.opacity(0.6)), style: StrokeStyle(lineWidth: unit * 0.02, lineCap: .round))
        context.fill(bolts, with: .color(Theme.lfBolt))

        // 9. Chain sparks
        for effect in game.effects {
            guard case .spark(let to) = effect.kind else { continue }
            let age = now - effect.start
            guard age >= 0 && age < effect.duration else { continue }
            var line = Path()
            line.move(to: screen(effect.position))
            line.addLine(to: screen(to))
            context.stroke(line, with: .color(Theme.lfSpark.opacity(1 - age / effect.duration)),
                           style: StrokeStyle(lineWidth: unit * 0.015, lineCap: .round))
        }

        // 10. Hero at the exact centre (no shake), heading tick and dash ring
        var heroOpacity = 1.0
        if game.hero.iFrames > 0 {
            if reduceMotion {
                heroOpacity = 0.6
            } else {
                heroOpacity = Int(game.hero.iFrames / Self.iFrameBlink) % 2 == 0 ? 1 : 0.35
            }
        }
        context.fill(Path(ellipseIn: disc(centre, tuning.heroRadius * unit)), with: .color(Theme.lfHero.opacity(heroOpacity)))
        let heading = HordeMath.direction(degrees: game.hero.heading)
        var tick = Path()
        tick.move(to: CGPoint(x: cx + heading.x * tuning.heroRadius * unit, y: cy + heading.y * tuning.heroRadius * unit))
        tick.addLine(to: CGPoint(x: cx + heading.x * (tuning.heroRadius + Self.headingTick) * unit,
                                 y: cy + heading.y * (tuning.heroRadius + Self.headingTick) * unit))
        context.stroke(tick, with: .color(Theme.lfLantern), style: StrokeStyle(lineWidth: unit * 0.025, lineCap: .round))

        let ringR = (tuning.heroRadius + Self.dashRingGap) * unit
        let fraction = game.dashReadyFraction
        if fraction >= 1 {
            context.stroke(Path(ellipseIn: disc(centre, ringR)), with: .color(Theme.shield.opacity(0.6)), lineWidth: unit * 0.012)
        } else if fraction > 0 {
            var arc = Path()
            let segments = Self.dashRingSegments
            for i in 0...segments {
                let d = HordeMath.direction(degrees: 360 * fraction * Double(i) / Double(segments))
                let p = CGPoint(x: cx + d.x * ringR, y: cy + d.y * ringR)
                if i == 0 { arc.move(to: p) } else { arc.addLine(to: p) }
            }
            context.stroke(arc, with: .color(Theme.shield.opacity(0.35)), style: StrokeStyle(lineWidth: unit * 0.012, lineCap: .round))
        }

        // 11. Puffs where enemies fell
        for effect in game.effects {
            guard case .puff(let radius) = effect.kind else { continue }
            let age = now - effect.start
            guard age >= 0 && age < effect.duration else { continue }
            let t = age / effect.duration
            let r = radius * unit * (reduceMotion ? 1 : 1 + t)
            context.stroke(Path(ellipseIn: disc(screen(effect.position), r)),
                           with: .color(Theme.lfPuff.opacity(1 - t)), lineWidth: unit * 0.012)
        }

        // 12. Arrow at the edge pointing to an off-screen Warden
        if let boss = game.boss {
            let d = boss.position - heroPos
            if abs(d.x) > halfW || abs(d.y) > halfH {
                let tx = d.x != 0 ? Self.arrowInset * halfW / abs(d.x) : Double.infinity
                let ty = d.y != 0 ? Self.arrowInset * halfH / abs(d.y) : Double.infinity
                let t = min(tx, ty)
                let n = d.normalized()
                let s = Self.arrowSize * unit
                let base = CGPoint(x: cx + d.x * t * unit, y: cy + d.y * t * unit)
                var arrow = Path()
                arrow.move(to: CGPoint(x: Double(base.x) + n.x * s, y: Double(base.y) + n.y * s))
                arrow.addLine(to: CGPoint(x: Double(base.x) - n.x * s * 0.6 - n.y * s * 0.6,
                                          y: Double(base.y) - n.y * s * 0.6 + n.x * s * 0.6))
                arrow.addLine(to: CGPoint(x: Double(base.x) - n.x * s * 0.6 + n.y * s * 0.6,
                                          y: Double(base.y) - n.y * s * 0.6 - n.x * s * 0.6))
                arrow.closeSubpath()
                context.fill(arrow, with: .color(game.isEnraged ? Theme.lfEnraged : Theme.lfWarden))
            }
        }

        // 13. Reduce Motion: a static red tint instead of the shake
        if reduceMotion, let hurt = latestHurt, now - hurt.start >= 0, now - hurt.start < hurt.duration {
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.danger.opacity(0.18)))
        }
    }
}
