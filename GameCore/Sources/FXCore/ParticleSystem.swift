import GameCore

/// A deterministic, capped particle system. It never holds more than
/// `capacity` particles (the oldest go first) and spawns nothing while
/// disabled, which is how Reduce Motion turns particles off.
public struct ParticleSystem: Equatable {
    public let capacity: Int
    public private(set) var particles: [Particle]
    public private(set) var isEnabled: Bool
    var rng: SplitMix64

    public init(capacity: Int, seed: UInt64, enabled: Bool = true) {
        self.capacity = max(capacity, 0)
        particles = []
        particles.reserveCapacity(self.capacity)
        isEnabled = enabled
        rng = SplitMix64(seed: seed)
    }

    public var count: Int { particles.count }

    /// Spawns `spec.count` particles at `origin`, aimed along `direction`
    /// (spread by `spec.spread`) or in random directions when it is nil.
    /// Returns how many were spawned.
    @discardableResult
    public mutating func emit(_ spec: BurstSpec, at origin: FXVec, direction: FXVec? = nil) -> Int {
        guard isEnabled && spec.count > 0 && capacity > 0 else { return 0 }
        for _ in 0..<spec.count {
            let dir: FXVec
            if let d = direction?.normalized(), d != .zero {
                let spread = (d + disk() * spec.spread).normalized()
                dir = spread == .zero ? d : spread
            } else {
                dir = unit()
            }
            let speed = spec.speedMin + rng.nextUnit() * (spec.speedMax - spec.speedMin)
            let life = spec.lifeMin + rng.nextUnit() * (spec.lifeMax - spec.lifeMin)
            let size = spec.sizeMin + rng.nextUnit() * (spec.sizeMax - spec.sizeMin)
            if particles.count == capacity {
                particles.removeFirst()
            }
            particles.append(Particle(position: origin, velocity: dir * speed, age: 0, life: life, size: size,
                                      drag: spec.drag, gravity: spec.gravity, style: spec.style))
        }
        return spec.count
    }

    /// Moves and ages every particle, then drops the expired ones.
    public mutating func update(dt: Double) {
        guard dt > 0 else { return }
        for i in particles.indices {
            var p = particles[i]
            p.velocity = p.velocity * max(0, 1 - p.drag * dt)
            p.velocity.y += p.gravity * dt
            p.position += p.velocity * dt
            p.age += dt
            particles[i] = p
        }
        particles.removeAll { $0.age >= $0.life - 1e-9 }
    }

    /// Off (Reduce Motion): clears everything and blocks `emit`.
    public mutating func setEnabled(_ on: Bool) {
        isEnabled = on
        if !on { particles.removeAll() }
    }

    public mutating func clear() {
        particles.removeAll()
    }

    /// A random point in the unit disk (rejection sampling, at most 8 tries).
    private mutating func disk() -> FXVec {
        for _ in 0..<8 {
            let x = 2 * rng.nextUnit() - 1, y = 2 * rng.nextUnit() - 1
            if x * x + y * y <= 1 { return FXVec(x: x, y: y) }
        }
        return .zero
    }

    /// A random unit vector (no trigonometry needed).
    private mutating func unit() -> FXVec {
        for _ in 0..<8 {
            let x = 2 * rng.nextUnit() - 1, y = 2 * rng.nextUnit() - 1
            let l2 = x * x + y * y
            if l2 > 1e-4 && l2 <= 1 { return FXVec(x: x, y: y).normalized() }
        }
        return FXVec(x: 1, y: 0)
    }
}
