#!/usr/bin/env python3
"""Draws the Ringward app icon.

Run with `python3 -I icon/make_icon.py` from anywhere. Needs only the standard
library and Pillow. Draws at 4096 px and scales down to 1024 px with LANCZOS,
so every run produces the same file. Also writes small previews to
build/icon-preview/ (gitignored) to judge the icon at real on-screen sizes.

The look follows RingwardWatch/Theme.swift: pure black, a faint spawn ring, a
white core with a cyan glow, a thick cyan shield arc and orange shards, drawn
bolder than in the game so it still reads at watch-icon size.
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "Shared" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon.png"
PREVIEW_DIR = ROOT / "build" / "icon-preview"
PREVIEW_SIZES = (48, 80, 100, 180)

WORK = 4096          # drawing size
FINAL = 1024         # App Store / asset catalog size
SAFE_RADIUS = 0.415  # of FINAL: everything farther out is forced to pure black


def theme(r, g, b):
    return (round(r * 255), round(g * 255), round(b * 255))


def on_black(color, alpha):
    """A colour at `alpha` opacity, pre-blended on black."""
    return tuple(round(c * alpha) for c in color)


BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
SHIELD = theme(0.30, 0.85, 1.00)
SHARD = theme(1.00, 0.55, 0.20)
RING = on_black(WHITE, 0.18)
TAIL = on_black(SHARD, 0.55)

# Geometry, as fractions of the image side. Angles in degrees, 0 = 12 o'clock,
# clockwise, the same convention as GameCore.AngleMath.
RING_RADIUS = 0.38
RING_WIDTH = 0.012
CORE_RADIUS = 0.09
GLOW_RADIUS = 0.16
GLOW_BLUR = 0.035
GLOW_STRENGTH = 0.55
SHIELD_RADIUS = 0.215     # centre line of the arc
SHIELD_WIDTH = 0.07
SHIELD_CENTRE = 315.0     # about half past ten
SHIELD_SPAN = 70.0
TAIL_LENGTH = 0.10
# (angle, distance of the centre, radius); the first is about to hit the arc.
SHARDS = (
    (305.0, 0.300, 0.040),
    (135.0, 0.270, 0.040),
    (215.0, 0.280, 0.040),
)


def px(fraction):
    return fraction * WORK


def point(angle, distance):
    a = math.radians(angle)
    c = WORK / 2
    return (c + px(distance) * math.sin(a), c - px(distance) * math.cos(a))


def disc_box(centre, radius):
    x, y = centre
    return (x - radius, y - radius, x + radius, y + radius)


def draw_icon():
    centre = (WORK / 2, WORK / 2)
    img = Image.new("RGB", (WORK, WORK), BLACK)
    draw = ImageDraw.Draw(img)

    # Spawn ring
    draw.ellipse(disc_box(centre, px(RING_RADIUS)), outline=RING, width=round(px(RING_WIDTH)))

    # Soft cyan glow around the core
    glow = Image.new("L", (WORK, WORK), 0)
    ImageDraw.Draw(glow).ellipse(disc_box(centre, px(GLOW_RADIUS)), fill=round(255 * GLOW_STRENGTH))
    glow = glow.filter(ImageFilter.GaussianBlur(px(GLOW_BLUR)))
    img = Image.composite(Image.new("RGB", (WORK, WORK), SHIELD), img, glow)
    draw = ImageDraw.Draw(img)

    # Core
    draw.ellipse(disc_box(centre, px(CORE_RADIUS)), fill=WHITE)

    # Shield arc with round caps. Pillow measures arc angles from 3 o'clock.
    start = SHIELD_CENTRE - SHIELD_SPAN / 2
    end = SHIELD_CENTRE + SHIELD_SPAN / 2
    outer = px(SHIELD_RADIUS + SHIELD_WIDTH / 2)
    draw.arc(disc_box(centre, outer), start - 90, end - 90, fill=SHIELD, width=round(px(SHIELD_WIDTH)))
    for angle in (start, end):
        draw.ellipse(disc_box(point(angle, SHIELD_RADIUS), px(SHIELD_WIDTH) / 2), fill=SHIELD)

    # Shards: a tapered tail trailing back towards the rim, then the head.
    for angle, distance, radius in SHARDS:
        head = point(angle, distance)
        tip = point(angle, distance + TAIL_LENGTH)
        side = math.radians(angle + 90)
        half = px(radius) * 0.8
        dx, dy = half * math.sin(side), -half * math.cos(side)
        draw.polygon([(head[0] + dx, head[1] + dy), (head[0] - dx, head[1] - dy), tip], fill=TAIL)
        draw.ellipse(disc_box(head, px(radius)), fill=SHARD)

    return img


def clear_outside_safe_circle(img):
    """Forces every pixel outside the safe circle to pure black, so the round
    watch mask never shows anything and resampling halos can't leak out."""
    size = img.size[0]
    limit = (SAFE_RADIUS * size) ** 2
    c = size / 2
    pixels = img.load()
    for y in range(size):
        dy = (y + 0.5 - c) ** 2
        for x in range(size):
            if (x + 0.5 - c) ** 2 + dy > limit:
                pixels[x, y] = BLACK


def main():
    icon = draw_icon().resize((FINAL, FINAL), Image.LANCZOS)
    clear_outside_safe_circle(icon)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    icon.save(OUTPUT, format="PNG")
    print(f"wrote {OUTPUT.relative_to(ROOT)}")

    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    for size in PREVIEW_SIZES:
        path = PREVIEW_DIR / f"AppIcon-{size}.png"
        icon.resize((size, size), Image.LANCZOS).save(path, format="PNG")
        print(f"wrote {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
