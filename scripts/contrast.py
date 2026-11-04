#!/usr/bin/env python3
"""WCAG 2.x contrast check for the watch app's Theme colours.

Usage: python3 -I scripts/contrast.py RingwardWatch/Theme.swift
Reads `static let name = Color(red:, green:, blue:)[.opacity(a)]`, `Color.white/black[.opacity(a)]`
and aliases `static let a = b[.opacity(x)]`. Prints a Markdown table; exits 1 if any pair fails.
"""
import re
import sys

NUM = r"([0-9]*\.?[0-9]+)"
RGB = re.compile(r"static let (\w+) = Color\(red: " + NUM + r", green: " + NUM + r", blue: " + NUM + r"\)(?:\.opacity\(" + NUM + r"\))?\s*$")
NAMED = re.compile(r"static let (\w+) = Color\.(white|black)(?:\.opacity\(" + NUM + r"\))?\s*$")
ALIAS = re.compile(r"static let (\w+) = ([a-z]\w*)(?:\.opacity\(" + NUM + r"\))?\s*$")

# (foreground, background, minimum, what it is). Backgrounds with opacity are composited over nightCenter,
# the lightest point of the night gradient (the worst case for light text).
PAIRS = [
    ("hudPrimary", "nightCenter", 4.5, "HUD and body text"),
    ("hudPrimary", "cardFill", 4.5, "Card and option titles"),
    ("hudPrimary", "hudPlate", 4.5, "Lanternfall HUD on its plate"),
    ("secondaryText", "nightCenter", 4.5, "Secondary text"),
    ("secondaryText", "cardFill", 4.5, "Card detail and option effect lines"),
    ("danger", "nightCenter", 4.5, "Health text"),
    ("danger", "hudPlate", 4.5, "Health text on plate"),
    ("pulse", "nightCenter", 4.5, "Ringward multiplier and Pulse label"),
    ("lfWarden", "hudPlate", 4.5, "Warden banner"),
    ("lfEnraged", "hudPlate", 4.5, "Enraged banner"),
    ("lanternfallAccent", "hudPlate", 4.5, "Lanternfall level caption"),
    ("lanternfallAccent", "cardFill", 4.5, "Level-up option level line"),
]
ACCENTS = ["ringwardAccent", "lanternfallAccent", "driftlineAccent", "moonputtAccent", "glowgridAccent"]
for a in ACCENTS:
    PAIRS.append((a, "cardFill", 4.5, "Card title (" + a + ")"))
    PAIRS.append((a, "nightCenter", 3.0, "Large screen title (" + a + ")"))
    PAIRS.append(("onAccent", a, 4.5, "Primary button label (" + a + ")"))


def parse(path):
    colours = {}
    with open(path, encoding="utf-8") as f:
        for raw in f:
            line = raw.strip()
            m = RGB.match(line)
            if m:
                colours[m.group(1)] = ((float(m.group(2)), float(m.group(3)), float(m.group(4))), float(m.group(5) or 1))
                continue
            m = NAMED.match(line)
            if m:
                rgb = (1.0, 1.0, 1.0) if m.group(2) == "white" else (0.0, 0.0, 0.0)
                colours[m.group(1)] = (rgb, float(m.group(3) or 1))
                continue
            m = ALIAS.match(line)
            if m and m.group(2) in colours:
                rgb, a = colours[m.group(2)]
                colours[m.group(1)] = (rgb, a * float(m.group(3) or 1))
    return colours


def over(fg, a, bg):
    return tuple(f * a + b * (1 - a) for f, b in zip(fg, bg))


def lum(rgb):
    def lin(c):
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (lin(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def ratio(a, b):
    la, lb = lum(a), lum(b)
    return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)


def main():
    colours = parse(sys.argv[1])
    missing = sorted({n for p in PAIRS for n in p[:2] if n not in colours} | ({"nightCenter"} - colours.keys()))
    if missing:
        print("::error::Theme colours not found: " + ", ".join(missing))
        return 1
    base = colours["nightCenter"][0]
    failed = 0
    print("| Text | Background | Ratio | Min | Result | Use |")
    print("|---|---|---|---|---|---|")
    for fg, bg, minimum, use in PAIRS:
        bg_rgb = over(colours[bg][0], colours[bg][1], base)
        fg_rgb = over(colours[fg][0], colours[fg][1], bg_rgb)
        r = ratio(fg_rgb, bg_rgb)
        ok = r >= minimum
        failed += 0 if ok else 1
        print(f"| {fg} | {bg} | {r:.2f}:1 | {minimum}:1 | {'pass' if ok else 'FAIL'} | {use} |")
    if failed:
        print(f"::error::{failed} colour pair(s) below the WCAG minimum")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
