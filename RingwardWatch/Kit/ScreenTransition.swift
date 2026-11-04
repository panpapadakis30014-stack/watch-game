import SwiftUI

/// Picker ↔ game ↔ results: a short fade with a slight scale; fade only
/// under Reduce Motion.
enum ScreenTransition {
    static func make(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: Theme.screenTransitionScale))
    }

    static let animation = Animation.easeInOut(duration: Theme.screenTransitionDuration)
}
