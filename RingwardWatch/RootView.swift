import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
            switch model.screen {
            case .start:
                StartView()
            case .playing(let controller):
                GameView(controller: controller)
                    .id(ObjectIdentifier(controller))
            case .gameOver(let result):
                GameOverView(result: result)
            }
        }
    }
}
