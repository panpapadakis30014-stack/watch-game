import SwiftUI

/// Ringward's screens over the shared night background (drawn by the hub),
/// with a short transition between them (fade only under Reduce Motion).
struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let transition = ScreenTransition.make(reduceMotion: reduceMotion)
        ZStack {
            switch model.screen {
            case .start:
                StartView()
                    .transition(transition)
            case .playing(let controller):
                GameView(controller: controller)
                    .id(ObjectIdentifier(controller))
                    .transition(transition)
            case .gameOver(let result):
                GameOverView(result: result)
                    .transition(transition)
            }
        }
        .animation(ScreenTransition.animation, value: model.screenKey)
    }
}
