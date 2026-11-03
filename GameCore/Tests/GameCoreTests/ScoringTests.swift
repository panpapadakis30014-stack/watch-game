import XCTest
@testable import GameCore

/// (c) Score and combo rules.
final class ScoringTests: XCTestCase {
    func testComboMultiplierSteps() {
        var g = Game.quiet()
        for _ in 1...5 { g.blockOne() }
        XCTAssertEqual(g.score, 50)
        XCTAssertEqual(g.multiplier, 1)

        g.blockOne()                       // 6th
        XCTAssertEqual(g.score, 70)
        XCTAssertEqual(g.multiplier, 2)

        for _ in 7...10 { g.blockOne() }
        XCTAssertEqual(g.score, 150)

        g.blockOne()                       // 11th
        XCTAssertEqual(g.score, 180)
        XCTAssertEqual(g.multiplier, 3)

        for _ in 12...15 { g.blockOne() }
        for n in 16...25 {
            let before = g.score
            let events = g.blockOne()
            XCTAssertEqual(g.score - before, 40, "block \(n)")
            XCTAssertTrue(events.contains(.blocked(angle: 0, points: 40, combo: n)))
        }
        XCTAssertEqual(g.multiplier, 4)
        XCTAssertEqual(g.totalBlocks, 25)
    }

    func testHitResetsCombo() {
        var g = Game.quiet()
        for _ in 1...7 { g.blockOne() }
        XCTAssertEqual(g.combo, 7)
        g.takeHit()
        XCTAssertEqual(g.combo, 0)
        let before = g.score
        g.blockOne()
        XCTAssertEqual(g.score - before, 10)
    }

    func testPulseScoresPerShardAndKeepsCombo() {
        var g = Game.quiet()
        for _ in 1...8 { g.blockOne() }
        XCTAssertTrue(g.isPulseReady)
        let combo = g.combo
        g.place(angle: 90, distance: 0.9)
        g.place(angle: 180, distance: 0.9)
        g.place(angle: 270, distance: 0.9)
        let before = g.score
        let events = g.usePulse()
        XCTAssertEqual(events, [.pulse(cleared: 3, points: 15)])
        XCTAssertEqual(g.score - before, 15)
        XCTAssertEqual(g.combo, combo)
    }
}
