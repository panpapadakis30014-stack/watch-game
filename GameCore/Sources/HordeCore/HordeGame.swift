import GameCore

/// One Lanternfall run as a value. Driven by a fixed-timestep `step(dt:)`; the
/// renderer feeds real frame time through `advance(by:)`. The hero walks
/// forward along `hero.heading`, weapons fire on their own, and the run ends at
/// `.fallen` (hp 0) or `.dawn` (Grave Warden defeated).
public struct HordeGame: Equatable {
    public internal(set) var tuning: HordeTuning
    public internal(set) var phase: HordePhase = .playing
    public internal(set) var isPaused = false
    public internal(set) var elapsed: Double = 0
    public internal(set) var hero: Hero
    public internal(set) var enemies: [Enemy] = []
    public internal(set) var projectiles: [Projectile] = []
    public internal(set) var gems: [Gem] = []
    public internal(set) var effects: [HordeEffect] = []
    public internal(set) var kills = 0
    public internal(set) var level = 1
    public internal(set) var xp = 0
    public internal(set) var pendingLevelUps = 0
    public internal(set) var offer: UpgradeOffer?
    public internal(set) var upgradeLevels: [Int]     // indexed by UpgradeKind.rawValue
    public internal(set) var bossSpawned = false
    public internal(set) var isEnraged = false
    public internal(set) var emberPhase: Double = 0

    var rng: SplitMix64
    var offerRng: SplitMix64
    var accumulator: Double = 0
    var nextID = 0
    var offerSerial = 0
    var openingDone = false
    var spawnTimers: [Double]                         // shambler, sprinter, bloat
    var boltTimer: Double = 0
    var saltTimer: Double = 0
    var chainTimer: Double = 0
    var summonTimer: Double = 0
    var mendTimer: Double = 0

    public init(seed: UInt64, tuning: HordeTuning = .standard) {
        self.tuning = tuning
        hero = Hero(hp: tuning.heroBaseHP)
        upgradeLevels = Array(repeating: 0, count: UpgradeKind.allCases.count)
        upgradeLevels[UpgradeKind.lanternBolt.rawValue] = 1
        rng = SplitMix64(seed: seed)
        offerRng = SplitMix64(seed: seed ^ 0x4C41_4E54_4552_4E21)
        spawnTimers = [tuning.shamblerSpawn.firstDelay, tuning.sprinterSpawn.firstDelay, tuning.bloatSpawn.firstDelay]
    }

    // MARK: Derived state

    /// True while the simulation should advance: playing, not paused, no offer open.
    public var isRunning: Bool { phase == .playing && !isPaused && offer == nil }

    public var stats: HeroStats { HeroStats(levels: upgradeLevels, tuning: tuning) }

    public var xpToNext: Int { tuning.xpToNext(level: level) }

    public var boss: Enemy? { enemies.first { $0.kind == .warden } }

    /// 0 right after a dash, 1 when the dash is ready again.
    public var dashReadyFraction: Double {
        let cooldown = stats.dashCooldown
        guard cooldown > 0 else { return 1 }
        return min(max(1 - hero.dashCooldownRemaining / cooldown, 0), 1)
    }

    public var summary: HordeRunSummary {
        HordeRunSummary(seconds: Int(elapsed), kills: kills, level: level, reachedDawn: phase == .dawn)
    }

    public func level(of kind: UpgradeKind) -> Int {
        upgradeLevels[kind.rawValue]
    }

    /// World position of ember `i` of the current ember count.
    public func emberPosition(_ i: Int) -> Vec2 {
        let count = max(stats.emberCount, 1)
        let angle = emberPhase + 360 * Double(i) / Double(count)
        return hero.position + HordeMath.direction(degrees: angle) * tuning.emberOrbitRadius
    }

    private var eps: Double { tuning.timeEpsilon }

    // MARK: Time

    /// Feeds a real frame duration. Frames longer than `maxFrameDelta` are
    /// clamped and the rest runs as fixed steps.
    @discardableResult
    public mutating func advance(by frameDelta: Double) -> [HordeEvent] {
        guard isRunning else { return [] }
        accumulator += min(max(frameDelta, 0), tuning.maxFrameDelta)
        var events: [HordeEvent] = []
        while accumulator >= tuning.fixedTimeStep - eps {
            events += step(dt: tuning.fixedTimeStep)
            accumulator -= tuning.fixedTimeStep
            if !isRunning {
                accumulator = 0
                break
            }
        }
        return events
    }

    /// One simulation step, in a fixed order (see the plan): hero, mending,
    /// boss, spawns, summons, enemies, weapons, kills, gems, contact, effects, offer.
    @discardableResult
    public mutating func step(dt: Double) -> [HordeEvent] {
        guard isRunning else { return [] }
        elapsed += dt
        let s = stats
        var events: [HordeEvent] = []

        // Hero
        let dashing = hero.dashRemaining > eps
        hero.position += HordeMath.direction(degrees: hero.heading) * ((dashing ? tuning.dashSpeed : s.moveSpeed) * dt)
        hero.dashRemaining = max(0, hero.dashRemaining - dt)
        hero.dashCooldownRemaining = max(0, hero.dashCooldownRemaining - dt)
        hero.iFrames = max(0, hero.iFrames - dt)

        // Mending
        if s.mendInterval > 0 {
            mendTimer += dt
            if mendTimer >= s.mendInterval - eps {
                mendTimer -= s.mendInterval
                hero.hp = min(hero.hp + 1, s.maxHP)
            }
        }

        // Boss and enrage
        if !bossSpawned && elapsed >= tuning.bossTime - eps {
            if enemies.count >= tuning.maxEnemies, let far = farthestNonWarden() {
                enemies.remove(at: far)
            }
            spawnEnemy(.warden, at: hero.position + HordeMath.direction(degrees: hero.heading) * tuning.spawnRadius)
            bossSpawned = true
            summonTimer = tuning.summonInterval
            events.append(.bossArrived)
        }
        if boss != nil && !isEnraged && elapsed >= tuning.enrageTime - eps {
            isEnraged = true
            events.append(.bossEnraged)
        }

        // Opening burst, ahead of the hero
        if !openingDone {
            for _ in 0..<tuning.openingShamblers {
                let angle = hero.heading - tuning.openingArc / 2 + rng.nextUnit() * tuning.openingArc
                spawnEnemy(.shambler, at: ringPoint(angle))
            }
            openingDone = true
        }

        // Regular spawns
        let rules: [(EnemyKind, SpawnRule)] = [(.shambler, tuning.shamblerSpawn), (.sprinter, tuning.sprinterSpawn), (.bloat, tuning.bloatSpawn)]
        for (k, (kind, rule)) in rules.enumerated() where elapsed >= rule.start - eps {
            spawnTimers[k] -= dt
            while spawnTimers[k] <= eps {
                if enemies.count < tuning.maxEnemies {
                    spawnEnemy(kind, at: ringPoint(rng.nextUnit() * 360))
                }
                spawnTimers[k] += rule.interval(at: elapsed) * (isEnraged ? tuning.enrageSpawnScale : 1)
            }
        }

        // Summons
        if let b = boss {
            summonTimer -= dt
            if summonTimer <= eps {
                for i in 0..<tuning.summonCount where enemies.count < tuning.maxEnemies {
                    let angle = 360 * Double(i) / Double(tuning.summonCount)
                    spawnEnemy(.shambler, at: b.position + HordeMath.direction(degrees: angle) * tuning.summonRingRadius)
                }
                summonTimer += isEnraged ? tuning.enragedSummonInterval : tuning.summonInterval
            }
        }

        moveEnemies(dt: dt)
        fireWeapons(dt: dt, stats: s)

        // Kill pass
        var bossDefeated = false
        var survivors: [Enemy] = []
        survivors.reserveCapacity(enemies.count)
        for e in enemies {
            guard e.hp <= 0 else {
                survivors.append(e)
                continue
            }
            kills += 1
            addEffect(.puff(radius: tuning.stats(for: e.kind).radius), at: e.position)
            if e.kind == .warden {
                bossDefeated = true
            } else {
                dropGem(value: tuning.stats(for: e.kind).xp, at: e.position)
            }
        }
        enemies = survivors
        if bossDefeated {
            phase = .dawn
            events.append(.dawn)
            return events
        }

        // Gems
        var g = 0
        while g < gems.count {
            var gem = gems[g]
            if !gem.magnetized && (gem.position - hero.position).length <= s.pickupRadius {
                gem.magnetized = true
            }
            if gem.magnetized {
                let to = hero.position - gem.position
                let d = to.length
                let move = tuning.gemMagnetSpeed * dt
                gem.position = d <= move ? hero.position : gem.position + to * (move / d)
            }
            if (gem.position - hero.position).length <= tuning.heroRadius + tuning.gemRadius {
                xp += gem.value
                gems.remove(at: g)
            } else {
                gems[g] = gem
                g += 1
            }
        }
        while xp >= xpToNext {
            xp -= xpToNext
            level += 1
            pendingLevelUps += 1
        }

        // Contact damage
        let invulnerable = dashing || hero.iFrames > eps
        if !invulnerable, let hit = enemies.first(where: { ($0.position - hero.position).length < tuning.heroRadius + $0.radius(tuning) }) {
            let damage = (hit.kind == .warden && isEnraged) ? tuning.enragedWardenDamage : tuning.stats(for: hit.kind).damage
            hero.hp -= damage
            hero.iFrames = tuning.iFrameDuration
            addEffect(.hurt, at: hero.position)
            events.append(.hurt(hpLeft: max(hero.hp, 0)))
            if hero.hp <= 0 {
                hero.hp = 0
                phase = .fallen
                events.append(.fallen)
                return events
            }
        }

        // Effects
        let now = elapsed, epsilon = eps
        effects.removeAll { now - $0.start >= $0.duration - epsilon }

        // Offer
        if offer == nil && pendingLevelUps > 0 {
            events.append(openOffer())
        }
        return events
    }

    // MARK: Input

    /// Turns the heading by a Crown delta (in Crown units). Only while running.
    public mutating func applyCrown(delta units: Double) {
        guard isRunning else { return }
        hero.heading = AngleMath.normalize(hero.heading + units * tuning.crownDegreesPerUnit)
    }

    /// Starts a dash when it is ready: a burst of speed with no contact damage.
    @discardableResult
    public mutating func dash() -> [HordeEvent] {
        guard isRunning, hero.dashCooldownRemaining <= eps, hero.dashRemaining <= eps else { return [] }
        hero.dashRemaining = tuning.dashDuration
        hero.dashCooldownRemaining = stats.dashCooldown
        return [.dashed]
    }

    /// Takes option `index` of the open offer, then opens the next queued one.
    @discardableResult
    public mutating func choose(_ index: Int) -> [HordeEvent] {
        guard phase == .playing, !isPaused, let current = offer, current.options.indices.contains(index) else { return [] }
        apply(current.options[index].kind)
        offer = nil
        return pendingLevelUps > 0 ? [openOffer()] : []
    }

    /// Pauses; an open offer is kept.
    public mutating func pause() {
        guard phase == .playing else { return }
        isPaused = true
        accumulator = 0
    }

    public mutating func resume() {
        guard phase == .playing else { return }
        isPaused = false
    }

    // MARK: Upgrades

    mutating func apply(_ kind: UpgradeKind) {
        if kind == .hotTea {
            hero.hp = min(hero.hp + tuning.hotTeaHeal, stats.maxHP)
            return
        }
        upgradeLevels[kind.rawValue] += 1
        let newLevel = upgradeLevels[kind.rawValue]
        switch kind {
        case .thickCoat:
            hero.hp = min(hero.hp + 1, stats.maxHP)
        case .saltBurst where newLevel == 1:
            saltTimer = tuning.saltFirstDelay
        case .chainSpark where newLevel == 1:
            chainTimer = tuning.chainFirstDelay
        case .mending where newLevel == 1:
            mendTimer = 0
        default:
            break
        }
    }

    private mutating func openOffer() -> HordeEvent {
        pendingLevelUps -= 1
        let heroLevel = level - pendingLevelUps
        offer = makeOffer(heroLevel: heroLevel)
        return .offerOpened(heroLevel: heroLevel)
    }

    /// Up to 3 distinct, non-maxed upgrades (partial Fisher–Yates on a
    /// dedicated RNG); Hot Tea fills in only when fewer than 3 remain.
    private mutating func makeOffer(heroLevel: Int) -> UpgradeOffer {
        var pool = UpgradeKind.allCases.filter { $0 != .hotTea && level(of: $0) < $0.maxLevel }
        let k = min(3, pool.count)
        for i in 0..<k {
            let j = i + Int(offerRng.next() % UInt64(pool.count - i))
            pool.swapAt(i, j)
        }
        var options = pool[0..<k].map { UpgradeOption(kind: $0, fromLevel: level(of: $0), toLevel: level(of: $0) + 1) }
        if k < 3 {
            options.append(UpgradeOption(kind: .hotTea, fromLevel: 0, toLevel: 0))
        }
        offerSerial += 1
        return UpgradeOffer(serial: offerSerial, heroLevel: heroLevel, options: options)
    }

    // MARK: Enemies

    private func ringPoint(_ angle: Double) -> Vec2 {
        hero.position + HordeMath.direction(degrees: angle) * tuning.spawnRadius
    }

    mutating func spawnEnemy(_ kind: EnemyKind, at position: Vec2) {
        let st = tuning.stats(for: kind)
        enemies.append(Enemy(id: nextID, kind: kind, position: position, hp: st.hp, maxHP: st.hp))
        nextID += 1
    }

    private func farthestNonWarden() -> Int? {
        var best: Int?
        var bestD = -1.0
        for (i, e) in enemies.enumerated() where e.kind != .warden {
            let d = (e.position - hero.position).lengthSquared
            if d > bestD {
                bestD = d
                best = i
            }
        }
        return best
    }

    private mutating func moveEnemies(dt: Double) {
        for i in enemies.indices {
            var e = enemies[i]
            e.emberCooldown = max(0, e.emberCooldown - dt)
            e.hitFlash = max(0, e.hitFlash - dt)
            var speed = tuning.stats(for: e.kind).speed
            if isEnraged {
                speed = e.kind == .warden ? tuning.enragedWardenSpeed : speed * tuning.enrageEnemySpeedScale
            }
            let to = hero.position - e.position
            let d = to.length
            if d > eps {
                e.position += to * (min(speed * dt, d) / d)
            }
            if (hero.position - e.position).length > tuning.despawnRadius {
                e.position = ringPoint(hero.heading - tuning.recycleArc / 2 + rng.nextUnit() * tuning.recycleArc)
            }
            enemies[i] = e
        }

        // Separation: push overlapping pairs apart; the Warden is never pushed.
        let n = enemies.count
        guard n > 1 else { return }
        for i in 0..<(n - 1) {
            for j in (i + 1)..<n {
                let ri = enemies[i].radius(tuning), rj = enemies[j].radius(tuning)
                let minD = ri + rj
                let dv = enemies[j].position - enemies[i].position
                if dv.lengthSquared >= minD * minD { continue }
                let dist = dv.length
                let normal = dist > eps ? dv * (1 / dist) : Vec2(x: 1, y: 0)
                let push = (minD - dist) * tuning.separationStrength
                if enemies[i].kind == .warden {
                    enemies[j].position += normal * push
                } else if enemies[j].kind == .warden {
                    enemies[i].position -= normal * push
                } else {
                    enemies[i].position -= normal * (push / 2)
                    enemies[j].position += normal * (push / 2)
                }
            }
        }
    }

    /// Nearest enemy with hp > 0 within `range` of `point` (ties to the lower index).
    private func nearestAlive(to point: Vec2, within range: Double, excluding: [Int] = []) -> Int? {
        var best: Int?
        var bestD = range * range
        for (i, e) in enemies.enumerated() where e.hp > 0 && !excluding.contains(i) {
            let d = (e.position - point).lengthSquared
            if d <= bestD && (best == nil || d < bestD) {
                bestD = d
                best = i
            }
        }
        return best
    }

    private mutating func damage(_ i: Int, _ amount: Double) {
        enemies[i].hp -= amount
        enemies[i].hitFlash = tuning.hitFlashDuration
    }

    // MARK: Weapons

    private mutating func fireWeapons(dt: Double, stats s: HeroStats) {
        // Lantern Bolt
        boltTimer = max(0, boltTimer - dt)
        if level(of: .lanternBolt) > 0, boltTimer <= eps, projectiles.count < tuning.maxProjectiles,
           let target = nearestAlive(to: hero.position, within: tuning.boltRange) {
            let velocity = (enemies[target].position - hero.position).normalized() * tuning.boltSpeed
            projectiles.append(Projectile(id: nextID, position: hero.position, velocity: velocity,
                                          damage: s.boltDamage, life: tuning.boltLifetime))
            nextID += 1
            boltTimer = s.boltCooldown
        }

        // Projectiles: swept test against every alive enemy, earliest entry wins.
        var p = 0
        while p < projectiles.count {
            var proj = projectiles[p]
            let d = proj.velocity * dt
            var hit: Int?
            var hitS = 2.0
            for (i, e) in enemies.enumerated() where e.hp > 0 {
                if let t = HordeMath.entryTime(from: proj.position, delta: d, center: e.position,
                                               radius: tuning.projectileRadius + e.radius(tuning)), t < hitS {
                    hitS = t
                    hit = i
                }
            }
            if let i = hit {
                damage(i, proj.damage)
                projectiles.remove(at: p)
                continue
            }
            proj.position += d
            proj.life -= dt
            if proj.life <= eps {
                projectiles.remove(at: p)
            } else {
                projectiles[p] = proj
                p += 1
            }
        }

        // Ember Orbit
        emberPhase = AngleMath.normalize(emberPhase + tuning.emberDegreesPerSecond * dt)
        for k in 0..<s.emberCount {
            let ember = emberPosition(k)
            for i in enemies.indices where enemies[i].hp > 0 && enemies[i].emberCooldown <= eps {
                if (enemies[i].position - ember).length <= tuning.emberRadius + enemies[i].radius(tuning) {
                    damage(i, s.emberDamage)
                    enemies[i].emberCooldown = tuning.emberHitInterval
                }
            }
        }

        // Salt Burst
        if level(of: .saltBurst) > 0 {
            saltTimer -= dt
            if saltTimer <= eps {
                for i in enemies.indices where enemies[i].hp > 0 {
                    let away = enemies[i].position - hero.position
                    guard away.length <= s.saltRadius + enemies[i].radius(tuning) else { continue }
                    damage(i, s.saltDamage)
                    if enemies[i].kind != .warden {
                        let dir = away == .zero ? HordeMath.direction(degrees: hero.heading) : away.normalized()
                        enemies[i].position += dir * tuning.saltKnockback
                    }
                }
                addEffect(.saltRing(radius: s.saltRadius), at: hero.position)
                saltTimer += s.saltInterval
            }
        }

        // Chain Spark
        if level(of: .chainSpark) > 0 {
            chainTimer = max(0, chainTimer - dt)
            if chainTimer <= eps, let first = nearestAlive(to: hero.position, within: tuning.chainRange) {
                var struck = [first]
                var from = hero.position
                var current = first
                damage(current, s.chainDamage)
                addEffect(.spark(to: enemies[current].position), at: from)
                for _ in 0..<s.chainJumps {
                    from = enemies[current].position
                    guard let next = nearestAlive(to: from, within: tuning.chainJumpRange, excluding: struck) else { break }
                    damage(next, s.chainDamage)
                    addEffect(.spark(to: enemies[next].position), at: from)
                    struck.append(next)
                    current = next
                }
                chainTimer = s.chainInterval
            }
        }
    }

    // MARK: Gems and effects

    private mutating func dropGem(value: Int, at position: Vec2) {
        var total = value
        if gems.count >= tuning.maxGems {
            // Merge the farthest gem into the new one: XP is conserved and drops stay near the action.
            var far = 0
            var farD = -1.0
            for (i, gem) in gems.enumerated() {
                let d = (gem.position - hero.position).lengthSquared
                if d > farD {
                    farD = d
                    far = i
                }
            }
            total += gems[far].value
            gems.remove(at: far)
        }
        gems.append(Gem(id: nextID, position: position, value: total))
        nextID += 1
    }

    private mutating func addEffect(_ kind: HordeEffect.Kind, at position: Vec2) {
        let duration: Double
        switch kind {
        case .puff: duration = tuning.puffDuration
        case .saltRing: duration = tuning.saltRingDuration
        case .spark: duration = tuning.sparkDuration
        case .hurt: duration = tuning.hurtDuration
        }
        effects.append(HordeEffect(kind: kind, position: position, start: elapsed, duration: duration))
        if effects.count > tuning.maxEffects {
            effects.removeFirst(effects.count - tuning.maxEffects)
        }
    }
}

extension Enemy {
    /// Collision radius from the tuning for this kind.
    public func radius(_ tuning: HordeTuning) -> Double {
        tuning.stats(for: kind).radius
    }
}
