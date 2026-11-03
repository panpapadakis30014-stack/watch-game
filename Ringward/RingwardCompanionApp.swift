import SwiftUI

/// iOS container app. It exists only to carry the watch app onto the phone;
/// the game itself runs on the watch.
@main
struct RingwardCompanionApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 12) {
                Text("Ringward")
                    .font(.largeTitle.bold())
                Text("Open Ringward on your Apple Watch to play.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
