#!/usr/bin/env python3
"""Extract the Endless arena skins into runtime art (spec story_and_endless/05, ADR-0014).

Usage (repo root):
  python3 tools/art/extract_endless.py            # every skin in the manifest
  python3 tools/art/extract_endless.py drowned_sanctum aurora_throne

Reads concept_art/wisp_rush_endless_v1/assets/skins_manifest.json and writes
assets/art/environment/endless/<skin_id>.png (941x1672 RGB) plus a Shop card thumbnail
assets/art/environment/endless/thumbnails/<skin_id>.png (THUMB_SCALE of the runtime art), so the
Shop never loads thirty full-size backgrounds. Never hand-edit the outputs: change
FLOOR_ADJUST below (or the source art) and re-run, then tools/validate.sh.

FLOOR_ADJUST applies a per-skin floor dim (value multiplier) and saturation multiplier through a
feathered mask of the frozen floor template (not ARENA_FLOOR_UV), so the Wisp stays the brightest
small object. Every skin passed tools/art/check_endless_skin.py's luminance limit (floor at most
x0.91 of Obsidian Garden's) on 2026-09-15, so the table starts empty.
"""

import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SOURCE_DIR = "concept_art/wisp_rush_endless_v1/assets"
MANIFEST = os.path.join(SOURCE_DIR, "skins_manifest.json")
TEMPLATE_JSON = "concept_art/wisp_rush_endless_v1/floor_template.json"
OUT_DIR = "assets/art/environment/endless"
THUMB_DIR = os.path.join(OUT_DIR, "thumbnails")
# Shop thumbnails: 282x502, enough for the ARENAS card at every QA phone size.
THUMB_SCALE = 0.3
CANVAS = (941, 1672)
# Feather of the template mask, in source px, so an adjustment never draws a hard line at the rim.
FEATHER_PX = 10
# skin_id -> (floor value multiplier, floor saturation multiplier).
FLOOR_ADJUST = {}


def template_mask(template):
    mask = Image.new("L", CANVAS, 0)
    points = [(u * CANVAS[0], v * CANVAS[1]) for u, v in template["polygon_uv"]]
    ImageDraw.Draw(mask).polygon(points, fill=255)
    return np.asarray(mask.filter(ImageFilter.GaussianBlur(FEATHER_PX)), dtype=np.float32) / 255.0


def adjust_floor(image, mask, value, saturation):
    hsv = np.asarray(image.convert("HSV"), dtype=np.float32)
    hsv[:, :, 1] *= 1.0 + (saturation - 1.0) * mask
    hsv[:, :, 2] *= 1.0 + (value - 1.0) * mask
    return Image.fromarray(hsv.clip(0, 255).astype(np.uint8), "HSV").convert("RGB")


def main(argv):
    with open(MANIFEST) as handle:
        manifest = json.load(handle)
    with open(TEMPLATE_JSON) as handle:
        template = json.load(handle)
    wanted = set(argv)
    mask = template_mask(template) if FLOOR_ADJUST else None
    os.makedirs(THUMB_DIR, exist_ok=True)
    written = 0
    for entry in manifest:
        skin_id = entry["skin_id"]
        if wanted and skin_id not in wanted:
            continue
        image = Image.open(os.path.join(SOURCE_DIR, entry["filename"]))
        if image.size != CANVAS:
            print("SKIP %s: %sx%s, need 941x1672" % (skin_id, image.size[0], image.size[1]))
            continue
        image = image.convert("RGB")
        if skin_id in FLOOR_ADJUST:
            image = adjust_floor(image, mask, *FLOOR_ADJUST[skin_id])
        image.save(os.path.join(OUT_DIR, skin_id + ".png"), optimize=True)
        thumb_size = (round(CANVAS[0] * THUMB_SCALE), round(CANVAS[1] * THUMB_SCALE))
        image.resize(thumb_size, Image.LANCZOS).save(
            os.path.join(THUMB_DIR, skin_id + ".png"), optimize=True
        )
        written += 1
    print("extract_endless: wrote %d skin(s) to %s" % (written, OUT_DIR))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
