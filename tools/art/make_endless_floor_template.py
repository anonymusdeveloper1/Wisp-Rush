#!/usr/bin/env python3
"""Render the Endless arena floor template images from floor_template.json (ADR-0014).

Every purchasable Endless arena skin paints its walkable floor to ONE canonical shape, so a cosmetic
background can never change how the game plays. That shape's single source of truth is
concept_art/wisp_rush_endless_v1/floor_template.json. This tool renders, next to it:

  floor_template_mask.png    white playable floor on black (tools, masked or inpainting workflows)
  floor_template_layout.png  grey-box composition reference: attach it to EVERY image generation
  floor_template_guide.png   annotated reference for people: zones, sizes, HUD band, phone crop

Run from the repo root:
  python3 tools/art/make_endless_floor_template.py
Placeholder arena for one skin (never ships; ROADMAP M6), one visually distinct style per skin id:
  python3 tools/art/make_endless_floor_template.py --style astral_observatory \
      --placeholder assets/art/environment/endless/astral_observatory.png
All three placeholder skins at their runtime paths (assets/art/environment/endless/<skin_id>.png):
  python3 tools/art/make_endless_floor_template.py --placeholder-skins
Every style paints the identical floor template; only colours and scenery differ. The owner's real
skins (spec 05) replace these outputs through the checker and extraction tools.

Never hand-edit the PNGs: they are regenerated from the JSON, and ADR-0014 freezes the JSON.
Requires Pillow only.
"""

import argparse
import json
import math
import os
import random
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

PACK_DIR = os.path.join("concept_art", "wisp_rush_endless_v1")
TEMPLATE_PATH = os.path.join(PACK_DIR, "floor_template.json")
REQUIRED_KEYS = (
    "canvas_px", "source_rect_uv", "chamfer_px", "polygon_uv", "floor_bleed_px",
    "rim_band_px", "rim_tolerance_px", "hud_band_max_v", "crop_20x9_u",
)
# polygon_uv is stored rounded to 5 decimals; anything looser means the JSON was edited by hand.
UV_TOLERANCE = 1e-4

# Three flat values an image model reads as three zones, ordered like the intended painting:
# the darkest scenery, a mid-dark floor, and a lighter rim that makes the floor edge obvious.
LAYOUT_SCENERY = (20, 24, 34)
LAYOUT_FLOOR = (84, 94, 100)
LAYOUT_RIM = (158, 168, 172)

# Guide annotation colours come from the style guide palette.
SOUL_CYAN = (98, 232, 242)
WARNING_AMBER = (243, 168, 71)
RIFT_MAGENTA = (177, 76, 217)
SOUL_WHITE = (234, 253, 255)
LABEL_PLATE = (10, 12, 18)
FONT_CANDIDATES = (
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
    "/Library/Fonts/Arial.ttf",
    "/System/Library/Fonts/Helvetica.ttc",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "DejaVuSans-Bold.ttf",
)


def load_template(path):
    with open(path, "r", encoding="utf-8") as handle:
        data = json.load(handle)
    missing = [key for key in REQUIRED_KEYS if key not in data]
    if missing:
        sys.exit("%s is missing: %s" % (path, ", ".join(missing)))
    return data


def chamfered_rect_uv(data):
    """The eight vertices implied by source_rect_uv and chamfer_px, clockwise from the top edge."""
    width, height = data["canvas_px"]
    u0, v0, u1, v1 = data["source_rect_uv"]
    du = data["chamfer_px"] / float(width)
    dv = data["chamfer_px"] / float(height)
    return [
        (u0 + du, v0), (u1 - du, v0), (u1, v0 + dv), (u1, v1 - dv),
        (u1 - du, v1), (u0 + du, v1), (u0, v1 - dv), (u0, v0 + dv),
    ]


def check_consistency(data):
    stored = [tuple(point) for point in data["polygon_uv"]]
    derived = chamfered_rect_uv(data)
    if len(stored) != len(derived):
        sys.exit("polygon_uv has %d vertices; the chamfered rectangle has %d"
                 % (len(stored), len(derived)))
    for index, (kept, expected) in enumerate(zip(stored, derived)):
        if abs(kept[0] - expected[0]) > UV_TOLERANCE or abs(kept[1] - expected[1]) > UV_TOLERANCE:
            sys.exit("polygon_uv vertex %d %s disagrees with source_rect_uv + chamfer_px %s"
                     % (index, kept, tuple(round(value, 5) for value in expected)))
    return stored


def to_pixels(points_uv, data):
    width, height = data["canvas_px"]
    return [(u * width, v * height) for u, v in points_uv]


def offset_convex(points, distance):
    """Pushes every edge of a convex polygon outward by `distance` px, with mitred corners."""
    count = len(points)
    centre_x = sum(point[0] for point in points) / count
    centre_y = sum(point[1] for point in points) / count
    lines = []
    for index in range(count):
        ax, ay = points[index]
        bx, by = points[(index + 1) % count]
        dx, dy = bx - ax, by - ay
        length = math.hypot(dx, dy)
        nx, ny = dy / length, -dx / length
        if ((ax + bx) * 0.5 - centre_x) * nx + ((ay + by) * 0.5 - centre_y) * ny < 0.0:
            nx, ny = -nx, -ny
        lines.append(((ax + nx * distance, ay + ny * distance), (dx, dy)))
    result = []
    for index in range(count):
        (px1, py1), (dx1, dy1) = lines[index - 1]
        (px2, py2), (dx2, dy2) = lines[index]
        denominator = dx1 * dy2 - dy1 * dx2
        if abs(denominator) < 1e-9:
            result.append((px2, py2))
            continue
        t = ((px2 - px1) * dy2 - (py2 - py1) * dx2) / denominator
        result.append((px1 + dx1 * t, py1 + dy1 * t))
    return result


def polygon_area(points):
    total = 0.0
    for index, (x1, y1) in enumerate(points):
        x2, y2 = points[(index + 1) % len(points)]
        total += x1 * y2 - x2 * y1
    return abs(total) * 0.5


def load_font(size):
    # A real TrueType face keeps guide labels legible; Pillow's built-in fallback is tiny.
    for candidate in FONT_CANDIDATES:
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            continue
    try:
        return ImageFont.load_default(size=size)
    except TypeError:  # Pillow < 10.1 has only the small bitmap font.
        return ImageFont.load_default()


def draw_label(draw, position, text, size, fill=SOUL_WHITE, anchor="mm"):
    font = load_font(size)
    try:
        box = draw.textbbox(position, text, font=font, anchor=anchor)
    except ValueError:  # bitmap fonts do not support anchors
        anchor = None
        box = draw.textbbox(position, text, font=font)
    draw.rectangle((box[0] - 8, box[1] - 5, box[2] + 8, box[3] + 5), fill=LABEL_PLATE)
    draw.text(position, text, font=font, fill=fill, anchor=anchor)


def draw_dashed(draw, start, end, fill, width, dash=18, gap=12):
    length = math.hypot(end[0] - start[0], end[1] - start[1])
    if length <= 0.0:
        return
    ux, uy = (end[0] - start[0]) / length, (end[1] - start[1]) / length
    position = 0.0
    while position < length:
        stop = min(length, position + dash)
        draw.line([(start[0] + ux * position, start[1] + uy * position),
                   (start[0] + ux * stop, start[1] + uy * stop)], fill=fill, width=width)
        position = stop + gap


def draw_outline(draw, points, fill, width, dashed=False):
    closed = list(points) + [points[0]]
    for start, end in zip(closed, closed[1:]):
        if dashed:
            draw_dashed(draw, start, end, fill, width)
        else:
            draw.line([start, end], fill=fill, width=width)


def render_mask(data, template):
    image = Image.new("L", tuple(data["canvas_px"]), 0)
    ImageDraw.Draw(image).polygon(template, fill=255)
    return image


def render_layout(data, template):
    image = Image.new("RGB", tuple(data["canvas_px"]), LAYOUT_SCENERY)
    draw = ImageDraw.Draw(image)
    draw.polygon(offset_convex(template, data["rim_band_px"][1]), fill=LAYOUT_RIM)
    draw.polygon(offset_convex(template, data["floor_bleed_px"]), fill=LAYOUT_FLOOR)
    return image


def render_guide(data, template):
    width, height = data["canvas_px"]
    hud_y = data["hud_band_max_v"] * height
    crop_left = data["crop_20x9_u"][0] * width
    crop_right = data["crop_20x9_u"][1] * width
    base = render_layout(data, template).convert("RGBA")
    shade = Image.new("RGBA", base.size, (0, 0, 0, 0))
    shade_draw = ImageDraw.Draw(shade)
    shade_draw.rectangle((0, 0, width, hud_y), fill=(0, 0, 0, 120))
    shade_draw.rectangle((0, 0, crop_left, height), fill=(0, 0, 0, 100))
    shade_draw.rectangle((crop_right, 0, width, height), fill=(0, 0, 0, 100))
    image = Image.alpha_composite(base, shade).convert("RGB")
    draw = ImageDraw.Draw(image)

    draw_outline(draw, offset_convex(template, data["rim_tolerance_px"]), WARNING_AMBER, 2, dashed=True)
    draw_outline(draw, offset_convex(template, data["floor_bleed_px"]), WARNING_AMBER, 2, dashed=True)
    draw_outline(draw, template, SOUL_CYAN, 4)
    draw_dashed(draw, (crop_left, 0), (crop_left, height), RIFT_MAGENTA, 3)
    draw_dashed(draw, (crop_right, 0), (crop_right, height), RIFT_MAGENTA, 3)
    draw_dashed(draw, (0, hud_y), (width, hud_y), SOUL_WHITE, 2)

    xs = [point[0] for point in template]
    ys = [point[1] for point in template]
    centre_x = (min(xs) + max(xs)) * 0.5
    centre_y = (min(ys) + max(ys)) * 0.5
    draw_label(draw, (centre_x, centre_y - 90), "PLAYABLE FLOOR", 44, SOUL_CYAN)
    draw_label(draw, (centre_x, centre_y - 30), "flat / clear / dark", 28)
    draw_label(draw, (centre_x, centre_y + 30), "%d x %d px, corners cut %d px"
               % (round(max(xs) - min(xs)), round(max(ys) - min(ys)), data["chamfer_px"]), 26)
    draw_label(draw, (centre_x, centre_y + 80), "x %d-%d   y %d-%d"
               % (round(min(xs)), round(max(xs)), round(min(ys)), round(max(ys))), 26)
    draw_label(draw, (centre_x, max(ys) + 90), "floor bleeds %d px past the cyan line"
               % data["floor_bleed_px"], 24, WARNING_AMBER)
    draw_label(draw, (centre_x, max(ys) + 135), "rim %d-%d px outside it, never past %d px"
               % (data["rim_band_px"][0], data["rim_band_px"][1], data["rim_tolerance_px"]), 24,
               WARNING_AMBER)
    draw_label(draw, (centre_x, max(ys) + 180), "scenery beyond the rim", 24)
    draw_label(draw, (centre_x, hud_y - 45), "HUD band above y %d: decorative only" % round(hud_y), 24)
    draw_label(draw, (crop_left + 12, height - 70), "20:9 crop", 22, RIFT_MAGENTA, "lm")
    draw_label(draw, (crop_right - 12, height - 70), "20:9 crop", 22, RIFT_MAGENTA, "rm")
    return image


# Placeholder looks, one per Endless skin id. Floors stay dark and low-contrast so the Wisp remains the
# brightest object; scenery and rim carry each skin's identity (GENERATION_PROMPTS.md).
PLACEHOLDER_DIR = os.path.join("assets", "art", "environment", "endless")
PLACEHOLDER_STYLES = {
    "astral_observatory": {
        "label": "ASTRAL OBSERVATORY",
        "scenery": (12, 14, 34), "speck": (150, 160, 215), "specks": 900,
        "rim": (104, 110, 128), "stud": (170, 182, 205),
        "floor": (30, 34, 50), "line": (37, 42, 60), "pattern": "slabs",
        "decor": "nebula",
    },
    "drowned_sanctum": {
        "label": "DROWNED SANCTUM",
        "scenery": (7, 16, 17), "speck": (26, 48, 44), "specks": 0,
        "rim": (66, 76, 70), "stud": (150, 166, 158),
        "floor": (27, 35, 36), "line": (33, 42, 43), "pattern": "flagstones",
        "decor": "ripples",
    },
    "moonpetal_shrine": {
        "label": "MOONPETAL SHRINE",
        "scenery": (19, 21, 27), "speck": (60, 64, 72), "specks": 300,
        "rim": (128, 124, 118), "stud": (84, 80, 74),
        "floor": (34, 34, 38), "line": (41, 41, 46), "pattern": "tiles",
        "decor": "blossoms",
    },
}
DEFAULT_PLACEHOLDER_STYLE = "astral_observatory"


def _draw_decor(image, style, rng):
    width, height = image.size
    draw = ImageDraw.Draw(image)
    for _ in range(style["specks"]):
        radius = rng.choice((0, 0, 0, 1, 1, 2))
        x, y = rng.randrange(width), rng.randrange(height)
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=style["speck"])
    if style["decor"] == "nebula":
        haze = Image.new("RGB", image.size, (0, 0, 0))
        haze_draw = ImageDraw.Draw(haze)
        haze_draw.ellipse((-200, 60, 620, 520), fill=(38, 22, 70))
        haze_draw.ellipse((420, 1240, 1180, 1700), fill=(24, 30, 72))
        image.paste(ImageChops.add(image, haze.filter(ImageFilter.GaussianBlur(90))))
        draw = ImageDraw.Draw(image)
        for centre, radius in (((150, 210), 120), ((820, 1500), 150)):
            draw.ellipse((centre[0] - radius, centre[1] - radius, centre[0] + radius,
                          centre[1] + radius), outline=(70, 76, 96), width=6)
    elif style["decor"] == "ripples":
        for _ in range(260):
            x, y = rng.randrange(-60, width), rng.randrange(height)
            length = rng.randrange(30, 140)
            draw.line([(x, y), (x + length, y)], fill=(22, 40, 38), width=2)
        for centre in ((70, 330), (880, 330), (70, 1420), (880, 1420), (470, 1560)):
            draw.ellipse((centre[0] - 44, centre[1] - 44, centre[0] + 44, centre[1] + 44),
                         fill=(40, 50, 47), outline=(58, 70, 64), width=4)
    elif style["decor"] == "blossoms":
        for _ in range(26):
            x, y = rng.randrange(width), rng.randrange(height)
            radius = rng.randrange(40, 90)
            draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(26, 26, 28))
            for _ in range(18):
                bx = x + rng.randrange(-radius, radius)
                by = y + rng.randrange(-radius, radius)
                petal = rng.randrange(3, 7)
                draw.ellipse((bx - petal, by - petal, bx + petal, by + petal), fill=(214, 206, 198))


def _floor_pattern(size, style):
    width, height = size
    layer = Image.new("RGB", size, style["floor"])
    draw = ImageDraw.Draw(layer)
    line = style["line"]
    if style["pattern"] == "slabs":
        for x in range(0, width, 96):
            draw.line([(x, 0), (x, height)], fill=line, width=2)
        for y in range(0, height, 96):
            draw.line([(0, y), (width, y)], fill=line, width=2)
    elif style["pattern"] == "flagstones":
        for row, y in enumerate(range(0, height, 64)):
            draw.line([(0, y), (width, y)], fill=line, width=2)
            for x in range(-60 if row % 2 else 0, width, 120):
                draw.line([(x, y), (x, y + 64)], fill=line, width=2)
    else:
        for offset in range(-height, width + height, 90):
            draw.line([(offset, 0), (offset + height, height)], fill=line, width=2)
            draw.line([(offset, height), (offset + height, 0)], fill=line, width=2)
    return layer


def render_placeholder(data, template, output_path, style_name=DEFAULT_PLACEHOLDER_STYLE):
    """A clearly marked stand-in arena that satisfies the template exactly (never ships)."""
    style = PLACEHOLDER_STYLES[style_name]
    width, height = data["canvas_px"]
    rng = random.Random(1409)
    image = Image.new("RGB", (width, height), style["scenery"])
    _draw_decor(image, style, rng)
    draw = ImageDraw.Draw(image)
    draw.polygon(offset_convex(template, data["rim_band_px"][1]), fill=style["rim"])
    stud_path = offset_convex(template, (data["rim_band_px"][0] + data["rim_band_px"][1]) * 0.5)
    for start, end in zip(stud_path, stud_path[1:] + stud_path[:1]):
        length = math.hypot(end[0] - start[0], end[1] - start[1])
        for step in range(int(length // 70) + 1):
            t = step * 70.0 / length if length > 0.0 else 0.0
            x = start[0] + (end[0] - start[0]) * t
            y = start[1] + (end[1] - start[1]) * t
            draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=style["stud"])
    floor = offset_convex(template, data["floor_bleed_px"])
    mask = Image.new("L", (width, height), 0)
    ImageDraw.Draw(mask).polygon(floor, fill=255)
    image.paste(_floor_pattern((width, height), style), (0, 0), mask)
    label_draw = ImageDraw.Draw(image)
    draw_label(label_draw, (width * 0.5, height - 160), style["label"], 26, SOUL_WHITE)
    draw_label(label_draw, (width * 0.5, height - 110), "PLACEHOLDER - NOT FOR RELEASE", 26,
               WARNING_AMBER)
    image.save(output_path, optimize=True)


def main():
    parser = argparse.ArgumentParser(description="Render the Endless floor template images (ADR-0014).")
    parser.add_argument("--placeholder", metavar="PNG",
                        help="also write a development-only placeholder arena to this path")
    parser.add_argument("--style", choices=sorted(PLACEHOLDER_STYLES), default=DEFAULT_PLACEHOLDER_STYLE,
                        help="placeholder look for --placeholder (one per Endless skin id)")
    parser.add_argument("--placeholder-skins", action="store_true",
                        help="write every placeholder style to %s/<skin_id>.png" % PLACEHOLDER_DIR)
    args = parser.parse_args()
    if not os.path.isfile(TEMPLATE_PATH):
        sys.exit("Run from the repo root: %s not found" % TEMPLATE_PATH)

    data = load_template(TEMPLATE_PATH)
    template = to_pixels(check_consistency(data), data)
    outputs = (
        ("floor_template_mask.png", render_mask(data, template)),
        ("floor_template_layout.png", render_layout(data, template)),
        ("floor_template_guide.png", render_guide(data, template)),
    )
    for name, image in outputs:
        path = os.path.join(PACK_DIR, name)
        image.save(path, optimize=True)
        print("wrote %s  %dx%d" % (path, image.width, image.height))
    if args.placeholder:
        directory = os.path.dirname(args.placeholder)
        if directory:
            os.makedirs(directory, exist_ok=True)
        render_placeholder(data, template, args.placeholder, args.style)
        print("wrote %s  (%s placeholder, never ships)" % (args.placeholder, args.style))
    if args.placeholder_skins:
        os.makedirs(PLACEHOLDER_DIR, exist_ok=True)
        for style_name in sorted(PLACEHOLDER_STYLES):
            path = os.path.join(PLACEHOLDER_DIR, style_name + ".png")
            render_placeholder(data, template, path, style_name)
            print("wrote %s  (placeholder, never ships)" % path)

    xs = [point[0] for point in template]
    ys = [point[1] for point in template]
    width, height = data["canvas_px"]
    print("template: x %.1f-%.1f  y %.1f-%.1f px  |  UV area %.4f"
          % (min(xs), max(xs), min(ys), max(ys), polygon_area(template) / (width * height)))


if __name__ == "__main__":
    main()
