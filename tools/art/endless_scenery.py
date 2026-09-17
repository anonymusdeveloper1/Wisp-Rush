#!/usr/bin/env python3
"""Animated scenery of the Legendary and Mythic Endless arena skins: the per-skin table and the
scenery mask generator (owner feedback 2026-09-15; spec story_and_endless/05; ADR-0014).

Usage (repo root):
  python3 tools/art/endless_scenery.py [skin_id ...]   # masks + logs/endless/scenery_masks_preview.png
  python3 tools/art/set_endless_import_lossy.py         # once Godot has imported new masks
  python3 tools/art/make_endless_skin_data.py           # writes ArenaSceneryData into the skin .tres
  tools/validate.sh

Writes assets/art/environment/endless/masks/<skin_id>.png (MASK_SIZE, RGBA) for every skin in
SCENERY. Never hand-edit the masks: change the table below and re-run. The runtime is
ArenaAmbience + assets/shaders/arena_scenery.gdshader (docs/systems/endless_mode.md).

Mask channels (texture UV of the 941x1672 background):
  R  emissive light: the painting's own light sources, found per zone by brightness / saturation /
     hue rules inside the zone's rects, plus a soft halo. Zero within MOTION_CLEARANCE_PX of the floor.
  G  animated distortion weight (water, fire, aurora, clouds, mist), per zone rules. Same clearance.
  B  scenery weight: 0 inside the floor template, rising linearly to 1 across rim_tolerance_px;
     the grade uses it, and the shader and particles treat only B ~ 1 as scenery.
  A  zone id, nearest-sampled: A = 255 - id * ZONE_ALPHA_STEP (id 0 = no zone, never 0 alpha).

Zone runtime parameters (light colour, breathing, flicker, flares, colour cycling, twinkle, travel
pulses, sweep weight, distortion mode) and the set piece, light sweep, shooting stars and particle
emitters are written into the skin data by make_endless_skin_data.py from the same table.
Particle emission points are sampled here from scenery pixels whose whole drift path (speed,
spread, gravity, lifetime) stays outside the floor + rim tolerance.
"""

import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

TEMPLATE_JSON = "concept_art/wisp_rush_endless_v1/floor_template.json"
BACKGROUND_DIR = "assets/art/environment/endless"
MASK_DIR = os.path.join(BACKGROUND_DIR, "masks")
PREVIEW = "logs/endless/scenery_masks_preview.png"
CANVAS = (941, 1672)
MASK_SIZE = (471, 836)
# Zone ids live in alpha so they survive bilinear R/G/B sampling (read with nearest filtering).
ZONE_ALPHA_STEP = 28
MAX_ZONES = 7
# Emissive and distortion start this far past the rim tolerance, so nothing moves on the rim.
MOTION_CLEARANCE_PX = 16
# Particle emission: points per emitter and extra distance kept from the keep-out along the path.
EMITTER_POINTS = 48
EMITTER_PATH_MARGIN_PX = 12

# Palette (scripts/utils/palette.gd) plus scenery light colours. Data only: UI keeps Palette.
COLORS = {
    "VOID_CHARCOAL": "111521", "SLATE_TEAL": "263D42", "SOUL_CYAN": "62E8F2",
    "SOUL_WHITE": "EAFDFF", "WARNING_AMBER": "F3A847", "RIFT_MAGENTA": "B14CD9",
    "MOSS_GREEN": "5E7D4C", "TEXT_MUTED": "8FB3BA", "STEEL_BORDER": "4C6670",
    "EMBER": "FF7A2E", "FLAME_RED": "E8482A", "GOLD": "FFC56B", "AURORA_GREEN": "52F5A4",
    "AURORA_TEAL": "3FE0D0", "ICE_BLUE": "9CD6FF", "ABYSS_BLUE": "3D8BFF",
    "NEBULA_VIOLET": "9B7BFF", "STORM_BLUE": "7FA8FF", "DUSK_ROSE": "FF8A7A",
    "MOONLIGHT": "D8E6FF", "LEAF_GREEN": "8EE07A",
}

WARP_MODES = ["NONE", "RIPPLE", "SHIMMER", "WAVE", "ROIL"]
PIECE_KINDS = ["NONE", "CORONA", "SWIRL"]
SPRITES = ["SOFT_DOT", "SPARKLE"]

ZONE_DEFAULTS = dict(
    color="SOUL_WHITE", alt=None, strength=0.0, breathe=0.0, breathe_hz=0.15, flicker=0.0,
    flicker_hz=6.0, flare_interval=0.0, flare_boost=0.0, flare_rise=0.3, flare_fade=1.2,
    flash=False, hue_cycle=0.0, hue_cycle_hz=0.05, shift=0.0, shift_cycles=2.0, shift_hz=0.08,
    twinkle=0.0, twinkle_hz=1.0, travel=0.0, travel_cycles=8.0, travel_hz=0.5, sweep=0.0,
    warp_mode="NONE", warp_px=0.0, warp_hz=0.1, warp_cycles=4.0,
)

# Particle presets: speeds px/s, gravity px/s^2, sizes px diameter, all in background pixels.
EMITTER_PRESETS = {
    "embers": dict(lifetime=3.2, direction=(0.0, -1.0), spread=25, speed=(14, 34), gravity=(0, -8),
                   size=(9, 16), color="EMBER", end="FLAME_RED", alpha=1.0, pulses=0, additive=True,
                   sprite="SOFT_DOT", spin=0),
    "snow": dict(lifetime=6.0, direction=(0.25, 1.0), spread=30, speed=(8, 20), gravity=(0, 3),
                 size=(7, 14), color="SOUL_WHITE", end="ICE_BLUE", alpha=1.0, pulses=0, additive=True,
                 sprite="SOFT_DOT", spin=0),
    "ash": dict(lifetime=7.0, direction=(0.35, 1.0), spread=40, speed=(5, 14), gravity=(0, 2),
                size=(7, 13), color="TEXT_MUTED", end="STEEL_BORDER", alpha=0.9, pulses=0,
                additive=True, sprite="SOFT_DOT", spin=0),
    "motes": dict(lifetime=5.0, direction=(0.0, -1.0), spread=35, speed=(6, 18), gravity=(0, -2),
                  size=(9, 16), color="SOUL_CYAN", end="ABYSS_BLUE", alpha=1.0, pulses=0,
                  additive=True, sprite="SOFT_DOT", spin=0),
    "fireflies": dict(lifetime=6.0, direction=(0.0, -1.0), spread=180, speed=(3, 9), gravity=(0, 0),
                      size=(9, 15), color="LEAF_GREEN", end="GOLD", alpha=1.0, pulses=2,
                      additive=True, sprite="SOFT_DOT", spin=0),
    "stardust": dict(lifetime=4.5, direction=(0.2, 1.0), spread=20, speed=(5, 14), gravity=(0, 2),
                     size=(12, 22), color="SOUL_WHITE", end="NEBULA_VIOLET", alpha=1.0, pulses=1,
                     additive=True, sprite="SPARKLE", spin=90),
    "smoke": dict(lifetime=6.0, direction=(0.0, -1.0), spread=20, speed=(6, 14), gravity=(0, -2),
                  size=(60, 110), color="TEXT_MUTED", end="STEEL_BORDER", alpha=0.16, pulses=0,
                  additive=False, sprite="SOFT_DOT", spin=0),
    "spray": dict(lifetime=1.4, direction=(0.0, -1.0), spread=35, speed=(24, 60), gravity=(0, 50),
                  size=(7, 12), color="ICE_BLUE", end="SOUL_WHITE", alpha=0.9, pulses=0,
                  additive=True, sprite="SOFT_DOT", spin=0),
}


def zone(name, rects, emit=None, warp=None, ellipse=False, feather=24, **params):
    """A lit and/or moving region. rects: [u, v, w, h] UV rects (ellipse: inscribed ellipses).
    emit / warp: {"rules": [...], "halo": px, "gain": g}; rules multiply (see rule_weight)."""
    unknown = set(params) - set(ZONE_DEFAULTS)
    if unknown:
        raise SystemExit("zone %s: unknown parameters %s" % (name, sorted(unknown)))
    merged = dict(ZONE_DEFAULTS)
    merged.update(params)
    return dict(name=name, rects=rects, emit=emit, warp=warp, ellipse=ellipse, feather=feather,
                params=merged)


def emitter(name, rects, preset, amount, rule=None, **overrides):
    """Particles spawned from scenery pixels in rects (optionally only where rule weight >= 0.5)."""
    values = dict(EMITTER_PRESETS[preset])
    unknown = set(overrides) - set(values)
    if unknown:
        raise SystemExit("emitter %s: unknown parameters %s" % (name, sorted(unknown)))
    values.update(overrides)
    return dict(name=name, rects=rects, rule=rule, amount=amount, values=values)


def light(*rules, halo=0, gain=1.0):
    return dict(rules=list(rules), halo=halo, gain=gain)


AREA = ("area",)

# Anchors measured on the runtime art (2026-09-15): eclipse sun centre (468, 128) px radius 96;
# galaxy core (200, 128); gate seam u 0.507-0.518 v 0.016-0.21, runes u 0.261 / 0.745; aurora
# torches (0.105, 0.199), (0.882, 0.213), (0.953, 0.27); dragon eye glows u 0.05-0.16, 0.23-0.29,
# 0.67-0.71, 0.76-0.91 at v 0.02-0.11. Top scenery ends at v 0.2263 and bottom scenery starts at
# v 0.7987 over the floor's width.
TOP = [0.0, 0.0, 1.0, 0.2263]
BOTTOM = [0.0, 0.7987, 1.0, 0.2013]

SCENERY = {
    # ---------------------------------------------------------------- Legendary: calm living touches
    "titans_palm": dict(
        grade=dict(saturation=1.25, contrast=1.08, exposure=1.04, shadow=("STORM_BLUE", 0.22),
                   highlight=("GOLD", 0.16), floor_saturation=1.04),
        zones=[
            zone("clouds", [TOP, BOTTOM], warp=light(("luma", 0.28, 0.62)),
                 warp_mode="ROIL", warp_px=3.0, warp_hz=0.035, warp_cycles=3.0, sweep=1.0,
                 emit=light(("luma", 0.55, 0.85), gain=0.6), color="GOLD", strength=0.18,
                 breathe=0.4, breathe_hz=0.05),
        ],
        sweep=dict(color="GOLD", strength=0.32, angle=25, width_px=80, period=12.0, duty=0.45),
        emitters=[
            emitter("dust", [TOP, BOTTOM], "motes", 12, color="SOUL_WHITE", end="GOLD", alpha=0.7),
        ],
    ),
    "clocktower_crown": dict(
        grade=dict(saturation=1.25, contrast=1.08, exposure=1.03, shadow=("STORM_BLUE", 0.24),
                   highlight=("MOONLIGHT", 0.14), floor_saturation=1.04),
        zones=[
            zone("clouds", [TOP, BOTTOM], warp=light(("luma", 0.25, 0.6)),
                 warp_mode="ROIL", warp_px=2.6, warp_hz=0.035, warp_cycles=3.0),
            zone("bell", [[0.28, 0.0, 0.44, 0.17]], sweep=1.0),
            zone("moon", [[0.86, 0.0, 0.1, 0.07]], ellipse=True, feather=10,
                 emit=light(("luma", 0.45, 0.85), halo=18, gain=1.0), color="MOONLIGHT",
                 strength=0.75, breathe=0.25, breathe_hz=0.07),
        ],
        sweep=dict(color="GOLD", strength=0.55, angle=0, width_px=26, period=9.0, duty=0.3),
        emitters=[
            emitter("drift", [BOTTOM], "motes", 10, color="MOONLIGHT", end="STORM_BLUE", alpha=0.6),
        ],
    ),
    "storm_anvil": dict(
        grade=dict(saturation=1.2, contrast=1.08, exposure=1.03, shadow=("STORM_BLUE", 0.16),
                   highlight=("ICE_BLUE", 0.12), floor_saturation=1.04),
        zones=[
            zone("storm", [TOP, BOTTOM], warp=light(("luma", 0.25, 0.6)),
                 emit=light(("tophat", 8, 0.16, 0.4), ("luma", 0.5, 0.8), halo=10),
                 color="STORM_BLUE", alt="SOUL_WHITE", strength=0.12, flare_interval=8.0,
                 flare_boost=0.9, flare_rise=0.14, flare_fade=0.9, flash=True, hue_cycle=0.3,
                 warp_mode="ROIL", warp_px=2.4, warp_hz=0.05, warp_cycles=3.5),
            zone("forge fires", [[0.66, 0.08, 0.3, 0.09], [0.1, 0.84, 0.08, 0.1],
                                 [0.64, 0.8, 0.22, 0.08]],
                 emit=light(("warm", 0.18, 0.4), halo=14), warp=light(("warm", 0.1, 0.3)),
                 color="EMBER", alt="GOLD", strength=1.0, flicker=0.5, flicker_hz=5.0, shift=0.3,
                 warp_mode="SHIMMER", warp_px=1.4, warp_hz=0.6, warp_cycles=16.0),
        ],
        emitters=[
            emitter("embers", [[0.64, 0.05, 0.36, 0.15], [0.0, 0.8, 0.9, 0.2]], "embers", 14,
                    rule=("warm_near", 0.15, 40)),
        ],
    ),
    "world_tree_crown": dict(
        grade=dict(saturation=1.25, contrast=1.06, exposure=1.04, shadow=("ABYSS_BLUE", 0.14),
                   highlight=("LEAF_GREEN", 0.18), floor_saturation=1.04),
        zones=[
            zone("canopy", [TOP, BOTTOM], emit=light(("tophat", 5, 0.14, 0.34), halo=6),
                 color="LEAF_GREEN", alt="GOLD", strength=0.55, twinkle=0.6, twinkle_hz=0.5,
                 shift=0.4, shift_cycles=3.0),
            zone("moon glow", [[0.58, 0.0, 0.3, 0.14]], ellipse=True, feather=40,
                 emit=light(("luma", 0.3, 0.65), halo=14, gain=0.8), color="MOONLIGHT",
                 strength=0.45, breathe=0.3, breathe_hz=0.06),
            zone("waterfalls", [[0.48, 0.1, 0.05, 0.12], [0.72, 0.1, 0.05, 0.12],
                                [0.85, 0.12, 0.05, 0.1], [0.4, 0.81, 0.06, 0.07],
                                [0.5, 0.85, 0.06, 0.1]],
                 emit=light(("luma", 0.4, 0.7)), warp=light(("luma", 0.3, 0.6)),
                 color="ICE_BLUE", strength=0.45, travel=0.7, travel_cycles=26.0, travel_hz=0.8,
                 warp_mode="SHIMMER", warp_px=1.2, warp_hz=0.5, warp_cycles=20.0),
        ],
        emitters=[
            emitter("fireflies", [TOP, BOTTOM], "fireflies", 16),
        ],
    ),
    "galleon_wreck": dict(
        grade=dict(saturation=1.3, contrast=1.1, exposure=1.03, shadow=("ABYSS_BLUE", 0.22),
                   highlight=("DUSK_ROSE", 0.2), floor_saturation=1.04),
        zones=[
            zone("sea", [[0.0, 0.1, 1.0, 0.1263], [0.3, 0.8, 0.7, 0.12]],
                 warp=light(("luma", 0.08, 0.4)), warp_mode="RIPPLE", warp_px=2.4, warp_hz=0.14,
                 warp_cycles=9.0, emit=light(("tophat", 4, 0.12, 0.3)), color="ICE_BLUE",
                 strength=0.4, twinkle=0.7, twinkle_hz=0.9),
            zone("sunset", [[0.7, 0.0, 0.3, 0.19]], ellipse=True, feather=40,
                 emit=light(("warm", 0.06, 0.25), halo=20), color="GOLD", alt="DUSK_ROSE",
                 strength=0.6, breathe=0.25, breathe_hz=0.06, shift=0.4, shift_cycles=1.5),
            zone("lantern", [[0.92, 0.22, 0.07, 0.09]], emit=light(("warm", 0.15, 0.35), halo=16),
                 color="GOLD", alt="EMBER", strength=1.1, flicker=0.45, flicker_hz=4.0),
        ],
        emitters=[
            emitter("spray", [[0.0, 0.14, 1.0, 0.08]], "spray", 12),
        ],
    ),
    # ---------------------------------------------------------------- Mythic: premium, alive
    "eclipse_sanctum": dict(
        grade=dict(saturation=1.6, contrast=1.12, exposure=1.12, shadow=("NEBULA_VIOLET", 0.4),
                   highlight=("GOLD", 0.3), floor_saturation=1.06),
        zones=[
            zone("sky", [TOP], emit=light(("tophat", 6, 0.12, 0.3)), warp=light(("luma", 0.12, 0.5)),
                 color="ICE_BLUE", alt="NEBULA_VIOLET", strength=0.9, twinkle=0.85, twinkle_hz=0.8,
                 shift=0.5, sweep=1.0, warp_mode="ROIL", warp_px=3.5, warp_hz=0.11, warp_cycles=3.0),
            zone("underworld", [BOTTOM], emit=light(("tophat", 6, 0.1, 0.26)),
                 warp=light(("luma", 0.18, 0.5)), color="ICE_BLUE", alt="GOLD", strength=0.7,
                 twinkle=0.7, twinkle_hz=0.6, shift=0.3, sweep=0.7, warp_mode="ROIL", warp_px=5.0,
                 warp_hz=0.088, warp_cycles=3.0),
            zone("crescents", [[0.28, 0.12, 0.07, 0.06], [0.65, 0.12, 0.07, 0.06]],
                 emit=light(("luma", 0.28, 0.6), halo=10), color="GOLD", strength=0.9,
                 breathe=0.35, breathe_hz=0.2),
            zone("banner gold", [[0.12, 0.8, 0.18, 0.13], [0.7, 0.8, 0.18, 0.13]],
                 emit=light(("warm", 0.06, 0.2), ("luma", 0.2, 0.5), halo=10), color="GOLD",
                 alt="EMBER", strength=0.9, breathe=0.3, breathe_hz=0.15, shift=0.3),
            zone("corona", [[0.33, 0.0, 0.34, 0.2]], ellipse=True, feather=20,
                 emit=light(("luma", 0.4, 0.9), halo=8), color="SOUL_WHITE", alt="GOLD",
                 strength=0.8, breathe=0.25, breathe_hz=0.12, hue_cycle=0.4, hue_cycle_hz=0.04),
        ],
        piece=dict(kind="CORONA", centre=(0.4973, 0.0766), radius_px=96, extent_px=190,
                   color="MOONLIGHT", strength=0.6, rays=22, speed=0.05, sharpness=6.0,
                   flare_interval=5.5, flare_length_px=160, flare_width_deg=10, flare_color="GOLD",
                   flare_boost=1.6),
        sweep=dict(color="GOLD", strength=0.4, angle=70, width_px=60, period=10.0, duty=0.5),
        emitters=[
            emitter("ash", [[0.0, 0.0, 1.0, 0.17]], "ash", 34, color="SOUL_WHITE",
                    end="NEBULA_VIOLET", alpha=0.7),
            emitter("gold motes", [BOTTOM], "motes", 18, color="GOLD", end="EMBER", alpha=0.85),
        ],
    ),
    "starforged_citadel": dict(
        grade=dict(saturation=1.5, contrast=1.12, exposure=1.06, shadow=("NEBULA_VIOLET", 0.32),
                   highlight=("SOUL_CYAN", 0.26), floor_saturation=1.06),
        zones=[
            zone("starfield", [TOP], emit=light(("tophat", 5, 0.1, 0.28)),
                 warp=light(("luma", 0.3, 0.7)), color="SOUL_WHITE", alt="NEBULA_VIOLET",
                 strength=1.0, twinkle=0.9, twinkle_hz=1.0, shift=0.45, warp_mode="ROIL",
                 warp_px=2.0, warp_hz=0.088, warp_cycles=3.0),
            zone("deep sky", [BOTTOM], emit=light(("tophat", 5, 0.1, 0.28)),
                 color="SOUL_WHITE", alt="SOUL_CYAN", strength=0.9, twinkle=0.9, twinkle_hz=0.8,
                 shift=0.4),
            zone("galaxy", [[0.05, 0.0, 0.34, 0.16]], ellipse=True, feather=40,
                 emit=light(("luma", 0.35, 0.9), halo=10), warp=light(AREA),
                 color="NEBULA_VIOLET", alt="SOUL_CYAN", strength=0.55, breathe=0.2,
                 breathe_hz=0.08, shift=0.6, shift_cycles=3.0, shift_hz=0.05),
            zone("planets", [[0.55, 0.83, 0.45, 0.17], [0.8, 0.0, 0.2, 0.12]],
                 emit=light(("tophat", 12, 0.06, 0.2), halo=8), color="ICE_BLUE",
                 strength=0.5, breathe=0.15, breathe_hz=0.05),
            zone("light falls", [[0.03, 0.08, 0.07, 0.14], [0.66, 0.05, 0.06, 0.15],
                                 [0.05, 0.8, 0.07, 0.18], [0.25, 0.8, 0.07, 0.18]],
                 emit=light(("luma", 0.42, 0.8), halo=8), warp=light(("luma", 0.3, 0.7)),
                 color="SOUL_CYAN", alt="SOUL_WHITE", strength=0.75, travel=0.8,
                 travel_cycles=18.0, travel_hz=0.7, warp_mode="SHIMMER", warp_px=1.5,
                 warp_hz=0.5, warp_cycles=20.0),
        ],
        piece=dict(kind="SWIRL", centre=(0.2125, 0.0766), radius_px=165, swirl_radians=0.24,
                   speed=0.14, color="NEBULA_VIOLET", strength=0.22),
        streaks=dict(region=[0.08, 0.0, 0.84, 0.19], interval=3.5, speed_px=520.0, length_px=90.0,
                     width_px=2.2, duration=0.55, angle=(15.0, 40.0), color="SOUL_WHITE",
                     strength=1.0),
        emitters=[
            emitter("stardust", [[0.0, 0.0, 1.0, 0.15]], "stardust", 22),
            emitter("rising light", [BOTTOM], "motes", 22, color="SOUL_CYAN", end="NEBULA_VIOLET"),
        ],
    ),
    "abyssal_gate": dict(
        grade=dict(saturation=1.3, contrast=1.12, exposure=1.08, shadow=("ABYSS_BLUE", 0.2),
                   highlight=("SOUL_CYAN", 0.2), floor_saturation=1.06),
        zones=[
            zone("gate mist", [TOP], warp=light(("blue", 0.03, 0.14)), warp_mode="ROIL",
                 warp_px=3.0, warp_hz=0.11, warp_cycles=3.0, sweep=0.8,
                 emit=light(("luma", 0.3, 0.6), ("blue", 0.05, 0.2), gain=0.7),
                 color="ABYSS_BLUE", strength=0.3, breathe=0.4, breathe_hz=0.1),
            zone("abyss", [BOTTOM], warp=light(("luma", 0.15, 0.45)), warp_mode="ROIL",
                 warp_px=5.0, warp_hz=0.11, warp_cycles=3.0, sweep=0.8,
                 emit=light(("luma", 0.25, 0.6), gain=0.8), color="ABYSS_BLUE", alt="SOUL_CYAN",
                 strength=0.35, breathe=0.4, breathe_hz=0.08, shift=0.3),
            zone("runes", [[0.225, 0.01, 0.07, 0.15], [0.71, 0.01, 0.07, 0.15]],
                 emit=light(("cyan", 0.12, 0.3), halo=10), color="SOUL_CYAN", alt="ABYSS_BLUE",
                 strength=1.0, breathe=0.45, breathe_hz=0.22, travel=0.5, travel_cycles=6.0,
                 travel_hz=-0.3),
            zone("seam", [[0.485, 0.0, 0.05, 0.225]], feather=10,
                 emit=light(("cyan", 0.12, 0.3), halo=12), color="SOUL_CYAN", alt="SOUL_WHITE",
                 strength=1.2, breathe=0.3, breathe_hz=0.18, travel=0.7, travel_cycles=5.0,
                 travel_hz=0.5, flare_interval=7.0, flare_boost=0.8, flare_rise=0.4,
                 flare_fade=1.4, hue_cycle=0.3),
        ],
        piece=dict(kind="SWIRL", centre=(0.505, 0.085), radius_px=175, swirl_radians=0.12,
                   speed=0.1, color="SOUL_CYAN", strength=0.12),
        sweep=dict(color="SOUL_CYAN", strength=0.5, angle=60, width_px=40, period=7.0, duty=0.35),
        emitters=[
            emitter("abyss motes", [BOTTOM], "motes", 30),
            emitter("gate motes", [[0.0, 0.08, 1.0, 0.14]], "motes", 16, lifetime=6.0),
        ],
    ),
    "aurora_throne": dict(
        grade=dict(saturation=1.45, contrast=1.1, exposure=1.05, shadow=("AURORA_TEAL", 0.24),
                   highlight=("AURORA_GREEN", 0.16), floor_saturation=1.06),
        zones=[
            zone("peaks mist", [TOP], warp=light(("luma", 0.3, 0.6)), warp_mode="ROIL",
                 warp_px=2.5, warp_hz=0.088, warp_cycles=3.0),
            zone("green abyss", [BOTTOM], emit=light(("green", 0.02, 0.12), halo=10),
                 warp=light(("luma", 0.2, 0.55)), color="AURORA_GREEN", alt="AURORA_TEAL",
                 strength=0.5, breathe=0.35, breathe_hz=0.08, shift=0.3, warp_mode="ROIL",
                 warp_px=5.0, warp_hz=0.11, warp_cycles=3.0),
            zone("aurora", [[0.0, 0.0, 1.0, 0.14]], feather=40,
                 emit=light(("green", 0.1, 0.3), ("luma", 0.22, 0.55), halo=8),
                 warp=light(("green", 0.03, 0.2)), color="AURORA_GREEN", alt="NEBULA_VIOLET",
                 strength=0.85, breathe=0.25, breathe_hz=0.1, hue_cycle=0.35, hue_cycle_hz=0.06,
                 shift=0.5, shift_cycles=1.5, shift_hz=0.12, warp_mode="WAVE", warp_px=6.0, warp_hz=0.08, warp_cycles=1.6),
            zone("banner glyphs", [[0.0, 0.03, 0.1, 0.15], [0.9, 0.05, 0.1, 0.15]],
                 emit=light(("luma", 0.33, 0.6), halo=8), color="AURORA_GREEN", strength=0.6,
                 breathe=0.4, breathe_hz=0.15),
            zone("torches", [[0.06, 0.17, 0.08, 0.06], [0.85, 0.18, 0.07, 0.06],
                             [0.92, 0.23, 0.08, 0.07]],
                 feather=12, emit=light(("warm", 0.15, 0.35), halo=14), warp=light(AREA),
                 color="EMBER", alt="GOLD", strength=1.3, flicker=0.55, flicker_hz=7.0, shift=0.3,
                 warp_mode="SHIMMER", warp_px=1.5, warp_hz=0.6, warp_cycles=18.0),
        ],
        emitters=[
            emitter("snow high", [[0.0, 0.0, 1.0, 0.14]], "snow", 40),
            emitter("snow low", [BOTTOM], "snow", 30),
            emitter("torch sparks", [[0.04, 0.14, 0.12, 0.09], [0.83, 0.15, 0.17, 0.16]],
                    "embers", 12, rule=("warm_near", 0.15, 30)),
        ],
    ),
    "dragon_skull_throne": dict(
        grade=dict(saturation=1.4, contrast=1.12, exposure=1.08, shadow=("ABYSS_BLUE", 0.22),
                   highlight=("EMBER", 0.2), floor_saturation=1.05),
        zones=[
            zone("sky", [TOP], warp=light(("luma", 0.25, 0.55)), warp_mode="ROIL", warp_px=2.5,
                 warp_hz=0.088, warp_cycles=3.0),
            zone("chasm", [BOTTOM], emit=light(("tophat", 6, 0.1, 0.26)),
                 warp=light(("luma", 0.08, 0.4)), color="EMBER", alt="GOLD", strength=0.5,
                 twinkle=0.6, twinkle_hz=0.7, warp_mode="SHIMMER", warp_px=2.2, warp_hz=0.35,
                 warp_cycles=12.0),
            zone("maw heat", [[0.3, 0.0, 0.4, 0.21]], feather=40, warp=light(("dark", 0.2, 0.45)),
                 warp_mode="SHIMMER", warp_px=1.8, warp_hz=0.45, warp_cycles=14.0),
            zone("throat fire", [[0.4, 0.02, 0.2, 0.17]], ellipse=True, feather=70,
                 emit=light(("dark", 0.1, 0.3), gain=0.7, halo=20), color="EMBER",
                 alt="FLAME_RED", strength=0.3, breathe=0.35, breathe_hz=0.1, flicker=0.3,
                 flicker_hz=3.0),
            zone("eye sockets", [[0.04, 0.035, 0.13, 0.07], [0.22, 0.04, 0.08, 0.08],
                                 [0.66, 0.04, 0.06, 0.065], [0.75, 0.01, 0.17, 0.09]],
                 feather=14, emit=light(("blue", 0.14, 0.32), ("luma", 0.3, 0.55), halo=10),
                 color="ABYSS_BLUE",
                 alt="SOUL_CYAN", strength=1.0, breathe=0.35, breathe_hz=0.12,
                 flare_interval=6.0, flare_boost=1.4, flare_rise=0.6, flare_fade=1.6, shift=0.35),
        ],
        emitters=[
            emitter("embers low", [BOTTOM], "embers", 36),
            emitter("embers high", [[0.0, 0.0, 1.0, 0.2]], "embers", 20, lifetime=4.0),
            emitter("smoke", [BOTTOM], "smoke", 8),
        ],
    ),
}


# ------------------------------------------------------------------------------------ geometry


def load_template():
    with open(TEMPLATE_JSON) as handle:
        return json.load(handle)


def floor_distance(template):
    """Distance in background px from every pixel to the floor template (0 inside)."""
    mask = Image.new("L", CANVAS, 0)
    ImageDraw.Draw(mask).polygon([(u * CANVAS[0], v * CANVAS[1]) for u, v in template["polygon_uv"]],
                                 fill=255)
    inside = np.asarray(mask) > 0
    return ndimage.distance_transform_edt(~inside).astype(np.float32)


def smoothstep(lo, hi, x):
    t = np.clip((x - lo) / max(hi - lo, 1e-6), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def coverage(rects, ellipse, feather):
    """Feathered 0-1 coverage of UV rects (or their inscribed ellipses)."""
    image = Image.new("L", CANVAS, 0)
    draw = ImageDraw.Draw(image)
    for u, v, w, h in rects:
        box = [u * CANVAS[0], v * CANVAS[1], (u + w) * CANVAS[0], (v + h) * CANVAS[1]]
        (draw.ellipse if ellipse else draw.rectangle)(box, fill=255)
    hard = np.asarray(image, dtype=np.float32) / 255.0
    if feather <= 0:
        return hard
    # Feather inward only, so a zone never reaches past its authored rect.
    inner = ndimage.distance_transform_edt(hard > 0.5)
    return np.clip(inner / feather, 0.0, 1.0).astype(np.float32)


def rule_weight(rule, pixels):
    kind = rule[0]
    rgb, luma, blurred = pixels["rgb"], pixels["luma"], pixels["blur"]
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    if kind == "area":
        return np.ones_like(luma)
    if kind == "luma":
        return smoothstep(rule[1], rule[2], luma)
    if kind == "tophat":
        sigma = rule[1]
        if sigma not in blurred:
            blurred[sigma] = ndimage.gaussian_filter(luma, sigma)
        return smoothstep(rule[2], rule[3], luma - blurred[sigma])
    if kind == "warm":
        return smoothstep(rule[1], rule[2], r - b) * smoothstep(0.3, 0.55, r)
    if kind == "blue":
        return smoothstep(rule[1], rule[2], b - r)
    if kind == "cyan":
        return smoothstep(rule[1], rule[2], np.minimum(g, b) - r) * smoothstep(0.4, 0.65, g)
    if kind == "dark":
        return 1.0 - smoothstep(rule[1], rule[2], luma)
    if kind == "green":
        return smoothstep(rule[1], rule[2], g - (r + b) * 0.5)
    raise SystemExit("unknown rule %s" % (rule,))


def rules_weight(spec, pixels):
    weight = np.ones_like(pixels["luma"])
    for rule in spec["rules"]:
        weight = weight * rule_weight(rule, pixels)
    weight = weight * spec.get("gain", 1.0)
    halo = spec.get("halo", 0)
    if halo > 0:
        weight = np.maximum(weight, ndimage.gaussian_filter(weight, halo) * 1.6)
    return np.clip(weight, 0.0, 1.0)


# ------------------------------------------------------------------------------------ masks


def build_mask(skin_id, table, distance, rim_tolerance):
    image = Image.open(os.path.join(BACKGROUND_DIR, skin_id + ".png")).convert("RGB")
    rgb = np.asarray(image, dtype=np.float32) / 255.0
    pixels = dict(rgb=rgb, luma=rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32), blur={})
    motion_gate = smoothstep(rim_tolerance, rim_tolerance + MOTION_CLEARANCE_PX, distance)
    red = np.zeros(distance.shape, np.float32)
    green = np.zeros(distance.shape, np.float32)
    ids = np.zeros(distance.shape, np.uint8)
    if len(table["zones"]) > MAX_ZONES:
        raise SystemExit("%s has more than %d zones" % (skin_id, MAX_ZONES))
    for index, spec in enumerate(table["zones"], 1):
        cover = coverage(spec["rects"], spec["ellipse"], spec["feather"])
        inside = cover > 0.0
        emit = rules_weight(spec["emit"], pixels) if spec["emit"] else 0.0
        warp = rules_weight(spec["warp"], pixels) if spec["warp"] else 0.0
        red[inside] = (emit * cover * motion_gate)[inside] if spec["emit"] else 0.0
        green[inside] = (warp * cover * motion_gate)[inside] if spec["warp"] else 0.0
        ids[inside] = index
    blue = np.clip(distance / rim_tolerance, 0.0, 1.0)
    return red, green, blue, ids, pixels


def to_mask_image(red, green, blue, ids):
    def channel(values):
        full = Image.fromarray(np.clip(values * 255.0 + 0.5, 0, 255).astype(np.uint8), "L")
        return full.resize(MASK_SIZE, Image.BOX)

    # Box-filtered R/G/B stay exactly 0 on mask texels fully inside the floor; ids are
    # nearest-sampled so no in-between id is ever invented.
    alpha = Image.fromarray((255 - ids.astype(np.int32) * ZONE_ALPHA_STEP).astype(np.uint8), "L")
    return Image.merge("RGBA", (channel(red), channel(green), channel(blue),
                                alpha.resize(MASK_SIZE, Image.NEAREST)))


def emission_points(skin_id, spec, distance, rim_tolerance, pixels, seed):
    values = spec["values"]
    cover = coverage(spec["rects"], False, 0) > 0.5
    candidates = cover & (distance >= rim_tolerance + EMITTER_PATH_MARGIN_PX)
    rule = spec["rule"]
    if rule is not None and rule[0] == "warm_near":
        # Scenery within rule[2] px of a warm light source (torches, forges).
        warm = rule_weight(("warm", rule[1], rule[1] + 0.2), pixels) > 0.5
        near = ndimage.distance_transform_edt(~warm) <= rule[2]
        candidates &= near
    ys, xs = np.nonzero(candidates)
    rng = np.random.default_rng(seed)
    order = rng.permutation(len(xs))
    points = []
    for index in order:
        x, y = float(xs[index]), float(ys[index])
        if path_clear(x, y, values, distance, rim_tolerance):
            points.append((x / CANVAS[0], y / CANVAS[1]))
            if len(points) == EMITTER_POINTS:
                break
    if len(points) < 4:
        raise SystemExit("%s emitter %s: only %d clear emission points" % (skin_id, spec["name"],
                                                                         len(points)))
    return points


def path_samples(x, y, values):
    """Positions a particle from (x, y) can reach: both speed limits, the spread edges and centre,
    sampled along its lifetime (background px)."""
    dx, dy = values["direction"]
    length = math.hypot(dx, dy) or 1.0
    base = math.atan2(dy / length, dx / length)
    gx, gy = values["gravity"]
    life = values["lifetime"]
    for angle in (base - math.radians(values["spread"]), base, base + math.radians(values["spread"])):
        for speed in values["speed"]:
            for step in (0.25, 0.5, 0.75, 1.0):
                t = life * step
                yield (x + math.cos(angle) * speed * t + 0.5 * gx * t * t,
                       y + math.sin(angle) * speed * t + 0.5 * gy * t * t)


def path_clear(x, y, values, distance, rim_tolerance):
    for px, py in path_samples(x, y, values):
        ix, iy = int(round(px)), int(round(py))
        if ix < 0 or iy < 0 or ix >= CANVAS[0] or iy >= CANVAS[1]:
            continue
        if distance[iy, ix] < rim_tolerance + EMITTER_PATH_MARGIN_PX:
            return False
    return True


def skin_index(skin_id):
    return sorted(SCENERY).index(skin_id) + 1


def all_emission_points(skin_id, distance=None, template=None):
    """Emission points per emitter (UV), deterministic per skin."""
    template = template or load_template()
    distance = floor_distance(template) if distance is None else distance
    image = Image.open(os.path.join(BACKGROUND_DIR, skin_id + ".png")).convert("RGB")
    rgb = np.asarray(image, dtype=np.float32) / 255.0
    pixels = dict(rgb=rgb, luma=rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32), blur={})
    result = []
    for number, spec in enumerate(SCENERY[skin_id].get("emitters", []), 1):
        result.append(emission_points(skin_id, spec, distance, template["rim_tolerance_px"], pixels,
                                      skin_index(skin_id) * 100 + number))
    return result


def preview_tile(skin_id, red, green, pixels, points):
    """Top and bottom scenery bands with R (red), G (green) and emission points (white)."""
    base = pixels["rgb"] * 0.75
    overlay = base.copy()
    overlay[..., 0] = np.clip(overlay[..., 0] + red * 0.9, 0, 1)
    overlay[..., 1] = np.clip(overlay[..., 1] + green * 0.45, 0, 1)
    image = Image.fromarray((overlay * 255).astype(np.uint8), "RGB")
    draw = ImageDraw.Draw(image)
    for emitter_points in points:
        for u, v in emitter_points:
            x, y = u * CANVAS[0], v * CANVAS[1]
            draw.ellipse([x - 4, y - 4, x + 4, y + 4], outline=(255, 255, 255))
    top = image.crop((0, 0, CANVAS[0], int(CANVAS[1] * 0.24)))
    bottom = image.crop((0, int(CANVAS[1] * 0.78), CANVAS[0], CANVAS[1]))
    width = 420
    tile = Image.new("RGB", (width * 2 + 6, int(top.height * width / CANVAS[0])), (40, 0, 40))
    tile.paste(top.resize((width, tile.height)), (0, 0))
    bottom_h = int(bottom.height * width / CANVAS[0])
    tile.paste(bottom.resize((width, bottom_h)), (width + 6, 0))
    ImageDraw.Draw(tile).text((4, tile.height - 12), skin_id, fill=(255, 255, 0))
    return tile


def main(argv):
    template = load_template()
    rim_tolerance = float(template["rim_tolerance_px"])
    distance = floor_distance(template)
    wanted = [skin for skin in SCENERY if not argv or skin in argv]
    os.makedirs(MASK_DIR, exist_ok=True)
    tiles = []
    for skin_id in wanted:
        red, green, blue, ids, pixels = build_mask(skin_id, SCENERY[skin_id], distance, rim_tolerance)
        mask = to_mask_image(red, green, blue, ids)
        mask.save(os.path.join(MASK_DIR, skin_id + ".png"), optimize=True)
        points = all_emission_points(skin_id, distance, template)
        tiles.append(preview_tile(skin_id, red, green, pixels, points))
        print("endless_scenery: %s mask, %d zones, %d emitters" % (
            skin_id, len(SCENERY[skin_id]["zones"]), len(points)))
    if tiles:
        os.makedirs(os.path.dirname(PREVIEW), exist_ok=True)
        sheet = Image.new("RGB", (tiles[0].width, sum(tile.height + 4 for tile in tiles)), (0, 0, 0))
        y = 0
        for tile in tiles:
            sheet.paste(tile, (0, y))
            y += tile.height + 4
        sheet.save(PREVIEW)
        print("endless_scenery: preview -> %s" % PREVIEW)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
