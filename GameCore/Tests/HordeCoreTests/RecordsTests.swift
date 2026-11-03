import XCTest
@testable import HordeCore
import GameCore

/// (j) Records only improve, dawns count up, and they round-trip through a store.
final class RecordsTests: XCTestCase {
    func testRecordsOnlyImprove() {
        let store = InMemoryHordeRecordsStore()
        let keeper = HordeRecordsKeeper(store: store)
        XCTAssertFalse(keeper.records.hasAny)

        XCTAssertEqual(keeper.submit(HordeRunSummary(seconds: 300, kills: 100, level: 9, reachedDawn: false)),
                       HordeRecordsUpdate(newBestTime: true, newMostKills: true, newDawn: false))
        XCTAssertEqual(keeper.submit(HordeRunSummary(seconds: 200, kills: 150, level: 8, reachedDawn: false)),
                       HordeRecordsUpdate(newBestTime: false, newMostKills: true, newDawn: false))
        XCTAssertEqual(keeper.records, HordeRecords(bestSeconds: 300, mostKills: 150, dawns: 0))

        XCTAssertTrue(keeper.submit(HordeRunSummary(seconds: 280, kills: 90, level: 12, reachedDawn: true)).newDawn)
        XCTAssertEqual(keeper.records.dawns, 1)
        keeper.submit(HordeRunSummary(seconds: 250, kills: 80, level: 11, reachedDawn: true))
        XCTAssertEqual(keeper.records.dawns, 2)

        let before = keeper.records
        XCTAssertEqual(keeper.submit(HordeRunSummary(seconds: 10, kills: 5, level: 1, reachedDawn: false)),
                       HordeRecordsUpdate(newBestTime: false, newMostKills: false, newDawn: false))
        XCTAssertEqual(keeper.records, before)
        XCTAssertTrue(keeper.records.hasAny)
    }

    func testRoundTripThroughStore() {
        let store = InMemoryHordeRecordsStore(initial: HordeRecords(bestSeconds: 61, mostKills: 7, dawns: 0))
        XCTAssertEqual(HordeRecordsKeeper(store: store).records.bestSeconds, 61)
        HordeRecordsKeeper(store: store).submit(HordeRunSummary(seconds: 90, kills: 3, level: 2, reachedDawn: false))
        XCTAssertEqual(store.loadRecords(), HordeRecords(bestSeconds: 90, mostKills: 7, dawns: 0))
        XCTAssertEqual(HordeRecordsKeeper(store: store).records, store.loadRecords())
    }
}
