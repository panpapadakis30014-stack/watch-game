import XCTest
@testable import HordeCore
import GameCore

/// (h) The Grave Warden: arrival, dawn, enrage and summons.
final class BossTests: XCTestCase {
    private let dt = 1.0 / 30.0

    func testWardenArrivesAheadAtFiveMinutes() {
        var g = HordeGame.quiet { $0.bossTime = 300 }
        g.elapsed = 299.95
        XCTAssertFalse(g.step(dt: dt).contains(.bossArrived))
        XCTAssertNil(g.boss)
        let events = g.step(dt: dt)
        XCTAssertEqual(events.filter { $0 == .bossArrived }.count, 1)
        guard let boss = g.boss else { return XCTFail("no warden") }
        let offset = boss.position - g.hero.position
        XCTAssertEqual(offset.length, 1.75, accuracy: 0.02)
        XCTAssertGreaterThan(offset.normalized().dot(HordeMath.direction(degrees: g.hero.heading)), 0.99)
        XCTAssertFalse(g.step(dt: dt).contains(.bossArrived))
    }

    func testWardenAtTheCapReplacesFarthestEnemy() {
        var g = HordeGame.quiet {
            $0.bossTime = 300
            $0.maxEnemies = 3
        }
        g.place(.shambler, at: Vec2(x: 0.6, y: 0))
        let far = g.enemies[g.place(.shambler, at: Vec2(x: 1.2, y: 0))].id
        g.place(.shambler, at: Vec2(x: -0.6, y: 0))
        g.elapsed = 299.99
        g.step(dt: dt)
        XCTAssertEqual(g.enemies.count, 3)
        XCTAssertNotNil(g.boss)
        XCTAssertFalse(g.enemies.contains { $0.id == far })
    }

    func testDefeatingWardenBringsDawn() {
        var g = HordeGame.quiet()
        let w = g.place(.warden, at: Vec2(x: 1.0, y: 0))
        g.enemies[w].hp = 0
        let events = g.step(dt: dt)
        XCTAssertEqual(events.filter { $0 == .dawn }.count, 1)
        XCTAssertEqual(g.phase, .dawn)
        XCTAssertTrue(g.summary.reachedDawn)
        let frozen = g
        XCTAssertEqual(g.step(dt: 1), [])
        XCTAssertEqual(g.dash(), [])
        g.applyCrown(delta: 2)
        g.pause()
        XCTAssertEqual(g, frozen)
    }

    func testEnrageSpeedsUpWardenAndHorde() {
        var g = HordeGame.quiet { $0.enrageTime = 420 }
        g.noBolt()
        let w = g.place(.warden, at: Vec2(x: 1.0, y: 0))
        let s = g.place(.shambler, at: Vec2(x: -1.0, y: 0))
        g.summonTimer = 0.01
        g.elapsed = 419.98
        let wardenBefore = g.enemies[w].position
        let shamblerBefore = g.enemies[s].position
        let events = g.step(dt: dt)
        XCTAssertEqual(events.filter { $0 == .bossEnraged }.count, 1)
        XCTAssertTrue(g.isEnraged)
        XCTAssertEqual((g.enemies[w].position - wardenBefore).length, 0.40 * dt, accuracy: 1e-9)
        XCTAssertEqual((g.enemies[s].position - shamblerBefore).length, 0.22 * 1.25 * dt, accuracy: 1e-9)
        XCTAssertEqual(g.summonTimer, 0.01 - dt + 5, accuracy: 1e-9)   // next summon in 5 s
        XCTAssertFalse(g.step(dt: dt).contains(.bossEnraged))
    }

    func testSummonRingAroundWardenTruncatedAtCap() {
        var g = HordeGame.quiet {
            $0.warden.speed = 0
            $0.shambler.speed = 0
        }
        g.noBolt()
        let w = g.place(.warden, at: Vec2(x: 1.0, y: 0))
        g.summonTimer = 0.01
        g.step(dt: dt)
        let summoned = g.enemies.filter { $0.kind == .shambler }
        XCTAssertEqual(summoned.count, 8)
        for e in summoned {
            XCTAssertEqual((e.position - g.enemies[w].position).length, 0.45, accuracy: 1e-9)
        }
        XCTAssertEqual(g.summonTimer, 0.01 - dt + 10, accuracy: 1e-9)

        var capped = HordeGame.quiet { $0.maxEnemies = 5 }
        capped.place(.warden, at: Vec2(x: 1.0, y: 0))
        capped.summonTimer = 0.01
        capped.step(dt: dt)
        XCTAssertEqual(capped.enemies.count, 5)
    }
}
