import XCTest
@testable import GameCore

final class AngleMathTests: XCTestCase {
    func testNormalizeWrapsIntoRange() {
        XCTAssertEqual(AngleMath.normalize(-10), 350)
        XCTAssertEqual(AngleMath.normalize(720), 0)
        XCTAssertEqual(AngleMath.normalize(360), 0)
        XCTAssertEqual(AngleMath.normalize(-360), 0)
        XCTAssertEqual(AngleMath.normalize(45), 45)
    }

    func testSignedDeltaTakesShortWayAcrossZero() {
        XCTAssertEqual(AngleMath.signedDelta(from: 350, to: 10), 20)
        XCTAssertEqual(AngleMath.signedDelta(from: 10, to: 350), -20)
        XCTAssertEqual(AngleMath.signedDelta(from: 0, to: 180), 180)
    }

    func testArcEdgeIsInclusive() {
        XCTAssertTrue(AngleMath.isWithinArc(35, center: 0, width: 70))
        XCTAssertTrue(AngleMath.isWithinArc(325, center: 0, width: 70))
        XCTAssertFalse(AngleMath.isWithinArc(35.5, center: 0, width: 70))
    }
}
