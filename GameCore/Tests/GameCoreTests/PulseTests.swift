import XCTest
@testable import GameCore

/// (f) Pulse charge, use and reset.
final class PulseTests: XCTestCase {
    func testNewGameHasNoCharge() {
        let g = Game(seed: 5)
        XCTAssertEqual(g.pulseCharge, 0)
        XCTAssertFalse(g.isPulseReady)
    }

    func testEightBlocksChargeThePulseOnce() {
        var g = Game.quiet()
        var readies = 0
        for _ in 1...8 {
            readies += g.blockOne().filter { $0 == .pulseReady }.count
        }
        XCTAssertEqual(g.pulseCharge, 8)
        XCTAssertTrue(g.isPulseReady)
        XCTAssertEqual(readies, 1)

        let ninth = g.blockOne()
        XCTAssertEqual(g.pulseCharge, 8)
        XCTAssertFalse(ninth.contains(.pulseReady))
    }

    func testUsingPulseClearsShardsAndResetsCharge() {
        var g = Game.quiet()
        for _ in 1...8 { g.blockOne() }
        g.place(angle: 45, distance: 0.8)
        g.place(angle: 135, distance: 0.6)
        g.usePulse()
        XCTAssertTrue(g.shards.isEmpty)
        XCTAssertEqual(g.pulseCharge, 0)
        XCTAssertFalse(g.isPulseReady)
        XCTAssertEqual(g.usePulse(), [])
    }

    func testPulseBeforeFullDoesNothing() {
        var g = Game.quiet()
        for _ in 1...7 { g.blockOne() }
        g.place(angle: 45, distance: 0.8)
        let before = g
        XCTAssertEqual(g.usePulse(), [])
        XCTAssertEqual(g, before)
    }

    func testPulseWhilePausedDoesNothing() {
        var g = Game.quiet()
        for _ in 1...8 { g.blockOne() }
        g.place(angle: 45, distance: 0.8)
        g.pause()
        let before = g
        XCTAssertEqual(g.usePulse(), [])
        XCTAssertEqual(g, before)
    }
}
