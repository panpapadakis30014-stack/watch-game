import SwiftUI

/// A HUD text in one of four fixed type roles, rounded and with monospaced
/// digits. Optional SF Symbol, dark plate, and a rolling-number transition
/// when `countingValue` is set (none under Reduce Motion).
struct HUDLabel: View {
    enum Role {
        case score, value, detail, caption
    }

    let text: String
    let role: Role
    var color: Color = Theme.hudPrimary
    var symbol: String? = nil
    var countingValue: Double? = nil
    var plate: Bool = false
    let accessibilityText: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let rolling = countingValue != nil && !reduceMotion
        HStack(spacing: 2) {
            if let symbol {
                Image(systemName: symbol)
            }
            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(Theme.hudMinScale)
                .contentTransition(rolling ? .numericText(value: countingValue ?? 0) : .identity)
        }
        .font(font)
        .fontDesign(.rounded)
        .foregroundStyle(color)
        .padding(.horizontal, plate ? Theme.hudPlatePaddingH : 0)
        .padding(.vertical, plate ? Theme.hudPlatePaddingV : 0)
        .background {
            if plate {
                Capsule().fill(Theme.hudPlate)
            }
        }
        .animation(rolling ? Theme.numberAnimation : nil, value: countingValue)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var font: Font {
        switch role {
        case .score: return Theme.hudScoreFont
        case .value: return Theme.hudValueFont
        case .detail: return Theme.hudDetailFont
        case .caption: return Theme.hudCaptionFont
        }
    }
}
