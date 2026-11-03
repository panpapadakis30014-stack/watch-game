/// What the watch keeps between Lanternfall runs. No other progress carries over.
public struct HordeRecords: Equatable {
    public var bestSeconds: Int
    public var mostKills: Int
    public var dawns: Int

    public init(bestSeconds: Int = 0, mostKills: Int = 0, dawns: Int = 0) {
        self.bestSeconds = bestSeconds
        self.mostKills = mostKills
        self.dawns = dawns
    }

    public var hasAny: Bool { bestSeconds > 0 || mostKills > 0 || dawns > 0 }
}

/// The result of one run.
public struct HordeRunSummary: Equatable {
    public let seconds: Int
    public let kills: Int
    public let level: Int
    public let reachedDawn: Bool

    public init(seconds: Int, kills: Int, level: Int, reachedDawn: Bool) {
        self.seconds = seconds
        self.kills = kills
        self.level = level
        self.reachedDawn = reachedDawn
    }
}

/// Which records a run improved.
public struct HordeRecordsUpdate: Equatable {
    public let newBestTime: Bool
    public let newMostKills: Bool
    public let newDawn: Bool
}

public protocol HordeRecordsStore {
    func loadRecords() -> HordeRecords
    func saveRecords(_ records: HordeRecords)
}

public final class InMemoryHordeRecordsStore: HordeRecordsStore {
    private var value: HordeRecords

    public init(initial: HordeRecords = HordeRecords()) {
        value = initial
    }

    public func loadRecords() -> HordeRecords { value }

    public func saveRecords(_ records: HordeRecords) { value = records }
}

/// Records only ever improve; dawns count up.
public struct HordeRecordsKeeper {
    private let store: HordeRecordsStore

    public init(store: HordeRecordsStore) {
        self.store = store
    }

    public var records: HordeRecords { store.loadRecords() }

    @discardableResult
    public func submit(_ run: HordeRunSummary) -> HordeRecordsUpdate {
        let old = records
        let new = HordeRecords(
            bestSeconds: max(old.bestSeconds, run.seconds),
            mostKills: max(old.mostKills, run.kills),
            dawns: old.dawns + (run.reachedDawn ? 1 : 0)
        )
        if new != old {
            store.saveRecords(new)
        }
        return HordeRecordsUpdate(
            newBestTime: run.seconds > old.bestSeconds,
            newMostKills: run.kills > old.mostKills,
            newDawn: run.reachedDawn
        )
    }
}
