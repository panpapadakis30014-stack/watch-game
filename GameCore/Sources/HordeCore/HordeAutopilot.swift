import GameCore

/// A simple scripted player used for the screenshot demo states and the pacing
/// tests. It steers away from nearby enemies and towards gems with a
/// human-plausible turn rate, dashes when something is about to touch it, and
/// picks upgrades by a fixed preference order.
enum HordeAutopilot {
    static let preference: [UpgradeKind] = [
        .emberOrbit, .lanternBolt, .saltBurst, .chainSpark, .keenWick, .thickCoat,
        .quickHands, .swiftBoots, .lodestone, .secondWind, .mending, .hotTea
    ]
    static let maxTurnDegreesPerSecond = 270.0
    static let threatRange = 0.9
    static let gemRange = 1.5
    static let dashMargin = 0.12

    @discardableResult
    static func act(on g: inout HordeGame) -> [HordeEvent] {
        if let offer = g.offer {
            let best = offer.options.indices.min {
                rank(offer.options[$0].kind) < rank(offer.options[$1].kind)
            } ?? 0
            return g.choose(best)
        }

        // Steer away from nearby threats and towards nearby gems, like a player
        // collecting experience would. Close threats outweigh gems.
        var threat = Vec2.zero
        for e in g.enemies {
            let away = g.hero.position - e.position
            if away.length <= threatRange {
                threat += away * (1 / max(away.lengthSquared, 0.01))
            }
        }
        var lure = Vec2.zero
        for gem in g.gems {
            let toward = gem.position - g.hero.position
            if toward.length <= gemRange {
                lure += toward * (Double(gem.value) / max(toward.lengthSquared, 0.04))
            }
        }
        var bestTurn = 0.0
        if threat != .zero || lure != .zero {
            let threatWeight = min(threat.length / 4, 2)
            let flee = threat.normalized(), seek = lure.normalized()
            var bestScore = -Double.infinity
            for i in 0..<8 {
                let h = 45 * Double(i)
                let delta = AngleMath.signedDelta(from: g.hero.heading, to: h)
                let dir = HordeMath.direction(degrees: h)
                let score = threatWeight * dir.dot(flee) + dir.dot(seek) - 0.3 * abs(delta) / 180
                if score > bestScore {
                    bestScore = score
                    bestTurn = delta
                }
            }
            let limit = maxTurnDegreesPerSecond * g.tuning.fixedTimeStep
            let turn = min(max(bestTurn, -limit), limit)
            g.applyCrown(delta: turn / g.tuning.crownDegreesPerUnit)
        }

        // Dash when an enemy is about to touch and the heading is roughly right.
        let close = g.enemies.contains {
            ($0.position - g.hero.position).length <= g.tuning.heroRadius + $0.radius(g.tuning) + dashMargin
        }
        if close && g.hero.dashCooldownRemaining <= g.tuning.timeEpsilon && abs(bestTurn) <= 45 {
            return g.dash()
        }
        return []
    }

    private static func rank(_ kind: UpgradeKind) -> Int {
        preference.firstIndex(of: kind) ?? preference.count
    }
}
