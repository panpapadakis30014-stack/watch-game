import SwiftUI

/// Lanternfall's screens over the shared night background (drawn by the hub),
/// with a short transition between them (fade only under Reduce Motion).
struct LanternfallRootView: View {
    @Environment(LanternfallModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let transition = ScreenTransition.make(reduceMotion: reduceMotion)
        ZStack {
            switch model.screen {
            case .start:
                LanternfallStartView()
                    .transition(transition)
            case .playing(let controller):
                LanternfallGameView(controller: controller)
                    .id(ObjectIdentifier(controller))
                    .transition(transition)
            case .results(let result):
                LanternfallResultsView(result: result)
                    .transition(transition)
            }
        }
        .animation(ScreenTransition.animation, value: model.screenKey)
    }
}
