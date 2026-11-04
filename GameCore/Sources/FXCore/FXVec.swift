/// A 2D vector for particles, in the caller's units with y pointing down.
/// FXCore keeps its own type so it does not depend on any game's core.
public struct FXVec: Equatable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public static let zero = FXVec(x: 0, y: 0)

    public static func + (a: FXVec, b: FXVec) -> FXVec { FXVec(x: a.x + b.x, y: a.y + b.y) }
    public static func - (a: FXVec, b: FXVec) -> FXVec { FXVec(x: a.x - b.x, y: a.y - b.y) }
    public static func * (a: FXVec, k: Double) -> FXVec { FXVec(x: a.x * k, y: a.y * k) }
    public static func += (a: inout FXVec, b: FXVec) { a = a + b }

    public var lengthSquared: Double { x * x + y * y }
    public var length: Double { lengthSquared.squareRoot() }

    /// Unit vector in the same direction; the zero vector stays zero.
    public func normalized() -> FXVec {
        let l = length
        return l > 0 ? self * (1 / l) : .zero
    }
}
