#!/usr/bin/env python3
"""Build nine-patch-safe UI theme textures from res://assets/art/ui/frames/*.png.

Run from the repo root (Python 3.7+, Pillow, numpy):
    python3 assets/ui/theme/tools/build_theme_textures.py [--preview]
then import in Godot and rebuild the theme:
    "$GODOT" --headless --path . --import
    "$GODOT" --headless --path . --script res://assets/ui/theme/tools/build_wisp_theme.gd

Why derived textures instead of the raw frame pieces: the frame kit paints ornaments (crest
medallion, diamonds, amber gem, bottom notches) in the middle of edges, exactly where a nine-patch
stretches. Each piece is therefore "spliced": corners are kept untouched, the stretchable middle
of every edge is replaced by a 4 px strip averaged from a plain stretch of that edge, and the
centre ornaments are exported separately (textures/ornament_*.png) for optional overlays. Panel
interiors are flattened to a smooth near-black blue at ~92 % alpha (STYLE_GUIDE: 88-94 %) so
stretched centres never show smeared cracks. Magenta accents are recoloured to steel cyan on
default pieces (magenta is reserved for selection/boss states) and kept on *_selected variants.

Outputs: assets/ui/theme/textures/<name>.png and textures/slices.json with, per texture:
size, margins (nine-patch texture margins l,t,r,b), expand (glow/shadow outside the solid frame),
frame (solid frame size) and inner (frame edge -> flat interior distances), plus ornament offsets.
Sources in concept_art/ and assets/art/ are never modified.
"""
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
SRC = os.path.join(ROOT, "assets", "art", "ui", "frames")
OUT = os.path.join(ROOT, "assets", "ui", "theme", "textures")
LOG = os.path.join(ROOT, "logs", "redesign", "design")

PANEL_FILL = (20, 28, 41)  # Palette.PANEL_BG (near-black blue)
PANEL_ALPHA = 0.92
BAND = 4  # px of averaged plain edge kept as the stretchable strip

HUE_CYAN = (0.42, 0.60)
HUE_MAGENTA = (0.74, 0.97)
H_CYAN = 0.51
H_MAGENTA = 0.786  # #B14CD9
H_AMBER = 0.095  # #F3A847


# ---------------------------------------------------------------- colour helpers

def rgb2hsv(rgb):
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    mx = rgb.max(-1)
    mn = rgb.min(-1)
    d = mx - mn
    ds = np.where(d > 1e-6, d, 1.0)
    h = np.select(
        [d <= 1e-6, mx == r, mx == g],
        [0.0, ((g - b) / ds) % 6.0, (b - r) / ds + 2.0],
        (r - g) / ds + 4.0,
    ) / 6.0
    s = np.where(mx > 1e-6, d / np.where(mx > 1e-6, mx, 1.0), 0.0)
    return h, s, mx


def hsv2rgb(h, s, v):
    i = np.floor(h * 6.0)
    f = h * 6.0 - i
    p = v * (1 - s)
    q = v * (1 - f * s)
    t = v * (1 - (1 - f) * s)
    i = i.astype(int) % 6
    conds = [i == k for k in range(6)]
    r = np.select(conds, [v, q, p, p, t, v])
    g = np.select(conds, [t, v, v, q, p, p])
    b = np.select(conds, [p, p, t, v, v, q])
    return np.stack([r, g, b], -1)


def recolor(a, hue_range, new_hue=None, s_gain=1.0, v_gain=1.0, min_s=0.25, min_v=0.2):
    """Shift/dim pixels whose hue lies in hue_range (straight RGBA float 0..255)."""
    rgb = a[..., :3] / 255.0
    h, s, v = rgb2hsv(rgb)
    sel = (h >= hue_range[0]) & (h <= hue_range[1]) & (s >= min_s) & (v >= min_v) & (a[..., 3] > 0)
    nh = np.where(sel, new_hue if new_hue is not None else h, h)
    ns = np.where(sel, np.clip(s * s_gain, 0, 1), s)
    nv = np.where(sel, np.clip(v * v_gain, 0, 1), v)
    out = a.copy()
    out[..., :3] = hsv2rgb(nh, ns, nv) * 255.0
    return out


def flatten_interior(a, rect, fill, alpha, thresh=85.0):
    """Flood-fill the dark interior from the rect centre and paint it one flat colour.

    fill: (r,g,b) or "avg" (mean of the flooded pixels). Returns (image, interior mask)."""
    x0, y0, x1, y1 = rect
    lum = a[..., :3].mean(-1)
    h, s, v = rgb2hsv(a[..., :3] / 255.0)
    accent = (s > 0.45) & (v > 0.45)
    cand = (a[..., 3] > 200) & (lum < thresh) & ~accent
    bound = np.zeros(cand.shape, bool)
    bound[y0:y1, x0:x1] = True
    cand &= bound
    mask = np.zeros(cand.shape, bool)
    cy, cx = (y0 + y1) // 2, (x0 + x1) // 2
    ys, xs = np.nonzero(cand)
    k = np.argmin((ys - cy) ** 2 + (xs - cx) ** 2)
    mask[ys[k], xs[k]] = True
    while True:
        g = mask.copy()
        g[1:] |= mask[:-1]
        g[:-1] |= mask[1:]
        g[:, 1:] |= mask[:, :-1]
        g[:, :-1] |= mask[:, 1:]
        g &= cand
        if (g == mask).all():
            break
        mask = g
    # close small holes (light cracks) inside the bound
    for _ in range(3):
        d = mask.copy()
        d[1:] |= mask[:-1]
        d[:-1] |= mask[1:]
        d[:, 1:] |= mask[:, :-1]
        d[:, :-1] |= mask[:, 1:]
        mask = d & bound & ~accent & (lum < 110)
    out = a.copy()
    if fill == "avg":
        col = a[mask][:, :3].mean(0)
    else:
        col = np.array(fill, np.float32)
    out[mask, :3] = col
    out[mask, 3] = alpha * 255.0
    return out, mask


# ---------------------------------------------------------------- geometry helpers

def premul(a):
    p = a.copy()
    p[..., :3] *= a[..., 3:4] / 255.0
    return p


def unpremul(p):
    a = p.copy()
    al = p[..., 3:4]
    a[..., :3] = np.where(al > 0.5, p[..., :3] * 255.0 / np.maximum(al, 1e-6), 0.0)
    return a


def splice_x(p, rows):
    """rows: [(y0, y1, left_end, band0, band1, right_start)] covering every row (premultiplied)."""
    H, W = p.shape[:2]
    L = max(r[2] for r in rows)
    R = max(W - r[5] for r in rows)
    out = np.zeros((H, L + BAND + R, 4), np.float32)
    for y0, y1, le, b0, b1, rs in rows:
        seg = p[y0:y1]
        band = seg[:, b0:b1].mean(axis=1, keepdims=True)
        left = np.concatenate([seg[:, :le], np.repeat(band, L - le, 1)], 1)
        right = np.concatenate([np.repeat(band, R - (W - rs), 1), seg[:, rs:]], 1)
        out[y0:y1] = np.concatenate([left, np.repeat(band, BAND, 1), right], 1)
    return out, L, R


def splice_y(p, cols):
    top_end, b0, b1, bottom_start = cols
    t = np.transpose(p, (1, 0, 2))
    W = t.shape[1]
    out, T, B = splice_x(t, [(0, t.shape[0], top_end, b0, b1, bottom_start)])
    return np.transpose(out, (1, 0, 2)), T, B


def bbox(mask):
    ys, xs = np.nonzero(mask)
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def resize(a, s):
    if abs(s - 1.0) < 1e-6:
        return a
    im = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8), "RGBA").convert("RGBa")
    w, h = im.size
    im = im.resize((max(1, round(w * s)), max(1, round(h * s))), Image.LANCZOS)
    return np.asarray(im.convert("RGBA")).astype(np.float32)


def save(a, name):
    Image.fromarray(np.clip(a + 0.5, 0, 255).astype(np.uint8), "RGBA").save(
        os.path.join(OUT, name + ".png"), optimize=True)


def load(name):
    return np.asarray(Image.open(os.path.join(SRC, name + ".png")).convert("RGBA")).astype(np.float32)


# ---------------------------------------------------------------- piece definitions

def styled(src, spec):
    """Recolour + flatten a source piece; returns (straight rgba, interior mask or None)."""
    a = load(src)
    if spec.get("magenta_to_steel"):
        a = recolor(a, HUE_MAGENTA, H_CYAN, 0.55, 0.8)
    for rc in spec.get("recolor", []):
        a = recolor(a, HUE_CYAN, *rc)
    mask = None
    if "interior" in spec:
        it = spec["interior"]
        a, mask = flatten_interior(a, it["rect"], it.get("fill", PANEL_FILL), it.get("alpha", PANEL_ALPHA))
    return a, mask


# Buttons stretch vertically on a row inside the upper chamfer (cols=(30..32) / (58..60) on the
# glowing piece), not through the side diamonds: a taller button gets longer straight sides while
# the tip diamonds keep their shape.
PIECES = {
    # Default PanelContainer: the amber-gem panel with gem and notch removed = the plainest frame.
    "panel_default": dict(src="panel_amber", magenta_to_steel=True,
                          interior=dict(rect=(20, 36, 276, 158)),
                          rows=[(0, 196, 60, 62, 110, 235)], cols=(80, 80, 100, 100)),
    "panel_card": dict(src="panel_card", magenta_to_steel=True,
                       interior=dict(rect=(30, 46, 194, 252)),
                       rows=[(0, 170, 64, 66, 78, 159), (170, 292, 95, 100, 120, 128)],
                       cols=(148, 148, 170, 170)),
    "panel_card_selected": dict(src="panel_card", magenta_to_steel=True,
                                recolor=[(H_MAGENTA, 1.0, 1.05)],
                                interior=dict(rect=(30, 46, 194, 252), fill=(30, 20, 44)),
                                rows=[(0, 170, 64, 66, 78, 159), (170, 292, 95, 100, 120, 128)],
                                cols=(148, 148, 170, 170)),
    "panel_crest": dict(src="panel_crest", magenta_to_steel=True,
                        interior=dict(rect=(54, 74, 340, 346)),
                        rows=[(0, 386, 92, 94, 108, 284)], cols=(228, 230, 248, 250)),
    "panel_banner": dict(src="banner", magenta_to_steel=True, scale=0.62,
                         interior=dict(rect=(40, 64, 378, 162)),
                         rows=[(0, 207, 100, 110, 140, 318)], cols=(84, 84, 94, 94)),
    "plate_small": dict(src="plate", scale=0.65,
                        interior=dict(rect=(36, 24, 260, 86)),
                        rows=[(0, 109, 100, 110, 180, 196)], cols=(50, 50, 56, 56)),
    "slot": dict(src="slot", interior=dict(rect=(26, 26, 200, 199)),
                 rows=[(0, 226, 60, 80, 150, 168)], cols=(62, 70, 110, 162)),
    "slot_selected": dict(src="slot", recolor=[(H_MAGENTA, 1.0, 1.05)],
                          interior=dict(rect=(26, 26, 200, 199), fill=(30, 20, 44)),
                          rows=[(0, 226, 60, 80, 150, 168)], cols=(62, 70, 110, 162)),
    "slot_small": dict(src="slot", scale=0.5, interior=dict(rect=(26, 26, 200, 199)),
                       rows=[(0, 226, 60, 80, 150, 168)], cols=(62, 70, 110, 162)),
    "button_primary": dict(src="button_primary",
                           interior=dict(rect=(44, 28, 290, 98), fill="avg", alpha=0.95),
                           rows=[(0, 125, 62, 100, 230, 274)], cols=(30, 30, 32, 32)),
    "button_primary_pressed": dict(src="button_primary_active", match="button_primary",
                                   interior=dict(rect=(60, 52, 303, 120), fill="avg", alpha=0.95),
                                   rows=[(0, 174, 86, 120, 240, 277)], cols=(58, 58, 60, 60)),
    "button_primary_focus": dict(src="button_primary_active", match="button_primary",
                                 interior=dict(rect=(60, 52, 303, 120), fill=(0, 0, 0), alpha=0.0),
                                 rows=[(0, 174, 86, 120, 240, 277)], cols=(58, 58, 60, 60)),
    "button_focus_small": dict(src="button_primary_active", match="button_primary", scale=0.85,
                               interior=dict(rect=(60, 52, 303, 120), fill=(0, 0, 0), alpha=0.0),
                               rows=[(0, 174, 86, 120, 240, 277)], cols=(58, 58, 60, 60)),
    "button_secondary": dict(src="button_primary", scale=0.85, recolor=[(None, 0.4, 0.62)],
                             interior=dict(rect=(44, 28, 290, 98), fill=(17, 23, 33)),
                             rows=[(0, 125, 62, 100, 230, 274)], cols=(30, 30, 32, 32)),
    "button_secondary_pressed": dict(src="button_primary", scale=0.85,
                                     interior=dict(rect=(44, 28, 290, 98), fill="avg", alpha=0.95),
                                     rows=[(0, 125, 62, 100, 230, 274)], cols=(30, 30, 32, 32)),
    "button_danger": dict(src="button_primary", scale=0.85, recolor=[(H_AMBER, 1.0, 1.0)],
                          interior=dict(rect=(44, 28, 290, 98), fill=(30, 23, 22)),
                          rows=[(0, 125, 62, 100, 230, 274)], cols=(30, 30, 32, 32)),
    "button_danger_pressed": dict(src="button_primary", scale=0.85, recolor=[(H_AMBER, 1.0, 1.2)],
                                  interior=dict(rect=(44, 28, 290, 98), fill=(66, 44, 24), alpha=0.95),
                                  rows=[(0, 125, 62, 100, 230, 274)], cols=(30, 30, 32, 32)),
    "button_disabled": dict(src="button_disabled",
                            interior=dict(rect=(47, 28, 287, 98), fill="avg", alpha=0.9),
                            rows=[(0, 125, 62, 100, 230, 271)], cols=(30, 30, 32, 32)),
    "button_disabled_small": dict(src="button_disabled", scale=0.85,
                                  interior=dict(rect=(47, 28, 287, 98), fill="avg", alpha=0.9),
                                  rows=[(0, 125, 62, 100, 230, 271)], cols=(30, 30, 32, 32)),
    "bar_track": dict(src="bar_track", scale=0.6,
                      interior=dict(rect=(44, 27, 330, 55), fill=(12, 16, 25), alpha=0.95),
                      rows=[(0, 81, 60, 100, 280, 316)], cols=(39, 39, 41, 41)),
    "divider_line": dict(src="divider", scale=0.75, rows=[(0, 73, 45, 60, 110, 274)]),
}

# name: (piece it overlays, source crop x0,y0,x1,y1, edge)
ORNAMENTS = {
    "ornament_crest_top": ("panel_crest", (108, 0, 284, 112), "top"),
    "ornament_crest_bottom": ("panel_crest", (148, 318, 244, 386), "bottom"),
    "ornament_card_top": ("panel_card", (78, 0, 146, 72), "top"),
    "ornament_banner_top": ("panel_banner", (140, 0, 278, 100), "top"),
    "ornament_amber_top": ("panel_default", (118, 0, 177, 62), "top"),
}


def frame_height(src):
    a = load(src)
    x0, y0, x1, y1 = bbox(a[..., 3] >= 250)
    return y1 - y0


def build_piece(name, spec, report):
    a, mask = styled(spec["src"], spec)
    p = premul(a)
    p, L, R = splice_x(p, spec["rows"])
    T, B = 0, 0
    if "cols" in spec:
        p, T, B = splice_y(p, spec["cols"])
    pre_trim = unpremul(p)
    x0, y0, x1, y1 = bbox(pre_trim[..., 3] > 2)
    H, W = pre_trim.shape[:2]
    out = pre_trim[y0:y1, x0:x1]
    m = [L - x0, T - y0 if "cols" in spec else 0, R - (W - x1), B - (H - y1) if "cols" in spec else 0]
    s = spec.get("scale", 1.0)
    if "match" in spec:
        s *= frame_height(spec["match"]) / frame_height(spec["src"])
    out = resize(out, s)
    m = [int(round(v * s)) for v in m]
    if "cols" not in spec:
        m[1] = m[3] = 0
    h, w = out.shape[:2]
    fx0, fy0, fx1, fy1 = bbox(out[..., 3] >= 250)
    entry = dict(size=[w, h], margins=m, expand=[fx0, fy0, w - fx1, h - fy1],
                 frame=[fx1 - fx0, fy1 - fy0], scale=round(s, 4))
    if "interior" in spec:
        fill = spec["interior"].get("fill", PANEL_FILL)
        al = spec["interior"].get("alpha", PANEL_ALPHA)
        if al > 0:
            if fill == "avg":
                # sample the flattened colour at the texture centre
                fill = out[h // 2, w // 2, :3]
            diff = np.abs(out[..., :3] - np.array(fill, np.float32)).max(-1)
            inner = (diff < 6) & (np.abs(out[..., 3] - al * 255) < 8)
        else:
            inner = out[..., 3] < 8
            inner[:, :fx0] = False
            inner[:, fx1:] = False
            inner[:fy0] = False
            inner[fy1:] = False
        # interior extents: walk out from the texture centre along its middle row/column
        cy, cx = h // 2, w // 2
        ix0 = cx
        while ix0 > 0 and inner[cy, ix0 - 1]:
            ix0 -= 1
        ix1 = cx
        while ix1 < w and inner[cy, ix1]:
            ix1 += 1
        iy0 = cy
        while iy0 > 0 and inner[iy0 - 1, cx]:
            iy0 -= 1
        iy1 = cy
        while iy1 < h and inner[iy1, cx]:
            iy1 += 1
        entry["inner"] = [ix0 - fx0, iy0 - fy0, fx1 - ix1, fy1 - iy1]
    save(out, name)
    report[name] = entry
    # keep data for ornaments / bar fill
    frame_top_src = bbox(pre_trim[..., 3] >= 250)[1]
    fb = bbox(pre_trim[..., 3] >= 250)[3]
    cols = spec.get("cols")
    frame_bottom_src = fb - (cols[0] + BAND) + cols[3] if cols else fb
    src_a = a
    mid_rows = src_a[(cols[1] if cols else 0):(cols[2] if cols else src_a.shape[0])]
    sx0, _, sx1, _ = bbox(mid_rows[..., 3] >= 250)
    return dict(styled=a, mask=mask, scale=s, frame_top=frame_top_src,
                frame_bottom=frame_bottom_src, frame_cx=(sx0 + sx1) / 2.0,
                pre_trim=pre_trim, trim=(x0, y0, x1, y1), L=L, R=R, T=T, B=B)


def build_ornament(name, info, crop, edge, report):
    a = info["styled"].copy()
    if info["mask"] is not None:
        a[info["mask"], 3] = 0.0
    x0, y0, x1, y1 = crop
    o = a[y0:y1, x0:x1]
    bx0, by0, bx1, by1 = bbox(o[..., 3] > 2)
    o = o[by0:by1, bx0:bx1]
    ax0, ay0, ax1, ay1 = x0 + bx0, y0 + by0, x0 + bx1, y0 + by1
    s = info["scale"]
    o = resize(o, s)
    h, w = o.shape[:2]
    off_x = ((ax0 + ax1) / 2.0 - info["frame_cx"]) * s
    if edge == "top":
        off_y = (ay0 - info["frame_top"]) * s  # art top relative to frame top
    else:
        off_y = (ay1 - info["frame_bottom"]) * s  # art bottom relative to frame bottom
    save(o, name)
    report[name] = dict(size=[w, h], edge=edge, offset=[round(off_x, 1), round(off_y, 1)])


def build_bar_fill(track, report):
    """Cyan (and magenta boss) fill laid out on the track's canvas so it sits inside the channel."""
    pre = track["pre_trim"]
    tx0, ty0, tx1, ty1 = track["trim"]
    s = track["scale"]
    # channel = flattened interior of the track, in pre-trim coords, minus a dark lip
    col = np.array((12, 16, 25), np.float32)
    ch = (np.abs(pre[..., :3] - col).max(-1) < 6) & (pre[..., 3] > 200)
    H, W = pre.shape[:2]
    my, mx = H // 2, W // 2  # walk out from the centre: the outline also matches the colour
    cx0, cx1, cy0, cy1 = mx, mx, my, my
    while cx0 > 0 and ch[my, cx0 - 1]:
        cx0 -= 1
    while cx1 < W and ch[my, cx1]:
        cx1 += 1
    while cy0 > 0 and ch[cy0 - 1, mx]:
        cy0 -= 1
    while cy1 < H and ch[cy1, mx]:
        cy1 += 1
    cx0, cy0, cx1, cy1 = cx0 + 3, cy0 + 3, cx1 - 3, cy1 - 3
    fill = load("bar_fill")
    fx0, fy0, fx1, fy1 = bbox(fill[..., 3] > 2)
    pill = resize(fill[fy0:fy1, fx0:fx1], (cy1 - cy0) / float(fy1 - fy0))
    ph, pw = pill.shape[:2]
    cap = ph // 2 + 2
    pp, PL, PR = splice_x(premul(pill), [(0, ph, cap, cap + 4, pw - cap - 4, pw - cap)])
    pill = unpremul(pp)
    canvas_w = cx0 + pill.shape[1] + (W - cx1)
    tm = report["bar_track"]["margins"]
    e = report["bar_track"]["expand"]
    for name, hue in (("bar_fill", None), ("bar_fill_boss", H_MAGENTA)):
        pl = pill if hue is None else recolor(pill, HUE_CYAN, hue, 1.0, 1.0, 0.1, 0.1)
        can = np.zeros((H, canvas_w, 4), np.float32)
        can[cy0:cy0 + ph, cx0:cx0 + pl.shape[1]] = pl
        can = resize(can[ty0:ty1, tx0:canvas_w - (W - tx1)], s)
        m = [int(round((cx0 - tx0 + PL) * s)), tm[1], int(round((PR + tx1 - cx1) * s)), tm[3]]
        h, w = can.shape[:2]
        save(can, name)
        report[name] = dict(size=[w, h], margins=m, expand=list(e), scale=round(s, 4),
                            content=[max(0, m[0] - e[0]), 0, max(0, m[2] - e[2]), 0])


def build_diamonds(report):
    """Slider grabbers + a generic diamond ornament cut from the divider's centre gem."""
    a = load("divider")
    crop = a[8:68, 128:190]
    x0, y0, x1, y1 = bbox(crop[..., 3] > 2)
    d = crop[y0:y1, x0:x1]
    save(d, "ornament_diamond")
    report["ornament_diamond"] = dict(size=[d.shape[1], d.shape[0]], edge="top", offset=[0, 0])
    g = resize(d, 1.0)
    variants = {
        "grabber": g,
        "grabber_highlight": recolor(g, (0.0, 1.0), None, 0.55, 1.25, 0.0, 0.0),
        "grabber_disabled": recolor(g, (0.0, 1.0), None, 0.08, 0.6, 0.0, 0.0),
    }
    for n, v in variants.items():
        save(v, n)
        report[n] = dict(size=[v.shape[1], v.shape[0]])


def ninepatch_preview(img, m, size):
    """Approximate Godot's nine-patch stretch for the contact sheet (no Godot import needed)."""
    h, w = img.shape[:2]
    l, t, r, b = m
    W, H = size
    xs = [(0, l, 0, l), (l, w - r, l, W - r), (w - r, w, W - r, W)]
    ys = [(0, t, 0, t), (t, h - b, t, H - b), (h - b, h, H - b, H)]
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    src = Image.fromarray(np.clip(img, 0, 255).astype(np.uint8), "RGBA")
    for sx0, sx1, dx0, dx1 in xs:
        for sy0, sy1, dy0, dy1 in ys:
            if sx1 <= sx0 or sy1 <= sy0 or dx1 <= dx0 or dy1 <= dy0:
                continue
            part = src.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.BILINEAR)
            out.alpha_composite(part, (dx0, dy0))
    return out


def contact_sheet(report):
    names = [n for n in report if "margins" in report[n]]
    rows = []
    for n in names:
        e = report[n]
        img = np.asarray(Image.open(os.path.join(OUT, n + ".png")).convert("RGBA")).astype(np.float32)
        w, h = e["size"]
        big = ninepatch_preview(img, e["margins"], (int(w * 2.2), max(h, int(h * 1.5))))
        rows.append((n, Image.fromarray(img.astype(np.uint8), "RGBA"), big))
    W = 1500
    H = sum(max(r[1].height, r[2].height) + 24 for r in rows) + 20
    sheet = Image.new("RGBA", (W, H), (17, 21, 33, 255))
    bgart = Image.open(os.path.join(ROOT, "assets", "art", "environment", "menu_background.png")).convert("RGBA")
    bgart = bgart.resize((W, int(bgart.height * W / bgart.width)))
    for yy in range(0, H, bgart.height):
        sheet.alpha_composite(bgart, (0, yy))
    from PIL import ImageDraw
    d = ImageDraw.Draw(sheet)
    y = 10
    for n, native, big in rows:
        d.text((10, y), n, fill=(255, 255, 255, 255))
        sheet.alpha_composite(native, (10, y + 14))
        sheet.alpha_composite(big, (min(W - big.width - 10, 30 + native.width), y + 14))
        y += max(native.height, big.height) + 24
    os.makedirs(LOG, exist_ok=True)
    sheet.save(os.path.join(LOG, "theme_textures_preview.png"))


def main():
    os.makedirs(OUT, exist_ok=True)
    report = {}
    infos = {}
    for name, spec in PIECES.items():
        infos[name] = build_piece(name, spec, report)
    for name, (piece, crop, edge) in ORNAMENTS.items():
        build_ornament(name, infos[piece], crop, edge, report)
    build_bar_fill(infos["bar_track"], report)
    build_diamonds(report)
    with open(os.path.join(OUT, "slices.json"), "w") as f:
        json.dump(report, f, indent=1, sort_keys=True)
    for n in sorted(report):
        print(n, report[n])
    if "--preview" in sys.argv:
        contact_sheet(report)


if __name__ == "__main__":
    main()
