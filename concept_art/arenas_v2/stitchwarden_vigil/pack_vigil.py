#!/usr/bin/env python3
"""Packs Stitchwarden's Vigil from the target-matched source_v2 pieces.

The original kit remains in ../stitched_doll_pixel_kit/. The revised art in source_v2 keeps
its working cloth and animation frames, and replaces the board, doll, head, scythe and jungle
backdrop to match the owner's 2026-09-30 reference. This script writes:

- assets/art/environment/arenas/stitchwarden_vigil/*.png: every layer resampled onto one texel
  grid (4 design px per texel at group scale 1, the pixel UI kit's grid), with hard alpha and a
  limited palette per piece;
- scenes/arenas/stitchwarden_vigil.tscn: the layered scene, generated (re-run this, never hand-edit
  it); its script is scenes/arenas/stitchwarden_vigil.gd;
- assets/art/environment/arenas/stitchwarden_vigil.png: a 941x1672 still for the Shop card, and
  thumbnails/stitchwarden_vigil.png;
- arena.json: the still's floor and the layout numbers;
- review/: the arena at phone sizes with the HUD's boxes and the Wisp drawn in, for checking.

The generated board is split into a frame and an unobstructed 120x264-texel floor. The
original cloth shader and motion remain in use. The scene's floor and collision rectangle
are the same; nothing else is allowed to draw inside it.

Run from the repo root, then tools/validate.sh:

    python concept_art/arenas_v2/stitchwarden_vigil/pack_vigil.py
"""
from __future__ import annotations

import json
import math
import re
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
RAW = HERE.parent / "stitched_doll_pixel_kit"
SOURCE_V2 = HERE / "source_v2"
REPO = HERE.parents[2]
ART_DIR = REPO / "assets/art/environment/arenas/stitchwarden_vigil"
ART_RES = "res://assets/art/environment/arenas/stitchwarden_vigil"
STILL = REPO / "assets/art/environment/arenas/stitchwarden_vigil.png"
THUMBNAIL = REPO / "assets/art/environment/arenas/thumbnails/stitchwarden_vigil.png"
SCENE = REPO / "scenes/arenas/stitchwarden_vigil.tscn"
SCRIPT_RES = "res://scenes/arenas/stitchwarden_vigil.gd"
CLOTH_SHADER_RES = "res://assets/shaders/cloth_wave.gdshader"
LANTERN_SHADER_RES = "res://assets/shaders/lantern_flicker.gdshader"
FIRE_SHADER_RES = "res://assets/shaders/arena_fire_wave.gdshader"
HOOD_SHADER_RES = "res://assets/shaders/arena_hood_follow.gdshader"
FRAME_SHADER_RES = "res://assets/shaders/arena_frame_tilt.gdshader"
REVIEW = HERE / "review"
MANIFEST = HERE / "arena.json"

TEXEL = 4.0  # design px per texel at group scale 1
FLOOR_W, FLOOR_H = 120, 264
HEAD_RIG_PIVOT = (64, -52)  # under the hood, above the scarf and fixed gloves
STILL_SIZE = (941, 1672)  # EndlessCatalog.BACKGROUND_SIZE
THUMBNAIL_SIZE = (282, 502)

# Fit rules, mirrored by LayeredArenaVisual.fit() (design px).
HEAD_CLEAR = 70.0
BOTTOM_MARGIN = 40.0
SIDE_MARGIN = 12.0
MAX_SCALE = 1.3
BACKDROP_OVERSCAN = 16.0  # GameWorld.BACKGROUND_OVERSCAN: screen shake never shows an edge

# --- Board (frame.png source px) ------------------------------------------------------------------
FRAME_HOLE = (272, 153, 680, 1457)  # the frame's clear inside
BANNER_BOX = (420, 40, 526, 232)  # the top banner, which hangs 79 px into the hole
BANNER_KEEP_TOP = 60  # rows of the banner's top (its fold over the beam) kept whole
LEFT_BAND = (338, 426)  # plain rail sections repeated to widen the rails (seamless per column)
RIGHT_BAND = (521, 616)
BEAM_TOP_SRC, BEAM_BOTTOM_SRC = 65, 100  # the top rail's log
POST_SRC = (175, 272)  # the left post, outer to inner edge

# --- Floor (floor.png) ----------------------------------------------------------------------------
FLOOR_CONTENT = (213, 136, 648, 1661)  # 4 columns x 14 rows of tiles
FLOOR_ROWS = (0, 1, 2, 3, 10, 11, 12, 13)  # the top and bottom four rows: 8 rows, edges kept

# --- Doll (texels per source px, group texels) -----------------------------------------------------
BODY_SCALE = 0.15
BODY_RAIL_ROW = 685  # body.png row that sits at the middle of the rail's log (sleeves; fists hidden)
BODY_CENTER_X = 775
HEAD_SCALE = 0.054
HEAD_NECK_SRC = (790, 960)  # pivot in head.png: the bottom of the hood, over the collar
HEAD_NECK_ON_BODY = (800, 320)  # where the pivot sits on body.png
HEAD_TURN_DEGREES = 5.0  # animation reach, for the fit's content rect
HAND_SCALE = 0.078
HAND_BOXES = {"left": (60, 170, 892, 610), "right": (1278, 170, 2110, 610)}  # grip_hands.png halves
HAND_FINGERS = {"left": (530, 505), "right": (1640, 505)}  # finger centre x, finger bottom y
HAND_ON_BODY_X = {"left": 330, "right": 1220}  # the sleeve each hand ends

# --- Scythe and flame -----------------------------------------------------------------------------
SCYTHE_SCALE = 0.14
SCYTHE_ROTATION = -6.0  # degrees, PIL sense (positive = counter-clockwise)
SCYTHE_GRIP_Y = 480  # scythe.png handle row held at the left hand
SCYTHE_GRIP_DX = 6  # texels right of the left hand's finger centre (the handle passes its thumb)
HANDLE = ((651.0, 700.0), 0.11)  # handle centre at y 700 and its lean (x per y), scythe.png
FLAME_LOW, FLAME_HIGH = (130, 300), (470, 110)  # blade back, scythe.png: the flame's two ends
FLAME_A, FLAME_B = (128, 460), (400, 200)  # the same two ends in the flame frames

# --- Cloth, lanterns, wisps, bats, fog ------------------------------------------------------------
CLOTH_SCALE = 0.115
CLOTH_ROTATION = 52.0
CLOTH_ROOTS = {"left": (1440, 60), "right": (80, 50)}  # cloth_*.png root
CLOTH_TIPS = {"left": (40, 930), "right": (1500, 940)}
CLOTH_ON_BODY = {"left": (210, 470), "right": (1330, 470)}
CLOTH_AMPLITUDE = 3.0  # texels at the tip
CLOTH_PAD = 5
LANTERN_HEIGHT = 38
LANTERN_Y = (12, FLOOR_H - 12 - 38)
WISP_HEIGHT = 12
BAT_WIDTH = 12
FOG_SCALE = 0.15
FOG_Y = 0.62  # of the floor's height: the fog's middle, behind the board's lower half
FOG_ALPHA = 0.4
# Wisp paths in group texels: centre x, centre y, x reach, y reach, seconds per loop, phase.
WISPS = (
    (182.0, -78.0, 6.0, 10.0, 7.0, 0.0),
    (-44.0, 236.0, 4.0, 16.0, 9.0, 1.7),
    (197.0, 196.0, 4.0, 18.0, 8.0, 3.1),
    (-18.0, 376.0, 10.0, 5.0, 11.0, 4.4),
)

# Phones the review checks (design px): the owner's Samsung (1080x2340), taller and 9:16 phones and
# a portrait tablet. The safe top is an assumption for the review only; the game reads the device.
REVIEW_VIEWS = {
    "phone_1080x2340": (1080, 2340, 125.0),
    "phone_1080x2400": (1080, 2400, 125.0),
    "phone_1080x1920": (1080, 1920, 60.0),
    "tablet_1200x1920": (1200, 1920, 40.0),
}
# The HUD's left buttons (GameWorld HUD_PAUSE_SIZE, HUD_UPGRADE_BUTTON_SIZE and gap), x from the
# safe left margin (27 px on a 1080-wide screen), y from the safe top.
HUD_BUTTONS = ((0.0, 0.0, 112.0, 112.0), (0.0, 130.0, 132.0, 262.0))
HUD_MARGIN_X = 27.0


# ------------------------------------------------------------------------------------------------
def snake(name: str) -> str:
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()


def load(path: str) -> Image.Image:
    """RGBA with hard alpha: the kit's faint generated halos (alpha < 128) are dropped."""
    im = Image.open(RAW / path).convert("RGBA")
    a = np.asarray(im).copy()
    a[..., 3] = np.where(a[..., 3] >= 128, 255, 0)
    return Image.fromarray(a)


def grid(im: Image.Image, size: tuple[int, int], box=None, colors: int = 40, alpha_levels: int = 0) -> Image.Image:
    """Area-resamples [im] (optionally its [box]) to [size] texels: hard alpha, limited palette."""
    a = np.asarray(im).astype(np.float64) / 255.0
    pre = a.copy()
    pre[..., :3] *= a[..., 3:4]
    src = Image.fromarray((pre * 255.0).round().astype(np.uint8))
    small = np.asarray(src.resize(size, Image.Resampling.BOX, box=box)).astype(np.float64) / 255.0
    alpha = small[..., 3]
    rgb = np.where(alpha[..., None] > 1e-4, small[..., :3] / np.maximum(alpha[..., None], 1e-4), 0.0)
    out = np.zeros((size[1], size[0], 4), np.uint8)
    out[..., :3] = (np.clip(rgb, 0.0, 1.0) * 255.0).round().astype(np.uint8)
    if alpha_levels:
        out[..., 3] = (np.round(alpha * alpha_levels) / alpha_levels * 255.0).astype(np.uint8)
    else:
        out[..., 3] = np.where(alpha >= 0.5, 255, 0)
    if colors:
        opaque = out[..., 3] > 0
        if opaque.any():
            q = Image.fromarray(out[..., :3]).quantize(colors=colors, method=Image.Quantize.MEDIANCUT,
                                                        dither=Image.Dither.NONE)
            out[..., :3] = np.asarray(q.convert("RGB"))
        out[~opaque, :3] = 0
    return Image.fromarray(out)


def grid_scale(im: Image.Image, scale: float, **kw) -> Image.Image:
    return grid(im, (max(1, round(im.width * scale)), max(1, round(im.height * scale))), **kw)


def grid_aligned(im: Image.Image, scale: float, anchor: tuple[float, float], colors: int = 40):
    """Resamples so source point [anchor] falls exactly on a texel corner.

    Returns the image and the anchor's texel, so a piece can be placed with an exact edge.
    """
    pad = int(math.ceil(2.0 / scale)) + 2
    padded = Image.new("RGBA", (im.width + 2 * pad, im.height + 2 * pad))
    padded.paste(im, (pad, pad))
    ax, ay = anchor[0] + pad, anchor[1] + pad
    tx, ty = math.floor(ax * scale), math.floor(ay * scale)
    ox, oy = ax - tx / scale, ay - ty / scale
    w = math.floor((padded.width - ox) * scale)
    h = math.floor((padded.height - oy) * scale)
    box = (ox, oy, ox + w / scale, oy + h / scale)
    return grid(padded, (w, h), box=box, colors=colors), (tx, ty)


def rotate(im: Image.Image, degrees: float) -> Image.Image:
    return im.rotate(degrees, resample=Image.Resampling.BICUBIC, expand=True)


def rotate_point(p, degrees: float, old_size, new_size):
    """Where source point [p] lands after `rotate(im, degrees)`."""
    r = math.radians(degrees)
    x, y = p[0] - old_size[0] / 2.0, p[1] - old_size[1] / 2.0
    return (x * math.cos(r) + y * math.sin(r) + new_size[0] / 2.0,
            -x * math.sin(r) + y * math.cos(r) + new_size[1] / 2.0)


class Layer:
    """One sprite of the group or the scenery: texture(s), texel position, and scene extras."""

    def __init__(self, name: str, images: list[Image.Image], pos, kind: str = "sprite", **extra):
        self.name = name
        self.images = images
        self.pos = (int(round(pos[0])), int(round(pos[1])))
        self.kind = kind
        self.extra = extra

    @property
    def rect(self):
        w = max(i.width for i in self.images)
        h = max(i.height for i in self.images)
        return (self.pos[0], self.pos[1], self.pos[0] + w, self.pos[1] + h)


# ------------------------------------------------------------------------------------------------
def build_frame():
    """The frame with a hole of exactly FLOOR_W x FLOOR_H texels; returns (image, hole texel)."""
    im = np.asarray(load("arena/frame.png")).copy()
    x0, y0, x1, y1 = FRAME_HOLE
    bx0, by0, bx1, by1 = BANNER_BOX
    banner = im[by0:by1, bx0:bx1].copy()
    drop = by1 - y0
    short = np.concatenate([banner[:BANNER_KEEP_TOP], banner[BANNER_KEEP_TOP + drop:]], axis=0)
    im[y0:y1, x0:x1] = 0
    region = im[by0:by0 + short.shape[0], bx0:bx1]
    region[:] = np.where(short[..., 3:4] > 0, short, region)
    left = im[:, LEFT_BAND[0]:LEFT_BAND[1]].copy()
    right = im[:, RIGHT_BAND[0]:RIGHT_BAND[1]].copy()
    im = np.concatenate([im[:, :RIGHT_BAND[1]], right, im[:, RIGHT_BAND[1]:]], axis=1)
    im = np.concatenate([im[:, :LEFT_BAND[1]], left, im[:, LEFT_BAND[1]:]], axis=1)
    hole_w = (x1 - x0) + left.shape[1] + right.shape[1]
    scale = FLOOR_W / hole_w
    cut = (y1 - y0) - round(FLOOR_H / scale)
    rgb = im[..., :3].astype(np.float64) * (im[..., 3:4] / 255.0)
    cols = np.r_[140:300, im.shape[1] - 300:im.shape[1] - 140]
    best = min(range(y0 + 150, y1 - 150 - cut),
               key=lambda ya: float(np.abs(rgb[ya, cols] - rgb[ya + cut, cols]).mean()))
    im = np.concatenate([im[:best], im[best + cut:]], axis=0)
    frame, (tx, ty) = grid_aligned(Image.fromarray(im), scale, (x0, y0), colors=48)
    a = np.asarray(frame).copy()
    a[ty:ty + FLOOR_H, tx:tx + FLOOR_W] = 0
    return Image.fromarray(a), (tx, ty), scale


def build_floor() -> Image.Image:
    im = np.asarray(load("arena/floor.png"))
    fx0, fy0, fx1, fy1 = FLOOR_CONTENT
    th = (fy1 - fy0) / 14.0
    rows = [im[int(round(fy0 + r * th)):int(round(fy0 + (r + 1) * th)), fx0:fx1] for r in FLOOR_ROWS]
    tiles = grid(Image.fromarray(np.concatenate(rows, axis=0)), (FLOOR_W, FLOOR_H), colors=24)
    return Image.fromarray(np.pad(np.asarray(tiles), ((3, 3), (3, 3), (0, 0)), mode="edge"))


def handle_point(y: float):
    (hx, hy), lean = HANDLE
    return (hx + lean * (y - hy), y)


def build_group():
    """Every group layer, back to front, in group texels (the floor's top-left is the origin)."""
    layers: list[Layer] = []
    frame, (hx, hy), frame_scale = build_frame()
    beam_mid = ((BEAM_TOP_SRC + BEAM_BOTTOM_SRC) / 2.0 - FRAME_HOLE[1]) * frame_scale
    beam_bottom = (BEAM_BOTTOM_SRC - FRAME_HOLE[1]) * frame_scale
    post_center = ((POST_SRC[0] + POST_SRC[1]) / 2.0 - FRAME_HOLE[0]) * frame_scale

    # Fog and wisps sit behind everything of the group.
    fog = grid_scale(load("fx/fog_bank.png"), FOG_SCALE, colors=12, alpha_levels=4)
    fog_pos = (FLOOR_W / 2.0 - fog.width / 2.0, FLOOR_H * FOG_Y - fog.height / 2.0)
    layers.append(Layer("Fog", [fog], fog_pos, extra_alpha=FOG_ALPHA, content=False))
    wisp_src = [load(f"fx/wisp/processed/hover-{i}.png") for i in range(1, 5)]
    wscale = WISP_HEIGHT / (465 - 46)
    wisp = [grid_scale(w, wscale, colors=12) for w in wisp_src]
    for index, (cx, cy, rx, ry, period, phase) in enumerate(WISPS):
        pos = (cx - wisp[0].width / 2.0, cy - wisp[0].height / 2.0)
        layers.append(Layer(f"Wisp{index + 1}", wisp, pos, kind="animated", fps=1000.0 / 180.0,
                            path=(cx, cy, rx, ry), period=period, phase=phase, content=False))

    body_src = load("doll/body.png")
    body = grid_scale(body_src, BODY_SCALE)
    body_pos = (FLOOR_W / 2.0 - BODY_CENTER_X * BODY_SCALE, beam_mid - BODY_RAIL_ROW * BODY_SCALE)
    body_layer = Layer("Body", [body], body_pos)
    layers.append(body_layer)
    bx, by = body_layer.pos

    hands = {}
    grips = load("doll/grip_hands.png")
    for side in ("left", "right"):
        box = HAND_BOXES[side]
        img = grid_scale(grips.crop(box), HAND_SCALE)
        fx, fy = HAND_FINGERS[side]
        finger = ((fx - box[0]) * HAND_SCALE, (fy - box[1]) * HAND_SCALE)
        at = (bx + HAND_ON_BODY_X[side] * BODY_SCALE, beam_bottom + 2.0)
        hands[side] = Layer(f"Hand{side.title()}", [img], (at[0] - finger[0], at[1] - finger[1]))
    left_finger_x = hands["left"].pos[0] + (HAND_FINGERS["left"][0] - HAND_BOXES["left"][0]) * HAND_SCALE

    # Scythe, its handle through the left hand, and the flame on the upper blade.
    scythe_src = load("doll/scythe.png")
    rotated = rotate(scythe_src, SCYTHE_ROTATION)
    grip = rotate_point(handle_point(SCYTHE_GRIP_Y), SCYTHE_ROTATION, scythe_src.size, rotated.size)
    scythe = grid_scale(rotated, SCYTHE_SCALE)
    target = (left_finger_x + SCYTHE_GRIP_DX, beam_mid)
    scythe_layer = Layer("Scythe", [scythe], (target[0] - grip[0] * SCYTHE_SCALE, target[1] - grip[1] * SCYTHE_SCALE))
    layers.append(scythe_layer)
    low = rotate_point(FLAME_LOW, SCYTHE_ROTATION, scythe_src.size, rotated.size)
    high = rotate_point(FLAME_HIGH, SCYTHE_ROTATION, scythe_src.size, rotated.size)
    va = (FLAME_B[0] - FLAME_A[0], FLAME_B[1] - FLAME_A[1])
    vb = (high[0] - low[0], high[1] - low[1])
    k = math.hypot(*vb) / math.hypot(*va)
    angle = math.degrees(math.atan2(vb[1], vb[0]) - math.atan2(va[1], va[0]))
    flames = []
    anchor = None
    for i in range(1, 5):
        fsrc = load(f"fx/flame/processed/idle-{i}.png")
        frot = rotate(fsrc, -angle)
        anchor = rotate_point(FLAME_A, -angle, fsrc.size, frot.size)
        flames.append(grid_scale(frot, k * SCYTHE_SCALE, colors=12))
    sx, sy = scythe_layer.pos
    flame_pos = (sx + low[0] * SCYTHE_SCALE - anchor[0] * k * SCYTHE_SCALE,
                 sy + low[1] * SCYTHE_SCALE - anchor[1] * k * SCYTHE_SCALE)
    layers.append(Layer("Flame", flames, flame_pos, kind="animated", fps=1000.0 / 120.0))

    head_src = load("doll/head.png")
    head = grid_scale(head_src, HEAD_SCALE)
    pivot = (bx + HEAD_NECK_ON_BODY[0] * BODY_SCALE, by + HEAD_NECK_ON_BODY[1] * BODY_SCALE)
    head_pos = (pivot[0] - HEAD_NECK_SRC[0] * HEAD_SCALE, pivot[1] - HEAD_NECK_SRC[1] * HEAD_SCALE)
    head_layer = Layer("Head", [head], head_pos)
    head_layer.extra["pivot"] = (round(pivot[0]) - head_layer.pos[0], round(pivot[1]) - head_layer.pos[1])
    layers.append(head_layer)

    layers.append(Layer("Floor", [build_floor()], (-3, -3)))
    layers.append(Layer("Frame", [frame], (-hx, -hy)))

    for side in ("left", "right"):
        src = load(f"doll/cloth_{side}.png")
        degrees = CLOTH_ROTATION if side == "left" else -CLOTH_ROTATION
        rot = rotate(src, degrees)
        img = grid_scale(rot, CLOTH_SCALE, colors=24)
        root = rotate_point(CLOTH_ROOTS[side], degrees, src.size, rot.size)
        tip = rotate_point(CLOTH_TIPS[side], degrees, src.size, rot.size)
        root_t = (root[0] * CLOTH_SCALE, root[1] * CLOTH_SCALE)
        tip_t = (tip[0] * CLOTH_SCALE, tip[1] * CLOTH_SCALE)
        at = (bx + CLOTH_ON_BODY[side][0] * BODY_SCALE, by + CLOTH_ON_BODY[side][1] * BODY_SCALE)
        layer = Layer(f"Cloth{side.title()}", [img], (at[0] - root_t[0], at[1] - root_t[1]), kind="cloth",
                      root=root_t, tip=tip_t, phase=0.0 if side == "left" else 2.1)
        # Nothing but the floor inside the floor: cut what the cloth would draw there.
        a = np.asarray(layer.images[0]).copy()
        x0, y0 = -layer.pos[0], -layer.pos[1]
        a[max(0, y0):max(0, y0 + FLOOR_H), max(0, x0):max(0, x0 + FLOOR_W)] = 0
        layer.images[0] = Image.fromarray(a)
        layer.extra["clip"] = (x0, y0, FLOOR_W, FLOOR_H)
        layers.append(layer)

    layers.append(hands["left"])
    layers.append(hands["right"])
    lantern_src = load("fx/lantern.png")
    lantern = grid_scale(lantern_src, LANTERN_HEIGHT / (1472 - 63), colors=24)
    index = 0
    for x in (post_center, FLOOR_W - post_center):
        for y in LANTERN_Y:
            index += 1
            layers.append(Layer(f"Lantern{index}", [lantern], (x - lantern.width / 2.0, y), kind="lantern",
                                phase=index * 1.37))
    for layer in layers:
        if layer.name != "Floor" and not layer.name.startswith("Wisp"):
            trim(layer, CLOTH_PAD if layer.kind == "cloth" else 0)
    head_top = head_layer.pos[1] - 2.0  # the hood's top, with the turn's reach
    return layers, head_top


def source_v2(name: str) -> Image.Image:
    return Image.open(SOURCE_V2 / name).convert("RGBA")


def build_group_v2():
    """Place the revised pieces on one grid, with the floor's top-left at (0, 0)."""
    layers: list[Layer] = []
    board_source = source_v2("board.png").crop((73, 0, 813, 1774))
    board = grid(board_source, (158, 369), colors=56)
    board_pos = (-20, -41)
    board_pixels = np.asarray(board).copy()
    # The floor in the revised board is a straight rectangle. Cover the source's hanging
    # banner and split out a calm tile surface, so animation and gameplay cannot cross it.
    floor = grid(source_v2("floor.png"), (FLOOR_W, FLOOR_H), colors=32)
    layers.append(Layer("Fog", [source_v2("fog.png")], (-100, 205), extra_alpha=0.28,
                        content=False))
    wisp_frames = [source_v2(f"wisp_{i}.png") for i in range(1, 5)]
    for index, (cx, cy, rx, ry, period, phase) in enumerate(WISPS):
        layers.append(Layer(f"Wisp{index + 1}", wisp_frames,
                            (cx - 10 - wisp_frames[0].width / 2, cy - wisp_frames[0].height / 2),
                            kind="animated", fps=1000.0 / 180.0,
                            path=(cx - 10, cy, rx, ry), period=period, phase=phase, content=False))

    # The metal and fire stay behind the doll's left fist and the top rail.
    scythe_src = source_v2("scythe.png").crop((0, 0, 1024, 1095))
    layers.append(Layer("Scythe", [grid(scythe_src, (125, 134), colors=48)], (-68, -114)))
    fire = grid(source_v2("fire.png"), (100, 94), colors=18)
    layers.append(Layer("Flame", [fire], (-71, -109), kind="fire"))

    layers.append(Layer("Floor", [floor], (0, 0)))
    board_pixels[41:41 + FLOOR_H, 20:20 + FLOOR_W] = 0
    layers.append(Layer("Frame", [Image.fromarray(board_pixels)], board_pos))

    # Keep the two cloth panels and their existing wind shader. Their roots remain at the
    # shoulders, and the clip rectangle prevents the wave reaching the playable floor.
    for side, pos, root, tip, phase in (
        ("Left", (-80, -67), (61, 7), (7, 205), 0.0),
        ("Right", (129, -67), (7, 7), (61, 205), 2.1),
    ):
        img = source_v2(f"cloth_{side.lower()}.png")
        layer = Layer(f"Cloth{side}", [img], pos, kind="cloth", root=root, tip=tip,
                      phase=phase, clip=(-pos[0], -pos[1], FLOOR_W, FLOOR_H))
        a = np.asarray(img).copy()
        x0, y0 = -pos[0], -pos[1]
        a[max(0, y0):max(0, y0 + FLOOR_H), max(0, x0):max(0, x0 + FLOOR_W)] = 0
        layer.images[0] = Image.fromarray(a)
        layers.append(layer)

    body = grid(source_v2("body.png"), (250, 105), colors=48)
    layers.append(Layer("Body", [body], (-67, -104)))
    face = grid(source_v2("head.png"), (58, 46), colors=36)
    head_layer = Layer("Head", [face], (43, -92), pivot=(29, 40))
    layers.append(head_layer)

    # Bright lantern sprites cover the dim lamp cores in the new frame; the existing shader
    # varies their light while keeping their cages still.
    lamp = grid(source_v2("lantern.png"), (10, 22), colors=20)
    for index, (cx, cy) in enumerate(((-8, 18), (129, 18), (-8, FLOOR_H - 5), (129, FLOOR_H - 5)), 1):
        layers.append(Layer(f"Lantern{index}", [lamp], (cx - 5, cy - 11),
                            kind="lantern", phase=index * 1.37))

    for layer in layers:
        if layer.name != "Floor" and not layer.name.startswith("Wisp"):
            trim(layer, CLOTH_PAD if layer.kind == "cloth" else 0)
    return layers, -104.0


def trim(layer: Layer, pad: int = 0) -> None:
    """Crops a layer's images to what they draw (plus [pad]) and moves its anchors with them."""
    boxes = [img.getbbox() for img in layer.images if img.getbbox()]
    x0 = min(b[0] for b in boxes) - pad
    y0 = min(b[1] for b in boxes) - pad
    x1 = max(b[2] for b in boxes) + pad
    y1 = max(b[3] for b in boxes) + pad
    layer.images = [img.crop((x0, y0, x1, y1)) for img in layer.images]
    layer.pos = (layer.pos[0] + x0, layer.pos[1] + y0)
    for key in ("root", "tip", "pivot"):
        if key in layer.extra:
            layer.extra[key] = (layer.extra[key][0] - x0, layer.extra[key][1] - y0)
    if "clip" in layer.extra:
        cx, cy, cw, ch = layer.extra["clip"]
        layer.extra["clip"] = (cx - x0, cy - y0, cw, ch)
    if "path" in layer.extra:
        pass  # a wisp's path is about its centre, not its texture


def content_rect(layers):
    rects = [l.rect for l in layers if l.extra.get("content", True)]
    x0 = min(r[0] for r in rects)
    y0 = min(r[1] for r in rects)
    x1 = max(r[2] for r in rects)
    y1 = max(r[3] for r in rects)
    return (x0, y0, x1, y1)


def check_floor_clear(layers):
    """Fails if any layer drawn over the floor (after it) draws inside it; the floor is opaque, so
    what is behind it never shows."""
    names = [l.name for l in layers]
    for layer in layers[names.index("Floor") + 1:]:
        for img in layer.images:
            a = np.asarray(img)[..., 3]
            x0, y0 = -layer.pos[0], -layer.pos[1]
            sub = a[max(0, y0):max(0, y0 + FLOOR_H), max(0, x0):max(0, x0 + FLOOR_W)]
            if sub.size and sub.any():
                raise SystemExit(f"{layer.name} draws {int((sub > 0).sum())} texels inside the floor")


# ------------------------------------------------------------------------------------------------
def fit(view_w: float, view_h: float, safe_top: float, content, head_top: float):
    """Mirror of LayeredArenaVisual.fit(): group scale, unit (design px per texel), group origin."""
    center = FLOOR_W / 2.0
    half = max(center - content[0], content[2] - center)
    fit_w = (view_w / 2.0 - SIDE_MARGIN) / (half * TEXEL)
    fit_h = (view_h - BOTTOM_MARGIN - safe_top - HEAD_CLEAR) / ((content[3] - head_top) * TEXEL)
    scale = min(MAX_SCALE, fit_w, fit_h)
    unit = TEXEL * scale
    origin = (round(view_w / 2.0 - center * unit), round(safe_top + HEAD_CLEAR - head_top * unit))
    return scale, unit, origin


def backdrop_images():
    plate = source_v2("backdrop.png")
    return grid(plate, (278, round(plate.height * 278 / plate.width)), colors=128), {}


def backdrop_cover(view_w, view_h, plate_size):
    w, h = view_w + 2 * BACKDROP_OVERSCAN, view_h + 2 * BACKDROP_OVERSCAN
    cover = max(w / plate_size[0], h / plate_size[1])
    return cover, ((view_w - plate_size[0] * cover) / 2.0, (view_h - plate_size[1] * cover) / 2.0)


def render(view_w, view_h, safe_top, layers, head_top, content, backplate, trees, bat, hud=False):
    page = Image.new("RGBA", (view_w, view_h), (8, 12, 30, 255))
    cover, origin = backdrop_cover(view_w, view_h, backplate.size)

    def put(img, texel_pos, unit, base, alpha=1.0):
        w, h = max(1, round(img.width * unit)), max(1, round(img.height * unit))
        big = img.resize((w, h), Image.Resampling.NEAREST)
        if alpha < 1.0:
            a = np.asarray(big).copy()
            a[..., 3] = (a[..., 3] * alpha).astype(np.uint8)
            big = Image.fromarray(a)
        page.alpha_composite(big, (int(round(base[0] + texel_pos[0] * unit)), int(round(base[1] + texel_pos[1] * unit))))

    put(backplate, (0, 0), cover, origin)
    for side in trees:
        put(trees[side][0], trees[side][1], cover, origin)
    if bat is not None:  # the review shows one bat where they cross; the Shop still has none
        put(bat, (view_w * 0.62 / cover, view_h * 0.17 / cover), cover, (0, 0))
    scale, unit, g = fit(view_w, view_h, safe_top, content, head_top)
    for layer in layers:
        put(layer.images[0], layer.pos, unit, g, layer.extra.get("extra_alpha", 1.0))
    floor = (g[0], g[1], g[0] + FLOOR_W * unit, g[1] + FLOOR_H * unit)
    if hud:
        d = ImageDraw.Draw(page, "RGBA")
        d.rectangle(floor, outline=(0, 255, 120, 255), width=3)
        for x0, y0, x1, y1 in HUD_BUTTONS:
            d.rectangle((HUD_MARGIN_X + x0, safe_top + y0, HUD_MARGIN_X + x1, safe_top + y1),
                        fill=(255, 0, 80, 70), outline=(255, 0, 80, 220), width=2)
        d.rectangle((view_w - HUD_MARGIN_X - 260, safe_top, view_w - HUD_MARGIN_X, safe_top + 100),
                    fill=(255, 0, 80, 70), outline=(255, 0, 80, 220), width=2)
        for y0, y1, w in ((14, 34, 500), (38, 72, 240), (80, 112, 500)):
            d.rectangle((view_w / 2 - w / 2, safe_top + y0, view_w / 2 + w / 2, safe_top + y1),
                        fill=(255, 0, 80, 70), outline=(255, 0, 80, 220), width=2)
        d.rectangle((view_w / 2 - 300, safe_top + 150, view_w / 2 + 300, safe_top + 210),
                    outline=(255, 200, 0, 200), width=2)
    return page.convert("RGB"), scale, floor


def hud_overlap(layers, head_top, content, view_w, view_h, safe_top):
    """Texels of the scythe, flame and head that fall under the pause or UPGRADE button."""
    scale, unit, g = fit(view_w, view_h, safe_top, content, head_top)
    hits = 0
    for layer in layers:
        if layer.name not in ("Scythe", "Flame", "Head"):
            continue
        for img in layer.images:
            ys, xs = np.nonzero(np.asarray(img)[..., 3])
            px = g[0] + (layer.pos[0] + xs + 0.5) * unit
            py = g[1] + (layer.pos[1] + ys + 0.5) * unit
            for x0, y0, x1, y1 in HUD_BUTTONS:
                hits += int(((px >= HUD_MARGIN_X + x0) & (px <= HUD_MARGIN_X + x1)
                             & (py >= safe_top + y0) & (py <= safe_top + y1)).sum())
    return hits


# ------------------------------------------------------------------------------------------------
def tscn_value(v) -> str:
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, float):
        return f"{v:.4f}".rstrip("0").rstrip(".") if not v.is_integer() else f"{v:.1f}"
    return str(v)


def write_scene(layers, content, head_top, backplate_path, tree_paths, tree_offsets, bat_paths):
    ext = []  # (id, type, path)
    sub = []  # text blocks
    nodes = []

    def ext_id(kind, path):
        for i, t, p in ext:
            if p == path:
                return i
        new = f"{len(ext) + 1}_{Path(path).stem}"
        ext.append((new, kind, path))
        return new

    ext_id("Script", SCRIPT_RES)
    cloth_shader = ext_id("Shader", CLOTH_SHADER_RES)
    lantern_shader = ext_id("Shader", LANTERN_SHADER_RES)
    fire_shader = ext_id("Shader", FIRE_SHADER_RES)
    hood_shader = ext_id("Shader", HOOD_SHADER_RES)
    frame_shader = ext_id("Shader", FRAME_SHADER_RES)

    def frames_resource(name, paths, fps):
        ids = [ext_id("Texture2D", p) for p in paths]
        frames = ", ".join('{\n"duration": 1.0,\n"texture": ExtResource("%s")\n}' % i for i in ids)
        sub.append(f'[sub_resource type="SpriteFrames" id="SpriteFrames_{name}"]\n'
                   f'animations = [{{\n"frames": [{frames}],\n"loop": true,\n"name": &"default",\n'
                   f'"speed": {tscn_value(float(fps))}\n}}]\n')
        return f"SpriteFrames_{name}"

    cx0, cy0, cx1, cy1 = content
    root = ['[node name="StitchwardenVigil" type="Control"]',
            "process_mode = 1", "layout_mode = 3", "anchors_preset = 15", "anchor_right = 1.0",
            "anchor_bottom = 1.0", "grow_horizontal = 2", "grow_vertical = 2", "mouse_filter = 2",
            "texture_filter = 1", 'script = ExtResource("1_stitchwarden_vigil")',
            f"floor_texels = Vector2({FLOOR_W}, {FLOOR_H})",
            f"content_rect = Rect2({cx0}, {cy0}, {cx1 - cx0}, {cy1 - cy0})",
            f"head_top = {tscn_value(float(round(head_top, 2)))}",
            f"head_clear = {tscn_value(HEAD_CLEAR)}", f"bottom_margin = {tscn_value(BOTTOM_MARGIN)}",
            f"side_margin = {tscn_value(SIDE_MARGIN)}", f"max_scale = {tscn_value(MAX_SCALE)}",
            f"backdrop_overscan = {tscn_value(BACKDROP_OVERSCAN)}"]
    nodes.append("\n".join(root) + "\n")
    bp = ext_id("Texture2D", backplate_path)
    nodes.append('[node name="Backdrop" type="Node2D" parent="."]\nunique_name_in_owner = true\n')
    nodes.append(f'[node name="Backplate" type="Sprite2D" parent="Backdrop"]\nunique_name_in_owner = true\n'
                 f'texture = ExtResource("{bp}")\ncentered = false\n')
    for side in tree_paths:
        t = ext_id("Texture2D", tree_paths[side])
        ox, oy = tree_offsets[side]
        nodes.append(f'[node name="Tree{side.title()}" type="Sprite2D" parent="Backdrop"]\n'
                     f'position = Vector2({ox}, {oy})\ntexture = ExtResource("{t}")\ncentered = false\n')
    bat_frames = frames_resource("bat", bat_paths, 1000.0 / 150.0)
    nodes.append('[node name="Bats" type="Node2D" parent="."]\nunique_name_in_owner = true\n')
    for i in (1, 2):
        nodes.append(f'[node name="Bat{i}" type="AnimatedSprite2D" parent="Bats"]\nvisible = false\n'
                     f'sprite_frames = SubResource("{bat_frames}")\n')
    nodes.append('[node name="Group" type="Node2D" parent="."]\nunique_name_in_owner = true\n')

    frames_cache = {}
    body_layer = next(layer for layer in layers if layer.name == "Body")
    for layer in layers:
        paths = layer.extra["paths"]
        lines = [f'[node name="{layer.name}" type="{"AnimatedSprite2D" if layer.kind == "animated" else "Sprite2D"}" parent="Group"]']
        if layer.name.startswith("Wisp"):
            lines[0] = f'[node name="{layer.name}" type="AnimatedSprite2D" parent="Group/Wisps"]'
        pos = layer.pos
        if layer.name == "Head":
            rig_x, rig_y = HEAD_RIG_PIVOT
            body_id = ext_id("Texture2D", body_layer.extra["paths"][0])
            body_img = body_layer.images[0]
            sub.append(f'[sub_resource type="ShaderMaterial" id="ShaderMaterial_hood"]\n'
                       f'shader = ExtResource("{hood_shader}")\n'
                       f'shader_parameter/texture_texels = Vector2({body_img.width}, {body_img.height})\n'
                       'shader_parameter/hood_piece = true\n')
            nodes.append('[node name="HeadRig" type="Node2D" parent="Group"]\n'
                         f'unique_name_in_owner = true\nposition = Vector2({rig_x}, {rig_y})\n')
            nodes.append('[node name="Hood" type="Sprite2D" parent="Group/HeadRig"]\n'
                         f'position = Vector2({body_layer.pos[0] - rig_x}, {body_layer.pos[1] - rig_y})\n'
                         'material = SubResource("ShaderMaterial_hood")\n'
                         f'texture = ExtResource("{body_id}")\ncentered = false\n')
            lines[0] = '[node name="Head" type="Sprite2D" parent="Group/HeadRig"]'
            lines.append(f"position = Vector2({pos[0] - rig_x}, {pos[1] - rig_y})")
            lines.append(f'texture = ExtResource("{ext_id("Texture2D", paths[0])}")')
            lines.append("centered = false")
        elif layer.kind == "animated":
            key = tuple(paths)
            if key not in frames_cache:
                frames_cache[key] = frames_resource(layer.name.lower().rstrip("0123456789"), paths, layer.extra["fps"])
            lines.append(f"position = Vector2({pos[0]}, {pos[1]})")
            lines.append(f'sprite_frames = SubResource("{frames_cache[key]}")')
            lines.append("centered = false")
            if "path" in layer.extra:
                cx, cy, rx, ry = layer.extra["path"]
                lines.append(f"metadata/path = Vector4({tscn_value(cx)}, {tscn_value(cy)}, {tscn_value(rx)}, {tscn_value(ry)})")
                lines.append(f"metadata/period = {tscn_value(float(layer.extra['period']))}")
                lines.append(f"metadata/phase = {tscn_value(float(layer.extra['phase']))}")
        else:
            lines.append(f"position = Vector2({pos[0]}, {pos[1]})")
            if layer.extra.get("extra_alpha", 1.0) < 1.0:
                lines.append(f"modulate = Color(1, 1, 1, {tscn_value(float(layer.extra['extra_alpha']))})")
            if layer.kind == "cloth":
                mid = f"ShaderMaterial_{layer.name.lower()}"
                rx, ry = layer.extra["root"]
                tx, ty = layer.extra["tip"]
                cx, cy, cw, ch = layer.extra["clip"]
                img = layer.images[0]
                sub.append(f'[sub_resource type="ShaderMaterial" id="{mid}"]\nshader = ExtResource("{cloth_shader}")\n'
                           f"shader_parameter/texture_texels = Vector2({img.width}, {img.height})\n"
                           f"shader_parameter/root_texel = Vector2({tscn_value(round(rx, 2))}, {tscn_value(round(ry, 2))})\n"
                           f"shader_parameter/tip_texel = Vector2({tscn_value(round(tx, 2))}, {tscn_value(round(ty, 2))})\n"
                           f"shader_parameter/clip_rect = Vector4({cx}, {cy}, {cw}, {ch})\n"
                           f"shader_parameter/amplitude = {tscn_value(CLOTH_AMPLITUDE)}\n"
                           f"shader_parameter/phase = {tscn_value(float(layer.extra['phase']))}\n")
                lines.append(f'material = SubResource("{mid}")')
            if layer.kind == "lantern":
                mid = f"ShaderMaterial_{layer.name.lower()}"
                sub.append(f'[sub_resource type="ShaderMaterial" id="{mid}"]\nshader = ExtResource("{lantern_shader}")\n'
                           f"shader_parameter/glow = 1.0\n")
                lines.append(f'material = SubResource("{mid}")')
                lines.append(f"metadata/phase = {tscn_value(float(layer.extra['phase']))}")
            if layer.kind == "fire":
                mid = "ShaderMaterial_flame"
                sub.append(f'[sub_resource type="ShaderMaterial" id="{mid}"]\n'
                           f'shader = ExtResource("{fire_shader}")\n'
                           'shader_parameter/time_s = 0.0\n')
                lines.append(f'material = SubResource("{mid}")')
            if layer.name == "Body":
                mid = "ShaderMaterial_body"
                img = layer.images[0]
                sub.append(f'[sub_resource type="ShaderMaterial" id="{mid}"]\n'
                           f'shader = ExtResource("{hood_shader}")\n'
                           f'shader_parameter/texture_texels = Vector2({img.width}, {img.height})\n'
                           'shader_parameter/shift_texels = Vector2(0, 0)\n')
                lines.append(f'material = SubResource("{mid}")')
            if layer.name == "Frame":
                mid = "ShaderMaterial_frame"
                img = layer.images[0]
                sub.append(f'[sub_resource type="ShaderMaterial" id="{mid}"]\n'
                           f'shader = ExtResource("{frame_shader}")\n'
                           f'shader_parameter/texture_width = {tscn_value(float(img.width))}\n'
                           f'shader_parameter/group_top_y = {tscn_value(float(layer.pos[1]))}\n'
                           f'shader_parameter/floor_height = {tscn_value(float(FLOOR_H))}\n')
                lines.append(f'material = SubResource("{mid}")')
            lines.append(f'texture = ExtResource("{ext_id("Texture2D", paths[0])}")')
            lines.append("centered = false")
        if layer.name == "Wisp1":
            nodes.append('[node name="Wisps" type="Node2D" parent="Group"]\nunique_name_in_owner = true\n')
        if layer.name in ("Head", "Flame", "Fog", "Body"):
            lines.insert(1, "unique_name_in_owner = true")
        nodes.append("\n".join(lines) + "\n")

    header = f"[gd_scene load_steps={len(ext) + len(sub) + 1} format=3]\n"
    ext_text = "".join(f'[ext_resource type="{t}" path="{p}" id="{i}"]\n' for i, t, p in ext)
    text = header + "\n" + ext_text + "\n" + "\n".join(sub) + ("\n" if sub else "") + "\n".join(nodes)
    SCENE.parent.mkdir(parents=True, exist_ok=True)
    SCENE.write_text(text, encoding="utf-8", newline="\n")


# ------------------------------------------------------------------------------------------------
def main() -> None:
    layers, head_top = build_group_v2()
    check_floor_clear(layers)
    content = content_rect(layers)
    # Animation reach: the head turns a few degrees; the cloth sways inside its padding.
    head = next(l for l in layers if l.name == "Head")
    reach = math.sin(math.radians(HEAD_TURN_DEGREES)) * head.images[0].height
    content = (min(content[0], head.rect[0] - reach), content[1], max(content[2], head.rect[2] + reach), content[3])
    content = tuple(int(math.floor(v)) if i < 2 else int(math.ceil(v)) for i, v in enumerate(content))

    ART_DIR.mkdir(parents=True, exist_ok=True)
    for old in ART_DIR.glob("*.png"):
        old.unlink()
    written = {}
    for layer in layers:
        base = snake(layer.name).rstrip("0123456789")
        paths = []
        for i, img in enumerate(layer.images):
            name = f"{base}_{i + 1}.png" if len(layer.images) > 1 else f"{base}.png"
            if name not in written:
                img.save(ART_DIR / name)
                written[name] = True
            paths.append(f"{ART_RES}/{name}")
        layer.extra["paths"] = paths
    backplate, trees = backdrop_images()
    backplate.save(ART_DIR / "backplate.png")
    tree_paths, tree_offsets = {}, {}
    for side in trees:
        trees[side][0].save(ART_DIR / f"tree_{side}.png")
        tree_paths[side] = f"{ART_RES}/tree_{side}.png"
        tree_offsets[side] = trees[side][1]
    bats = [source_v2(f"bat_{i}.png") for i in range(1, 5)]
    bat_paths = []
    for i, img in enumerate(bats):
        img.save(ART_DIR / f"bat_{i + 1}.png")
        bat_paths.append(f"{ART_RES}/bat_{i + 1}.png")
    write_scene(layers, content, head_top, f"{ART_RES}/backplate.png", tree_paths, tree_offsets, bat_paths)

    # Review at phone sizes, and the owner's phone's HUD check.
    REVIEW.mkdir(exist_ok=True)
    report = {}
    for name, (w, h, top) in REVIEW_VIEWS.items():
        img, scale, floor = render(w, h, top, layers, head_top, content, backplate, trees, bats[0], hud=True)
        img.save(REVIEW / f"{name}.png")
        report[name] = {"scale": round(scale, 4), "floor_px": [round(v) for v in floor],
                        "hud_overlap_texels": hud_overlap(layers, head_top, content, w, h, top)}
        print(f"{name}: scale {scale:.3f}, floor {[round(v) for v in floor]}, "
              f"under the HUD buttons: {report[name]['hud_overlap_texels']} texels")

    still, scale, floor = render(STILL_SIZE[0], STILL_SIZE[1], 40.0, layers, head_top, content, backplate, trees, None)
    STILL.parent.mkdir(parents=True, exist_ok=True)
    still.save(STILL)
    still.resize(THUMBNAIL_SIZE, Image.Resampling.NEAREST).save(THUMBNAIL)
    floor_px = [int(round(v)) for v in floor]
    manifest = {
        "id": "stitchwarden_vigil",
        "display_name": "STITCHWARDEN'S VIGIL",
        "source": "source_v2/",
        "source_note": "Target-matched pixel art generated for the owner's 2026-09-30 reference. "
                       "The working cloth and FX frames came from the original kit.",
        "floor_rect_px": floor_px,
        "floor_rect_note": "The floor in the 941x1672 Shop still, [left, top, right, bottom]. In a run "
                           "the arena is the layered scene; its floor is fitted to the screen "
                           "(LayeredArenaVisual.fit).",
        "floor_texels": [FLOOR_W, FLOOR_H],
        "texel_design_px": TEXEL,
        "content_rect_texels": list(content),
        "head_top_texels": round(head_top, 2),
        "fit": {"head_clear": HEAD_CLEAR, "bottom_margin": BOTTOM_MARGIN, "side_margin": SIDE_MARGIN,
                "max_scale": MAX_SCALE},
        "review": report,
        "review_note": "Safe tops in the review are assumed values for the check, not measured.",
    }
    MANIFEST.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
    uv = (floor_px[0] / STILL_SIZE[0], floor_px[1] / STILL_SIZE[1],
          (floor_px[2] - floor_px[0]) / STILL_SIZE[0], (floor_px[3] - floor_px[1]) / STILL_SIZE[1])
    print("still floor px", floor_px, "uv Rect2(%.5f, %.5f, %.5f, %.5f)" % uv)
    print("content", content, "head_top", round(head_top, 2), "layers", len(layers))


if __name__ == "__main__":
    main()
