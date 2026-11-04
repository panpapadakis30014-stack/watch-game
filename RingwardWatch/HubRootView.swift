import SwiftUI

/// The night sky behind everything, and the current route on top of it with
/// a short screen transition (fade only under Reduce Motion).
struct HubRootView: View {
    @Environment(HubModel.self) private var hub
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let transition = ScreenTransition.make(reduceMotion: reduceMotion)
        ZStack {
            NightBackground()
            switch hub.route {
            case .picker:
                GamePickerView()
                    .transition(transition)
            case .ringward:
                RootView()
                    .environment(hub.ringward)
                    .transition(transition)
            case .lanternfall:
                LanternfallRootView()
                    .environment(hub.lanternfall)
                    .transition(transition)
            }
        }
        .animation(ScreenTransition.animation, value: hub.route)
        .fontDesign(.rounded)
    }
}
