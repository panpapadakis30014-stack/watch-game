import XCTest
@testable import HordeCore
import GameCore

/// (i) Nothing moves while paused or while an upgrade offer is open.
final class FreezeTests: XCTestCase {
    private func busyGame() -> HordeGame {
        var g = HordeGame(seed: 3, tuning: .tough())
        for _ in 0..<90 {
            if g.offer != nil { g.choose(0) }
            g.step(dt: 1.0 / 30.0)
        }
        XCTAssertFalse(g.enemies.isEmpty)
        return g
    }

    func testPausedGameIsFullyFrozen() {
        var g = busyGame()
        if g.offer != nil { g.choose(0) }
        g.pause()
        let before = g
        for _ in 0..<10 { XCTAssertEqual(g.advance(by: 0.2), []) }
        XCTAssertEqual(g.step(dt: 1), [])
        g.applyCrown(delta: 3)
        XCTAssertEqual(g.dash(), [])
        XCTAssertEqual(g, before)
    }

    func testOpenOfferFreezesTheGame() {
        var g = busyGame()
        if g.offer == nil { g.forceOffer() }
        XCTAssertNotNil(g.offer)
        XCTAssertFalse(g.isRunning)
        let before = g
        for _ in 0..<10 { XCTAssertEqual(g.advance(by: 0.2), []) }
        XCTAssertEqual(g.step(dt: 1), [])
        g.applyCrown(delta: 3)
        XCTAssertEqual(g, before)
    }

    func testPauseDuringOfferKeepsTheOffer() {
        var g = busyGame()
        if g.offer == nil { g.forceOffer() }
        let serial = g.offer?.serial
        g.pause()
        XCTAssertEqual(g.choose(0), [])
        g.resume()
        XCTAssertEqual(g.offer?.serial, serial)
        XCTAssertFalse(g.isRunning)
    }

    func testResumeAdvancesExactlyOneStep() {
        var g = HordeGame.quiet()
        g.advance(by: 0.02)          // leaves time in the accumulator
        g.pause()
        g.resume()
        let start = g.elapsed
        g.advance(by: 1.0 / 30.0)
        XCTAssertEqual(g.elapsed - start, 1.0 / 30.0, accuracy: 1e-12)
    }
}
