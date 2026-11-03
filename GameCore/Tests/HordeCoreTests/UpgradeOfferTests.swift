import XCTest
@testable import HordeCore
import GameCore

/// (e) Offers: three distinct, non-maxed choices; Hot Tea only as filler.
final class UpgradeOfferTests: XCTestCase {
    func testTwoHundredOffersAreValid() {
        var picker = SplitMix64(seed: 77)
        var offers = 0
        for seed: UInt64 in 1...10 {
            var g = HordeGame.quiet(seed: seed)
            for _ in 0..<20 {
                g.forceOffer()
                guard let offer = g.offer else { return XCTFail("no offer") }
                offers += 1
                XCTAssertEqual(offer.options.count, 3)
                XCTAssertEqual(Set(offer.options.map(\.kind.rawValue)).count, 3)
                for o in offer.options {
                    XCTAssertNotEqual(o.kind, .hotTea)
                    XCTAssertLessThan(o.fromLevel, o.kind.maxLevel)
                    XCTAssertEqual(o.fromLevel, g.level(of: o.kind))
                    XCTAssertEqual(o.toLevel, o.fromLevel + 1)
                }
                g.choose(Int(picker.next() % 3))
            }
        }
        XCTAssertEqual(offers, 200)
    }

    func testPickingEverythingMaxesOutThenOnlyTea() {
        var g = HordeGame.quiet(seed: 9)
        var picks = 0
        while true {
            g.forceOffer()
            guard let offer = g.offer else { return XCTFail("no offer") }
            if offer.options == [UpgradeOption(kind: .hotTea, fromLevel: 0, toLevel: 0)] { break }
            g.choose(0)
            picks += 1
            for kind in UpgradeKind.allCases where kind != .hotTea {
                XCTAssertLessThanOrEqual(g.level(of: kind), kind.maxLevel)
            }
            XCTAssertLessThan(picks, 100)
        }
        let totalLevels = UpgradeKind.allCases.map(\.maxLevel).reduce(0, +)
        XCTAssertEqual(picks, totalLevels - 1)   // 36 levels, minus the Lantern Bolt you start with
        XCTAssertEqual(picks, 35)
    }

    func testSmallPoolsGetHotTea() {
        var g = HordeGame.quiet()
        g.maxAll()
        g.upgradeLevels[UpgradeKind.mending.rawValue] = 0
        g.upgradeLevels[UpgradeKind.keenWick.rawValue] = 2
        g.forceOffer()
        let kinds = g.offer?.options.map(\.kind) ?? []
        XCTAssertEqual(kinds.count, 3)
        XCTAssertEqual(Set(kinds.prefix(2).map(\.rawValue)), [UpgradeKind.mending.rawValue, UpgradeKind.keenWick.rawValue])
        XCTAssertEqual(kinds.last, .hotTea)

        var full = HordeGame.quiet()
        full.maxAll()
        full.forceOffer()
        XCTAssertEqual(full.offer?.options, [UpgradeOption(kind: .hotTea, fromLevel: 0, toLevel: 0)])
    }

    func testSameSeedSameOffers() {
        func offers(_ seed: UInt64) -> [UpgradeOffer] {
            var g = HordeGame.quiet(seed: seed)
            var list: [UpgradeOffer] = []
            for _ in 0..<15 {
                g.forceOffer()
                if let o = g.offer { list.append(o) }
                g.choose(1)
            }
            return list
        }
        XCTAssertEqual(offers(4), offers(4))
        XCTAssertNotEqual(offers(4), offers(5))
    }
}
