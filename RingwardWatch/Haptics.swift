import WatchKit

/// The game's feedback moments, each mapped to a distinct watch haptic.
enum HapticCue {
    case block, hit, pulseReady, pulse, gameOver, newBest
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
        }
    }
}
