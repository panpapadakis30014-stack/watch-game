/// Deterministic game states for the CI screenshots, produced by running the
/// real simulation with the autopilot from a fixed seed.
public enum HordeDemo {
    public static let seed: UInt64 = 20_261_104

    /// A busy round a few minutes in, with no offer open.
    public static func midGame() -> HordeGame {
        var g = HordeGame(seed: seed)
        while g.phase == .playing && g.elapsed < 240
            && !(g.elapsed >= 150 && g.offer == nil && g.enemies.count >= 12) {
            HordeAutopilot.act(on: &g)
            if g.offer == nil { g.step(dt: g.tuning.fixedTimeStep) }
        }
        return g
    }

    /// The first upgrade offer after the first minute, still open.
    public static func levelUpOffer() -> HordeGame {
        var g = HordeGame(seed: seed)
        while g.phase == .playing && g.elapsed < 240 {
            if g.offer != nil && g.elapsed >= 60 { break }
            HordeAutopilot.act(on: &g)
            if g.offer == nil { g.step(dt: g.tuning.fixedTimeStep) }
        }
        return g
    }
}
