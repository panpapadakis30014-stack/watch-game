import SwiftUI

struct HubRootView: View {
    @Environment(HubModel.self) private var hub

    var body: some View {
        switch hub.route {
        case .picker:
            ZStack {
                Theme.background
                    .ignoresSafeArea()
                GamePickerView()
            }
        case .ringward:
            RootView()
                .environment(hub.ringward)
        case .lanternfall:
            LanternfallRootView()
                .environment(hub.lanternfall)
        }
    }
}
