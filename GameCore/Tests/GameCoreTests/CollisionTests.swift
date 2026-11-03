import XCTest
@testable import GameCore

/// (b) Block vs hit at the shield arc edges, including the wrap at 0/360,
/// and AC4: fixed timestep, no tunnelling on frame spikes.
final class CollisionTests: XCTestCase {
    /// Places one shard just outside the shield at `angle` and runs it all the way in.
    private func outcome(shield: Double, shard angle: Double) -> (blocked: Int, hits: Int) {
        var g = Game.quiet()
        g.shieldAngle = shield
        g.place(angle: angle, distance: 0.35, speed: 0.4)
        let events = g.step(dt: 1)
        return (blockedCount(events), hitCount(events))
    }

    private func assertBlocks(shield: Double, shard: Double, file: StaticString = #filePath, line: UInt = #line) {
        let r = outcome(shield: shield, shard: shard)
        XCTAssertEqual(r.blocked, 1, "shield \(shield) shard \(shard) should block", file: file, line: line)
        XCTAssertEqual(r.hits, 0, file: file, line: line)
    }

    private func assertHits(shield: Double, shard: Double, file: StaticString = #filePath, line: UInt = #line) {
        let r = outcome(shield: shield, shard: shard)
        XCTAssertEqual(r.blocked, 0, "shield \(shield) shard \(shard) should hit", file: file, line: line)
        XCTAssertEqual(r.hits, 1, file: file, line: line)
    }

    func testArcEdgesAroundZero() {
        assertBlocks(shield: 0, shard: 35)
        assertBlocks(shield: 0, shard: 325)
        assertHits(shield: 0, shard: 35.5)
        assertHits(shield: 0, shard: 324.5)
    }

    func testArcEdgesWrappingPast360() {
        assertBlocks(shield: 350, shard: 15)
        assertBlocks(shield: 350, shard: 25)   // delta exactly 35
        assertHits(shield: 350, shard: 26)
    }

    func testArcEdgesWrappingBelowZero() {
        assertBlocks(shield: 10, shard: 335)   // delta exactly -35
        assertHits(shield: 10, shard: 334)
    }

    func testHugeStepCannotTunnelThroughShield() {
        var g = Game.quiet()
        g.place(angle: 0, distance: 1.0, speed: 0.4)
        let events = g.step(dt: 10)
        XCTAssertEqual(blockedCount(events), 1)
        XCTAssertEqual(hitCount(events), 0)
        XCTAssertEqual(g.lives, 3)
        XCTAssertTrue(g.shards.isEmpty)
    }

    func testHugeStepUnalignedIsAHit() {
        var g = Game.quiet()
        g.place(angle: 180, distance: 1.0, speed: 0.4)
        let events = g.step(dt: 10)
        XCTAssertEqual(blockedCount(events), 0)
        XCTAssertEqual(hitCount(events), 1)
        XCTAssertEqual(g.lives, 2)
    }

    func testFrameSpikeIsClampedToMaxFrameDelta() {
        var g = Game.quiet()
        var reference = g
        g.advance(by: 10)
        XCTAssertEqual(g.elapsed, 0.25, accuracy: 1e-9)
        for _ in 0..<15 { reference.step(dt: 1.0 / 60.0) }
        XCTAssertEqual(g.elapsed, reference.elapsed, accuracy: 1e-12)
        XCTAssertNotEqual(g.elapsed, 16.0 / 60.0, accuracy: 1e-6)
    }

    func testSubStepFramesAccumulate() {
        var g = Game.quiet()
        g.advance(by: 1.0 / 120.0)
        XCTAssertEqual(g.elapsed, 0)
        g.advance(by: 1.0 / 120.0)
        XCTAssertEqual(g.elapsed, 1.0 / 60.0, accuracy: 1e-12)
    }

    func testFrameSpikeThroughAdvanceStillBlocks() {
        var g = Game.quiet()
        g.place(angle: 0, distance: 0.4, speed: 0.85)
        let events = g.advance(by: 5)
        XCTAssertEqual(blockedCount(events), 1)
        XCTAssertEqual(g.lives, 3)
    }
}
