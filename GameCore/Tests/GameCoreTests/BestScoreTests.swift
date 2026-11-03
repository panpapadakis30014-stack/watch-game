import XCTest
@testable import GameCore

/// (h) Best score only goes up and round-trips through a store that
/// implements the core's protocol.
final class BestScoreTests: XCTestCase {
    func testBestOnlyGoesUp() {
        let keeper = BestScoreKeeper(store: InMemoryBestScoreStore())
        XCTAssertEqual(keeper.best, 0)
        XCTAssertTrue(keeper.submit(100))
        XCTAssertEqual(keeper.best, 100)
        XCTAssertFalse(keeper.submit(50))
        XCTAssertEqual(keeper.best, 100)
        XCTAssertFalse(keeper.submit(100))
        XCTAssertEqual(keeper.best, 100)
        XCTAssertTrue(keeper.submit(150))
        XCTAssertEqual(keeper.best, 150)
    }

    func testRoundTripsThroughStore() {
        let store = InMemoryBestScoreStore()
        BestScoreKeeper(store: store).submit(150)
        XCTAssertEqual(store.loadBest(), 150)
        XCTAssertEqual(BestScoreKeeper(store: store).best, 150)
    }

    func testStartsFromStoredValue() {
        let keeper = BestScoreKeeper(store: InMemoryBestScoreStore(initial: 300))
        XCTAssertEqual(keeper.best, 300)
        XCTAssertFalse(keeper.submit(200))
    }
}
