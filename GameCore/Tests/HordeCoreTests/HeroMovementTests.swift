import XCTest
@testable import HordeCore
import GameCore

/// (b) Steering and dash.
final class HeroMovementTests: XCTestCase {
    func testCrownSteersHeadingWithWrap() {
        var g = HordeGame.quiet()
        g.applyCrown(delta: 3)
        XCTAssertEqual(g.hero.heading, 30, accuracy: 1e-12)
        g.applyCrown(delta: -4)
        XCTAssertEqual(g.hero.heading, 350, accuracy: 1e-12)
        g.applyCrown(delta: 36)
        XCTAssertEqual(g.hero.heading, 350, accuracy: 1e-9)
    }

    func testHeroWalksAlongHeading() {
        var g = HordeGame.quiet()
        g.hero.heading = 90
        g.step(dt: 0.1)
        XCTAssertEqual(g.hero.position.x, 0.045, accuracy: 1e-12)
        XCTAssertEqual(g.hero.position.y, 0, accuracy: 1e-12)
    }

    func testDashLastsFiveStepsAndBlocksContact() {
        var g = HordeGame.quiet { $0.shambler.speed = 100 }   // the shambler stays glued to the hero
        g.noBolt()
        let s = g.place(.shambler, at: .zero)
        g.enemies[s].hp = 1e9
        XCTAssertEqual(g.dash(), [.dashed])
        var y = g.hero.position.y
        for i in 1...5 {
            let events = g.step(dt: 0.05)
            XCTAssertEqual(y - g.hero.position.y, 1.8 * 0.05, accuracy: 1e-9, "dash step \(i)")
            XCTAssertEqual(countHurts(events), 0, "dash step \(i)")
            y = g.hero.position.y
        }
        XCTAssertEqual(g.hero.position.y, -0.45, accuracy: 1e-9)
        let events = g.step(dt: 0.05)
        XCTAssertEqual(y - g.hero.position.y, 0.45 * 0.05, accuracy: 1e-9)
        XCTAssertEqual(countHurts(events), 1)
    }

    func testDashCooldown() {
        var g = HordeGame.quiet()
        g.dash()
        for _ in 0..<59 { g.step(dt: 0.05) }
        XCTAssertEqual(g.dash(), [])
        g.step(dt: 0.05)
        XCTAssertEqual(g.dash(), [.dashed])
    }

    func testSecondWindShortensCooldown() {
        var g = HordeGame.quiet()
        g.grant(.secondWind)
        g.dash()
        for _ in 0..<47 { g.step(dt: 0.05) }
        XCTAssertEqual(g.dash(), [])
        g.step(dt: 0.05)
        XCTAssertEqual(g.dash(), [.dashed])
    }

    func testCrownIgnoredWhilePausedOrOfferOpen() {
        var g = HordeGame.quiet()
        g.pause()
        g.applyCrown(delta: 5)
        XCTAssertEqual(g.hero.heading, 0)
        XCTAssertEqual(g.dash(), [])
        g.resume()
        g.forceOffer()
        XCTAssertNotNil(g.offer)
        g.applyCrown(delta: 5)
        XCTAssertEqual(g.hero.heading, 0)
        XCTAssertEqual(g.dash(), [])
    }
}
