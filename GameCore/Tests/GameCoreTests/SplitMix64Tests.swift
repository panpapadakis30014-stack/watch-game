import XCTest
@testable import GameCore

final class SplitMix64Tests: XCTestCase {
    func testKnownFirstOutputForSeedZero() {
        var rng = SplitMix64(seed: 0)
        XCTAssertEqual(rng.next(), 0xE220_A839_7B1D_CDAF)
    }

    func testNextUnitStaysInHalfOpenUnitRange() {
        var rng = SplitMix64(seed: 12_345)
        for _ in 0..<10_000 {
            let u = rng.nextUnit()
            XCTAssertGreaterThanOrEqual(u, 0)
            XCTAssertLessThan(u, 1)
        }
    }

    func testSameSeedGivesSameSequence() {
        var a = SplitMix64(seed: 7)
        var b = SplitMix64(seed: 7)
        for _ in 0..<100 { XCTAssertEqual(a.next(), b.next()) }
    }
}
