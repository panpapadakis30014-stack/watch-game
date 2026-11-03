/// A deterministic mid-game state for screenshots: an auto-aiming player runs
/// the real simulation from a fixed seed until there is something to show.
/// With perfect aim, shards only overlap once difficulty is past about half
/// (roughly a minute in), so the search may run up to 90 s.
public enum DemoScenario {
    public static let seed: UInt64 = 20_261_103
    static let maxElapsed: Double = 90

    public static func midGame() -> Game {
        var g = Game(seed: seed)
        while g.phase == .playing && (g.elapsed < 24 || g.shards.count < 2) && g.elapsed < maxElapsed {
            if let t = g.shards.min(by: { $0.distance < $1.distance }) {
                g.applyCrown(delta: AngleMath.signedDelta(from: g.shieldAngle, to: t.angle) / g.tuning.crownDegreesPerUnit)
            }
            g.step(dt: g.tuning.fixedTimeStep)
        }
        return g
    }
}
