import SwiftUI

/// Pre-rendered radial-gradient glow for point lights, supplied to a Canvas
/// through `symbols:` (one tagged view per colour) and stamped once per
/// light. The gradient is rendered as a symbol, not per frame, and gives a
/// smooth falloff to the background instead of a flat disc.
enum GlowSprite {
    static let side: CGFloat = 64

    /// The symbol view for one colour; tag it with an Int in the Canvas `symbols:` builder.
    static func view(_ color: Color) -> some View {
        RadialGradient(
            gradient: Gradient(stops: [
                .init(color: color.opacity(0.60), location: 0.00),
                .init(color: color.opacity(0.22), location: 0.35),
                .init(color: color.opacity(0.06), location: 0.70),
                .init(color: color.opacity(0.00), location: 1.00)
            ]),
            center: .center,
            startRadius: 0,
            endRadius: side / 2
        )
        .frame(width: side, height: side)
    }

    /// One draw per instance; `radius` = core radius × Theme.spriteGlowRatio.
    /// Draws nothing if the symbol isn't available.
    static func draw(_ tag: Int, at p: CGPoint, radius: CGFloat, in context: inout GraphicsContext) {
        guard let symbol = context.resolveSymbol(id: tag) else { return }
        context.draw(symbol, in: CGRect(x: p.x - radius, y: p.y - radius, width: 2 * radius, height: 2 * radius))
    }
}
