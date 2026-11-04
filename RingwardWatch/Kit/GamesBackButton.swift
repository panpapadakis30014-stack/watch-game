import SwiftUI

/// "‹ Games" in the top-left status-bar row, left of the clock. Every game's
/// start and results screens use it (only when opened from the picker), so
/// it never competes with the screen's own buttons for space.
struct GamesBackButton: View {
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Image(systemName: "chevron.left")
                Text("Games")
            }
            .font(Theme.hudCaptionFont)
            .foregroundStyle(accent)
            .frame(minWidth: 64, minHeight: Theme.minTapTarget, alignment: .leading)
            .padding(.leading, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back to games")
    }
}
