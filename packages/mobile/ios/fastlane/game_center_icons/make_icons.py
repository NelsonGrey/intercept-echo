#!/usr/bin/env python3
"""Generates the 5 Game Center achievement icons for Intercept Echo,
matching the game's real Signal theme palette (lib/theme/game_theme.dart).
"""
import math
import os

NAVY = "#07111F"
NAVY_CELL_OFF = "#101D30"
NAVY_CELL_BORDER = "#6E83A3"
BLUE = "#3F6ED8"
AMBER = "#FFB454"
MINT = "#70E0BD"
CORAL = "#FF8C75"
CREAM = "#F5F1E8"

SIZE = 1024

def bit_row(pattern, lit_color, off_color=NAVY_CELL_OFF, border=NAVY_CELL_BORDER):
    """8 rounded-square bit cells along the bottom, pattern is an 8-char
    string of '1'/'0' read left to right (MSB to LSB, matches the game's
    own register display convention)."""
    n = 8
    cell = 84
    gap = 14
    total_w = n * cell + (n - 1) * gap
    start_x = (SIZE - total_w) / 2
    y = 860
    parts = []
    for i, ch in enumerate(pattern):
        x = start_x + i * (cell + gap)
        on = ch == "1"
        fill = lit_color if on else off_color
        stroke_attr = "" if on else f'stroke="{border}" stroke-width="3"'
        parts.append(
            f'<rect x="{x:.1f}" y="{y}" width="{cell}" height="{cell}" '
            f'rx="16" fill="{fill}" {stroke_attr}/>'
        )
    return "\n".join(parts)

def svg_header():
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" viewBox="0 0 {SIZE} {SIZE}">'

def bg():
    return f'<rect width="{SIZE}" height="{SIZE}" fill="{NAVY}"/>'

def footer():
    return "</svg>"

def write(name, body):
    path = os.path.join(os.path.dirname(__file__), f"{name}.svg")
    with open(path, "w") as f:
        f.write(svg_header() + bg() + body + footer())
    print("wrote", path)

# ---------------------------------------------------------------------------
# 1. First Contact — a signal beacon with radiating waves.
cx, cy = 512, 430
arcs = []
for i, r in enumerate([120, 200, 280]):
    arcs.append(
        f'<path d="M {cx - r} {cy} A {r} {r} 0 0 1 {cx + r} {cy}" '
        f'fill="none" stroke="{AMBER}" stroke-width="20" stroke-linecap="round" '
        f'opacity="{1.0 - i * 0.28:.2f}"/>'
    )
beacon = f'<circle cx="{cx}" cy="{cy + 30}" r="34" fill="{AMBER}"/>'
stem = f'<rect x="{cx-10}" y="{cy+30}" width="20" height="90" fill="{AMBER}"/>'
first_contact = "\n".join(arcs) + beacon + stem + bit_row("10000000", MINT)
write("first_transmission", first_contact)

# ---------------------------------------------------------------------------
# 2. Campaign Complete — bold checkmark inside a rounded square badge.
badge = (
    f'<rect x="242" y="160" width="540" height="540" rx="64" '
    f'fill="none" stroke="{BLUE}" stroke-width="22"/>'
)
check = (
    f'<path d="M 370 440 L 470 540 L 660 320" fill="none" '
    f'stroke="{MINT}" stroke-width="46" stroke-linecap="round" stroke-linejoin="round"/>'
)
campaign_complete = badge + check + bit_row("11111111", BLUE)
write("campaign_complete", campaign_complete)

# ---------------------------------------------------------------------------
# 3. Used Rotate — a circular rotation arrow around a small register.
cx, cy, r = 512, 430, 210
start_deg, end_deg = -50, 230
def pt(deg, radius=r):
    rad = math.radians(deg)
    return cx + radius * math.cos(rad), cy + radius * math.sin(rad)
x0, y0 = pt(start_deg)
x1, y1 = pt(end_deg)
large_arc = 1 if (end_deg - start_deg) > 180 else 0
arc_path = f'<path d="M {x0:.1f} {y0:.1f} A {r} {r} 0 {large_arc} 1 {x1:.1f} {y1:.1f}" fill="none" stroke="{BLUE}" stroke-width="34" stroke-linecap="round"/>'
# arrowhead at the end of the arc
tangent_deg = end_deg + 90
ax, ay = pt(end_deg)
def head_point(base_deg, dist):
    rad = math.radians(base_deg)
    return ax + dist * math.cos(rad), ay + dist * math.sin(rad)
h1x, h1y = head_point(tangent_deg - 150, 60)
h2x, h2y = head_point(tangent_deg + 150, 60)
arrowhead = f'<path d="M {ax:.1f} {ay:.1f} L {h1x:.1f} {h1y:.1f} L {h2x:.1f} {h2y:.1f} Z" fill="{BLUE}"/>'
small_cells = []
for i in range(4):
    x = cx - 84 + i * 56
    small_cells.append(f'<rect x="{x:.1f}" y="{cy-28}" width="42" height="56" rx="8" fill="{CREAM}" opacity="0.9"/>')
used_rotate = arc_path + arrowhead + "".join(small_cells) + bit_row("10101010", BLUE)
write("used_rotate", used_rotate)

# ---------------------------------------------------------------------------
# 4. Hard Difficulty — a padlock (hidden values).
body_lock = f'<rect x="372" y="420" width="280" height="220" rx="28" fill="{CORAL}"/>'
shackle = (
    f'<path d="M 412 420 L 412 340 A 100 100 0 0 1 612 340 L 612 420" '
    f'fill="none" stroke="{CORAL}" stroke-width="34" stroke-linecap="round"/>'
)
keyhole = f'<circle cx="512" cy="500" r="26" fill="{NAVY}"/>' + \
    f'<rect x="498" y="500" width="28" height="60" fill="{NAVY}"/>'
hard_difficulty = shackle + body_lock + keyhole + bit_row("11111111", "#3A4A66", off_color="#3A4A66", border="#3A4A66")
write("hard_difficulty", hard_difficulty)

# ---------------------------------------------------------------------------
# 5. Perfect Shift — double chevron (shift) with a star.
def chevron(x_off, opacity):
    return (
        f'<path d="M {440+x_off} 300 L 560 430 L {440+x_off} 560" '
        f'fill="none" stroke="{AMBER}" stroke-width="34" stroke-linecap="round" '
        f'stroke-linejoin="round" opacity="{opacity}"/>'
    )
chevrons = chevron(0, 1.0) + chevron(90, 0.55)
# 5-point star above the chevrons
star_cx, star_cy, r_out, r_in = 512, 190, 46, 20
pts = []
for i in range(10):
    ang = math.radians(-90 + i * 36)
    rad = r_out if i % 2 == 0 else r_in
    pts.append(f"{star_cx + rad*math.cos(ang):.1f},{star_cy + rad*math.sin(ang):.1f}")
star = f'<polygon points="{" ".join(pts)}" fill="{MINT}"/>'
perfect_shift = chevrons + star + bit_row("01011000", AMBER)
write("perfect_shift", perfect_shift)

print("done")
