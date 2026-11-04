/// One particle. It fades out and shrinks a little as it ages.
public struct Particle: Equatable {
    public internal(set) var position: FXVec
    public internal(set) var velocity: FXVec
    public internal(set) var age: Double
    public let life: Double
    public let size: Double        // start radius
    public let drag: Double
    public let gravity: Double
    public let style: Int          // index into the renderer's palette

    /// 0 at birth, 1 at the end of its life.
    public var progress: Double { min(max(age / life, 0), 1) }

    /// Bright at first, then a quick fade.
    public var opacity: Double { 1 - progress * progress }

    public var radius: Double { size * (1 - 0.4 * progress) }
}

/// How one burst looks: how many particles, and ranges for their speed,
/// lifetime and size. `spread` widens a directed burst (0 = straight line).
public struct BurstSpec: Equatable {
    public var count: Int
    public var speedMin: Double
    public var speedMax: Double
    public var lifeMin: Double
    public var lifeMax: Double
    public var sizeMin: Double
    public var sizeMax: Double
    public var drag: Double
    public var gravity: Double
    public var spread: Double
    public var style: Int

    public init(count: Int, speedMin: Double, speedMax: Double, lifeMin: Double, lifeMax: Double,
                sizeMin: Double, sizeMax: Double, drag: Double, gravity: Double, spread: Double, style: Int) {
        self.count = count
        self.speedMin = speedMin
        self.speedMax = speedMax
        self.lifeMin = lifeMin
        self.lifeMax = lifeMax
        self.sizeMin = sizeMin
        self.sizeMax = sizeMax
        self.drag = drag
        self.gravity = gravity
        self.spread = spread
        self.style = style
    }
}
