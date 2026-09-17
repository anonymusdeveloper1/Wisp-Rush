#!/usr/bin/env python3
"""Check Endless arena skins against the frozen floor template (ADR-0014, spec story_and_endless/05).

Usage (repo root):
  python3 tools/art/check_endless_skin.py concept_art/wisp_rush_endless_v1/assets/*.png
  python3 tools/art/check_endless_skin.py --sheet logs/endless/check_sheet.png <png>...

Each image must be 941x1672 RGB. The painted floor is estimated with the floor-likeness heuristic of
extract_floor_polygons.py (smooth + desaturated) and compared with floor_template.json:
  coverage  - share of the template the painted floor covers                      (>= COVERAGE_MIN)
  rim       - share of the painted rim band (rim_band_px outside the template edge) that still looks
              like floor (<= RIM_FLOOR_MAX): a skin painted to the template has its stone rim there,
              an arena whose floor ignores the template keeps floor running through it
  overflow  - informational only (WARN): floor-like area beyond template + rim_tolerance_px. The
              heuristic leaks through gaps in a painted rim into smooth scenery (decks, water), so
              the eye review, not this number, decides those
  luminance - mean luminance inside the template relative to Obsidian Garden's runtime floor
              (<= 1 + LUMINANCE_MARGIN), so the Wisp stays the brightest object
  props     - high-variance blobs inside the (inset) template, as a share of it (<= PROPS_MAX)
Writes logs/endless/<name>_check.png (template cyan, estimated floor orange, flagged blobs magenta),
prints one line per metric and exits 1 if any image fails.

Calibration (2026-09-15): thresholds were set once so the generated placeholder skins pass and a Rift
background (ember_hollow) fails on shape; see the DEVLOG entry of that date for the numbers.
"""

import argparse
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import extract_floor_polygons as floor  # noqa: E402

TEMPLATE_JSON = "concept_art/wisp_rush_endless_v1/floor_template.json"
REFERENCE_FLOOR = "assets/art/environment/wisp_rush_arena_background.png"
OUT_DIR = "logs/endless"
CANVAS = (941, 1672)

COVERAGE_MIN = 0.80
OVERFLOW_WARN = 0.12
RIM_FLOOR_MAX = 0.35
OVERFLOW_RING_PX = 140
LUMINANCE_MARGIN = 0.10
PROPS_MAX = 0.015
# Variance (luminance, radius 3 at work width) above this marks a prop-like high-frequency blob.
PROP_VARIANCE = 0.012
# Blobs smaller than this many work pixels are texture, not props.
PROP_MIN_PIXELS = 12
# The rim band just inside the template edge is excluded from the prop search.
PROP_INSET_PX = 40


def load_template():
    with open(TEMPLATE_JSON) as handle:
        return json.load(handle)


def polygon_mask(polygon_uv, shape, grow_px=0.0):
    """Boolean mask of the UV polygon at `shape` (h, w), optionally grown/shrunk by source px."""
    height, width = shape
    image = Image.new("L", (width, height), 0)
    points = [(u * width, v * height) for u, v in polygon_uv]
    ImageDraw.Draw(image).polygon(points, fill=255)
    mask = np.asarray(image) > 0
    passes = int(round(abs(grow_px) * width / float(CANVAS[0])))
    if passes > 0:
        mask = floor.dilate(mask, passes) if grow_px > 0 else floor.erode(mask, passes)
    return mask


def luminance_and_variance(image, shape):
    height, width = shape
    small = image.convert("RGB").resize((width, height), Image.BILINEAR)
    pixels = np.asarray(small, dtype=np.float32) / 255.0
    luminance = pixels.mean(axis=2)
    mean = floor.box_mean(luminance, floor.VARIANCE_RADIUS)
    mean_square = floor.box_mean(luminance * luminance, floor.VARIANCE_RADIUS)
    variance = np.maximum(mean_square - mean * mean, 0.0)
    return luminance, variance


def components(mask, min_pixels):
    """Mask of connected regions of at least `min_pixels`."""
    from collections import deque
    height, width = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    keep = np.zeros_like(mask, dtype=bool)
    for y0, x0 in zip(*np.nonzero(mask)):
        if seen[y0, x0]:
            continue
        queue = deque([(y0, x0)])
        seen[y0, x0] = True
        pixels = []
        while queue:
            y, x = queue.popleft()
            pixels.append((y, x))
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = y + dy, x + dx
                if 0 <= ny < height and 0 <= nx < width and mask[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True
                    queue.append((ny, nx))
        if len(pixels) >= min_pixels:
            for y, x in pixels:
                keep[y, x] = True
    return keep


def reference_luminance(template):
    image = Image.open(REFERENCE_FLOOR)
    shape = (int(round(image.height * floor.WORK_WIDTH / float(image.width))), floor.WORK_WIDTH)
    luminance, _ = luminance_and_variance(image, shape)
    inside = polygon_mask(template["polygon_uv"], shape, -PROP_INSET_PX)
    return float(luminance[inside].mean())


def check(path, template, reference_lum):
    name = os.path.splitext(os.path.basename(path))[0]
    image = Image.open(path)
    result = {"name": name, "path": path, "failures": []}
    if image.size != CANVAS or image.mode != "RGB":
        result["failures"].append("size/mode %sx%s %s (need 941x1672 RGB)" % (
            image.size[0], image.size[1], image.mode))
        return result
    estimated = floor.floor_mask(image)
    shape = estimated.shape
    tmpl = polygon_mask(template["polygon_uv"], shape)
    tolerance = polygon_mask(template["polygon_uv"], shape, template["rim_tolerance_px"])
    ring = polygon_mask(template["polygon_uv"], shape, template["rim_tolerance_px"] + OVERFLOW_RING_PX)
    tmpl_area = float(tmpl.sum())
    coverage = float((estimated & tmpl).sum()) / tmpl_area
    overflow = float((estimated & ring & ~tolerance).sum()) / tmpl_area
    rim_band = template["rim_band_px"]
    band = (
        polygon_mask(template["polygon_uv"], shape, rim_band[1])
        & ~polygon_mask(template["polygon_uv"], shape, rim_band[0])
    )
    rim_floor = float((estimated & band).sum()) / max(float(band.sum()), 1.0)
    luminance, variance = luminance_and_variance(image, shape)
    inset = polygon_mask(template["polygon_uv"], shape, -PROP_INSET_PX)
    lum_ratio = float(luminance[inset].mean()) / max(reference_lum, 1e-6)
    blobs = components((variance > PROP_VARIANCE) & inset, PROP_MIN_PIXELS)
    props = float(blobs.sum()) / tmpl_area
    result.update(
        coverage=coverage, overflow=overflow, rim=rim_floor, luminance=lum_ratio, props=props
    )
    result["warnings"] = (
        ["overflow %.3f > %.2f (eye review)" % (overflow, OVERFLOW_WARN)] if overflow > OVERFLOW_WARN else []
    )
    if coverage < COVERAGE_MIN:
        result["failures"].append("coverage %.3f < %.2f" % (coverage, COVERAGE_MIN))
    if rim_floor > RIM_FLOOR_MAX:
        result["failures"].append("rim floor %.3f > %.2f" % (rim_floor, RIM_FLOOR_MAX))
    if lum_ratio > 1.0 + LUMINANCE_MARGIN:
        result["failures"].append("luminance x%.2f > x%.2f" % (lum_ratio, 1.0 + LUMINANCE_MARGIN))
    if props > PROPS_MAX:
        result["failures"].append("props %.3f > %.3f" % (props, PROPS_MAX))
    write_overlay(image, tmpl, estimated, blobs, os.path.join(OUT_DIR, name + "_check.png"))
    result["overlay"] = os.path.join(OUT_DIR, name + "_check.png")
    return result


def write_overlay(image, tmpl, estimated, blobs, out_path):
    base = image.convert("RGB").resize((tmpl.shape[1] * 2, tmpl.shape[0] * 2), Image.BILINEAR)
    pixels = np.asarray(base, dtype=np.float32)
    def up(mask):
        return np.repeat(np.repeat(mask, 2, axis=0), 2, axis=1)
    edge = up(tmpl & ~floor.erode(tmpl, 1))
    est = up(estimated & ~floor.erode(estimated, 1))
    pixels[up(estimated)] = pixels[up(estimated)] * 0.8 + np.array([243, 168, 71]) * 0.2
    pixels[est] = [243, 168, 71]
    pixels[up(blobs)] = [177, 76, 217]
    pixels[edge] = [98, 232, 242]
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    Image.fromarray(pixels.clip(0, 255).astype(np.uint8)).save(out_path)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("images", nargs="+")
    parser.add_argument("--sheet", help="also write a contact sheet of every overlay")
    args = parser.parse_args()
    template = load_template()
    reference_lum = reference_luminance(template)
    results = []
    for path in args.images:
        result = check(path, template, reference_lum)
        results.append(result)
        status = "PASS" if not result["failures"] else "FAIL"
        if "coverage" in result:
            print("%s %-34s coverage %.3f  rim %.3f  overflow %.3f  luminance x%.2f  props %.3f  %s" % (
                status, result["name"], result["coverage"], result["rim"], result["overflow"],
                result["luminance"], result["props"], "; ".join(result["failures"] + result["warnings"])))
        else:
            print("%s %-38s %s" % (status, result["name"], "; ".join(result["failures"])))
    if args.sheet:
        overlays = [Image.open(r["overlay"]) for r in results if "overlay" in r]
        if overlays:
            tile_w, tile_h = 188, 334
            columns = 10
            rows = (len(overlays) + columns - 1) // columns
            sheet = Image.new("RGB", (columns * tile_w, rows * tile_h), (20, 20, 20))
            for index, overlay in enumerate(overlays):
                sheet.paste(overlay.resize((tile_w, tile_h)), ((index % columns) * tile_w, (index // columns) * tile_h))
            sheet.save(args.sheet)
    failed = [r["name"] for r in results if r["failures"]]
    print("\n%d checked, %d failed%s" % (len(results), len(failed), (": " + ", ".join(failed)) if failed else ""))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
