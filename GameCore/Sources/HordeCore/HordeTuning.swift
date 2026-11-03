/// Stats for one kind of enemy.
public struct EnemyStats: Equatable {
    public var hp: Double
    public var speed: Double      // world units per second
    public var damage: Int
    public var radius: Double
    public var xp: Int

    public init(hp: Double, speed: Double, damage: Int, radius: Double, xp: Int) {
        self.hp = hp
        self.speed = speed
        self.damage = damage
        self.radius = radius
        self.xp = xp
    }
}

/// When and how often one enemy kind spawns. The interval shrinks linearly
/// from `startInterval` to `minInterval`.
public struct SpawnRule: Equatable {
    public var start: Double
    public var firstDelay: Double
    public var startInterval: Double
    public var minInterval: Double
    public var intervalDropPerSecond: Double

    public init(start: Double, firstDelay: Double, startInterval: Double, minInterval: Double, intervalDropPerSecond: Double) {
        self.start = start
        self.firstDelay = firstDelay
        self.startInterval = startInterval
        self.minInterval = minInterval
        self.intervalDropPerSecond = intervalDropPerSecond
    }

    public func interval(at t: Double) -> Double {
        max(minInterval, startInterval - (t - start) * intervalDropPerSecond)
    }
}

/// Every Lanternfall number in one place. None of it has been played on a
/// real watch yet; these are the knobs to turn after the first try.
/// World units: 1.0 = half the screen's shorter side.
public struct HordeTuning: Equatable {
    public static let standard = HordeTuning()

    public init() {}

    // Time
    public var fixedTimeStep: Double = 1.0 / 30.0
    public var maxFrameDelta: Double = 0.25
    public var timeEpsilon: Double = 1e-9

    // World
    public var spawnRadius: Double = 1.75        // off-screen on both SE sizes (corner ≈ 1.58)
    public var despawnRadius: Double = 2.6
    public var recycleArc: Double = 120          // degrees, centred on the heading

    // Hero
    public var heroRadius: Double = 0.08
    public var heroBaseHP: Int = 5
    public var heroSpeed: Double = 0.45
    public var iFrameDuration: Double = 0.8
    public var dashDuration: Double = 0.25
    public var dashSpeed: Double = 1.8
    public var dashCooldown: Double = 3.0
    public var crownDegreesPerUnit: Double = 10.0   // UNVERIFIED on device

    // Pickups
    public var pickupRadius: Double = 0.25
    public var gemRadius: Double = 0.03
    public var gemMagnetSpeed: Double = 1.5

    // Enemies
    public var shambler = EnemyStats(hp: 3, speed: 0.22, damage: 1, radius: 0.07, xp: 1)
    public var sprinter = EnemyStats(hp: 2, speed: 0.60, damage: 1, radius: 0.055, xp: 2)
    public var bloat = EnemyStats(hp: 14, speed: 0.15, damage: 2, radius: 0.11, xp: 5)
    public var warden = EnemyStats(hp: 600, speed: 0.18, damage: 2, radius: 0.22, xp: 0)
    public var separationStrength: Double = 0.5

    // Spawning
    public var openingShamblers: Int = 5
    public var openingArc: Double = 140
    public var shamblerSpawn = SpawnRule(start: 0, firstDelay: 1.0, startInterval: 1.0, minInterval: 0.45, intervalDropPerSecond: 0.0025)
    public var sprinterSpawn = SpawnRule(start: 60, firstDelay: 0, startInterval: 5.0, minInterval: 1.5, intervalDropPerSecond: 0.0125)
    public var bloatSpawn = SpawnRule(start: 150, firstDelay: 0, startInterval: 10.0, minInterval: 4.0, intervalDropPerSecond: 0.025)

    // Boss
    public var bossTime: Double = 300
    public var enrageTime: Double = 420
    public var summonInterval: Double = 10
    public var enragedSummonInterval: Double = 5
    public var summonCount: Int = 8
    public var summonRingRadius: Double = 0.45
    public var enragedWardenSpeed: Double = 0.30
    public var enragedWardenDamage: Int = 3
    public var enrageSpawnScale: Double = 0.6         // multiplies regular spawn intervals
    public var enrageEnemySpeedScale: Double = 1.25   // non-warden enemies while enraged

    // XP
    public var xpBase: Int = 5
    public var xpLinear: Int = 2
    public var xpQuadDivisor: Int = 5

    // Lantern Bolt
    public var boltBaseDamage: Double = 3
    public var boltDamagePerLevel: Double = 1
    public var boltBaseCooldown: Double = 0.9
    public var boltCooldownCutPerLevel: Double = 0.10
    public var boltRange: Double = 1.1
    public var boltSpeed: Double = 2.4
    public var boltLifetime: Double = 0.55
    public var projectileRadius: Double = 0.03

    // Ember Orbit
    public var emberDamage: Double = 2
    public var emberOrbitRadius: Double = 0.28
    public var emberRadius: Double = 0.045
    public var emberDegreesPerSecond: Double = 200
    public var emberHitInterval: Double = 0.5

    // Salt Burst
    public var saltInterval: Double = 4.0
    public var saltBaseRadius: Double = 0.35
    public var saltRadiusPerLevel: Double = 0.08
    public var saltBaseDamage: Double = 3
    public var saltDamagePerLevel: Double = 2
    public var saltKnockback: Double = 0.25
    public var saltFirstDelay: Double = 0.5

    // Chain Spark
    public var chainInterval: Double = 2.0
    public var chainDamage: Double = 4
    public var chainRange: Double = 1.0
    public var chainJumpRange: Double = 0.45
    public var chainFirstDelay: Double = 0.5

    // Passives
    public var swiftBootsPerLevel: Double = 0.10
    public var lodestonePerLevel: Double = 0.30
    public var quickHandsPerLevel: Double = 0.08
    public var keenWickPerLevel: Double = 0.15
    public var secondWindPerLevel: Double = 0.20
    public var mendingInterval: Double = 30
    public var hotTeaHeal: Int = 2

    // Caps
    public var maxEnemies: Int = 60
    public var maxProjectiles: Int = 40
    public var maxGems: Int = 80
    public var maxEffects: Int = 24

    // Effects (visual, kept in the core so they freeze and cap with the sim)
    public var puffDuration: Double = 0.3
    public var saltRingDuration: Double = 0.3
    public var sparkDuration: Double = 0.2
    public var hurtDuration: Double = 0.3
    public var hitFlashDuration: Double = 0.08

    public func stats(for kind: EnemyKind) -> EnemyStats {
        switch kind {
        case .shambler: return shambler
        case .sprinter: return sprinter
        case .bloat: return bloat
        case .warden: return warden
        }
    }

    /// XP needed to go from `level` to `level + 1`: 5, 7, 9, 12, 16, 20, …
    public func xpToNext(level: Int) -> Int {
        let k = max(level, 1) - 1
        return xpBase + xpLinear * k + (k * k) / xpQuadDivisor
    }
}
