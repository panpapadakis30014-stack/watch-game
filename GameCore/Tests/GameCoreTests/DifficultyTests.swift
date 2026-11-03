import XCTest
@testable import GameCore

/// (d) Difficulty rises monotonically to a stated cap.
final class DifficultyTests: XCTestCase {
    let tuning = Tuning.standard

    func testRisesMonotonically() {
        var previous = Difficulty.at(elapsed: 0, tuning: tuning)
        var elapsed = 0.5
        while elapsed <= 200 {
            let d = Difficulty.at(elapsed: elapsed, tuning: tuning)
            XCTAssertGreaterThanOrEqual(d.shardSpeed, previous.shardSpeed, "speed at \(elapsed)")
            XCTAssertGreaterThanOrEqual(d.maxShards, previous.maxShards, "maxShards at \(elapsed)")
            XCTAssertGreaterThanOrEqual(d.maxSpawnAngleJump, previous.maxSpawnAngleJump, "jump at \(elapsed)")
            XCTAssertLessThanOrEqual(d.spawnInterval, previous.spawnInterval, "interval at \(elapsed)")
            XCTAssertGreaterThanOrEqual(d.level, previous.level, "level at \(elapsed)")
            previous = d
            elapsed += 0.5
        }
    }

    func testStartValuesAtZero() {
        let d = Difficulty.at(elapsed: 0, tuning: tuning)
        XCTAssertEqual(d.level, 0)
        XCTAssertEqual(d.shardSpeed, 0.40)
        XCTAssertEqual(d.spawnInterval, 0.95)
        XCTAssertEqual(d.maxShards, 2)
        XCTAssertEqual(d.maxSpawnAngleJump, 100)
    }

    func testCapReachedAtRampEndAndHeld() {
        for elapsed in [120.0, 200.0] {
            let d = Difficulty.at(elapsed: elapsed, tuning: tuning)
            XCTAssertEqual(d.level, 1)
            XCTAssertEqual(d.shardSpeed, 0.95)
            XCTAssertEqual(d.spawnInterval, 0.35)
            XCTAssertEqual(d.maxShards, 6)
            XCTAssertEqual(d.maxSpawnAngleJump, 180)
        }
    }
}
