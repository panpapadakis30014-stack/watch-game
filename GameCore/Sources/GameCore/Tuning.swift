/// Every gameplay number in one place. Nothing here has been tuned on a real
/// watch yet, so these are the knobs to turn after the first device test.
public struct Tuning: Equatable {
    public static let standard = Tuning()

    public init() {}

    // Time
    public var fixedTimeStep: Double = 1.0 / 60.0
    public var maxFrameDelta: Double = 0.25          // longer frames are clamped (time dropped)

    // Geometry (normalized: spawn ring = 1.0)
    public var spawnRadius: Double = 1.0
    public var shieldRadius: Double = 0.34
    public var coreRadius: Double = 0.14
    public var shieldArcWidth: Double = 70.0         // degrees, total
    public var shardVisualRadius: Double = 0.035     // rendering only

    // Input
    public var crownDegreesPerUnit: Double = 10.0    // UNVERIFIED on device: Apple documents no units per turn
    public var crownMaxDeltaPerSample: Double = 50.0 // larger crown jumps are ignored

    // Rules
    public var startLives: Int = 3
    public var pulseChargeMax: Int = 8               // blocks to fill
    public var pointsPerBlock: Int = 10
    public var comboStep: Int = 5                    // multiplier +1 every 5 consecutive blocks
    public var maxMultiplier: Int = 4
    public var pointsPerPulsedShard: Int = 5

    // Spawning / difficulty
    public var firstSpawnDelay: Double = 1.0
    public var difficultyRampSeconds: Double = 120.0 // cap reached here
    public var startShardSpeed: Double = 0.40        // spawn-radius units per second
    public var maxShardSpeed: Double = 0.85
    public var startSpawnInterval: Double = 1.6
    public var minSpawnInterval: Double = 0.55
    public var startMaxShards: Int = 2
    public var maxShardsCap: Int = 6
    public var startSpawnJump: Double = 100.0        // max degrees between consecutive spawn angles
    public var maxSpawnJump: Double = 180.0
}
