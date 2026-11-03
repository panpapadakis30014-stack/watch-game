import XCTest
@testable import HordeCore
import GameCore

/// (e) Each upgrade changes exactly the stats it should.
final class UpgradeEffectTests: XCTestCase {
    private func after(_ kind: UpgradeKind, times: Int = 1) -> (HordeGame, HeroStats) {
        var g = HordeGame.quiet()
        g.grant(kind, times: times)
        return (g, g.stats)
    }

    private var base: HeroStats { HordeGame.quiet().stats }

    func testLanternBolt() {
        var e = base
        e.boltDamage = 4
        e.boltCooldown = 0.81
        assertStats(after(.lanternBolt).1, e)
    }

    func testEmberOrbit() {
        var e = base
        e.emberCount = 1
        e.emberDamage = 2
        assertStats(after(.emberOrbit).1, e)
    }

    func testSaltBurst() {
        var e = base
        e.saltRadius = 0.35
        e.saltDamage = 3
        e.saltInterval = 4.0
        assertStats(after(.saltBurst).1, e)
        e.saltRadius = 0.43
        e.saltDamage = 5
        assertStats(after(.saltBurst, times: 2).1, e)
    }

    func testChainSpark() {
        var e = base
        e.chainJumps = 1
        e.chainDamage = 4
        e.chainInterval = 2.0
        assertStats(after(.chainSpark).1, e)
        e.chainJumps = 2
        assertStats(after(.chainSpark, times: 2).1, e)
    }

    func testSwiftBoots() {
        var e = base
        e.moveSpeed = 0.495
        assertStats(after(.swiftBoots).1, e)
    }

    func testThickCoat() {
        var e = base
        e.maxHP = 6
        let (g, s) = after(.thickCoat)
        assertStats(s, e)
        XCTAssertEqual(g.hero.hp, 6)
        var hurt = HordeGame.quiet()
        hurt.hero.hp = 3
        hurt.grant(.thickCoat)
        XCTAssertEqual(hurt.hero.hp, 4)
    }

    func testLodestone() {
        var e = base
        e.pickupRadius = 0.325
        assertStats(after(.lodestone).1, e)
    }

    func testQuickHands() {
        var e = base
        e.cooldownScale = 0.92
        e.boltCooldown = 0.828
        assertStats(after(.quickHands).1, e)
    }

    func testKeenWick() {
        var e = base
        e.damageScale = 1.15
        e.boltDamage = 3.45
        assertStats(after(.keenWick).1, e)
    }

    func testSecondWind() {
        var e = base
        e.dashCooldown = 2.4
        assertStats(after(.secondWind).1, e)
    }

    func testMending() {
        var e = base
        e.mendInterval = 30
        assertStats(after(.mending).1, e)
        e.mendInterval = 15
        assertStats(after(.mending, times: 2).1, e)

        var g = HordeGame.quiet()
        g.hero.hp = 3
        g.grant(.mending)
        for _ in 0..<899 { g.step(dt: 1.0 / 30.0) }
        XCTAssertEqual(g.hero.hp, 3)
        g.step(dt: 1.0 / 30.0)
        XCTAssertEqual(g.hero.hp, 4)
    }

    func testHotTea() {
        var g = HordeGame.quiet()
        g.hero.hp = 2
        let levels = g.upgradeLevels
        g.grant(.hotTea)
        XCTAssertEqual(g.hero.hp, 4)
        g.grant(.hotTea)
        XCTAssertEqual(g.hero.hp, 5)
        XCTAssertEqual(g.upgradeLevels, levels)
        assertStats(g.stats, base)
    }
}
