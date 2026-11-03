import XCTest
@testable import GameCore

/// (a) Same seed and same inputs replay to the same score and state.
final class DeterminismTests: XCTestCase {
    private func play(seed: UInt64) -> Game {
        var g = Game(seed: seed)
        for i in 0..<1800 {
            if i % 7 == 0 { g.applyCrown(delta: 1.5) }
            if i % 300 == 0 { g.usePulse() }
            g.step(dt: 1.0 / 60.0)
        }
        return g
    }

    func testSameSeedAndInputsReplayIdentically() {
        let g1 = play(seed: 42)
        let g2 = play(seed: 42)
        XCTAssertEqual(g1, g2)
        XCTAssertEqual(g1.score, g2.score)
        XCTAssertGreaterThan(g1.elapsed, 0)
    }

    func testDifferentSeedDiverges() {
        XCTAssertNotEqual(play(seed: 43), play(seed: 42))
    }

    func testAdvanceWithSameFrameSequenceReplaysIdentically() {
        let frames = [0.016, 0.02, 0.3, 0.001, 0.0167, 0.033, 0.05, 0.008, 0.016, 0.1]
        var g1 = Game(seed: 99)
        var g2 = Game(seed: 99)
        for _ in 0..<60 {
            for f in frames {
                g1.applyCrown(delta: 0.7)
                g2.applyCrown(delta: 0.7)
                g1.advance(by: f)
                g2.advance(by: f)
            }
        }
        XCTAssertEqual(g1, g2)
        XCTAssertGreaterThan(g1.elapsed, 0)
    }
}
