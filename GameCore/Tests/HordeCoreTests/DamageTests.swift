import XCTest
@testable import HordeCore
import GameCore

/// (f) Contact damage, invulnerability frames and game over.
final class DamageTests: XCTestCase {
    private func gluedGame(_ kind: EnemyKind) -> HordeGame {
        var g = HordeGame.quiet {
            $0.shambler.speed = 100
            $0.bloat.speed = 100
        }
        g.noBolt()
        g.place(kind, at: .zero)
        return g
    }

    func testShamblerHurtsThenIFramesThenHurtsAgain() {
        var g = gluedGame(.shambler)
        g.enemies[0].hp = 1e9
        XCTAssertEqual(g.step(dt: 1.0 / 30.0), [.hurt(hpLeft: 4)])
        for i in 0..<23 {
            XCTAssertEqual(countHurts(g.step(dt: 1.0 / 30.0)), 0, "i-frame step \(i)")
        }
        var hurts = 0
        for _ in 0..<2 { hurts += countHurts(g.step(dt: 1.0 / 30.0)) }
        XCTAssertEqual(hurts, 1)
        XCTAssertEqual(g.hero.hp, 3)
    }

    func testBloatDoesTwo() {
        var g = gluedGame(.bloat)
        XCTAssertEqual(g.step(dt: 1.0 / 30.0), [.hurt(hpLeft: 3)])
    }

    func testFallenOnceThenFrozen() {
        var g = gluedGame(.bloat)
        g.enemies[0].hp = 1e9
        var events: [HordeEvent] = []
        for _ in 0..<200 where g.phase == .playing {
            events += g.step(dt: 1.0 / 30.0)
        }
        XCTAssertEqual(g.phase, .fallen)
        XCTAssertEqual(g.hero.hp, 0)
        XCTAssertEqual(events.filter { $0 == .fallen }.count, 1)
        XCTAssertEqual(events.last, .fallen)

        let frozen = g
        XCTAssertEqual(g.step(dt: 1), [])
        XCTAssertEqual(g.advance(by: 0.2), [])
        XCTAssertEqual(g.dash(), [])
        XCTAssertEqual(g.choose(0), [])
        g.applyCrown(delta: 3)
        g.pause()
        g.resume()
        XCTAssertEqual(g, frozen)
    }
}
