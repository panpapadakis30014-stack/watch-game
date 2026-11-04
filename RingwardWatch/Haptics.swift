import WatchKit
import HordeCore

/// The games' feedback moments, each mapped to a distinct watch haptic.
/// Ringward: block … newBest. Lanternfall: the `lf` cues.
enum HapticCue {
    case block, hit, pulseReady, pulse, gameOver, newBest
    case lfDash, lfHurt, lfLevelUp, lfBoss, lfDawn, lfDeath
}

/// The only place that talks to WatchKit haptics.
struct Haptics {
    var isEnabled: Bool

    @MainActor
    func play(_ cue: HapticCue) {
        guard isEnabled else { return }
        WKInterfaceDevice.current().play(Self.type(for: cue))
    }

    private static func type(for cue: HapticCue) -> WKHapticType {
        switch cue {
        case .block: return .click
        case .hit: return .directionDown
        case .pulseReady: return .start
        case .pulse: return .success
        case .gameOver: return .failure
        case .newBest: return .notification
        case .lfDash: return .click
        case .lfHurt: return .directionDown
        case .lfLevelUp: return .directionUp
        case .lfBoss: return .retry
        case .lfDawn: return .success
        case .lfDeath: return .failure
        }
    }
}

/// Lanternfall's haptics: each cue plays at most once per `minGap` seconds,
/// so a busy moment never turns into a continuous buzz. Kills have no cue.
@MainActor
final class ThrottledHaptics {
    static let minGap: Double = 0.15

    private let haptics: Haptics
    private var throttle = CueThrottle<HapticCue>(minGap: ThrottledHaptics.minGap)

    init(_ haptics: Haptics) {
        self.haptics = haptics
    }

    func play(_ cue: HapticCue, now: Double = ProcessInfo.processInfo.systemUptime) {
        guard throttle.allow(cue, at: now) else { return }
        haptics.play(cue)
    }
}
