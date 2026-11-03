import XCTest
@testable import HordeCore
import GameCore

/// (c) Targeting, swept hits, kills and the four weapons.
final class CombatTests: XCTestCase {
    /// Nothing moves on its own, so positions stay exact.
    private func still(_ tweak: (inout HordeTuning) -> Void = { _ in }) -> HordeGame {
        HordeGame.quiet {
            $0.heroSpeed = 0
            $0.shambler.speed = 0
            $0.warden.speed = 0
            $0.shambler.hp = 100
            tweak(&$0)
        }
    }

    private let dt = 1.0 / 30.0

    func testBoltAimsAtNearestEnemy() {
        var g = still()
        g.place(.shambler, at: Vec2(x: 0, y: 0.5))
        g.place(.shambler, at: Vec2(x: 0.3, y: 0))
        g.place(.shambler, at: Vec2(x: -1.5, y: 0))
        g.step(dt: dt)
        XCTAssertEqual(g.projectiles.count, 1)
        let v = g.projectiles[0].velocity
        XCTAssertEqual(v.x, 2.4, accuracy: 1e-12)
        XCTAssertEqual(v.y, 0, accuracy: 1e-12)
    }

    func testBoltTieGoesToLowerIndex() {
        var g = still()
        g.place(.shambler, at: Vec2(x: 0.4, y: 0))
        g.place(.shambler, at: Vec2(x: -0.4, y: 0))
        g.step(dt: dt)
        XCTAssertGreaterThan(g.projectiles.first?.velocity.x ?? 0, 0)
    }

    func testNoTargetInRangeMeansNoBoltAndReadyTimer() {
        var g = still()
        g.place(.shambler, at: Vec2(x: 1.5, y: 0))
        g.step(dt: dt)
        XCTAssertTrue(g.projectiles.isEmpty)
        XCTAssertEqual(g.boltTimer, 0)
    }

    func testFastProjectileCannotTunnel() {
        var g = still()
        g.noBolt()
        let target = g.place(.shambler, at: Vec2(x: 1.5, y: 0))
        g.projectiles.append(Projectile(id: 999, position: g.hero.position, velocity: Vec2(x: 30, y: 0), damage: 1, life: 1))
        g.step(dt: 0.1)                       // moves 3.0 in one step, far past the enemy
        XCTAssertEqual(g.enemies[target].hp, 99)
        XCTAssertTrue(g.projectiles.isEmpty)
    }

    func testKillRemovesEnemyCountsAndDropsGem() {
        var g = still()
        let i = g.place(.shambler, at: Vec2(x: 1.5, y: 0))
        g.enemies[i].hp = 0
        g.step(dt: dt)
        XCTAssertTrue(g.enemies.isEmpty)
        XCTAssertEqual(g.kills, 1)
        XCTAssertEqual(g.gems.count, 1)
        XCTAssertEqual(g.gems.first?.value, 1)
    }

    func testEmberHitsAtMostEveryHalfSecond() {
        var g = still { $0.emberDegreesPerSecond = 0 }
        g.noBolt()
        g.grant(.emberOrbit)
        let i = g.place(.shambler, at: g.emberPosition(0) - g.hero.position)
        for _ in 0..<30 { g.step(dt: dt) }
        XCTAssertEqual(g.enemies[i].hp, 96, accuracy: 1e-9)   // hits at 1/30 s and ~0.53 s
        g.step(dt: dt)
        XCTAssertEqual(g.enemies[i].hp, 94, accuracy: 1e-9)   // third hit 0.5 s after the second
    }

    func testSaltDamagesAndKnocksBackButNotTheWarden() {
        var g = still()
        g.noBolt()
        g.grant(.saltBurst)
        let s = g.place(.shambler, at: Vec2(x: 0.2, y: 0))
        let w = g.place(.warden, at: Vec2(x: -0.2, y: 0))
        g.summonTimer = 1e9                                   // no summoned ring in this test
        let wardenStart = g.enemies[w].position
        for _ in 0..<16 { g.step(dt: dt) }                    // first burst after 0.5 s
        XCTAssertEqual(g.enemies[s].hp, 97, accuracy: 1e-9)
        XCTAssertEqual(g.enemies[s].position.x, 0.45, accuracy: 1e-9)
        XCTAssertEqual(g.enemies[w].hp, g.tuning.warden.hp - 3, accuracy: 1e-6)
        XCTAssertEqual(g.enemies[w].position, wardenStart)
        XCTAssertTrue(g.effects.contains { if case .saltRing = $0.kind { return true } else { return false } })
    }

    private func chainStruck(level: Int) -> Int {
        var g = still()
        g.noBolt()
        g.grant(.chainSpark, times: level)
        for k in 1...5 { g.place(.shambler, at: Vec2(x: 0.3 * Double(k), y: 0)) }
        for _ in 0..<20 { g.step(dt: dt) }                    // first zap after 0.5 s
        return g.enemies.filter { $0.hp < 100 }.count
    }

    func testChainStrikesOnePlusJumps() {
        XCTAssertEqual(chainStruck(level: 1), 2)
        XCTAssertEqual(chainStruck(level: 3), 4)
    }
}
