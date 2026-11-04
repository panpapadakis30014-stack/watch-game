import SwiftUI

/// The shared night sky behind every screen: a radial gradient from deep navy
/// to black. Static, so it is composited, never redrawn per frame.
struct NightBackground: View {
    var body: some View {
        GeometryReader { geo in
            RadialGradient(
                gradient: Theme.nightGradient,
                center: Theme.nightCenterPoint,
                startRadius: 0,
                endRadius: max(geo.size.width, geo.size.height) * Theme.nightRadiusRatio
            )
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
