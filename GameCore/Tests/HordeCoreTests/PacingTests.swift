import XCTest
@testable import HordeCore
import GameCore

/// Early pacing with the autopilot, plus printed run-length evidence for the
/// tuning (no asserts on the printout).
final class HordePacingTests: XCTestCase {
    private func run(seed: UInt64, tuning: HordeTuning, until limit: Double,
                     onEvents: (HordeGame, [HordeEvent]) -> Bool = { _, _ in false }) -> HordeGame {
        var g = HordeGame(seed: seed, tuning: tuning)
        while g.phase == .playing && g.elapsed < limit {
            var events = HordeAutopilot.act(on: &g)
            if g.offer == nil { events += g.step(dt: g.tuning.fixedTimeStep) }
            if onEvents(g, events) { break }
        }
        return g
    }

    func testFirstLevelUpWithinTwentySeconds() {
        for seed: UInt64 in 1...5 {
            var first: Double?
            _ = run(seed: seed, tuning: .standard, until: 30) { g, events in
                if events.contains(where: { if case .offerOpened = $0 { return true } else { return false } }) {
                    first = g.elapsed
                    return true
                }
                return false
            }
            guard let t = first else { XCTFail("no level-up by 30 s, seed \(seed)"); continue }
            XCTAssertLessThan(t, 20, "seed \(seed)")
        }
    }

    func testWardenFallsBeforeEnrageForMostRuns() {
        var ends: [Double] = []
        var earlyDawns = 0
        for seed: UInt64 in 1...10 {
            let g = run(seed: seed, tuning: .standard, until: 900)
            ends.append(g.elapsed)
            if g.phase == .dawn && g.elapsed < g.tuning.enrageTime {
                earlyDawns += 1
            }
        }
        let sorted = ends.sorted()
        let median = (sorted[4] + sorted[5]) / 2
        XCTAssertGreaterThanOrEqual(earlyDawns, 6, "dawns before enrage")
        XCTAssertGreaterThanOrEqual(median, 300)
        XCTAssertLessThanOrEqual(median, 420)
    }

    func testPrintRunLengthEvidence() {
        var ends: [Double] = []
        for seed: UInt64 in 1...10 {
            let g = run(seed: seed, tuning: .standard, until: 900)
            let how: String
            switch g.phase {
            case .fallen: how = "fallen"
            case .dawn: how = "dawn"
            case .playing: how = "still playing at cap"
            }
            ends.append(g.elapsed)
            print("Lanternfall run-length: seed \(seed) ended at \(Int(g.elapsed)) s (\(how)), level \(g.level), kills \(g.kills)")
        }
        let sorted = ends.sorted()
        let median = (sorted[4] + sorted[5]) / 2
        print("Lanternfall run-length: median \(Int(median)) s, min \(Int(sorted.first ?? 0)) s, max \(Int(sorted.last ?? 0)) s")

        var heroOnly = HordeTuning.standard
        heroOnly.heroBaseHP = 1_000_000
        for seed: UInt64 in 1...5 {
            let g = run(seed: seed, tuning: heroOnly, until: 300)
            print("Lanternfall level at 300 s (unkillable hero): seed \(seed) level \(g.level), kills \(g.kills)")
        }
    }
}
