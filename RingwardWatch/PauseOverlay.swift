import SwiftUI

/// Dims the paused game. The whole overlay is one button, so any tap resumes.
struct PauseOverlay: View {
    let onResume: () -> Void

    var body: some View {
        Button(action: onResume) {
            ZStack {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                VStack(spacing: 4) {
                    Text("Paused")
                        .font(.title3)
                        .foregroundStyle(.white)
                    Text("Tap to resume")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Resume")
    }
}
