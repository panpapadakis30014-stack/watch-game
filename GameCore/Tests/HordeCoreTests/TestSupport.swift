import XCTest
@testable import HordeCore
import GameCore

extension HordeTuning {
    /// A hero that cannot fall and a Warden that cannot die, for long runs.
    static func tough(_ tweak: (inout HordeTuning) -> Void = { _ in }) -> HordeTuning {
        var t = HordeTuning.standard
        t.heroBaseHP = 1_000_000
        t.warden.hp = 1e9
        tweak(&t)
        return t
    }
}

extension HordeGame {
    /// Nothing spawns on its own and the Warden never comes.
    static func quiet(seed: UInt64 = 1, _ tweak: (inout HordeTuning) -> Void = { _ in }) -> HordeGame {
        var t = HordeTuning.standard
        t.shamblerSpawn.start = 1e9
        t.sprinterSpawn.start = 1e9
        t.bloatSpawn.start = 1e9
        t.openingShamblers = 0
        t.bossTime = 1e9
        tweak(&t)
        return HordeGame(seed: seed, tuning: t)
    }

    /// Adds an enemy at a position relative to the hero; returns its index.
    @discardableResult
    mutating func place(_ kind: EnemyKind, at offset: Vec2) -> Int {
        spawnEnemy(kind, at: hero.position + offset)
        return enemies.count - 1
    }

    mutating func grant(_ kind: UpgradeKind, times: Int = 1) {
        for _ in 0..<times { apply(kind) }
    }

    mutating func maxAll() {
        for kind in UpgradeKind.allCases where kind != .hotTea {
            while level(of: kind) < kind.maxLevel { apply(kind) }
        }
    }

    /// Removes the starting Lantern Bolt so a test sees only the weapon it is about.
    mutating func noBolt() {
        upgradeLevels[UpgradeKind.lanternBolt.rawValue] = 0
    }

    /// Queues one level-up and runs a step so the offer opens.
    @discardableResult
    mutating func forceOffer() -> [HordeEvent] {
        pendingLevelUps += 1
        return step(dt: tuning.fixedTimeStep)
    }
}

func countHurts(_ events: [HordeEvent]) -> Int {
    events.filter { if case .hurt = $0 { return true } else { return false } }.count
}

func assertStats(_ a: HeroStats, _ b: HeroStats, file: StaticString = #filePath, line: UInt = #line) {
    let doubles: [(String, Double, Double)] = [
        ("moveSpeed", a.moveSpeed, b.moveSpeed), ("pickupRadius", a.pickupRadius, b.pickupRadius),
        ("damageScale", a.damageScale, b.damageScale), ("cooldownScale", a.cooldownScale, b.cooldownScale),
        ("dashCooldown", a.dashCooldown, b.dashCooldown), ("mendInterval", a.mendInterval, b.mendInterval),
        ("boltDamage", a.boltDamage, b.boltDamage), ("boltCooldown", a.boltCooldown, b.boltCooldown),
        ("emberDamage", a.emberDamage, b.emberDamage), ("saltRadius", a.saltRadius, b.saltRadius),
        ("saltDamage", a.saltDamage, b.saltDamage), ("saltInterval", a.saltInterval, b.saltInterval),
        ("chainDamage", a.chainDamage, b.chainDamage), ("chainInterval", a.chainInterval, b.chainInterval)
    ]
    for (name, x, y) in doubles {
        XCTAssertEqual(x, y, accuracy: 1e-9, name, file: file, line: line)
    }
    XCTAssertEqual(a.maxHP, b.maxHP, "maxHP", file: file, line: line)
    XCTAssertEqual(a.emberCount, b.emberCount, "emberCount", file: file, line: line)
    XCTAssertEqual(a.chainJumps, b.chainJumps, "chainJumps", file: file, line: line)
}
