#!/usr/bin/env python3
"""Derive each Rift's playable floor polygon from its final runtime background.

The playfield used to be one shared rectangle (GameWorld.ARENA_FLOOR_UV, ADR-0006), which was
honest for the rectangular arenas and wrong for the oval ones: in Ember Hollow and Frozen Choir the
rectangle's corners sit in the lava and on the ice pillars, so the Wisp bounced off an invisible
wall visibly inside the painted edge.

This reads the **final runtime** background for every Rift - after extract_rifts.py has applied its
floor dimming and saturation changes, because that is what the player actually sees - estimates the
walkable floor, and writes a near-convex polygon in texture UV space into each Rift's .tres.

Run from the repo root:  python3 tools/art/extract_floor_polygons.py
Then re-import:          tools/validate.sh
Never hand-edit the baked polygons; change this file and re-run.

Requires Pillow and numpy only (no scipy): morphology goes through PIL rank filters and the local
variance through an integral image.
"""

import io
import json
import os
import sys
from collections import deque

import numpy as np
from PIL import Image, ImageFilter

# rift id -> its runtime background, relative to the repo root.
RIFTS = [
    ("obsidian_garden", "assets/art/environment/wisp_rush_arena_background.png"),
    ("shattered_rift", "assets/art/environment/rifts/shattered_background.png"),
    ("ember_hollow", "assets/art/environment/rifts/ember_hollow_background.png"),
    ("frozen_choir", "assets/art/environment/rifts/frozen_choir_background.png"),
    ("reapers_court", "assets/art/environment/rifts/reapers_court_background.png"),
]

OUT_DIR = "logs/rifts"
DATA_DIR = "data/rifts"

# Working resolution for the mask. Small enough to be quick, large enough to keep the floor edge.
WORK_WIDTH = 236
# Vertices in the baked polygon. 24 keeps an oval smooth while staying cheap to ray-cast.
VERTICES = 24
# Box radius (working pixels) for the local-variance estimate.
VARIANCE_RADIUS = 3
# Floor-likeness is scored, not threshold-ANDed. Two cues only: the floor is SMOOTH (perimeter
# scenery is high-frequency) and DESATURATED (lava, rift magenta and drapes are not). Luminance is
# deliberately NOT a cue - Frozen Choir's floor is pale ice while every other arena's is dark stone,
# so any brightness rule excludes one of them.
SMOOTHNESS_WEIGHT = 0.62
DESATURATION_WEIGHT = 0.38
# Keep the pixels scoring above this percentile.
FLOOR_PERCENTILE = 54.0
# Blur radius applied to the variance field, so speckle does not fragment the mask.
VARIANCE_SMOOTH_RADIUS = 2
# Closing passes applied before anything else. The floor is painted with interior detail - rune
# circles, cracks, rubble - which must not read as holes, or a ray from the centroid stops on the
# first crack it meets and the polygon collapses to a few percent of the arena.
CLOSING_PASSES = 4
# Erosion passes on the mask, so the polygon sits inside the painted floor rather than on its lip.
EROSION_PASSES = 3
# Each radius is pulled in by this much, leaving room for the Wisp's sprite at the wall.
RADIUS_SAFETY = 0.955
# A ray stops at the first run of this many consecutive non-floor working pixels.
BREAK_RUN = 2
# Edge midpoints are validated against the mask; adjacent radii shrink by this much per attempt.
MIDPOINT_SHRINK = 0.94
MIDPOINT_PASSES = 6
# No radius may collapse below this fraction of the image half-diagonal.
MIN_RADIUS_FRACTION = 0.06
# The polygon's top is clipped to this V. The old shared rectangle started at 0.255 partly to keep
# the resting Wisp out from behind the HUD header (ADR-0006), and four of the five painted floors
# reach well above that - frozen_choir as high as 0.124. Losing that clearance would re-open the
# exact bug ADR-0006 closed, so the bake enforces it rather than trusting the paintings.
MIN_FLOOR_V = 0.255
# Radial sampling produces occasional single-ray spikes where one direction happens to find a
# corridor of floor-coloured pixels through the scenery. Any radius more than this multiple of its
# neighbours' median is pulled back to that limit, which kills spikes without reshaping the arena.
SPIKE_LIMIT = 1.18
SPIKE_WINDOW = 5
SPIKE_PASSES = 3


def box_mean(values, radius):
    """Mean over a (2*radius+1) square, via an integral image. Edges clamp to the available area."""
    height, width = values.shape
    padded = np.zeros((height + 1, width + 1), dtype=np.float64)
    padded[1:, 1:] = values.cumsum(axis=0).cumsum(axis=1)
    ys = np.arange(height)
    xs = np.arange(width)
    y0 = np.clip(ys - radius, 0, height)[:, None]
    y1 = np.clip(ys + radius + 1, 0, height)[:, None]
    x0 = np.clip(xs - radius, 0, width)[None, :]
    x1 = np.clip(xs + radius + 1, 0, width)[None, :]
    total = padded[y1, x1] - padded[y0, x1] - padded[y1, x0] + padded[y0, x0]
    count = (y1 - y0) * (x1 - x0)
    return total / np.maximum(count, 1)


def normalise(values):
    """Scale to 0..1 against the 5th-95th percentile, so outliers cannot flatten the field."""
    low = np.percentile(values, 5.0)
    high = np.percentile(values, 95.0)
    if high - low < 1e-6:
        return np.zeros_like(values)
    return np.clip((values - low) / (high - low), 0.0, 1.0)


def floor_mask(image):
    """Boolean mask of the walkable floor at working resolution."""
    width = WORK_WIDTH
    height = max(1, int(round(image.height * (width / float(image.width)))))
    small = image.convert("RGB").resize((width, height), Image.BILINEAR)
    pixels = np.asarray(small, dtype=np.float32) / 255.0

    luminance = pixels.mean(axis=2)
    channel_max = pixels.max(axis=2)
    channel_min = pixels.min(axis=2)
    saturation = np.where(
        channel_max > 1e-5, (channel_max - channel_min) / np.maximum(channel_max, 1e-5), 0.0
    )

    # Local variance marks high-frequency scenery: pillars, lava channels, ice shards, foliage.
    mean = box_mean(luminance, VARIANCE_RADIUS)
    mean_square = box_mean(luminance * luminance, VARIANCE_RADIUS)
    variance = np.maximum(mean_square - mean * mean, 0.0)
    variance = box_mean(variance, VARIANCE_SMOOTH_RADIUS)

    score = (
        SMOOTHNESS_WEIGHT * (1.0 - normalise(variance))
        + DESATURATION_WEIGHT * (1.0 - normalise(saturation))
    )
    mask = score >= np.percentile(score, FLOOR_PERCENTILE)
    mask = close(mask, CLOSING_PASSES)
    mask = keep_largest_component(mask)
    mask = fill_holes(mask)
    mask = erode(mask, EROSION_PASSES)
    # Erosion can split the region; re-select so a stray island never wins.
    mask = keep_largest_component(mask)
    return mask


def erode(mask, passes):
    """Shrink the mask by `passes` pixels using PIL's rank filter."""
    return _rank(mask, passes, ImageFilter.MinFilter(3))


def dilate(mask, passes):
    """Grow the mask by `passes` pixels."""
    return _rank(mask, passes, ImageFilter.MaxFilter(3))


def close(mask, passes):
    """Dilate then erode, bridging cracks and swallowing interior detail."""
    return erode(dilate(mask, passes), passes)


def _rank(mask, passes, rank_filter):
    if passes <= 0:
        return mask
    image = Image.fromarray((mask * 255).astype(np.uint8), mode="L")
    for _ in range(passes):
        image = image.filter(rank_filter)
    return np.asarray(image) > 127


def fill_holes(mask):
    """Fill any background region not connected to the image border.

    Closing bridges narrow cracks; this finishes the job for genuinely enclosed detail such as
    Obsidian Garden's central rune, which sits well inside the floor and is not floor-coloured.
    """
    height, width = mask.shape
    outside = np.zeros_like(mask, dtype=bool)
    queue = deque()
    for x in range(width):
        for y in (0, height - 1):
            if not mask[y, x] and not outside[y, x]:
                outside[y, x] = True
                queue.append((y, x))
    for y in range(height):
        for x in (0, width - 1):
            if not mask[y, x] and not outside[y, x]:
                outside[y, x] = True
                queue.append((y, x))
    while queue:
        y, x = queue.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if (
                0 <= ny < height and 0 <= nx < width
                and not mask[ny, nx] and not outside[ny, nx]
            ):
                outside[ny, nx] = True
                queue.append((ny, nx))
    return mask | ~outside


def keep_largest_component(mask):
    """Keep only the largest connected region.

    Seeding from the image centre is wrong: Obsidian Garden paints a high-frequency rune circle
    dead centre, so the centre pixel scores as scenery and the flood fill lands on a speck. The
    floor is reliably the largest smooth region in every arena, so pick by area instead.
    """
    height, width = mask.shape
    seen = np.zeros_like(mask, dtype=bool)
    best_size = 0
    best_component = None
    for start_y in range(height):
        for start_x in range(width):
            if not mask[start_y, start_x] or seen[start_y, start_x]:
                continue
            component = []
            queue = deque([(start_y, start_x)])
            seen[start_y, start_x] = True
            while queue:
                y, x = queue.popleft()
                component.append((y, x))
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    ny, nx = y + dy, x + dx
                    if (
                        0 <= ny < height and 0 <= nx < width
                        and mask[ny, nx] and not seen[ny, nx]
                    ):
                        seen[ny, nx] = True
                        queue.append((ny, nx))
            if len(component) > best_size:
                best_size = len(component)
                best_component = component
    result = np.zeros_like(mask, dtype=bool)
    if best_component is not None:
        ys = np.fromiter((p[0] for p in best_component), dtype=np.int32, count=best_size)
        xs = np.fromiter((p[1] for p in best_component), dtype=np.int32, count=best_size)
        result[ys, xs] = True
    return result


def nearest_true(mask, y, x):
    """Nearest set pixel to (y, x), searched in expanding rings. None when the mask is empty."""
    height, width = mask.shape
    if mask[y, x]:
        return (y, x)
    for radius in range(1, max(height, width)):
        y0, y1 = max(0, y - radius), min(height - 1, y + radius)
        x0, x1 = max(0, x - radius), min(width - 1, x + radius)
        window = mask[y0:y1 + 1, x0:x1 + 1]
        if not window.any():
            continue
        ys, xs = np.nonzero(window)
        best = np.argmin((ys + y0 - y) ** 2 + (xs + x0 - x) ** 2)
        return (int(ys[best] + y0), int(xs[best] + x0))
    return None


def inside(mask, x, y):
    """Whether a working-space point lies on the floor."""
    height, width = mask.shape
    ix, iy = int(round(x)), int(round(y))
    if ix < 0 or iy < 0 or ix >= width or iy >= height:
        return False
    return bool(mask[iy, ix])


def ray_limit(mask, origin, angle, max_radius):
    """Farthest radius along `angle` still on the floor, stopping at the first real gap."""
    import math
    dx, dy = math.cos(angle), math.sin(angle)
    last_good = 0.0
    run = 0
    step = 0.5
    radius = step
    while radius <= max_radius:
        if inside(mask, origin[0] + dx * radius, origin[1] + dy * radius):
            last_good = radius
            run = 0
        else:
            run += 1
            # A single stray pixel should not truncate the ray; a real edge will persist.
            if run >= BREAK_RUN / step:
                break
        radius += step
    return last_good


def build_polygon(mask):
    """Near-convex polygon inside the mask, as working-space points."""
    import math
    height, width = mask.shape
    ys, xs = np.nonzero(mask)
    if len(xs) == 0:
        return []
    origin = (float(xs.mean()), float(ys.mean()))
    max_radius = math.hypot(width, height)
    min_radius = max_radius * MIN_RADIUS_FRACTION

    radii = []
    for index in range(VERTICES):
        angle = 2.0 * math.pi * index / VERTICES
        radii.append(max(min_radius, ray_limit(mask, origin, angle, max_radius) * RADIUS_SAFETY))

    radii = suppress_spikes(radii)

    # Vertices are guaranteed on the floor, but an edge between two of them can still cut a corner
    # on a concave arena. Pull the offending pair in until the midpoint is on the floor too.
    for _ in range(MIDPOINT_PASSES):
        adjusted = False
        for index in range(VERTICES):
            nxt = (index + 1) % VERTICES
            a = polar(origin, 2.0 * math.pi * index / VERTICES, radii[index])
            b = polar(origin, 2.0 * math.pi * nxt / VERTICES, radii[nxt])
            mid = ((a[0] + b[0]) * 0.5, (a[1] + b[1]) * 0.5)
            if not inside(mask, mid[0], mid[1]):
                radii[index] = max(min_radius, radii[index] * MIDPOINT_SHRINK)
                radii[nxt] = max(min_radius, radii[nxt] * MIDPOINT_SHRINK)
                adjusted = True
        if not adjusted:
            break

    return [polar(origin, 2.0 * math.pi * i / VERTICES, radii[i]) for i in range(VERTICES)]


def suppress_spikes(radii):
    """Clamp any radius that overshoots its neighbours, wrapping around the ring."""
    count = len(radii)
    half = SPIKE_WINDOW // 2
    result = list(radii)
    for _ in range(SPIKE_PASSES):
        changed = False
        neighbours_median = []
        for index in range(count):
            window = [
                result[(index + offset) % count]
                for offset in range(-half, half + 1)
                if offset != 0
            ]
            neighbours_median.append(float(np.median(window)))
        for index in range(count):
            limit = neighbours_median[index] * SPIKE_LIMIT
            if result[index] > limit:
                result[index] = limit
                changed = True
        if not changed:
            break
    return result


def polar(origin, angle, radius):
    import math
    return (origin[0] + math.cos(angle) * radius, origin[1] + math.sin(angle) * radius)


def to_uv(points, mask_shape):
    """Working-space points to texture UV space, clamped to the image and to the HUD band."""
    height, width = mask_shape
    return [
        (
            min(1.0, max(0.0, x / float(width))),
            min(1.0, max(MIN_FLOOR_V, y / float(height))),
        )
        for x, y in points
    ]


def polygon_area(points):
    """Absolute shoelace area, in the same units as the points."""
    total = 0.0
    for index in range(len(points)):
        x0, y0 = points[index]
        x1, y1 = points[(index + 1) % len(points)]
        total += x0 * y1 - x1 * y0
    return abs(total) * 0.5


def write_overlay(path, image, polygon_uv, out_path):
    """Debug render: the background with its baked polygon drawn on top."""
    from PIL import ImageDraw
    preview = image.convert("RGB").copy()
    draw = ImageDraw.Draw(preview)
    points = [(u * preview.width, v * preview.height) for u, v in polygon_uv]
    draw.line(points + [points[0]], fill=(255, 70, 70), width=5)
    for x, y in points:
        draw.ellipse([x - 6, y - 6, x + 6, y + 6], fill=(255, 220, 60))
    preview.resize((preview.width // 3, preview.height // 3)).save(out_path)


def bake(rift_id, polygon_uv):
    """Writes `floor_polygon` into a Rift's .tres, replacing any previous value."""
    path = os.path.join(DATA_DIR, "%s.tres" % rift_id)
    if not os.path.isfile(path):
        return False
    with io.open(path, encoding="utf-8") as handle:
        text = handle.read()
    values = ", ".join("%.5f, %.5f" % (u, v) for u, v in polygon_uv)
    line = "floor_polygon = PackedVector2Array(%s)" % values
    lines = [l for l in text.rstrip("\n").splitlines() if not l.startswith("floor_polygon")]
    lines.append(line)
    with io.open(path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")
    return True


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    report = {}
    for rift_id, source in RIFTS:
        if not os.path.isfile(source):
            sys.stderr.write("missing background for %s: %s\n" % (rift_id, source))
            return 1
        image = Image.open(source)
        mask = floor_mask(image)
        points = build_polygon(mask)
        if not points:
            sys.stderr.write("no floor found for %s\n" % rift_id)
            return 1
        polygon_uv = to_uv(points, mask.shape)
        coverage = polygon_area(polygon_uv)
        mask_share = float(mask.sum()) / float(mask.size)
        baked = bake(rift_id, polygon_uv)
        write_overlay(source, image, polygon_uv, os.path.join(OUT_DIR, "floor_%s.png" % rift_id))
        report[rift_id] = {
            "source": source,
            "vertices": len(polygon_uv),
            "polygon_uv_area": round(coverage, 4),
            "mask_share": round(mask_share, 4),
            "baked": baked,
        }
        print("%-16s vertices=%d  uv_area=%.3f  mask_share=%.3f  baked=%s"
              % (rift_id, len(polygon_uv), coverage, mask_share, baked))

    with io.open(os.path.join(OUT_DIR, "floor_polygons.json"), "w", encoding="utf-8") as handle:
        handle.write(json.dumps(report, indent=2, sort_keys=True))
    print("\nOverlays in %s/floor_<rift>.png - review them before trusting the bake." % OUT_DIR)
    return 0


if __name__ == "__main__":
    sys.exit(main())
