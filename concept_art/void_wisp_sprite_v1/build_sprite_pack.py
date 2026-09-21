#!/usr/bin/env python3
"""Build the Void Wisp whole-frame review pack from generated phase atlases.

The atlases contain separately drawn neighbouring poses. This builder preserves
those drawings, centres their visible content, adds only sub-pixel timing changes
inside each phase, and writes the exact Wisp Rush frame contract. It deliberately
does not cross-fade poses because a dissolve reads as a doubled/ghosted Wisp.
"""

from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageStat


ROOT = Path(__file__).resolve().parent
LOOP_ATLAS = ROOT / "loop_phase_atlas.png"
ACTION_ATLAS = ROOT / "action_phase_atlas.png"
DEATH_SPAWN_FLOOR_ATLAS = ROOT / "death_spawn_floor_atlas.png"
WALL_MENU_ATLAS = ROOT / "wall_menu_phase_atlas.png"
FRAMES = ROOT / "frames" / "void_wisp"
SHEETS = ROOT / "sheets"
PREVIEWS = ROOT / "previews"

GAMEPLAY_SIZE = 512
MENU_SIZE = 724
REVIEW_CELL = 256
REVIEW_COLUMNS = 12

STATE_COUNTS = {
    "idle_hover": 12,
    "move_fly": 8,
    "dash_start": 2,
    "dash_loop": 4,
    "dash_end": 2,
    "attack": 3,
    "hit_reaction": 3,
    "death": 6,
    "revive_spawn": 6,
    "victory": 8,
    "wall_bottom": 8,
    "wall_top": 8,
    "wall_left": 8,
    "storefront_idle": 12,
    "storefront_flourish": 8,
    "storefront_unlock": 10,
}

STATE_FPS = {
    "idle_hover": 6.7,
    "move_fly": 11.4,
    "dash_start": 16.0,
    "dash_loop": 12.5,
    "dash_end": 12.0,
    "attack": 12.5,
    "hit_reaction": 9.4,
    "death": 12.0,
    "revive_spawn": 10.3,
    "victory": 8.9,
    "wall_bottom": 6.7,
    "wall_top": 6.7,
    "wall_left": 6.7,
    "storefront_idle": 6.0,
    "storefront_flourish": 12.9,
    "storefront_unlock": 11.0,
}

LOOPING_STATES = {
    "idle_hover",
    "move_fly",
    "dash_loop",
    "victory",
    "wall_bottom",
    "wall_top",
    "wall_left",
    "storefront_idle",
}


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    bbox = alpha.point(lambda value: 255 if value > 8 else 0).getbbox()
    if bbox is None:
        raise ValueError("Pose has no visible pixels")
    return bbox


def clean_transparent_rgb(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    image.putdata(
        [
            (0, 0, 0, 0) if a == 0 else (r, g, b, a)
            for r, g, b, a in image.get_flattened_data()
        ]
    )
    return image


def extract_cell(atlas: Image.Image, index: int, canvas_size: int) -> Image.Image:
    """Extract one cell from a strict 4 x 4 atlas without altering its composition."""
    row, column = divmod(index, 4)
    x0 = round(atlas.width * column / 4)
    x1 = round(atlas.width * (column + 1) / 4)
    y0 = round(atlas.height * row / 4)
    y1 = round(atlas.height * (row + 1) / 4)
    cell = atlas.crop((x0, y0, x1, y1))
    return clean_transparent_rgb(
        cell.resize((canvas_size, canvas_size), Image.Resampling.LANCZOS)
    )


def affine_about_center(
    image: Image.Image,
    *,
    rotation: float = 0.0,
    scale_x: float = 1.0,
    scale_y: float = 1.0,
    shear_x: float = 0.0,
) -> Image.Image:
    width, height = image.size
    pivot_x = width / 2.0
    pivot_y = height / 2.0
    angle = math.radians(rotation)
    cos_a = math.cos(angle)
    sin_a = math.sin(angle)

    a = cos_a * scale_x
    b = cos_a * shear_x - sin_a * scale_y
    d = sin_a * scale_x
    e = sin_a * shear_x + cos_a * scale_y
    determinant = a * e - b * d
    ia = e / determinant
    ib = -b / determinant
    id_ = -d / determinant
    ie = a / determinant
    c = pivot_x - ia * pivot_x - ib * pivot_y
    f = pivot_y - id_ * pivot_x - ie * pivot_y
    result = image.transform(
        image.size,
        Image.Transform.AFFINE,
        (ia, ib, c, id_, ie, f),
        resample=Image.Resampling.BICUBIC,
        fillcolor=(0, 0, 0, 0),
    )
    return clean_transparent_rgb(result)


def expand_drawn_phases(phases: list[Image.Image], count: int) -> list[Image.Image]:
    """Distribute distinct drawings through a sequence using imperceptible micro-timing.

    Each generated drawing owns a contiguous group of output frames. The tiny centred
    deformation changes every neighbouring frame without replacing the artist-drawn
    flame contour or dissolving one pose into another.
    """
    if count < len(phases) or len(phases) < 2:
        raise ValueError("Need at least one timing frame per drawn phase")

    assignments = [min((index * len(phases)) // count, len(phases) - 1) for index in range(count)]
    group_sizes = [assignments.count(phase) for phase in range(len(phases))]
    group_offsets = [0] * len(phases)
    result: list[Image.Image] = []

    for phase_index in assignments:
        group_size = group_sizes[phase_index]
        offset = group_offsets[phase_index]
        group_offsets[phase_index] += 1
        local = 0.0 if group_size == 1 else -1.0 + (2.0 * offset / (group_size - 1))
        result.append(
            affine_about_center(
                phases[phase_index],
                rotation=0.12 * local,
                scale_x=1.0 + 0.0008 * local,
                scale_y=1.0 - 0.0006 * local,
                shear_x=0.0012 * local,
            )
        )
    return result


def register_visible_content(image: Image.Image) -> Image.Image:
    """Centre the alpha silhouette on its fixed canvas without rescaling it."""
    cropped = image.crop(alpha_bbox(image))
    canvas = Image.new("RGBA", image.size, (0, 0, 0, 0))
    canvas.alpha_composite(
        cropped,
        ((image.width - cropped.width) // 2, (image.height - cropped.height) // 2),
    )
    return clean_transparent_rgb(canvas)


def make_sequences(
    loop_game: list[Image.Image],
    loop_menu: list[Image.Image],
    action: list[Image.Image],
    death_spawn_floor: list[Image.Image],
    wall_game: list[Image.Image],
    wall_menu: list[Image.Image],
) -> dict[str, list[Image.Image]]:
    return {
        "idle_hover": expand_drawn_phases(loop_game[0:4], 12),
        "move_fly": expand_drawn_phases(loop_game[4:8], 8),
        "dash_start": [image.copy() for image in action[0:2]],
        "dash_loop": [image.copy() for image in action[4:8]],
        "dash_end": [image.copy() for image in action[2:4]],
        "attack": [image.copy() for image in action[8:11]],
        "hit_reaction": [image.copy() for image in action[12:15]],
        "death": [image.copy() for image in death_spawn_floor[0:6]],
        "revive_spawn": [image.copy() for image in death_spawn_floor[6:12]],
        "victory": expand_drawn_phases(loop_game[8:12], 8),
        "wall_bottom": expand_drawn_phases(death_spawn_floor[12:16], 8),
        "wall_top": expand_drawn_phases(wall_game[0:4], 8),
        "wall_left": expand_drawn_phases(wall_game[4:8], 8),
        "storefront_idle": expand_drawn_phases(loop_menu[12:16], 12),
        "storefront_flourish": expand_drawn_phases(wall_menu[8:12], 8),
        "storefront_unlock": expand_drawn_phases(wall_menu[12:16], 10),
    }


def save_numbered_frames(sequences: dict[str, list[Image.Image]]) -> None:
    for state, images in sequences.items():
        folder = FRAMES / ("storefront" if state.startswith("storefront_") else "")
        folder.mkdir(parents=True, exist_ok=True)
        for index, image in enumerate(images):
            image.save(folder / f"{state}_{index:02d}.png", optimize=True)


def fit_to_cell(image: Image.Image, width: int, height: int) -> Image.Image:
    cropped = image.crop(alpha_bbox(image))
    scale = min((width * 0.88) / cropped.width, (height * 0.88) / cropped.height)
    size = (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale)))
    cropped = cropped.resize(size, Image.Resampling.LANCZOS)
    cell = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    cell.alpha_composite(cropped, ((width - cropped.width) // 2, (height - cropped.height) // 2))
    return cell


def frame_difference(first: Image.Image, second: Image.Image) -> float:
    difference = ImageChops.difference(first, second).convert("RGB")
    rms = ImageStat.Stat(difference).rms
    return round(sum(rms) / (3.0 * 255.0), 5)


def make_review_sheet(
    sequences: dict[str, list[Image.Image]],
) -> tuple[Image.Image, dict[str, object]]:
    rows = list(STATE_COUNTS)
    sheet = Image.new(
        "RGBA",
        (REVIEW_COLUMNS * REVIEW_CELL, len(rows) * REVIEW_CELL),
        (0, 0, 0, 0),
    )
    manifest_rows: list[dict[str, object]] = []

    for row, state in enumerate(rows):
        images = sequences[state]
        for column, image in enumerate(images):
            sheet.alpha_composite(
                fit_to_cell(image, REVIEW_CELL, REVIEW_CELL),
                (column * REVIEW_CELL, row * REVIEW_CELL),
            )
        differences = [
            frame_difference(images[index], images[index + 1])
            for index in range(len(images) - 1)
        ]
        if state in LOOPING_STATES:
            differences.append(frame_difference(images[-1], images[0]))
        manifest_rows.append(
            {
                "row": row,
                "state": state,
                "frames": len(images),
                "fps": STATE_FPS[state],
                "loop": state in LOOPING_STATES,
                "neighbor_difference_mean": round(sum(differences) / len(differences), 5),
                "neighbor_difference_max": max(differences),
            }
        )

    manifest = {
        "character": "Void Wisp",
        "id": "void",
        "total_frames": sum(STATE_COUNTS.values()),
        "cell": [REVIEW_CELL, REVIEW_CELL],
        "columns": REVIEW_COLUMNS,
        "rows": manifest_rows,
        "dash_contact_frame": {"state": "dash_loop", "index": 2},
        "wall_right": "mirror wall_left at runtime",
        "character_selected": "storefront_flourish",
        "character_unlocked": "storefront_unlock",
        "aim_charge": "not generated",
    }
    return clean_transparent_rgb(sheet), manifest


def make_preview(sheet: Image.Image, manifest: dict[str, object]) -> Image.Image:
    scale = 0.5
    cell = round(REVIEW_CELL * scale)
    label_width = 260
    rows = manifest["rows"]
    assert isinstance(rows, list)
    preview = Image.new("RGB", (label_width + REVIEW_COLUMNS * cell, len(rows) * cell), (7, 13, 26))
    draw = ImageDraw.Draw(preview)
    font = ImageFont.load_default(size=18)
    small = ImageFont.load_default(size=14)

    for row_info in rows:
        assert isinstance(row_info, dict)
        row = int(row_info["row"])
        state = str(row_info["state"])
        frame_count = int(row_info["frames"])
        y = row * cell
        draw.rectangle((0, y, preview.width - 1, y + cell - 1), outline=(27, 57, 91))
        draw.text((16, y + 36), state, fill=(220, 242, 255), font=font)
        draw.text((16, y + 66), f"{frame_count} frames", fill=(90, 204, 245), font=small)
        row_crop = sheet.crop((0, row * REVIEW_CELL, sheet.width, (row + 1) * REVIEW_CELL))
        row_crop = row_crop.resize((REVIEW_COLUMNS * cell, cell), Image.Resampling.LANCZOS)
        preview.paste(row_crop.convert("RGB"), (label_width, y), row_crop.getchannel("A"))
        for column in range(REVIEW_COLUMNS + 1):
            x = label_width + column * cell
            draw.line((x, y, x, y + cell), fill=(20, 42, 70), width=1)
    return preview


def make_loop_preview(state: str, images: list[Image.Image]) -> None:
    rendered: list[Image.Image] = []
    for image in images:
        cell = fit_to_cell(image, 320, 320)
        background = Image.new("RGB", cell.size, (7, 13, 26))
        background.paste(cell.convert("RGB"), (0, 0), cell.getchannel("A"))
        rendered.append(background)
    duration = round(1000.0 / STATE_FPS[state])
    rendered[0].save(
        PREVIEWS / f"{state}.gif",
        save_all=True,
        append_images=rendered[1:],
        duration=duration,
        loop=0,
        optimize=False,
    )


def validate_pack(sequences: dict[str, list[Image.Image]]) -> dict[str, object]:
    flattened = [image for images in sequences.values() for image in images]
    if len(flattened) != 108:
        raise AssertionError(f"Expected 108 total frames, got {len(flattened)}")

    hashes: set[str] = set()
    centres: list[tuple[float, float]] = []
    for state, images in sequences.items():
        expected_size = MENU_SIZE if state.startswith("storefront_") else GAMEPLAY_SIZE
        if len(images) != STATE_COUNTS[state]:
            raise AssertionError(f"{state}: expected {STATE_COUNTS[state]}, got {len(images)}")
        for image in images:
            if image.size != (expected_size, expected_size):
                raise AssertionError(f"{state}: wrong canvas {image.size}")
            for red, green, blue, alpha in image.get_flattened_data():
                if alpha == 0 and (red or green or blue):
                    raise AssertionError(f"{state}: non-zero RGB under transparent alpha")
            hashes.add(hashlib.sha256(image.tobytes()).hexdigest())
            left, top, right, bottom = alpha_bbox(image)
            centres.append(((left + right) / 2.0, (top + bottom) / 2.0))

    if len(hashes) != len(flattened):
        raise AssertionError("Every output frame must be pixel-distinct")
    centre_offsets = [
        max(abs(x - flattened[index].width / 2.0), abs(y - flattened[index].height / 2.0))
        for index, (x, y) in enumerate(centres)
    ]
    return {
        "frames": len(flattened),
        "unique_frames": len(hashes),
        "maximum_alpha_bbox_centre_offset_px": max(centre_offsets),
        "transparent_rgb": "zeroed",
    }


def main() -> None:
    atlas_paths = (LOOP_ATLAS, ACTION_ATLAS, DEATH_SPAWN_FLOOR_ATLAS, WALL_MENU_ATLAS)
    missing = [path for path in atlas_paths if not path.exists()]
    if missing:
        raise FileNotFoundError(f"Missing generated atlas: {missing[0]}")

    loop_atlas = Image.open(LOOP_ATLAS).convert("RGBA")
    action_atlas = Image.open(ACTION_ATLAS).convert("RGBA")
    death_spawn_floor_atlas = Image.open(DEATH_SPAWN_FLOOR_ATLAS).convert("RGBA")
    wall_menu_atlas = Image.open(WALL_MENU_ATLAS).convert("RGBA")
    loop_game = [extract_cell(loop_atlas, index, GAMEPLAY_SIZE) for index in range(16)]
    loop_menu = [extract_cell(loop_atlas, index, MENU_SIZE) for index in range(16)]
    action = [extract_cell(action_atlas, index, GAMEPLAY_SIZE) for index in range(16)]
    death_spawn_floor = [
        extract_cell(death_spawn_floor_atlas, index, GAMEPLAY_SIZE) for index in range(16)
    ]
    wall_game = [extract_cell(wall_menu_atlas, index, GAMEPLAY_SIZE) for index in range(16)]
    wall_menu = [extract_cell(wall_menu_atlas, index, MENU_SIZE) for index in range(16)]

    sequences = make_sequences(
        loop_game,
        loop_menu,
        action,
        death_spawn_floor,
        wall_game,
        wall_menu,
    )
    sequences = {
        state: [register_visible_content(image) for image in images]
        for state, images in sequences.items()
    }
    qa = validate_pack(sequences)

    save_numbered_frames(sequences)
    SHEETS.mkdir(parents=True, exist_ok=True)
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    sheet, manifest = make_review_sheet(sequences)
    manifest["qa"] = qa
    sheet.save(SHEETS / "void_wisp_sprite_sheet.png", optimize=True)
    make_preview(sheet, manifest).save(SHEETS / "void_wisp_sprite_sheet_preview.png", optimize=True)
    (SHEETS / "void_wisp_sprite_sheet.json").write_text(
        json.dumps(manifest, indent=2) + "\n",
        encoding="utf-8",
    )
    for state in ("idle_hover", "move_fly", "wall_top", "storefront_idle"):
        make_loop_preview(state, sequences[state])

    print(f"Built {qa['frames']} unique frames")
    print(f"Registration: <= {qa['maximum_alpha_bbox_centre_offset_px']} px")
    print(f"Sheet: {sheet.width}x{sheet.height}")


if __name__ == "__main__":
    main()
