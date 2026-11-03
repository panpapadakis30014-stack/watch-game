import XCTest
@testable import HordeCore
import GameCore

/// (g) Spawn schedule, entity caps, a performance proxy and early pacing.
final class SpawnScheduleTests: XCTestCase {
    private let dt = 1.0 / 30.0

    func testSpawnScheduleFirstMinute() {
        var g = HordeGame(seed: 1, tuning: .tough { $0.maxEnemies = 200 })
        g.step(dt: dt)
        XCTAssertEqual(g.enemies.filter { $0.kind == .shambler }.count, 5)   // opening burst
        var firstSprinter: Double?
        while g.elapsed < 61 {
            g.step(dt: dt)
            if g.offer != nil { g.choose(0) }
            if firstSprinter == nil && g.enemies.contains(where: { $0.kind == .sprinter }) {
                firstSprinter = g.elapsed
            }
            XCTAssertFalse(g.enemies.contains { $0.kind == .bloat })
        }
        guard let t = firstSprinter else { return XCTFail("no sprinter") }
        XCTAssertGreaterThanOrEqual(t, 60 - 1e-6)
        XCTAssertLessThanOrEqual(t, 60 + dt + 1e-9)
    }

    func testBloatsFromTwoAndAHalfMinutes() {
        var g = HordeGame(seed: 1, tuning: .tough { $0.maxEnemies = 200 })
        g.elapsed = 149.95
        var firstBloat: Double?
        while g.elapsed < 151 && firstBloat == nil {
            g.step(dt: dt)
            if g.offer != nil { g.choose(0) }
            if g.enemies.contains(where: { $0.kind == .bloat }) { firstBloat = g.elapsed }
        }
        guard let t = firstBloat else { return XCTFail("no bloat") }
        XCTAssertGreaterThanOrEqual(t, 150)
        XCTAssertLessThanOrEqual(t, 150 + dt + 1e-9)
    }

    func testCapsHoldForEightMinutes() {
        let tuning = HordeTuning.tough()
        for seed: UInt64 in 1...3 {
            var g = HordeGame(seed: seed, tuning: tuning)
            for i in 0..<14_400 {
                if g.offer != nil { g.choose(0) }
                if i % 10 == 0 { g.applyCrown(delta: 1.0) }
                if i % 90 == 0 { g.dash() }
                g.step(dt: dt)
                if g.enemies.count > tuning.maxEnemies || g.projectiles.count > tuning.maxProjectiles
                    || g.gems.count > tuning.maxGems || g.effects.count > tuning.maxEffects {
                    return XCTFail("cap exceeded, seed \(seed) step \(i)")
                }
            }
            XCTAssertEqual(g.phase, .playing)
        }
    }

    func testPerformanceAtFullCaps() {
        let tuning = HordeTuning.tough {
            for rule in [\HordeTuning.shamblerSpawn, \.sprinterSpawn, \.bloatSpawn] {
                $0[keyPath: rule] = SpawnRule(start: 0, firstDelay: 0, startInterval: 0.02, minInterval: 0.02, intervalDropPerSecond: 0)
            }
            $0.boltBaseCooldown = 0.02
            $0.boltLifetime = 2.0
            $0.boltRange = 3.0
            $0.puffDuration = 1.0       // raised only so the effects cap is reached too
        }
        var g = HordeGame(seed: 5, tuning: tuning)
        g.maxAll()
        var maxEnemies = 0, maxProjectiles = 0, maxGems = 0, maxEffects = 0
        let duration = ContinuousClock().measure {
            for _ in 0..<14_400 {
                if g.offer != nil { g.choose(0) }
                g.step(dt: dt)
                maxEnemies = max(maxEnemies, g.enemies.count)
                maxProjectiles = max(maxProjectiles, g.projectiles.count)
                maxGems = max(maxGems, g.gems.count)
                maxEffects = max(maxEffects, g.effects.count)
            }
        }
        print("HordeCore: 8 simulated minutes at full caps took \(duration)")
        XCTAssertEqual(maxEnemies, tuning.maxEnemies)
        XCTAssertEqual(maxProjectiles, tuning.maxProjectiles)
        XCTAssertEqual(maxGems, tuning.maxGems)
        XCTAssertEqual(maxEffects, tuning.maxEffects)
    }

    func testBusyWithinFourSecondsWithoutInput() {
        for seed: UInt64 in 1...5 {
            var g = HordeGame(seed: seed)
            var busy = false
            while g.elapsed < 4 && !busy && g.phase == .playing {
                if g.offer != nil { g.choose(0) }
                g.step(dt: dt)
                let onScreen = g.enemies.filter {
                    let d = $0.position - g.hero.position
                    return abs(d.x) <= 1.0 && abs(d.y) <= 1.22
                }
                busy = onScreen.count >= 3
            }
            XCTAssertTrue(busy, "seed \(seed)")
        }
    }
}
