import SwiftUI

/// Centres its content vertically when it fits and scrolls when it does not
/// (large Dynamic Type sizes on the smaller watch).
struct CenteredScroll<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                content
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
        }
    }
}
