import XCTest
@testable import HordeCore
import GameCore

/// (d) Gems, XP and level-ups.
final class ExperienceTests: XCTestCase {
    private let dt = 1.0 / 30.0

    func testGemValuesPerKindAndNoneForWarden() {
        var g = HordeGame.quiet { $0.heroSpeed = 0 }
        for (k, kind) in [EnemyKind.shambler, .sprinter, .bloat].enumerated() {
            let i = g.place(kind, at: Vec2(x: 1.5, y: Double(k) * 0.4 - 0.4))
            g.enemies[i].hp = 0
        }
        g.step(dt: dt)
        XCTAssertEqual(g.gems.map(\.value).sorted(), [1, 2, 5])

        var w = HordeGame.quiet()
        let i = w.place(.warden, at: Vec2(x: 1.5, y: 0))
        w.enemies[i].hp = 0
        w.step(dt: dt)
        XCTAssertTrue(w.gems.isEmpty)
    }

    private func magnetizes(at distance: Double, lodestone: Int = 0) -> Bool {
        var g = HordeGame.quiet { $0.heroSpeed = 0 }
        g.grant(.lodestone, times: lodestone)
        g.gems.append(Gem(id: 999, position: Vec2(x: distance, y: 0), value: 1))
        g.step(dt: dt)
        return g.gems.first?.magnetized ?? true
    }

    func testPickupRadius() {
        XCTAssertTrue(magnetizes(at: 0.25 - 0.01))
        XCTAssertFalse(magnetizes(at: 0.25 + 0.05))
        XCTAssertTrue(magnetizes(at: 0.30, lodestone: 1))
    }

    func testXPCurve() {
        let t = HordeTuning.standard
        let expected = [5, 7, 9, 12, 16, 20, 24, 28, 33, 39, 45, 51, 57, 64, 72, 80, 88, 96]
        XCTAssertEqual((1...18).map { t.xpToNext(level: $0) }, expected)
        for level in 1..<60 {
            XCTAssertLessThan(t.xpToNext(level: level), t.xpToNext(level: level + 1))
        }
    }

    func testQueuedLevelUpsOfferInTurn() {
        var g = HordeGame.quiet { $0.heroSpeed = 0 }
        g.gems.append(Gem(id: 999, position: .zero, value: 30))
        let events = g.step(dt: dt)
        XCTAssertEqual(g.level, 4)
        XCTAssertEqual(g.xp, 9)
        XCTAssertEqual(events, [.offerOpened(heroLevel: 2)])
        XCTAssertEqual(g.offer?.heroLevel, 2)
        XCTAssertEqual(g.pendingLevelUps, 2)
        XCTAssertEqual(g.choose(0), [.offerOpened(heroLevel: 3)])
        XCTAssertEqual(g.choose(0), [.offerOpened(heroLevel: 4)])
        XCTAssertEqual(g.choose(0), [])
        XCTAssertNil(g.offer)
        XCTAssertTrue(g.isRunning)
    }

    func testGemCapMergesFarthestAndConservesXP() {
        var g = HordeGame.quiet { $0.heroSpeed = 0 }
        for k in 0..<80 {
            g.gems.append(Gem(id: 1000 + k, position: Vec2(x: 0.5 + Double(k) * 0.01, y: 0.5), value: 1))
        }
        let i = g.place(.bloat, at: Vec2(x: -1.0, y: 0))
        g.enemies[i].hp = 0
        g.step(dt: dt)
        XCTAssertEqual(g.gems.count, 80)
        XCTAssertEqual(g.gems.map(\.value).reduce(0, +), 85)
        XCTAssertFalse(g.gems.contains { $0.id == 1079 })   // the farthest one was merged
        XCTAssertEqual(g.gems.last?.value, 6)
    }
}
