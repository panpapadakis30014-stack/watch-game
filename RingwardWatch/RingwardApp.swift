import SwiftUI

@main
struct RingwardApp: App {
    @State private var model = AppModel(options: .current)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
    }
}
