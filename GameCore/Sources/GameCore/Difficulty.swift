/// Difficulty at a point in the round. Rises linearly from the start values to
/// the caps over `Tuning.difficultyRampSeconds`, then stays at the caps.
public struct Difficulty: Equatable {
    public let level: Double          // 0...1
    public let shardSpeed: Double
    public let spawnInterval: Double
    public let maxShards: Int
    public let maxSpawnAngleJump: Double

    public static func at(elapsed: Double, tuning: Tuning) -> Difficulty {
        let level = min(max(elapsed / tuning.difficultyRampSeconds, 0), 1)
        let extraShards = Double(tuning.maxShardsCap - tuning.startMaxShards) * level
        return Difficulty(
            level: level,
            shardSpeed: lerp(tuning.startShardSpeed, tuning.maxShardSpeed, level),
            spawnInterval: lerp(tuning.startSpawnInterval, tuning.minSpawnInterval, level),
            maxShards: tuning.startMaxShards + Int(extraShards.rounded(.down)),
            maxSpawnAngleJump: lerp(tuning.startSpawnJump, tuning.maxSpawnJump, level)
        )
    }

    /// Linear interpolation that hits both ends exactly and never overshoots them.
    private static func lerp(_ from: Double, _ to: Double, _ t: Double) -> Double {
        if t <= 0 { return from }
        if t >= 1 { return to }
        let value = from + (to - from) * t
        return min(max(value, min(from, to)), max(from, to))
    }
}
