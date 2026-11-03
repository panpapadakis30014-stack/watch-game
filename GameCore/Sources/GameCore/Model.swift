/// A shard flying in from the spawn ring towards the core along a fixed angle.
public struct Shard: Equatable, Identifiable {
    public let id: Int
    public let angle: Double             // degrees, see AngleMath
    public internal(set) var distance: Double  // from the centre, spawn ring = 1.0
    public let speed: Double             // spawn-radius units per second
}

public enum Phase: Equatable {
    case playing, paused, gameOver
}

/// What happened during a step or action, for haptics and effects.
public enum GameEvent: Equatable {
    case blocked(angle: Double, points: Int, combo: Int)
    case hit(angle: Double, livesLeft: Int)
    case pulseReady
    case pulse(cleared: Int, points: Int)
    case gameOver(finalScore: Int)
}
