#!/usr/bin/env python3
"""Build Verdant Shade's review sprite sheet from a generated key-pose atlas.

This source pack is intentionally outside runtime art.  The script extracts the
sixteen 4x4 key poses, registers them to a fixed canvas, creates the exact frame
counts from the character-frame contract, and writes the numbered PNGs plus a
single one-row-per-state review sheet.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
ATLAS = ROOT / "key_pose_atlas.png"
LOOP_ATLAS = ROOT / "loop_phase_atlas.png"
ACTION_ATLAS = ROOT / "action_phase_atlas.png"
DEATH_SPAWN_FLOOR_ATLAS = ROOT / "death_spawn_floor_atlas.png"
WALL_MENU_ATLAS = ROOT / "wall_menu_phase_atlas.png"
WALL_TOP_STRIP = ROOT / "wall_top_phase_strip.png"
FRAMES = ROOT / "frames" / "verdant_shade"
SHEETS = ROOT / "sheets"

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
    pixels = list(image.get_flattened_data())
    image.putdata([(0, 0, 0, 0) if a == 0 else (r, g, b, a) for r, g, b, a in pixels])
    return image


def extract_registered_cell(atlas: Image.Image, index: int, canvas_size: int) -> Image.Image:
    """Resize a complete atlas cell so generated pose-to-pose registration is preserved."""
    row, column = divmod(index, 4)
    x0 = round(atlas.width * column / 4)
    x1 = round(atlas.width * (column + 1) / 4)
    y0 = round(atlas.height * row / 4)
    y1 = round(atlas.height * (row + 1) / 4)
    cell = atlas.crop((x0, y0, x1, y1))
    cell = cell.resize((canvas_size, canvas_size), Image.Resampling.LANCZOS)
    return clean_transparent_rgb(cell)


def extract_horizontal_cell(
    strip: Image.Image,
    index: int,
    cell_count: int,
    canvas_size: int,
) -> Image.Image:
    """Extract one cell from a single-row animation strip."""
    x0 = round(strip.width * index / cell_count)
    x1 = round(strip.width * (index + 1) / cell_count)
    cell = strip.crop((x0, 0, x1, strip.height))
    cell = cell.resize((canvas_size, canvas_size), Image.Resampling.LANCZOS)
    return clean_transparent_rgb(cell)


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

    # Forward matrix: rotation * scale/shear. Pillow needs its inverse.
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


def interpolate_drawn_phases(
    phases: list[Image.Image],
    count: int,
    *,
    loop: bool,
) -> list[Image.Image]:
    """Expand registered hand-drawn phases into crisp timing frames without cross-fades."""
    if count < 1 or len(phases) < 2:
        raise ValueError("Animation interpolation needs frames and at least two drawn phases")
    result: list[Image.Image] = []
    for output_index in range(count):
        phase_position = output_index * len(phases) / count
        phase_index = min(int(math.floor(phase_position)), len(phases) - 1)
        local = (phase_position - math.floor(phase_position)) * 2.0 - 1.0
        # The visible change comes from the separately generated phase. These tiny centred steps
        # only distribute that drawing across its playback time; they never dissolve two bodies.
        amount = 0.38 if loop else 0.24
        result.append(
            affine_about_center(
                phases[phase_index],
                rotation=amount * local,
                scale_x=1.0 + 0.003 * local,
                scale_y=1.0 - 0.002 * local,
                shear_x=0.004 * local,
            )
        )
    return result


def make_sequences(
    loop_game: list[Image.Image],
    loop_menu: list[Image.Image],
    action: list[Image.Image],
    death_spawn_floor: list[Image.Image],
    wall_top_game: list[Image.Image],
    wall_game: list[Image.Image],
    wall_menu: list[Image.Image],
) -> dict[str, list[Image.Image]]:
    # Every source list below contains separately generated drawings. The expander only distributes
    # each crisp phase across its playback time; it never dissolves two bodies into a ghost frame.
    return {
        "idle_hover": interpolate_drawn_phases(loop_game[0:4], 12, loop=True),
        "move_fly": interpolate_drawn_phases(loop_game[4:8], 8, loop=True),
        "dash_start": [image.copy() for image in action[0:2]],
        "dash_loop": [image.copy() for image in action[4:8]],
        "dash_end": [image.copy() for image in action[2:4]],
        "attack": [image.copy() for image in action[8:11]],
        "hit_reaction": [image.copy() for image in action[12:15]],
        "death": [image.copy() for image in death_spawn_floor[0:6]],
        "revive_spawn": [image.copy() for image in death_spawn_floor[6:12]],
        "victory": interpolate_drawn_phases(loop_game[8:12], 8, loop=True),
        "wall_bottom": interpolate_drawn_phases(death_spawn_floor[12:16], 8, loop=True),
        "wall_top": interpolate_drawn_phases(wall_top_game, 8, loop=True),
        "wall_left": interpolate_drawn_phases(wall_game[4:8], 8, loop=True),
        "storefront_idle": interpolate_drawn_phases(loop_menu[12:16], 12, loop=True),
        "storefront_flourish": interpolate_drawn_phases(wall_menu[8:12], 8, loop=False),
        "storefront_unlock": interpolate_drawn_phases(wall_menu[12:16], 10, loop=False),
    }


def save_numbered_frames(sequences: dict[str, list[Image.Image]]) -> None:
    for state, images in sequences.items():
        folder = FRAMES / ("storefront" if state.startswith("storefront_") else "")
        folder.mkdir(parents=True, exist_ok=True)
        for index, image in enumerate(images):
            image.save(folder / f"{state}_{index:02d}.png", optimize=True)


def fit_to_cell(image: Image.Image, cell_width: int, cell_height: int) -> Image.Image:
    bbox = alpha_bbox(image)
    cropped = image.crop(bbox)
    scale = min((cell_width * 0.88) / cropped.width, (cell_height * 0.88) / cropped.height)
    size = (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale)))
    cropped = cropped.resize(size, Image.Resampling.LANCZOS)
    cell = Image.new("RGBA", (cell_width, cell_height), (0, 0, 0, 0))
    cell.alpha_composite(cropped, ((cell_width - cropped.width) // 2, (cell_height - cropped.height) // 2))
    return cell


def register_visible_content(image: Image.Image) -> Image.Image:
    """Place the visible drawing on the exact canvas centre without rescaling it."""
    cropped = image.crop(alpha_bbox(image))
    canvas = Image.new("RGBA", image.size, (0, 0, 0, 0))
    canvas.alpha_composite(cropped, ((image.width - cropped.width) // 2, (image.height - cropped.height) // 2))
    return clean_transparent_rgb(canvas)


def make_review_sheet(sequences: dict[str, list[Image.Image]]) -> tuple[Image.Image, dict[str, object]]:
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
            sheet.alpha_composite(fit_to_cell(image, REVIEW_CELL, REVIEW_CELL), (column * REVIEW_CELL, row * REVIEW_CELL))
        manifest_rows.append(
            {
                "row": row,
                "state": state,
                "frames": len(images),
                "fps": STATE_FPS[state],
                "loop": state in LOOPING_STATES,
            }
        )
    manifest = {
        "character": "Verdant Shade",
        "id": "verdant_shade",
        "cell": [REVIEW_CELL, REVIEW_CELL],
        "columns": REVIEW_COLUMNS,
        "rows": manifest_rows,
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
    preview = Image.new("RGB", (label_width + REVIEW_COLUMNS * cell, len(rows) * cell), (11, 20, 19))
    draw = ImageDraw.Draw(preview)
    font = ImageFont.load_default(size=18)
    small = ImageFont.load_default(size=14)
    for row_info in rows:
        assert isinstance(row_info, dict)
        row = int(row_info["row"])
        state = str(row_info["state"])
        frame_count = int(row_info["frames"])
        y = row * cell
        draw.rectangle((0, y, preview.width - 1, y + cell - 1), outline=(40, 75, 63))
        draw.text((16, y + 40), state, fill=(215, 235, 220), font=font)
        draw.text((16, y + 70), f"{frame_count} frames", fill=(132, 190, 151), font=small)
        row_crop = sheet.crop((0, row * REVIEW_CELL, sheet.width, (row + 1) * REVIEW_CELL))
        row_crop = row_crop.resize((REVIEW_COLUMNS * cell, cell), Image.Resampling.LANCZOS)
        preview.paste(row_crop.convert("RGB"), (label_width, y), row_crop.getchannel("A"))
        for column in range(REVIEW_COLUMNS + 1):
            x = label_width + column * cell
            draw.line((x, y, x, y + cell), fill=(27, 51, 44), width=1)
    return preview


def main() -> None:
    atlas_paths = (
        ATLAS,
        LOOP_ATLAS,
        ACTION_ATLAS,
        DEATH_SPAWN_FLOOR_ATLAS,
        WALL_MENU_ATLAS,
        WALL_TOP_STRIP,
    )
    missing = [path for path in atlas_paths if not path.exists()]
    if missing:
        raise FileNotFoundError(f"Missing generated atlas: {missing[0]}")

    loop_atlas = Image.open(LOOP_ATLAS).convert("RGBA")
    action_atlas = Image.open(ACTION_ATLAS).convert("RGBA")
    death_spawn_floor_atlas = Image.open(DEATH_SPAWN_FLOOR_ATLAS).convert("RGBA")
    wall_menu_atlas = Image.open(WALL_MENU_ATLAS).convert("RGBA")
    wall_top_strip = Image.open(WALL_TOP_STRIP).convert("RGBA")
    loop_game = [extract_registered_cell(loop_atlas, index, GAMEPLAY_SIZE) for index in range(16)]
    loop_menu = [extract_registered_cell(loop_atlas, index, MENU_SIZE) for index in range(16)]
    action = [extract_registered_cell(action_atlas, index, GAMEPLAY_SIZE) for index in range(16)]
    death_spawn_floor = [
        extract_registered_cell(death_spawn_floor_atlas, index, GAMEPLAY_SIZE)
        for index in range(16)
    ]
    wall_game = [extract_registered_cell(wall_menu_atlas, index, GAMEPLAY_SIZE) for index in range(16)]
    wall_menu = [extract_registered_cell(wall_menu_atlas, index, MENU_SIZE) for index in range(16)]
    wall_top_game = [
        extract_horizontal_cell(wall_top_strip, index, 4, GAMEPLAY_SIZE)
        for index in range(4)
    ]
    sequences = make_sequences(
        loop_game,
        loop_menu,
        action,
        death_spawn_floor,
        wall_top_game,
        wall_game,
        wall_menu,
    )
    sequences = {
        state: [register_visible_content(image) for image in images]
        for state, images in sequences.items()
    }

    for state, expected in STATE_COUNTS.items():
        actual = len(sequences[state])
        if actual != expected:
            raise AssertionError(f"{state}: expected {expected}, got {actual}")

    save_numbered_frames(sequences)
    SHEETS.mkdir(parents=True, exist_ok=True)
    sheet, manifest = make_review_sheet(sequences)
    sheet.save(SHEETS / "verdant_shade_sprite_sheet.png", optimize=True)
    make_preview(sheet, manifest).save(SHEETS / "verdant_shade_sprite_sheet_preview.png", optimize=True)
    (SHEETS / "verdant_shade_sprite_sheet.json").write_text(
        json.dumps(manifest, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Built {sum(len(images) for images in sequences.values())} frames")
    print(f"Sheet: {sheet.width}x{sheet.height}")


if __name__ == "__main__":
    main()
