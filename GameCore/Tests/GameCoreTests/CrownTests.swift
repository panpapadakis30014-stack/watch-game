import XCTest
@testable import GameCore

/// (i) Crown input to shield angle, with wrap.
final class CrownTests: XCTestCase {
    func testCrownTurnsShieldAndWraps() {
        var g = Game.quiet()
        XCTAssertEqual(g.shieldAngle, 0)
        g.applyCrown(delta: 3)
        XCTAssertEqual(g.shieldAngle, 30)
        g.applyCrown(delta: -4)
        XCTAssertEqual(g.shieldAngle, 350)
        g.applyCrown(delta: 36)
        XCTAssertEqual(g.shieldAngle, 350)
    }

    func testTrackerConvertsAbsoluteValuesToDeltas() {
        var tracker = CrownTracker()
        XCTAssertEqual(tracker.delta(for: 0), 0)
        XCTAssertEqual(tracker.delta(for: 2.5), 2.5)
        XCTAssertEqual(tracker.delta(for: 100), 0)     // jump ignored
        XCTAssertEqual(tracker.delta(for: 101), 1)
        XCTAssertEqual(tracker.delta(for: 99.5), -1.5)
    }

    func testFirstSampleIsZeroEvenFarFromOrigin() {
        var tracker = CrownTracker()
        XCTAssertEqual(tracker.delta(for: 500), 0)
        XCTAssertEqual(tracker.delta(for: 503), 3)
    }
}
