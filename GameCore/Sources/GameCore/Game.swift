/// The whole round as a value. Driven by a fixed-timestep `step(dt:)`; the
/// renderer feeds real frame time through `advance(by:)`.
public struct Game: Equatable {
    public internal(set) var tuning: Tuning
    public internal(set) var phase: Phase = .playing
    public internal(set) var elapsed: Double = 0         // simulated seconds
    public internal(set) var score: Int = 0
    public internal(set) var combo: Int = 0
    public internal(set) var lives: Int
    public internal(set) var pulseCharge: Int = 0
    public internal(set) var shieldAngle: Double = 0
    public internal(set) var shards: [Shard] = []
    public internal(set) var totalBlocks: Int = 0

    var rng: SplitMix64
    var spawnTimer: Double
    var nextShardID = 0
    var lastSpawnAngle: Double = 0
    var hasSpawned = false
    var accumulator: Double = 0

    public init(seed: UInt64, tuning: Tuning = .standard) {
        self.tuning = tuning
        self.lives = tuning.startLives
        self.rng = SplitMix64(seed: seed)
        self.spawnTimer = tuning.firstSpawnDelay
    }

    public var isPulseReady: Bool { pulseCharge >= tuning.pulseChargeMax }

    public var multiplier: Int {
        combo == 0 ? 1 : min(1 + (combo - 1) / tuning.comboStep, tuning.maxMultiplier)
    }

    public var difficulty: Difficulty { .at(elapsed: elapsed, tuning: tuning) }

    // MARK: Time

    /// Feeds a real frame duration. Frames longer than `maxFrameDelta` are
    /// clamped (the extra time is dropped) and the rest runs as fixed steps.
    @discardableResult
    public mutating func advance(by frameDelta: Double) -> [GameEvent] {
        guard phase == .playing else { return [] }
        accumulator += min(max(frameDelta, 0), tuning.maxFrameDelta)
        var events: [GameEvent] = []
        while accumulator >= tuning.fixedTimeStep - 1e-9 {
            events += step(dt: tuning.fixedTimeStep)
            accumulator -= tuning.fixedTimeStep
            if phase != .playing {
                accumulator = 0
                break
            }
        }
        return events
    }

    /// One simulation step. Collisions test whether a shard *crossed* the
    /// shield or core radius during the step, so no `dt` can tunnel through.
    @discardableResult
    public mutating func step(dt: Double) -> [GameEvent] {
        guard phase == .playing else { return [] }
        elapsed += dt
        let d = difficulty
        var events: [GameEvent] = []

        var i = 0
        while i < shards.count {
            let shard = shards[i]
            let prev = shard.distance
            let new = prev - shard.speed * dt
            if prev > tuning.shieldRadius && new <= tuning.shieldRadius
                && AngleMath.isWithinArc(shard.angle, center: shieldAngle, width: tuning.shieldArcWidth) {
                shards.remove(at: i)
                combo += 1
                let points = tuning.pointsPerBlock * multiplier
                score += points
                totalBlocks += 1
                events.append(.blocked(angle: shard.angle, points: points, combo: combo))
                if pulseCharge < tuning.pulseChargeMax {
                    pulseCharge += 1
                    if pulseCharge == tuning.pulseChargeMax { events.append(.pulseReady) }
                }
            } else if new <= tuning.coreRadius {
                shards.remove(at: i)
                lives -= 1
                combo = 0
                events.append(.hit(angle: shard.angle, livesLeft: lives))
                if lives == 0 {
                    phase = .gameOver
                    events.append(.gameOver(finalScore: score))
                    return events
                }
            } else {
                shards[i].distance = new
                i += 1
            }
        }

        spawnTimer -= dt
        while spawnTimer <= 0 {
            if shards.count < d.maxShards {
                spawn(d)
                spawnTimer += d.spawnInterval
            } else {
                spawnTimer = 0
                break
            }
        }
        return events
    }

    private mutating func spawn(_ d: Difficulty) {
        let angle = hasSpawned
            ? AngleMath.normalize(lastSpawnAngle + (rng.nextUnit() * 2 - 1) * d.maxSpawnAngleJump)
            : rng.nextUnit() * 360
        shards.append(Shard(id: nextShardID, angle: angle, distance: tuning.spawnRadius, speed: d.shardSpeed))
        nextShardID += 1
        lastSpawnAngle = angle
        hasSpawned = true
    }

    // MARK: Input

    /// Turns the shield by a Crown delta (in Crown units). Ignored unless playing.
    public mutating func applyCrown(delta units: Double) {
        guard phase == .playing else { return }
        shieldAngle = AngleMath.normalize(shieldAngle + units * tuning.crownDegreesPerUnit)
    }

    /// Clears every shard on screen when the Pulse is full. Combo is kept.
    @discardableResult
    public mutating func usePulse() -> [GameEvent] {
        guard phase == .playing && isPulseReady else { return [] }
        let n = shards.count
        let points = n * tuning.pointsPerPulsedShard
        score += points
        shards = []
        pulseCharge = 0
        return [.pulse(cleared: n, points: points)]
    }

    public mutating func pause() {
        guard phase == .playing else { return }
        phase = .paused
        accumulator = 0
    }

    public mutating func resume() {
        guard phase == .paused else { return }
        phase = .playing
    }
}
