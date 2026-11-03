import XCTest
@testable import GameCore

/// Keeps the CI screenshot state deterministic and worth looking at.
final class DemoScenarioTests: XCTestCase {
    func testMidGameIsDeterministic() {
        XCTAssertEqual(DemoScenario.midGame(), DemoScenario.midGame())
    }

    func testMidGameShowsALiveRound() {
        let g = DemoScenario.midGame()
        XCTAssertEqual(g.phase, .playing)
        XCTAssertGreaterThanOrEqual(g.shards.count, 2)
        XCTAssertGreaterThan(g.score, 0)
        XCTAssertGreaterThanOrEqual(g.elapsed, 24)
    }
}
