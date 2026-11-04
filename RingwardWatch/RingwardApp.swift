import SwiftUI

@main
struct RingwardApp: App {
    @State private var hub = HubModel(options: .current)

    var body: some Scene {
        WindowGroup {
            HubRootView()
                .environment(hub)
        }
    }
}
