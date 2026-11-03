import XCTest
@testable import GameCore

/// (e) Losing all three lives ends the game, and further input changes nothing.
final class LivesTests: XCTestCase {
    func testThreeHitsEndTheGameOnce() {
        var g = Game.quiet()
        var events: [GameEvent] = []
        events += g.takeHit()
        XCTAssertEqual(g.lives, 2)
        XCTAssertEqual(g.phase, .playing)
        events += g.takeHit()
        XCTAssertEqual(g.lives, 1)
        events += g.takeHit()
        XCTAssertEqual(g.lives, 0)
        XCTAssertEqual(g.phase, .gameOver)
        let overs = events.filter { if case .gameOver = $0 { return true } else { return false } }
        XCTAssertEqual(overs, [.gameOver(finalScore: 0)])
    }

    func testInputAfterGameOverChangesNothing() {
        var g = Game.quiet()
        g.blockOne()
        g.place(angle: 200, distance: 0.9)   // stays on screen after game over
        for _ in 0..<3 { g.takeHit() }
        XCTAssertEqual(g.phase, .gameOver)
        let frozen = g

        XCTAssertEqual(g.step(dt: 1), [])
        XCTAssertEqual(g.advance(by: 0.2), [])
        g.applyCrown(delta: 5)
        XCTAssertEqual(g.usePulse(), [])
        XCTAssertEqual(g, frozen)

        // pause()/resume() return Void: assert they leave the state untouched.
        g.pause()
        XCTAssertEqual(g, frozen)
        g.resume()
        XCTAssertEqual(g, frozen)
        XCTAssertEqual(g.phase, .gameOver)
    }

    func testGameOverStopsMidStepAndLeavesRemainingShards() {
        var g = Game.quiet { $0.startLives = 1 }
        g.place(angle: 180, distance: 0.15)
        g.place(angle: 200, distance: 0.15)
        let events = g.step(dt: 0.1)
        XCTAssertEqual(hitCount(events), 1)
        XCTAssertEqual(g.phase, .gameOver)
        XCTAssertEqual(g.shards.count, 1)
    }
}
