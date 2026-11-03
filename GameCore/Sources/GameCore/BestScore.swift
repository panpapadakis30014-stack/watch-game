/// Where the best score lives. The watch app adapts UserDefaults to this.
public protocol BestScoreStore {
    func loadBest() -> Int
    func saveBest(_ score: Int)
}

public final class InMemoryBestScoreStore: BestScoreStore {
    private var value: Int

    public init(initial: Int = 0) {
        value = initial
    }

    public func loadBest() -> Int { value }

    public func saveBest(_ score: Int) { value = score }
}

/// Keeps the best score monotonic: it only ever goes up.
public struct BestScoreKeeper {
    private let store: BestScoreStore

    public init(store: BestScoreStore) {
        self.store = store
    }

    public var best: Int { store.loadBest() }

    /// Saves `score` and returns true only when it beats the current best.
    @discardableResult
    public func submit(_ score: Int) -> Bool {
        guard score > best else { return false }
        store.saveBest(score)
        return true
    }
}
