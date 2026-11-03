import XCTest
@testable import GameCore

/// Helpers for rule tests: a game where nothing spawns on its own, plus
/// shards placed by hand through the internal setters.
extension Game {
    static func quiet(_ tweak: (inout Tuning) -> Void = { _ in }) -> Game {
        var t = Tuning.standard
        t.firstSpawnDelay = 1e9
        tweak(&t)
        return Game(seed: 1, tuning: t)
    }

    mutating func place(angle: Double, distance: Double = 0.35, speed: Double = 0.4) {
        shards.append(Shard(id: nextShardID, angle: angle, distance: distance, speed: speed))
        nextShardID += 1
    }

    /// Puts a shard just outside the shield, in line with it, and steps it through.
    @discardableResult
    mutating func blockOne() -> [GameEvent] {
        place(angle: shieldAngle)
        return step(dt: 0.1)
    }

    /// Puts a shard just outside the core, opposite the shield, and steps it in.
    @discardableResult
    mutating func takeHit() -> [GameEvent] {
        place(angle: AngleMath.normalize(shieldAngle + 180), distance: tuning.coreRadius + 0.01)
        return step(dt: 0.1)
    }
}

func blockedCount(_ events: [GameEvent]) -> Int {
    events.filter { if case .blocked = $0 { return true } else { return false } }.count
}

func hitCount(_ events: [GameEvent]) -> Int {
    events.filter { if case .hit = $0 { return true } else { return false } }.count
}
