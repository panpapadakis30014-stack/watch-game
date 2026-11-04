import SwiftUI
import HordeCore
import FXCore

/// Draws the graveyard from a `HordeGame` snapshot in one Canvas. Stateless:
/// everything comes from the game, and effect timing uses game time so it
/// freezes with the game. The hero is always drawn at the centre; the world
/// scrolls under it. The night background shows through (drawn by the hub).
///
/// Budget: ≤ 64 calls, 1 gradient (worst case ≈ 53: grid 1, lantern glow 1,
/// gems 6, salt 2, enemies 7, embers 2, bolts 3, sparks 4, hero 4, puffs 1,
/// arrow 1, hurt tint 1, particles ≤ 20). One Path per colour; no blur,
/// shadow or filters.
struct LanternfallCanvas: View {
    let game: HordeGame
    let particles: ParticleSystem
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
    private static let wardenHaloScale = 1.6
    private static let wardenHaloOpacity = 0.2

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
        func visible(_ p: Vec2, margin: Double) -> Bool {
            abs(p.x - heroPos.x) <= halfW + margin && abs(p.y - heroPos.y) <= halfH + margin
        }
        func addDisc(_ path: inout Path, _ c: CGPoint, _ r: Double) {
            GlowPath.addCircle(&path, c, CGFloat(r))
        }
        let centre = CGPoint(x: cx, y: cy)

        // 1. Dot grid, fixed to the world so it shows movement
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

        // 2. Lantern glow around the hero (the frame's only gradient)
        let glowR = Self.glowRadius * unit
        var glow = Path()
        addDisc(&glow, centre, glowR)
        context.fill(glow, with: .radialGradient(Theme.lanternGlowGradient, center: centre, startRadius: 0, endRadius: glowR))

        // 3. Gems in three tiers, softly glowing
        var gemCores = [Path(), Path(), Path()], gemHalos = [Path(), Path(), Path()]
        for gem in game.gems where visible(gem.position, margin: 0.1) {
            let tier = gem.value >= 5 ? 2 : (gem.value >= 2 ? 1 : 0)
            let p = screen(gem.position)
            let r = Self.gemRadius(gem.value) * unit
            addDisc(&gemCores[tier], p, r)
            addDisc(&gemHalos[tier], p, r * Double(Theme.glowSoft.haloWidth))
        }
        for (tier, colour) in [Theme.lfGemSmall, Theme.lfGemMedium, Theme.lfGemLarge].enumerated() {
            GlowPath.fill(core: gemCores[tier], halo: gemHalos[tier], in: &context, color: colour, style: Theme.glowSoft)
        }

        // 4. Salt rings: an expanding glowing ring, or a static fill under Reduce Motion
        for effect in game.effects {
            guard case .saltRing(let radius) = effect.kind else { continue }
            let age = now - effect.start
            guard age >= 0 else { continue }
            let p = screen(effect.position)
            var ring = Path()
            if reduceMotion {
                if age < Self.reducedSaltDuration {
                    addDisc(&ring, p, radius * unit)
                    context.fill(ring, with: .color(Theme.lfSalt.opacity(0.18)))
                }
            } else {
                let t = min(age / effect.duration, 1)
                addDisc(&ring, p, radius * unit * (0.4 + 0.6 * t))
                GlowPath.stroke(ring, in: &context, color: Theme.lfSalt.opacity(1 - t),
                                width: unit * 0.02, style: Theme.glowStandard)
            }
        }

        // 5. Enemies by kind, white while just hit, a halo on the Warden, and eyes
        var shamblers = Path(), sprinters = Path(), bloats = Path(), wardens = Path()
        var flashed = Path(), eyes = Path(), wardenHalo = Path()
        for e in game.enemies where visible(e.position, margin: 0.3) {
            let r = e.radius(tuning) * unit
            let p = screen(e.position)
            if e.kind == .warden {
                addDisc(&wardenHalo, p, r * Self.wardenHaloScale)
            }
            if e.hitFlash > 0 && !reduceMotion {
                addDisc(&flashed, p, r)
            } else {
                switch e.kind {
                case .shambler: addDisc(&shamblers, p, r)
                case .sprinter: addDisc(&sprinters, p, r)
                case .bloat: addDisc(&bloats, p, r)
                case .warden: addDisc(&wardens, p, r)
                }
            }
            for side in [-1.0, 1.0] {
                addDisc(&eyes, CGPoint(x: Double(p.x) + side * 0.32 * r, y: Double(p.y) - 0.2 * r), max(1, 0.14 * r))
            }
        }
        let wardenColour = game.isEnraged ? Theme.lfEnraged : Theme.lfWarden
        if !wardenHalo.isEmpty {
            context.fill(wardenHalo, with: .color(wardenColour.opacity(Self.wardenHaloOpacity)))
        }
        context.fill(shamblers, with: .color(Theme.lfShambler))
        context.fill(sprinters, with: .color(Theme.lfSprinter))
        context.fill(bloats, with: .color(Theme.lfBloat))
        context.fill(wardens, with: .color(wardenColour))
        context.fill(flashed, with: .color(Theme.glowHot))
        context.fill(eyes, with: .color(Theme.lfGround))

        // 6. Embers
        let stats = game.stats
        var embers = Path(), emberHalos = Path()
        for i in 0..<stats.emberCount {
            let p = screen(game.emberPosition(i))
            addDisc(&embers, p, tuning.emberRadius * unit)
            addDisc(&emberHalos, p, tuning.emberRadius * unit * Double(Theme.glowSoft.haloWidth))
        }
        GlowPath.fill(core: embers, halo: emberHalos, in: &context, color: Theme.lfEmber, style: Theme.glowSoft)

        // 7. Lantern bolts: trails (motion, so not under Reduce Motion), then glowing heads
        var trails = Path(), bolts = Path(), boltHalos = Path()
        for proj in game.projectiles where visible(proj.position, margin: 0.2) {
            let p = screen(proj.position)
            if !reduceMotion {
                trails.move(to: p)
                trails.addLine(to: screen(proj.position - proj.velocity * Self.projectileTrail))
            }
            addDisc(&bolts, p, tuning.projectileRadius * unit)
            addDisc(&boltHalos, p, tuning.projectileRadius * unit * Double(Theme.glowStandard.haloWidth))
        }
        if !trails.isEmpty {
            context.stroke(trails, with: .color(Theme.lfBolt.opacity(0.6)), style: StrokeStyle(lineWidth: unit * 0.02, lineCap: .round))
        }
        GlowPath.fill(core: bolts, halo: boltHalos, in: &context, color: Theme.lfBolt, style: Theme.glowStandard)

        // 8. Chain sparks, in two fade steps
        var freshSparks = Path(), fadingSparks = Path()
        for effect in game.effects {
            guard case .spark(let to) = effect.kind else { continue }
            let age = now - effect.start
            guard age >= 0 && age < effect.duration else { continue }
            if age < effect.duration / 2 {
                freshSparks.move(to: screen(effect.position))
                freshSparks.addLine(to: screen(to))
            } else {
                fadingSparks.move(to: screen(effect.position))
                fadingSparks.addLine(to: screen(to))
            }
        }
        GlowPath.stroke(freshSparks, in: &context, color: Theme.lfSpark, width: unit * 0.015, style: Theme.glowStandard)
        GlowPath.stroke(fadingSparks, in: &context, color: Theme.lfSpark.opacity(0.5), width: unit * 0.015, style: Theme.glowStandard)

        // 9. Hero at the exact centre (no shake): lantern halo, heading tick and dash ring
        var heroOpacity = 1.0
        if game.hero.iFrames > 0 {
            if reduceMotion {
                heroOpacity = 0.6
            } else {
                heroOpacity = Int(game.hero.iFrames / Self.iFrameBlink) % 2 == 0 ? 1 : 0.35
            }
        }
        var heroCore = Path(), heroHalo = Path()
        addDisc(&heroCore, centre, tuning.heroRadius * unit)
        addDisc(&heroHalo, centre, tuning.heroRadius * unit * Double(Theme.glowStrong.haloWidth))
        GlowPath.fill(core: heroCore, halo: heroHalo, in: &context, color: Theme.lfHero.opacity(heroOpacity),
                      haloColor: Theme.lanternfallAccent, style: Theme.glowStrong)
        let heading = HordeMath.direction(degrees: game.hero.heading)
        var tick = Path()
        tick.move(to: CGPoint(x: cx + heading.x * tuning.heroRadius * unit, y: cy + heading.y * tuning.heroRadius * unit))
        tick.addLine(to: CGPoint(x: cx + heading.x * (tuning.heroRadius + Self.headingTick) * unit,
                                 y: cy + heading.y * (tuning.heroRadius + Self.headingTick) * unit))
        context.stroke(tick, with: .color(Theme.lanternfallAccent), style: StrokeStyle(lineWidth: unit * 0.025, lineCap: .round))

        let ringR = (tuning.heroRadius + Self.dashRingGap) * unit
        let fraction = game.dashReadyFraction
        if fraction >= 1 {
            var ring = Path()
            addDisc(&ring, centre, ringR)
            context.stroke(ring, with: .color(Theme.shield.opacity(0.6)), lineWidth: unit * 0.012)
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

        // 10. Puffs: only under Reduce Motion, as a static fade (particles replace them otherwise)
        if reduceMotion {
            var puffs = Path()
            for effect in game.effects {
                guard case .puff(let radius) = effect.kind else { continue }
                let age = now - effect.start
                guard age >= 0 && age < effect.duration else { continue }
                addDisc(&puffs, screen(effect.position), radius * unit)
            }
            if !puffs.isEmpty {
                context.stroke(puffs, with: .color(Theme.lfPuff.opacity(0.5)), lineWidth: unit * 0.012)
            }
        }

        // 11. Arrow at the edge pointing to an off-screen Warden
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
                context.fill(arrow, with: .color(wardenColour))
            }
        }

        // 12. Reduce Motion: a static red tint instead of the shake
        if reduceMotion, let hurt = latestHurt, now - hurt.start >= 0, now - hurt.start < hurt.duration {
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.danger.opacity(0.18)))
        }

        // 13. Particles (none exist under Reduce Motion)
        ParticleLayer.draw(particles, in: &context,
                           palette: [Theme.lfShambler, Theme.lfSprinter, Theme.lfBloat, Theme.lanternfallAccent, Theme.danger],
                           scale: unit) { v in
            screen(Vec2(x: v.x, y: v.y))
        }
    }
}
