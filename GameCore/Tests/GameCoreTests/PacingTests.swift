import XCTest
@testable import GameCore

/// Early pacing: a round should get busy within seconds, while a player who
/// turns the Crown at a human-plausible speed can still keep up at first.
final class PacingTests: XCTestCase {
    /// Fastest shield turn the auto-aim player may make, in degrees per second.
    private let maxTurnRate = 400.0

    /// Plays `seed` with an auto-aim that turns the shield towards the nearest
    /// shard at no more than `maxTurnRate`, for `seconds` of simulated time.
    /// Returns the most shards seen on screen and the time of the first hit.
    private func autoAim(seed: UInt64, seconds: Double) -> (maxShards: Int, firstHit: Double?) {
        var g = Game(seed: seed)
        let dt = g.tuning.fixedTimeStep
        var maxShards = 0
        var firstHit: Double?
        while g.phase == .playing && g.elapsed < seconds {
            if let target = g.shards.min(by: { $0.distance < $1.distance }) {
                let wanted = AngleMath.signedDelta(from: g.shieldAngle, to: target.angle)
                let limit = maxTurnRate * dt
                let turn = min(max(wanted, -limit), limit)
                g.applyCrown(delta: turn / g.tuning.crownDegreesPerUnit)
            }
            let events = g.step(dt: dt)
            maxShards = max(maxShards, g.shards.count)
            if firstHit == nil && events.contains(where: { if case .hit = $0 { return true } else { return false } }) {
                firstHit = g.elapsed
            }
        }
        return (maxShards, firstHit)
    }

    func testStartIntervalIsWellBelowTravelTimeToShield() {
        let t = Tuning.standard
        let travel = (t.spawnRadius - t.shieldRadius) / t.startShardSpeed
        XCTAssertLessThanOrEqual(t.startSpawnInterval, 0.6 * travel)
    }

    func testTwoShardsOnScreenWithinFiveSeconds() {
        for seed: UInt64 in 1...10 {
            XCTAssertGreaterThanOrEqual(autoAim(seed: seed, seconds: 5.0).maxShards, 2, "seed \(seed)")
        }
    }

    func testTurnLimitedAutoAimTakesNoHitInFirstTwentySeconds() {
        for seed: UInt64 in 1...10 {
            XCTAssertNil(autoAim(seed: seed, seconds: 20.0).firstHit, "seed \(seed)")
        }
    }
}
