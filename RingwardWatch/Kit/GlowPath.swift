import SwiftUI

/// Glow by layering, not by blur: a wide translucent halo under a crisp
/// core (and optionally a thin white hot line). Callers batch every
/// same-coloured shape into one Path so each colour costs 2–3 draw calls.
enum GlowPath {
    static func addCircle(_ path: inout Path, _ centre: CGPoint, _ radius: CGFloat) {
        path.addEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius, width: 2 * radius, height: 2 * radius))
    }

    /// Halo at `width × haloWidth`, then the core at `width`, then the hot line. 2–3 calls.
    static func stroke(_ path: Path, in context: inout GraphicsContext, color: Color, width: CGFloat,
                       style: GlowStyle = Theme.glowStandard, cap: CGLineCap = .round) {
        guard !path.isEmpty else { return }
        context.stroke(path, with: .color(color.opacity(style.haloOpacity)),
                       style: StrokeStyle(lineWidth: width * style.haloWidth, lineCap: cap, lineJoin: .round))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: cap, lineJoin: .round))
        if style.hotOpacity > 0 && style.hotWidth > 0 {
            context.stroke(path, with: .color(Theme.glowHot.opacity(style.hotOpacity)),
                           style: StrokeStyle(lineWidth: width * style.hotWidth, lineCap: cap, lineJoin: .round))
        }
    }

    /// The halo Path (built by the caller at radius × haloWidth), then the core. 2 calls.
    static func fill(core: Path, halo: Path, in context: inout GraphicsContext, color: Color,
                     haloColor: Color? = nil, style: GlowStyle = Theme.glowSoft) {
        if !halo.isEmpty {
            context.fill(halo, with: .color((haloColor ?? color).opacity(style.haloOpacity)))
        }
        if !core.isEmpty {
            context.fill(core, with: .color(color))
        }
    }
}
