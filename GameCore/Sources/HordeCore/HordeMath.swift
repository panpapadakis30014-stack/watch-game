import GameCore

/// A 2D vector in world units (1.0 = half the screen's shorter side).
/// x points right, y points down.
public struct Vec2: Equatable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let zero = Vec2(x: 0, y: 0)

    public static func + (a: Vec2, b: Vec2) -> Vec2 { Vec2(x: a.x + b.x, y: a.y + b.y) }
    public static func - (a: Vec2, b: Vec2) -> Vec2 { Vec2(x: a.x - b.x, y: a.y - b.y) }
    public static func * (a: Vec2, k: Double) -> Vec2 { Vec2(x: a.x * k, y: a.y * k) }
    public static func += (a: inout Vec2, b: Vec2) { a = a + b }
    public static func -= (a: inout Vec2, b: Vec2) { a = a - b }

    public var lengthSquared: Double { x * x + y * y }
    public var length: Double { lengthSquared.squareRoot() }

    /// Unit vector in the same direction; the zero vector stays zero.
    public func normalized() -> Vec2 {
        let l = length
        return l > 0 ? self * (1 / l) : .zero
    }

    public func dot(_ o: Vec2) -> Double { x * o.x + y * o.y }
}

/// Deterministic trigonometry and swept collisions. No Foundation here, so the
/// results are bit-identical on Linux and on the watch.
public enum HordeMath {
    /// sin and cos of an angle in degrees, by quadrant reduction plus a Taylor
    /// polynomial on [-45°, 45°]. Error below 1e-11.
    public static func sinCos(degrees: Double) -> (sin: Double, cos: Double) {
        let n = AngleMath.normalize(degrees)
        let q = Int((n / 90).rounded())
        let r = (n - Double(q) * 90) * Double.pi / 180
        let r2 = r * r
        let s = r * (1 - r2 / 6 * (1 - r2 / 20 * (1 - r2 / 42 * (1 - r2 / 72 * (1 - r2 / 110)))))
        let c = 1 - r2 / 2 * (1 - r2 / 12 * (1 - r2 / 30 * (1 - r2 / 56 * (1 - r2 / 90 * (1 - r2 / 132)))))
        switch q & 3 {
        case 0: return (s, c)
        case 1: return (c, -s)
        case 2: return (-s, -c)
        default: return (-c, s)
        }
    }

    /// Unit vector for a heading: 0 = up (0, -1), 90 = right (1, 0).
    public static func direction(degrees: Double) -> Vec2 {
        let sc = sinCos(degrees: degrees)
        return Vec2(x: sc.sin, y: -sc.cos)
    }

    /// Fraction s in [0, 1] of the move `p0 → p0 + d` at which a point first
    /// comes within `r` of `c`. 0 if it already overlaps, nil if it never does.
    public static func entryTime(from p0: Vec2, delta d: Vec2, center c: Vec2, radius r: Double) -> Double? {
        let f = p0 - c
        let a = d.dot(d)
        let b = 2 * d.dot(f)
        let k = f.dot(f) - r * r
        if k <= 0 { return 0 }
        if a == 0 { return nil }
        let disc = b * b - 4 * a * k
        if disc < 0 { return nil }
        let s = (-b - disc.squareRoot()) / (2 * a)
        return (s >= 0 && s <= 1) ? s : nil
    }
}
