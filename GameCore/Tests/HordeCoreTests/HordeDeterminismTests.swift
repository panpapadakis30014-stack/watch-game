import XCTest
@testable import HordeCore
import GameCore

/// (a) Same seed and same inputs replay to the same state over 3 minutes.
final class HordeDeterminismTests: XCTestCase {
    private func play(seed: UInt64) -> HordeGame {
        var g = HordeGame(seed: seed, tuning: .tough())
        for i in 0..<5400 {
            if g.offer != nil { g.choose(0) }
            if i % 9 == 0 { g.applyCrown(delta: 1.2) }
            if i % 150 == 0 { g.dash() }
            g.step(dt: 1.0 / 30.0)
        }
        return g
    }

    func testThreeMinutesReplayIdentically() {
        let a = play(seed: 7)
        let b = play(seed: 7)
        XCTAssertEqual(a, b)
        XCTAssertGreaterThanOrEqual(a.elapsed, 179.9)
        XCTAssertGreaterThan(a.kills, 0)
    }

    func testDifferentSeedDiverges() {
        XCTAssertNotEqual(play(seed: 8), play(seed: 7))
    }

    func testAdvanceReplaysIdentically() {
        let frames = [0.016, 0.02, 0.3, 0.001, 0.0333, 0.05, 0.008, 0.1]
        var a = HordeGame(seed: 21, tuning: .tough())
        var b = HordeGame(seed: 21, tuning: .tough())
        for _ in 0..<120 {
            for f in frames {
                for g in [0, 1] {
                    if g == 0 {
                        if a.offer != nil { a.choose(0) }
                        a.applyCrown(delta: 0.5)
                        a.advance(by: f)
                    } else {
                        if b.offer != nil { b.choose(0) }
                        b.applyCrown(delta: 0.5)
                        b.advance(by: f)
                    }
                }
            }
        }
        XCTAssertEqual(a, b)
        XCTAssertGreaterThan(a.elapsed, 10)
    }
}
