#!/usr/bin/env python3
"""Build the runtime UI textures from the pixel-art kit concept_art/wisp_rush_pixel_ui_v1/.

Run from the repo root (Python 3.8+, Pillow, numpy):
    python assets/ui/theme/tools/build_theme_textures.py [--preview]
then import in Godot and rebuild the theme:
    "$GODOT" --headless --path . --import
    "$GODOT" --headless --path . --script res://assets/ui/theme/tools/build_wisp_theme.gd

Deterministic: the same kit always gives byte-identical PNGs and slices.json. The kit is read-only
here. Outputs (never hand-edit them):
  assets/ui/theme/textures/<name>.png  pieces the Theme uses (frames, bars, focus rings, grabbers)
  assets/ui/theme/icons/<name>.png     standalone sprites scenes use (glyphs, health, page diamonds,
                                       edge ornaments)
  assets/ui/theme/textures/slices.json per piece: size, nine-patch margins, kit content inset and,
                                       for panels, where the frame's top/bottom edge band sits
The Godot step wraps every PNG in a CanvasTexture .tres with nearest filtering, so the UI stays
crisp without touching the project-wide filter (the character sprites are filtered separately).

Why margins can differ from the kit manifest: with nearest filtering a nine-patch must only stretch
rows/columns that are identical, or ornaments smear into long bars. The manifest band is kept when
it is uniform; otherwise the band moves to the uniform run nearest the centre (preferring the run
below / right of a centred ornament), so corner stitches and side studs keep their native size and
their native distance from the top-left. Pieces drawn at native size are therefore exact copies of
the kit; taller pieces get longer straight walls. The divider's centre gem is healed out (a rule is
stretched across whole panels, so a centred gem cannot survive a one-band nine-patch). Focus rings
are the kit's focus art minus its normal art, drawn by Godot over whatever state the control is in.
The captioned tiles lose the seam above their caption (owner, 2026-10-05; `erase_seam`).
"""
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
KIT = os.path.join(ROOT, "concept_art", "wisp_rush_pixel_ui_v1")
OUT_TEX = os.path.join(ROOT, "assets", "ui", "theme", "textures")
OUT_ICON = os.path.join(ROOT, "assets", "ui", "theme", "icons")
LOG = os.path.join(ROOT, "logs", "pixel_ui")
GRID = 4

# Theme pieces copied from the kit (nine-patch margins derived below).
THEME_PIECES = [
    "button_primary_normal", "button_primary_hover", "button_primary_pressed",
    "button_primary_disabled",
    "button_secondary_normal", "button_secondary_hover", "button_secondary_pressed",
    "button_secondary_disabled",
    "button_danger_normal", "button_danger_pressed",
    "icon_tile_normal", "icon_tile_disabled",
    "caption_tile_normal", "caption_tile_disabled",
    "panel_default", "panel_card", "panel_card_selected", "panel_card_locked", "panel_crest",
    "panel_banner", "plate_small", "hud_alert_plate",
    "slot_normal", "slot_selected", "slot_disabled",
    "tab_normal", "tab_active", "nav_dock",
    "progress_track", "progress_fill_xp", "progress_fill_boss",
    "hud_slim_track", "hud_slim_fill_xp", "hud_slim_fill_rush",
    "divider",
    "slider_grabber_idle", "slider_grabber_active", "slider_grabber_disabled",
    "portrait_ring",
]
# Pieces whose stretch band is flattened to its dominant column (centred ornaments removed).
HEAL_H = {"divider"}
# Vertical stretch rows [start, end) for pieces with a side stud or rune at mid-height: the plain wall
# row just below the ornament group, so the ornament keeps its native distance from the top edge.
# (Pressed art is drawn 4 px lower, hence its +4.) Other pieces use the automatic choice below.
BAND_V = {
    "button_primary_normal": (76, 80), "button_primary_hover": (76, 80),
    "button_primary_pressed": (80, 84), "button_primary_disabled": (76, 80),
    "button_primary_focus_ring": (76, 80),
    "button_secondary_normal": (60, 64), "button_secondary_hover": (60, 64),
    "button_secondary_pressed": (64, 68), "button_secondary_disabled": (60, 64),
    "button_secondary_focus_ring": (60, 64),
    "button_danger_normal": (60, 64), "button_danger_pressed": (64, 68),
    "icon_tile_normal": (76, 80), "icon_tile_disabled": (76, 80), "icon_tile_focus_ring": (76, 80),
    "plate_small": (40, 44), "hud_alert_plate": (40, 44),
    "tab_normal": (40, 44), "tab_active": (40, 44),
    "panel_card_selected": (140, 188), "panel_crest": (168, 244), "panel_banner": (64, 68),
    "nav_dock": (56, 60),
}
# Drawn only at native height: no vertical stretch band.
NO_BAND_V = {"divider"}
# name: (focus art, normal art). The ring = pixels where the two differ.
FOCUS_RINGS = {
    "button_primary_focus_ring": ("button_primary_focus", "button_primary_normal"),
    "button_secondary_focus_ring": ("button_secondary_focus", "button_secondary_normal"),
    "icon_tile_focus_ring": ("icon_tile_focus", "icon_tile_normal"),
    "caption_tile_focus_ring": ("caption_tile_focus", "caption_tile_normal"),
}
# Standalone sprites for scenes and scripts (kit glyphs with a game user, health, page diamonds and
# the edge ornaments the ornament scenes draw).
ICONS = [
    "icon_play", "icon_pause", "icon_home", "icon_lock", "icon_settings", "icon_shop",
    "icon_trials", "icon_daily", "icon_stats", "icon_currency",
    "hud_health_full",
    "page_diamond_idle", "page_diamond_active", "page_diamond_locked",
    "ornament_diamond_cyan", "ornament_diamond_warm",
]
# Panels whose top/bottom edge band is measured for the ornament scenes.
EDGE_PIECES = ["panel_default", "panel_card", "panel_crest", "panel_banner"]
# Home's captioned tiles have no seam above the caption (owner, 2026-10-05): the kit's seam rows
# are replaced by the plain interior, in every state the tiles are built from.
SEAMLESS = {"caption_tile_normal", "caption_tile_disabled", "caption_tile_focus"}


def load_manifest():
    with open(os.path.join(KIT, "components.json"), encoding="utf8") as f:
        data = json.load(f)
    return {os.path.splitext(os.path.basename(c["file"]))[0]: c for c in data["components"]}


def load(name):
    a = np.asarray(Image.open(os.path.join(KIT, "components", name + ".png")).convert("RGBA"))
    return erase_seam(a) if name in SEAMLESS else a


def erase_seam(a):
    """Replace the first band of rows below the middle that differs from the middle row (the seam
    and its diamond above a captioned tile's caption) by the plain middle row."""
    h = a.shape[0]
    ref = a[h // 2]
    y = h // 2
    while y < h and np.array_equal(a[y], ref):
        y += 1
    top = y
    while y < h and not np.array_equal(a[y], ref):
        y += 1
    if y >= h:
        raise SystemExit("seam not followed by a plain row; refusing to erase the bottom frame")
    out = a.copy()
    out[top:y] = ref
    return out


def save(a, folder, name):
    Image.fromarray(np.ascontiguousarray(a), "RGBA").save(os.path.join(folder, name + ".png"),
                                                          optimize=True)


def same_as_next(a, axis):
    """Bool per column (axis=1) or row (axis=0): identical to the following one."""
    if axis == 1:
        return np.all(a[:, :-1] == a[:, 1:], axis=(0, 2))
    return np.all(a[:-1] == a[1:], axis=(1, 2))


def uniform(a, axis, start, end):
    if end - start <= 1:
        return True
    return bool(same_as_next(a, axis)[start:end - 1].all())


def uniform_runs(a, axis, lo, hi):
    """Maximal runs [s, e) of identical columns/rows inside [lo, hi), each at least one grid cell."""
    eq = same_as_next(a, axis)
    runs = []
    s = lo
    for i in range(lo, hi):
        if i == hi - 1 or not eq[i]:
            if i + 1 - s >= GRID:
                runs.append((s, i + 1))
            s = i + 1
    return runs


def choose_band(a, axis, near, far):
    """Nine-patch margins (near, far) along one axis whose stretch band is uniform.

    Keeps the manifest band when it is uniform; otherwise takes the longest run of identical
    rows/columns (at least two grid cells, so a single row through an ornament never qualifies),
    ties going to the run nearest the centre.
    """
    n = a.shape[1] if axis == 1 else a.shape[0]
    if uniform(a, axis, near, n - far):
        return near, far, False
    alpha = a[..., 3] > 0
    filled = np.nonzero(alpha.any(axis=0 if axis == 1 else 1))[0]
    lo, hi = int(filled[0]) + GRID, int(filled[-1]) + 1 - GRID
    runs = [r for r in uniform_runs(a, axis, lo, hi) if r[1] - r[0] >= 2 * GRID]
    if not runs:
        raise SystemExit("no uniform %s band" % ("column" if axis == 1 else "row"))
    centre = n / 2.0
    s, e = min(runs, key=lambda r: (-(r[1] - r[0]), abs((r[0] + r[1]) / 2.0 - centre)))
    if e - s >= 3 * GRID:  # sample safely inside identical texels at the band edges
        s, e = s + GRID, e - GRID
    return s, n - e, True


def vertical_band(a, name, top, bottom):
    """Vertical margins: an explicit BAND_V entry, none for NO_BAND_V, else choose_band."""
    h = a.shape[0]
    if name in NO_BAND_V:
        return h // 2, h - h // 2, True
    if name in BAND_V:
        s, e = BAND_V[name]
        if not uniform(a, 0, s, e):
            raise SystemExit("%s: BAND_V rows %d-%d are not identical" % (name, s, e))
        return s, h - e, (s, h - e) != (top, bottom)
    return choose_band(a, 0, top, bottom)


def heal_band(a, near, far):
    """Replace every column of the horizontal band by its most common column."""
    w = a.shape[1]
    cols = [a[:, x].tobytes() for x in range(near, w - far)]
    best = max(set(cols), key=cols.count)
    ref = a[:, near + cols.index(best)].copy()
    out = a.copy()
    out[:, near:w - far] = ref[:, None, :]
    return out


def edge_bands(a):
    """Top/bottom frame band centres at the middle column (for edge ornaments)."""
    h, w = a.shape[:2]
    cx, cy = w // 2, h // 2
    col = a[:, cx]
    interior = col[cy]
    opaque = np.nonzero(col[:, 3] > 0)[0]
    y0, y1 = int(opaque[0]), int(opaque[-1]) + 1
    same = np.all(col == interior, axis=1)
    top = cy
    while top > y0 and same[top - 1]:
        top -= 1
    bottom = cy
    while bottom < y1 and same[bottom]:
        bottom += 1
    return {"top_band": [y0, top], "bottom_band": [bottom, y1]}


def check_grid(a, name):
    """Every visible pixel must sit in a uniform 4x4 block (the kit's contract)."""
    h, w = a.shape[:2]
    if h % GRID or w % GRID:
        raise SystemExit("%s: %dx%d is off the %d px grid" % (name, w, h, GRID))
    blocks = a.reshape(h // GRID, GRID, w // GRID, GRID, 4)
    if not (blocks == blocks[:, :1, :, :1]).all():
        raise SystemExit("%s: pixels are not whole %d px blocks" % (name, GRID))


def build_piece(name, entry, report):
    a = load(name)
    check_grid(a, name)
    h, w = a.shape[:2]
    info = {"size": [w, h], "source": entry["file"]}
    ns = entry.get("nine_slice_px")
    if ns:
        l, t, r, b = ns
        if name in HEAL_H:
            a = heal_band(a, l, r)
            info["healed"] = True
        l, r, moved_h = choose_band(a, 1, l, r)
        t, b, moved_v = vertical_band(a, name, t, b)
        info["margins"] = [l, t, r, b]
        if moved_h or moved_v:
            info["manifest_margins"] = list(ns)
        assert uniform(a, 1, l, w - r), name
    else:
        info["margins"] = [0, 0, 0, 0]
    if entry.get("content_inset_px"):
        info["content"] = list(entry["content_inset_px"])
    if name in EDGE_PIECES:
        info.update(edge_bands(a))
    save(a, OUT_TEX, name)
    report[name] = info


def build_ring(name, focus, normal, manifest, report):
    f = load(focus)
    n = load(normal)
    diff = np.any(f != n, axis=2)
    ring = np.where(diff[..., None], f, 0).astype(np.uint8)
    check_grid(ring, name)
    h, w = ring.shape[:2]
    ns = manifest[normal].get("nine_slice_px")
    info = {"size": [w, h], "source": manifest[focus]["file"] + " minus " + manifest[normal]["file"]}
    if ns:
        l, r, _ = choose_band(ring, 1, ns[0], ns[2])
        t, b, _ = vertical_band(ring, name, ns[1], ns[3])
        info["margins"] = [l, t, r, b]
    else:
        info["margins"] = [0, 0, 0, 0]
    save(ring, OUT_TEX, name)
    report[name] = info


def clean(folder, keep):
    """Remove outputs of earlier runs that this run no longer produces (and their .import files)."""
    for f in sorted(os.listdir(folder)):
        base, ext = os.path.splitext(f)
        if ext == ".import":
            base, ext = os.path.splitext(base)
        if ext in (".png", ".tres") and base not in keep:
            os.remove(os.path.join(folder, f))


def nine_patch(img, m, size):
    """Nearest nine-patch stretch, like Godot draws it (for the preview sheet only)."""
    h, w = img.shape[:2]
    l, t, r, b = m
    W, H = size
    xs = np.concatenate([np.arange(l), np.linspace(l, w - r - 1e-3, max(0, W - l - r)).astype(int),
                         np.arange(w - r, w)])
    ys = np.concatenate([np.arange(t), np.linspace(t, h - b - 1e-3, max(0, H - t - b)).astype(int),
                         np.arange(h - b, h)])
    return img[ys][:, xs]


def preview(report):
    """Native piece + a 2.5x-wide, 1.6x-tall nine-patch stretch of it, on one sheet."""
    from PIL import ImageDraw
    rows = []
    for name, info in report.items():
        img = np.asarray(Image.open(os.path.join(OUT_TEX, name + ".png")).convert("RGBA"))
        w, h = info["size"]
        big = nine_patch(img, info["margins"], (int(w * 2.5), int(h * 1.6)))
        rows.append((name, img, big))
    W = 1400
    H = sum(max(n.shape[0], b.shape[0]) + 24 for _, n, b in rows) + 20
    sheet = Image.new("RGBA", (W, H), (21, 30, 36, 255))
    d = ImageDraw.Draw(sheet)
    y = 10
    for name, native, big in rows:
        d.text((10, y), name, fill=(232, 202, 160, 255))
        sheet.alpha_composite(Image.fromarray(native), (10, y + 14))
        sheet.alpha_composite(Image.fromarray(big), (40 + native.shape[1], y + 14))
        y += max(native.shape[0], big.shape[0]) + 24
    os.makedirs(LOG, exist_ok=True)
    sheet.save(os.path.join(LOG, "theme_textures_preview.png"))


def main():
    manifest = load_manifest()
    os.makedirs(OUT_TEX, exist_ok=True)
    os.makedirs(OUT_ICON, exist_ok=True)
    report = {}
    for name in THEME_PIECES:
        build_piece(name, manifest[name], report)
    for name, (focus, normal) in FOCUS_RINGS.items():
        build_ring(name, focus, normal, manifest, report)
    for name in ICONS:
        a = load(name)
        check_grid(a, name)
        save(a, OUT_ICON, name)
    clean(OUT_TEX, set(report))
    clean(OUT_ICON, set(ICONS))
    with open(os.path.join(OUT_TEX, "slices.json"), "w", encoding="utf8", newline="\n") as f:
        json.dump(report, f, indent=1, sort_keys=True)
        f.write("\n")
    for name in sorted(report):
        info = report[name]
        moved = " (manifest %s)" % info["manifest_margins"] if "manifest_margins" in info else ""
        print("%-28s %-10s margins %s%s" % (name, "x".join(map(str, info["size"])),
                                            info["margins"], moved))
    print("%d theme pieces, %d icons" % (len(report), len(ICONS)))
    if "--preview" in sys.argv:
        preview(report)


if __name__ == "__main__":
    main()
