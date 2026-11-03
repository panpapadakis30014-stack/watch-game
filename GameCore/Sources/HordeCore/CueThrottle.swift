/// Lets each cue fire at most once per `minGap` seconds; other cues are
/// independent. Used to keep haptics from buzzing continuously.
public struct CueThrottle<Key: Hashable>: Equatable {
    public let minGap: Double
    private var lastFired: [Key: Double] = [:]

    public init(minGap: Double) {
        self.minGap = minGap
    }

    /// True (and remembers `time`) when `key` has never fired or its last
    /// firing is at least `minGap` ago. Otherwise false and nothing is recorded.
    public mutating func allow(_ key: Key, at time: Double) -> Bool {
        if let last = lastFired[key], time - last < minGap - 1e-9 {
            return false
        }
        lastFired[key] = time
        return true
    }
}
