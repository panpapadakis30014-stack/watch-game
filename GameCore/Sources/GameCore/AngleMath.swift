/// Angle helpers. Convention: degrees, 0 = 12 o'clock, increasing clockwise.
public enum AngleMath {
    /// Wraps any angle into [0, 360).
    public static func normalize(_ degrees: Double) -> Double {
        var r = degrees.truncatingRemainder(dividingBy: 360)
        if r < 0 { r += 360 }
        if r >= 360 { r -= 360 }
        return r
    }

    /// Shortest signed turn from `a` to `b`, in (-180, 180].
    public static func signedDelta(from a: Double, to b: Double) -> Double {
        var d = normalize(b - a)
        if d > 180 { d -= 360 }
        return d
    }

    /// True when `angle` lies inside the arc of total `width` centred on `center`.
    /// The edges count as inside.
    public static func isWithinArc(_ angle: Double, center: Double, width: Double) -> Bool {
        abs(signedDelta(from: center, to: angle)) <= width / 2
    }
}
