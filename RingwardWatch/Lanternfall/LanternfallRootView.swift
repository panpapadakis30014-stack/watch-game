import SwiftUI

struct LanternfallRootView: View {
    @Environment(LanternfallModel.self) private var model

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()
            switch model.screen {
            case .start:
                LanternfallStartView()
            case .playing(let controller):
                LanternfallGameView(controller: controller)
                    .id(ObjectIdentifier(controller))
            case .results(let result):
                LanternfallResultsView(result: result)
            }
        }
    }
}
