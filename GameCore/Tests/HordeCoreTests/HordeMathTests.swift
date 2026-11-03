import XCTest
@testable import HordeCore
import GameCore

final class HordeMathTests: XCTestCase {
    func testSinCosKnownAngles() {
        let cases: [(Double, Double, Double)] = [
            (0, 0, 1), (30, 0.5, 0.75.squareRoot()), (90, 1, 0), (180, 0, -1),
            (270, -1, 0), (-90, -1, 0), (405, 0.5.squareRoot(), 0.5.squareRoot())
        ]
        for (deg, s, c) in cases {
            let r = HordeMath.sinCos(degrees: deg)
            XCTAssertEqual(r.sin, s, accuracy: 1e-10, "sin \(deg)")
            XCTAssertEqual(r.cos, c, accuracy: 1e-10, "cos \(deg)")
        }
    }

    func testPythagoreanIdentityHolds() {
        var deg = 0.0
        while deg <= 720 {
            let r = HordeMath.sinCos(degrees: deg)
            XCTAssertEqual(r.sin * r.sin + r.cos * r.cos, 1, accuracy: 1e-10, "at \(deg)")
            deg += 0.7
        }
    }

    func testDirectionConvention() {
        let up = HordeMath.direction(degrees: 0)
        XCTAssertEqual(up.x, 0, accuracy: 1e-12)
        XCTAssertEqual(up.y, -1, accuracy: 1e-12)
        let right = HordeMath.direction(degrees: 90)
        XCTAssertEqual(right.x, 1, accuracy: 1e-12)
        XCTAssertEqual(right.y, 0, accuracy: 1e-12)
    }

    func testEntryTime() {
        let c = Vec2(x: 1, y: 0)
        // Already overlapping.
        XCTAssertEqual(HordeMath.entryTime(from: Vec2(x: 0.95, y: 0), delta: Vec2(x: 1, y: 0), center: c, radius: 0.1), 0)
        // Passes straight through: enters at x = 0.9 of a move from 0 to 2.
        let s = HordeMath.entryTime(from: .zero, delta: Vec2(x: 2, y: 0), center: c, radius: 0.1)
        XCTAssertNotNil(s)
        XCTAssertEqual(s ?? -1, 0.45, accuracy: 1e-12)
        // Misses to the side.
        XCTAssertNil(HordeMath.entryTime(from: Vec2(x: 0, y: 0.5), delta: Vec2(x: 2, y: 0), center: c, radius: 0.1))
        // Stops short.
        XCTAssertNil(HordeMath.entryTime(from: .zero, delta: Vec2(x: 0.5, y: 0), center: c, radius: 0.1))
        // Not moving and not overlapping.
        XCTAssertNil(HordeMath.entryTime(from: .zero, delta: .zero, center: c, radius: 0.1))
    }

    func testCueThrottle() {
        var t = CueThrottle<String>(minGap: 0.15)
        XCTAssertTrue(t.allow("a", at: 0))
        XCTAssertFalse(t.allow("a", at: 0.1))
        XCTAssertTrue(t.allow("b", at: 0.1))
        XCTAssertTrue(t.allow("a", at: 0.15))
        XCTAssertFalse(t.allow("a", at: 0.2))
    }
}
