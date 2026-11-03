import XCTest
@testable import HordeCore
import GameCore

/// (k) The screenshot states are deterministic and show what they should.
final class HordeDemoTests: XCTestCase {
    func testMidGame() {
        let g = HordeDemo.midGame()
        XCTAssertEqual(g, HordeDemo.midGame())
        XCTAssertEqual(g.phase, .playing)
        XCTAssertGreaterThanOrEqual(g.elapsed, 150)
        XCTAssertLessThan(g.elapsed, 240)
        XCTAssertGreaterThanOrEqual(g.enemies.count, 12)
        XCTAssertGreaterThanOrEqual(g.level, 5)
        let weapons = [UpgradeKind.lanternBolt, .emberOrbit, .saltBurst, .chainSpark].filter { g.level(of: $0) > 0 }
        XCTAssertGreaterThanOrEqual(weapons.count, 2)
        XCTAssertNil(g.offer)
    }

    func testLevelUpOffer() {
        let g = HordeDemo.levelUpOffer()
        XCTAssertEqual(g, HordeDemo.levelUpOffer())
        XCTAssertEqual(g.phase, .playing)
        XCTAssertEqual(g.offer?.options.count, 3)
        XCTAssertGreaterThanOrEqual(g.elapsed, 60)
        XCTAssertTrue(g.offer?.options.contains { $0.fromLevel >= 1 } ?? false)
    }
}
