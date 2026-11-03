import XCTest
@testable import GameCore

/// (g) No time passes while paused.
final class PauseTests: XCTestCase {
    func testNothingMovesWhilePaused() {
        var g = Game(seed: 11)
        for _ in 0..<120 { g.step(dt: 1.0 / 60.0) }   // let a shard spawn
        XCTAssertFalse(g.shards.isEmpty)
        g.pause()
        XCTAssertEqual(g.phase, .paused)
        let before = g

        for _ in 0..<10 { XCTAssertEqual(g.advance(by: 0.2), []) }
        XCTAssertEqual(g.step(dt: 1), [])
        g.applyCrown(delta: 4)

        XCTAssertEqual(g.elapsed, before.elapsed)
        XCTAssertEqual(g.shards, before.shards)
        XCTAssertEqual(g.score, before.score)
        XCTAssertEqual(g.shieldAngle, before.shieldAngle)
        XCTAssertEqual(g, before)
    }

    func testResumeRunsExactlyOneStepPerFixedTimestep() {
        var g = Game(seed: 11)
        g.advance(by: 0.01)                 // leaves time in the accumulator
        XCTAssertEqual(g.elapsed, 0)
        g.pause()
        g.resume()
        XCTAssertEqual(g.phase, .playing)
        g.advance(by: 1.0 / 60.0)
        XCTAssertEqual(g.elapsed, 1.0 / 60.0, accuracy: 1e-12)
    }
}
