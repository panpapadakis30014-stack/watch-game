import SwiftUI

/// Glow by layering, not by blur: translucent halos drawn with additive
/// blending (.plusLighter, so they add light instead of tinting), then the
/// crisp core and an optional thin white hot line in normal blending.
/// Callers batch every same-coloured shape into one call, so each colour
/// costs a fixed 2–4 draw calls.
///
/// Rule for every game: a point light with at most `Theme.maxSpritesPerFrame`
/// (16) instances per frame — shards, embers, the hero, sparks, a ball, a
/// cup, lamps, sources — uses `GlowSprite` (a smooth radial falloff), never a
/// flat fill halo. `fillCircles` is only for small, numerous fills (gems,
/// bolts) and keeps its halo tight.
enum GlowPath {
    static func addCircle(_ path: inout Path, _ centre: CGPoint, _ radius: CGFloat) {
        path.addEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius, width: 2 * radius, height: 2 * radius))
    }

    /// Outer halo, inner halo, core, hot line. 2–4 calls.
    static func stroke(_ path: Path, in context: inout GraphicsContext, color: Color, width: CGFloat,
                       style: GlowStyle = Theme.glowStandard, cap: CGLineCap = .round) {
        guard !path.isEmpty else { return }
        context.blendMode = .plusLighter
        if style.outerOpacity > 0 && style.outerWidth > 0 {
            context.stroke(path, with: .color(color.opacity(style.outerOpacity)),
                           style: StrokeStyle(lineWidth: width * style.outerWidth, lineCap: cap, lineJoin: .round))
        }
        context.stroke(path, with: .color(color.opacity(style.haloOpacity)),
                       style: StrokeStyle(lineWidth: width * style.haloWidth, lineCap: cap, lineJoin: .round))
        context.blendMode = .normal
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: cap, lineJoin: .round))
        if style.hotOpacity > 0 && style.hotWidth > 0 {
            context.stroke(path, with: .color(Theme.glowHot.opacity(style.hotOpacity)),
                           style: StrokeStyle(lineWidth: width * style.hotWidth, lineCap: cap, lineJoin: .round))
        }
    }

    /// Small glowing discs of one radius: one tight additive halo, then the
    /// core. 2 calls for any number of discs.
    static func fillCircles(_ centres: [CGPoint], radius: CGFloat, in context: inout GraphicsContext, color: Color,
                            haloColor: Color? = nil, style: GlowStyle = Theme.glowSoft) {
        guard !centres.isEmpty else { return }
        var core = Path(), halo = Path()
        for c in centres {
            addCircle(&core, c, radius)
            addCircle(&halo, c, radius * style.fillHaloWidth)
        }
        context.blendMode = .plusLighter
        context.fill(halo, with: .color((haloColor ?? color).opacity(style.fillHaloOpacity)))
        context.blendMode = .normal
        context.fill(core, with: .color(color))
    }
}
