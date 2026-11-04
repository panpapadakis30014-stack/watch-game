import SwiftUI

/// Pause screen for Lanternfall. Unlike Ringward's, the background does not
/// resume, so a stray tap can never end or restart the run.
struct LanternfallPauseOverlay: View {
    let onResume: () -> Void
    let onEnd: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {}
            VStack(spacing: 6) {
                Text("Paused")
                    .font(.title3)
                    .foregroundStyle(.white)
                Button {
                    onResume()
                } label: {
                    Text("Resume")
                        .foregroundStyle(.black)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.lfLantern)
                .accessibilityLabel("Resume")
                Button {
                    onEnd()
                } label: {
                    Text("End run")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("End run")
                .accessibilityHint("Ends this run and saves your records")
            }
            .padding(.horizontal, 4)
        }
    }
}
