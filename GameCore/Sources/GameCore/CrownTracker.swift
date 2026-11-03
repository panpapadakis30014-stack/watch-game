/// Turns the Crown's absolute value into per-sample deltas, so the shield
/// follows relative motion and never jumps.
public struct CrownTracker: Equatable {
    private let maxDeltaPerSample: Double
    private var last: Double?

    public init(maxDeltaPerSample: Double = Tuning.standard.crownMaxDeltaPerSample) {
        self.maxDeltaPerSample = maxDeltaPerSample
    }

    /// The first sample returns 0; jumps larger than `maxDeltaPerSample` return 0.
    public mutating func delta(for newValue: Double) -> Double {
        defer { last = newValue }
        guard let last else { return 0 }
        let d = newValue - last
        return abs(d) > maxDeltaPerSample ? 0 : d
    }
}
