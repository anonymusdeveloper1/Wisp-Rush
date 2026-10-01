#!/usr/bin/env python3
"""Slice the enemy and boss sheets of the Rifts v1 concept pack into runtime art under assets/art/.

Companion to extract_redesign.py (ADR-0005): the pack (Milestone 8) ships clean 4x3 sheets with real
alpha, so it needs cell cropping and occupancy normalisation only - no checkerboard matting or
component segmentation. The pack's four Rift backdrops and its props sheet were removed with the
story Rifts (2026-09-25); the enemies and bosses it holds are the Endless enemy mixes' own.

Run from the repo root:  python3 tools/art/extract_rifts.py
Then re-import:          tools/validate.sh
Never hand-edit the outputs; change this file and re-run.
"""

import os
import sys

from PIL import Image

SRC = "concept_art/wisp_rush_rifts_v1/assets"
OUT = "assets/art"

# sheet -> (out dir, canvas, target content height, [(name, [cell indices sharing one scale])])
SHEETS = [
    (
        "06_new_enemies_sheet.png", "characters/enemies", 362, 260,
        [
            ("13_cinder_shade_idle_a.png", [0]),
            ("14_cinder_shade_idle_b.png", [1]),
            ("15_cinder_shade_split.png", [2]),
            ("16_cinder_shade_dissolve.png", [3]),
            ("17_warden_idle.png", [4]),
            ("18_warden_turn.png", [5]),
            ("19_warden_shield_hit.png", [6]),
            ("20_warden_dissolve.png", [7]),
            ("21_rift_spawn_rest.png", [8]),
            ("22_rift_spawn_taut.png", [9]),
            ("23_rift_spawn_snap.png", [10]),
            ("24_rift_spawn_dissolve.png", [11]),
        ],
        # One scale per enemy family (row), so all four of its frames stay consistent.
        [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11]],
    ),
    (
        "07_boss_hollow_choir_sheet.png", "characters/hollow_choir", 444, 390,
        [
            ("01_dormant.png", [0]),
            ("02_awaken.png", [1]),
            ("03_idle.png", [2]),
            ("04_core_broken_one.png", [3]),
            ("05_core_broken_two.png", [4]),
            ("06_cores_shattered.png", [5]),
            ("07_sound_windup.png", [6]),
            ("08_sound_release.png", [7]),
            ("09_frost_cast.png", [8]),
            ("10_stagger.png", [9]),
            ("11_shatter.png", [10]),
            ("12_dissolve.png", [11]),
        ],
        # One creature: every frame shares a single scale.
        [list(range(12))],
    ),
    (
        "08_boss_the_fracture.png", "characters/the_fracture", 444, 390,
        [
            ("01_dormant.png", [0]), ("02_awaken.png", [1]), ("03_idle.png", [2]),
            ("04_core_exposed.png", [3]), ("05_windup.png", [4]), ("06_slab_volley.png", [5]),
            ("07_portal_open.png", [6]), ("08_blink_out.png", [7]), ("09_reform.png", [8]),
            ("10_stagger.png", [9]), ("11_break.png", [10]), ("12_dissolve.png", [11]),
        ],
        [list(range(12))],
    ),
    (
        "09_boss_cinder_maw.png", "characters/cinder_maw", 444, 390,
        [
            ("01_dormant.png", [0]), ("02_awaken.png", [1]), ("03_idle.png", [2]),
            ("04_vent_one.png", [3]), ("05_vent_two.png", [4]), ("06_vent_three.png", [5]),
            ("07_inhale.png", [6]), ("08_erupt.png", [7]), ("09_magma_spray.png", [8]),
            ("10_stagger.png", [9]), ("11_collapse.png", [10]), ("12_dissolve.png", [11]),
        ],
        [list(range(12))],
    ),
    (
        # Four creatures of three poses each, laid out row-major: creature N owns cells 3N..3N+2,
        # which crosses the grid's row boundaries - group by index triple, not by row.
        "10_arena_enemies_sheet.png", "characters/enemies", 362, 260,
        [
            ("25_echo_idle_a.png", [0]),
            ("26_echo_idle_b.png", [1]),
            ("27_echo_dissolve.png", [2]),
            ("28_slag_hulk_idle_a.png", [3]),
            ("29_slag_hulk_idle_b.png", [4]),
            ("30_slag_hulk_dissolve.png", [5]),
            ("31_frost_wisp_idle_a.png", [6]),
            ("32_frost_wisp_idle_b.png", [7]),
            ("33_frost_wisp_dissolve.png", [8]),
            ("34_court_shade_idle_a.png", [9]),
            ("35_court_shade_idle_b.png", [10]),
            ("36_court_shade_dissolve.png", [11]),
        ],
        [[0, 1, 2], [3, 4, 5], [6, 7, 8], [9, 10, 11]],
    ),
]

ALPHA_FLOOR = 32
GRID_COLS = 4
GRID_ROWS = 3


def content_box(img):
    """Bounding box of pixels above ALPHA_FLOOR, or None when the cell is empty."""
    return img.split()[3].point(lambda a: 255 if a > ALPHA_FLOOR else 0).getbbox()


def cells(sheet):
    """Split a sheet into GRID_COLS x GRID_ROWS equal RGBA cells, row-major."""
    cw = sheet.width // GRID_COLS
    ch = sheet.height // GRID_ROWS
    out = []
    for row in range(GRID_ROWS):
        for col in range(GRID_COLS):
            out.append(sheet.crop((col * cw, row * ch, (col + 1) * cw, (row + 1) * ch)))
    return out


def normalise(cell, scale, canvas):
    """Trim a cell to its content, scale it, and centre it on a square transparent canvas."""
    box = content_box(cell)
    if box is None:
        return Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    art = cell.crop(box)
    width = max(1, int(round(art.width * scale)))
    height = max(1, int(round(art.height * scale)))
    # Content must never leave the canvas - shrink to fit as a last resort.
    if width > canvas or height > canvas:
        fit = min(canvas / float(width), canvas / float(height))
        width = max(1, int(width * fit))
        height = max(1, int(height * fit))
    art = art.resize((width, height), Image.LANCZOS)
    out = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    out.paste(art, ((canvas - width) // 2, (canvas - height) // 2))
    return out


def write_sheets(report):
    for sheet_name, out_dir, canvas, target_h, items, scale_groups in SHEETS:
        sheet = Image.open(os.path.join(SRC, sheet_name)).convert("RGBA")
        parts = cells(sheet)

        # One scale per group, from that group's median content height.
        scale_for_cell = {}
        for group in scale_groups:
            heights = []
            for index in group:
                box = content_box(parts[index])
                if box is not None:
                    heights.append(box[3] - box[1])
            if not heights:
                continue
            heights.sort()
            median = heights[len(heights) // 2]
            scale = target_h / float(median)
            for index in group:
                scale_for_cell[index] = scale

        target = os.path.join(OUT, out_dir)
        os.makedirs(target, exist_ok=True)
        for out_name, indices in items:
            index = indices[0]
            out = normalise(parts[index], scale_for_cell.get(index, 1.0), canvas)
            out.save(os.path.join(target, out_name))
            report.append("%s cell %2d -> %s/%s  %dx%d  scale=%.3f"
                          % (sheet_name, index, out_dir, out_name, canvas, canvas,
                             scale_for_cell.get(index, 1.0)))


def main():
    if not os.path.isdir(SRC):
        sys.stderr.write("missing source pack: %s\n" % SRC)
        return 1
    report = []
    write_sheets(report)
    os.makedirs("logs/rifts", exist_ok=True)
    with open("logs/rifts/extract_report.txt", "w") as handle:
        handle.write("\n".join(report) + "\n")
    print("\n".join(report))
    print("\n%d files written. Re-import with tools/validate.sh" % len(report))
    return 0


if __name__ == "__main__":
    sys.exit(main())
