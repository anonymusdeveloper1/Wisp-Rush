"""Pack the simulation kit from imagegen artwork; no illustration is drawn here.

Run from any directory with Python, Pillow and NumPy. Cropping, palette reduction,
chroma cleanup, repeat-edge conditioning and review composites are deterministic.
The generated reference and raw sheets are retained beside this script.
"""

from __future__ import annotations

import hashlib
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
ART_WIDTH = 540
SOURCE_HEIGHT = 1170
PALETTE = {
    "screen": ["#030A12", "#07111D", "#091B2D", "#0B2335", "#0E2B43", "#12354E", "#164158"],
    "metal": ["#121820", "#1B2430", "#29323F", "#394555", "#4A596A", "#637382", "#80939E", "#A7BCC5", "#CAD7D5"],
    "cyan": ["#093847", "#125568", "#188FA3", "#28BCD2", "#62E8F2", "#B8F7FC", "#EAFDFF"],
    "amber": ["#4E2713", "#7A4319", "#BA6D22", "#F3A847", "#FFD275", "#FFF1C3"],
    "boss": ["#2B143A", "#512860", "#883BA7", "#B14CD9", "#EB39B1", "#FF5FCB", "#FFA5E5", "#FFF1FA"],
}
COLORS = list(dict.fromkeys(c for values in PALETTE.values() for c in values))
FILES: list[dict] = []
IMAGES: dict[str, Image.Image] = {}
MEASUREMENTS: dict = {"pixel_palette": COLORS, "effects": {}, "repeat_edges": {}}
CAP_SIZES = {
    "cap_top_join": (540, 8),
    "cap_top_band": (540, 48),
    "cap_bottom_join": (540, 8),
    "cap_bottom_band": (540, 48),
}
CAP_SOURCE_CROPS = {
    "cap_top_join": (0, 0, 1456, 116),
    "cap_top_band": (0, 0, 1879, 837),
    "cap_bottom_join": (0, 848, 1629, 960),
    "cap_bottom_band": (0, 0, 1881, 836),
}
CAP_RAIL_CROP = (0, 64, 48, 112)


def rgb(value: str) -> tuple[int, int, int]:
    return tuple(int(value[index:index + 2], 16) for index in (1, 3, 5))


def quantize(image: Image.Image, colors: list[str] | None = None) -> Image.Image:
    image = image.convert("RGBA")
    choices = colors or COLORS
    palette = Image.new("P", (1, 1))
    triplets = [rgb(c) for c in choices]
    triplets += [triplets[0]] * (256 - len(triplets))
    palette.putpalette([channel for item in triplets for channel in item])
    out = image.convert("RGB").quantize(palette=palette, dither=Image.Dither.NONE).convert("RGBA")
    alpha = np.array(image.getchannel("A"))
    out.putalpha(Image.fromarray(np.where(alpha >= 128, 255, 0).astype(np.uint8)))
    pixels = np.array(out)
    pixels[pixels[:, :, 3] == 0, :3] = 0
    return Image.fromarray(pixels)


def key_magenta(image: Image.Image) -> Image.Image:
    pixels = np.array(image.convert("RGBA"))
    colors = pixels[:, :, :3].astype(np.int16)
    distance = np.sqrt(np.sum((colors - np.array([255, 0, 255])) ** 2, axis=2, dtype=np.int32))
    background = (distance < 150) | ((colors[:, :, 0] > 180) & (colors[:, :, 2] > 180) & (colors[:, :, 1] < 105))
    pixels[background] = 0
    return Image.fromarray(pixels)


def save_piece(path: str, image: Image.Image, **info: object) -> Image.Image:
    image = image.convert("RGBA")
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    image.save(target)
    IMAGES[path] = image
    entry = {"path": path, "size": list(image.size), "tiles": None, "sha256": hashlib.sha256(target.read_bytes()).hexdigest()}
    entry.update(info)
    FILES.append(entry)
    return image


def match_edges(image: Image.Image, axis: str, band: int = 2) -> Image.Image:
    image = image.copy()
    if "x" in axis:
        strip = image.crop((0, 0, band, image.height))
        image.paste(strip, (image.width - band, 0))
    if "y" in axis:
        strip = image.crop((0, 0, image.width, band))
        image.paste(strip, (0, image.height - band))
    return image


def tiled(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    result = Image.new("RGBA", size)
    for y in range(0, size[1], image.height):
        for x in range(0, size[0], image.width):
            result.alpha_composite(image, (x, y))
    return result


def paste(canvas: Image.Image, key: str, x: int, y: int) -> None:
    canvas.alpha_composite(IMAGES[key], (x, y))


def cut_static() -> None:
    original = Image.open(ROOT / "reference/approved_board.png").convert("RGBA")
    base = quantize(original.resize((ART_WIDTH, SOURCE_HEIGHT), Image.Resampling.NEAREST))
    base.save(ROOT / "review/approved_board_at_art_scale.png")
    # All border pieces are crops of the approved screen, not regenerated designs.
    border = np.array(base)
    border[64:SOURCE_HEIGHT - 64, 48:ART_WIDTH - 48] = 0
    border = Image.fromarray(border)
    boxes = {
        "corner_top_left": (0, 0, 72, 72),
        "corner_top_right": (468, 0, 540, 72),
        "corner_bottom_left": (0, 1098, 72, 1170),
        "corner_bottom_right": (468, 1098, 540, 1170),
        "side_left_segment": (0, 216, 48, 408),
        "side_right_segment": (492, 216, 540, 408),
        "top_segment": (132, 0, 204, 64),
        "bottom_segment": (132, 1106, 204, 1170),
    }
    for name, box in boxes.items():
        axis = "y" if "side" in name else "x" if "segment" in name else None
        piece = border.crop(box)
        if axis:
            piece = match_edges(piece, axis)
        save_piece(f"frame/{name}.png", piece, tiles=axis, source="reference/approved_board.png", source_crop_art=list(box))

    # Narrow rim samples remain separate so the collision boundary can be exact.
    samples = {
        "screen_rim_left": ((42, 240, 48, 264), "y"),
        "screen_rim_right": ((492, 240, 498, 264), "y"),
        "screen_rim_top": ((200, 57, 224, 63), "x"),
        "screen_rim_bottom": ((200, 1096, 224, 1102), "x"),
    }
    for name, (box, axis) in samples.items():
        save_piece(f"frame/{name}.png", match_edges(base.crop(box), axis), tiles=axis, source="reference/approved_board.png", source_crop_art=list(box))
    frame_pixels = np.array(base)
    cap_rows, cap_cols = np.where(np.all(frame_pixels[:64, :228, :3] == rgb("#29323F"), axis=2))
    cap_x, cap_y = int(cap_cols[0]), int(cap_rows[0])
    cap = base.crop((cap_x, cap_y, cap_x + 1, cap_y + 1)).resize((16, 8), Image.Resampling.NEAREST)
    save_piece("frame/outer_cap_segment.png", cap, tiles="xy", source="reference/approved_board.png", source_crop_art=[cap_x, cap_y, cap_x + 1, cap_y + 1])

    core = base.crop((228, 0, 312, 68))
    core.paste(tiled(core.crop((11, 31, 12, 32)), (32, 43)), (24, 9))
    save_piece("deco/core_housing.png", core, source="reference/approved_board.png", origin=[42, 0], wisp_position=[24, 9])
    wisp = np.array(base.crop((252, 9, 284, 52)))
    keep = ((wisp[:, :, 1] > wisp[:, :, 0] * 1.4) & (wisp[:, :, 2] > wisp[:, :, 0] * 1.3) & (wisp[:, :, 1] > 80)) | ((wisp[:, :, 1] > 180) & (wisp[:, :, 2] > 190))
    wisp[~keep] = 0
    save_piece("deco/core_wisp.png", Image.fromarray(wisp), source="reference/approved_board.png", origin=[16, 26], placement_in_housing=[24, 9])

    # The generated screen swatch replaces the concept's noisy, irregular glass.
    floor_source = key_magenta(Image.open(ROOT / "source/screen_tile_raw.png"))
    floor_source = floor_source.crop(floor_source.getbbox())
    tile = quantize(floor_source.resize((96, 96), Image.Resampling.NEAREST), PALETTE["screen"][1:4])
    # Restore flat pixel rows by repeating each generated row's most common pixel.
    # This removes generation speckle without drawing a new texture pattern.
    tile_rows = np.array(tile)
    for row in range(tile.height):
        values, counts = np.unique(tile_rows[row], axis=0, return_counts=True)
        tile_rows[row] = values[int(counts.argmax())]
    tile = Image.fromarray(tile_rows)
    tile = match_edges(tile, "xy")
    save_piece("floor/screen_tile.png", tile, tiles="xy", source="source/screen_tile_raw.png")
    data_boxes = {"screen_data_left": (52, 280, 88, 424), "screen_data_right": (452, 488, 488, 632)}
    for name, box in data_boxes.items():
        data = np.array(base.crop(box))
        selected = (data[:, :, 1] > 74) & (data[:, :, 2] > 95)
        data[~selected] = 0
        save_piece(f"deco/{name}.png", quantize(Image.fromarray(data), ["#12354E", "#164158", "#125568"]), source="reference/approved_board.png")

    # Gauges are cropped exactly from the concept; only the dynamic sockets are cleared.
    gauge_boxes = {"boss": (96, 132, 452, 166), "rush": (96, 174, 452, 210)}
    meter_rects = {"boss": [55, 12, 248, 11], "rush": [55, 12, 248, 11]}
    for kind, box in gauge_boxes.items():
        raw = base.crop(box)
        array = np.array(raw)
        # Key only the surrounding glass. Keep the cyan registration decoration.
        background = (array[:, :, 0] < 35) & (array[:, :, 1] < 62) & (array[:, :, 2] < 95)
        array[background] = 0
        raw = Image.fromarray(array)
        x, y, w, h = meter_rects[kind]
        empty = base.crop((382, box[1] + y, 388, box[1] + y + h))
        fill = base.crop((161, box[1] + y, 163, box[1] + y + h))
        track = raw.copy()
        track.paste(tiled(empty, (w, h)), (x, y))
        if kind == "rush":
            # Reuse the concept's black separator, not a procedurally illustrated bar.
            divider = base.crop((191, box[1] + y, 193, box[1] + y + h))
            fill_full = tiled(fill, (w, h))
            for split in range(1, 6):
                offset = round(w * split / 6)
                track.paste(divider, (x + offset, y))
                fill_full.paste(divider, (offset, 0))
        else:
            fill_full = tiled(fill, (w, h))
        save_piece(f"hud/{kind}_meter_track.png", track, fill_rect=[x, y, w, h], source="reference/approved_board.png")
        save_piece(f"hud/{kind}_meter_fill.png", fill_full, source="reference/approved_board.png", clip_axis="x", segments=6 if kind == "rush" else None)

    support = key_magenta(Image.open(ROOT / "source/support_hud_raw.png"))
    props = {
        "pause_button": ((64, 175, 364, 468), (36, 36), None),
        "score_plate": ((435, 228, 1024, 425), (128, 36), [12, 11, 104, 17]),
        "rp_plate": ((1078, 244, 1494, 415), (108, 32), [36, 10, 60, 16]),
        "level_badge": ((80, 600, 344, 862), (36, 36), [8, 8, 20, 20]),
        "soul_gauge_track": ((439, 682, 1083, 784), (108, 16), [10, 5, 88, 6]),
        "upgrade_badge": ((1202, 640, 1392, 832), (24, 24), [8, 8, 8, 9]),
    }
    for name, (box, size, socket) in props.items():
        piece = support.crop(box)
        piece = piece.crop(piece.getbbox()).resize(size, Image.Resampling.NEAREST)
        piece = quantize(piece)
        info = {"source": "source/support_hud_raw.png", "source_crop": list(box)}
        if socket:
            if name == "soul_gauge_track":
                info["fill_rect"] = socket
            else:
                info["text_rect"] = socket
            x, y, w, h = socket
            # Reserve sockets using the existing dark screen patch from the approved floor.
            piece.paste(tiled(tile.crop((0, 0, min(w, 96), min(h, 96))), (w, h)), (x, y))
        if name == "rp_plate":
            info["icon_socket"] = [12, 10, 17, 16]
        save_piece(f"hud/{name}.png", piece, **info)
    cyan_fill = base.crop((188, 11, 190, 14)).resize((2, 6), Image.Resampling.NEAREST)
    save_piece("hud/soul_gauge_fill.png", tiled(cyan_fill, (88, 6)), clip_axis="x", source="reference/approved_board.png")

    # Isolate the approved boss screen disturbance into small, reusable patches.
    boss = Image.open(ROOT / "reference/approved_boss_spawn.png").convert("RGBA").resize((ART_WIDTH, SOURCE_HEIGHT), Image.Resampling.NEAREST)
    pixels = np.array(boss)
    signed = pixels[:, :, :3].astype(np.int16)
    pink = (signed[:, :, 0] > 95) & (signed[:, :, 0] > signed[:, :, 1] * 1.5) & (signed[:, :, 2] > signed[:, :, 1] * 1.4)
    pixels[~pink] = 0
    extracted = quantize(Image.fromarray(pixels), PALETTE["boss"])
    patches = {
        "boss_scan_streak": (48, 266, 180, 294),
        "boss_edge_signal": (53, 180, 71, 210),
        "boss_corner_signal": (55, 64, 97, 99),
    }
    for name, box in patches.items():
        save_piece(f"anim/{name}.png", extracted.crop(box), source="reference/approved_boss_spawn.png", source_crop_art=list(box))


def pack_effect(kind: str, rows: int, columns: int, cell_size: int, origin: tuple[int, int]) -> list[Image.Image]:
    processor = ROOT / f"review/{kind}_processor"
    source_qc = ROOT / f"source/{kind}_processor_qc.json"
    source_clean = ROOT / f"source/{kind}_spawn_clean.png"
    if not source_qc.exists():
        source_qc.write_bytes((processor / "pipeline-meta.json").read_bytes())
    if not source_clean.exists():
        source_clean.write_bytes((processor / "raw-sheet-clean.png").read_bytes())
    metadata = json.loads(source_qc.read_text())
    assert not metadata["source_edge_touch_frames"]
    assert not metadata["output_edge_touch_frames"]
    assert not metadata["paste_clamped_frames"]
    assert not metadata["empty_frames"]
    cleaned = Image.open(source_clean).convert("RGBA")
    # Keep the fixed source slot anchor. Bbox centering would move a rising pixel column.
    raw_w, raw_h = cleaned.width / columns, cleaned.height / rows
    frames = []
    reports = []
    for index in range(rows * columns):
        col, row = index % columns, index // columns
        box = (round(col * raw_w), round(row * raw_h), round((col + 1) * raw_w), round((row + 1) * raw_h))
        frame = cleaned.crop(box).resize((cell_size, cell_size), Image.Resampling.NEAREST)
        if kind == "boss":
            temporary = ["#184952", "#2D8290", "#62E8F2", "#B7F7FA", "#EAFDFF"]
            replacement = ["#512860", "#883BA7", "#EB39B1", "#FF5FCB", "#FFA5E5"]
            frame = quantize(frame, temporary)
            colors = np.array(frame)
            original_colors = colors[:, :, :3].copy()
            for old, new in zip(temporary, replacement):
                hit = np.all(original_colors == rgb(old), axis=2) & (colors[:, :, 3] != 0)
                colors[hit, :3] = rgb(new)
            frame = Image.fromarray(colors)
        else:
            frame = quantize(frame, PALETTE["amber"])
        bbox = frame.getbbox()
        assert bbox and bbox[0] > 0 and bbox[1] > 0 and bbox[2] < cell_size and bbox[3] < cell_size, (kind, index, bbox)
        save_piece(f"anim/{kind}_spawn/frame_{index:02d}.png", frame, origin=list(origin), frame=index, source=f"source/{kind}_spawn_raw.png")
        frames.append(frame)
        reports.append({"frame": index, "bbox": list(bbox), "origin": list(origin), "visible_pixels": int(np.count_nonzero(np.array(frame)[:, :, 3])), "source_box": list(box)})
    sheet = Image.new("RGBA", (cell_size * columns, cell_size * rows))
    for index, frame in enumerate(frames):
        sheet.paste(frame, ((index % columns) * cell_size, (index // columns) * cell_size))
    save_piece(f"anim/{kind}_spawn_sheet.png", sheet, frame_size=[cell_size, cell_size], rows=rows, columns=columns, frame_count=len(frames), origin=list(origin), loop=False)
    # GIFs are presentation previews only; PNG frames are the runtime source.
    gif_frames = []
    for frame in frames:
        preview = Image.new("RGBA", frame.size, rgb("#091B2D") + (255,))
        preview.alpha_composite(frame)
        gif_frames.append(preview.convert("RGB").resize((cell_size * 2, cell_size * 2), Image.Resampling.NEAREST))
    gif_frames[0].save(ROOT / f"preview/{kind}_spawn.gif", save_all=True, append_images=gif_frames[1:], duration=75, loop=0, disposal=2)
    MEASUREMENTS["effects"][kind] = {"frames": reports, "empty_frames": 0, "edge_touch_frames": 0, "paste_clamped_frames": 0, "anchor_contract": "fixed raw-cell coordinates, no bbox recentering", "processor_strict_qc": True}
    return frames


def original_piece_hashes() -> dict[str, str]:
    """Keep the pre-cap kit's 54 files and palette fixed across rebuilds."""
    baseline = json.loads((ROOT / "source/cap_baseline_54.json").read_text())
    assert len(baseline["files"]) == 54
    assert baseline["palette"] == PALETTE
    for path, expected in baseline["files"].items():
        actual = hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
        assert actual == expected, f"Existing piece changed: {path}"
    return baseline["files"]


def hardware_cap_profile(side: str) -> Image.Image:
    """Composite the actual hardware attachment row, including the top core."""
    row = Image.new("RGBA", (540, 1), rgb("#030A12") + (255,))
    for key, x, width in [
        (f"frame/{side}_segment.png", 72, 396),
        (f"frame/corner_{side}_left.png", 0, 72),
        (f"frame/corner_{side}_right.png", 468, 72),
    ]:
        piece = IMAGES[key]
        y = 0 if side == "top" else piece.height - 1
        row.alpha_composite(tiled(piece.crop((0, y, piece.width, y + 1)), (width, 1)), (x, 0))
    if side == "top":
        row.alpha_composite(IMAGES["deco/core_housing.png"].crop((0, 0, 84, 1)), (228, 0))
    return row


def cut_caps() -> None:
    """Pack generated casing art; reuse rail and attachment pixels for exact joins."""
    rails = {
        side: match_edges(IMAGES[f"frame/side_{side}_segment.png"].crop(CAP_RAIL_CROP), "y")
        for side in ("left", "right")
    }
    packed = {}
    for name, size in CAP_SIZES.items():
        source = f"source/{name}_raw.png"
        raw = Image.open(ROOT / source).convert("RGBA")
        piece = quantize(raw.crop(CAP_SOURCE_CROPS[name]).resize(size, Image.Resampling.NEAREST), PALETTE["metal"][:5])
        piece.putalpha(255)
        # The outer 48 pixels retain the existing rails' pixel scale and columns.
        for side, x in [("left", 0), ("right", 492)]:
            piece.paste(tiled(rails[side], (48, size[1])), (x, 0))
        packed[name] = match_edges(piece, "y") if name.endswith("band") else piece
    top = packed["cap_top_join"]
    top.paste(packed["cap_top_band"].crop((0, 46, 540, 48)), (0, 0))
    top.paste(hardware_cap_profile("top").resize((540, 2), Image.Resampling.NEAREST), (0, 6))
    bottom = packed["cap_bottom_join"]
    bottom.paste(hardware_cap_profile("bottom").resize((540, 2), Image.Resampling.NEAREST), (0, 0))
    bottom.paste(packed["cap_bottom_band"].crop((0, 0, 540, 2)), (0, 6))
    for name in CAP_SIZES:
        save_piece(
            f"frame/{name}.png", packed[name],
            tiles="y" if name.endswith("band") else None,
            source=f"source/{name}_raw.png", source_crop=list(CAP_SOURCE_CROPS[name]),
            prompt=f"prompts/{name}.md", opaque=True,
            rail_sources=["frame/side_left_segment.png", "frame/side_right_segment.png"],
            rail_source_crop_art=list(CAP_RAIL_CROP),
            attachment_edge="bottom" if name == "cap_top_join" else "top" if name == "cap_bottom_join" else None,
        )


def cap_strip(side: str, height: int) -> Image.Image | None:
    """Anchor the join at the hardware, repeat outward and crop at the screen edge."""
    assert 0 <= height <= 128
    if height == 0:
        return None
    join = IMAGES[f"frame/cap_{side}_join.png"]
    band = IMAGES[f"frame/cap_{side}_band.png"]
    if height <= 8:
        box = (0, 8 - height, 540, 8) if side == "top" else (0, 0, 540, height)
        return join.crop(box)
    result = Image.new("RGBA", (540, height))
    outward = height - 8
    if side == "top":
        repeats = tiled(band, (540, math.ceil(outward / 48) * 48))
        result.paste(repeats.crop((0, repeats.height - outward, 540, repeats.height)), (0, 0))
        result.paste(join, (0, outward))
    else:
        result.paste(join, (0, 0))
        result.paste(tiled(band, (540, outward)), (0, 8))
    return result


def assemble(height: int, safe_top: int, draw_support: bool = False, safe_bottom: int = 0, draw_caps: bool = False) -> Image.Image:
    canvas = Image.new("RGBA", (540, height), rgb("#030A12") + (255,))
    if draw_caps:
        for side, cap_height, y in [("top", safe_top, 0), ("bottom", safe_bottom, height - safe_bottom)]:
            strip = cap_strip(side, cap_height)
            if strip is not None:
                canvas.alpha_composite(strip, (0, y))
    elif safe_top:
        canvas.alpha_composite(tiled(IMAGES["frame/outer_cap_segment.png"], (540, safe_top)), (0, 0))
    board_height = height - safe_top - safe_bottom
    board_bottom = height - safe_bottom
    floor = (48, safe_top + 64, 444, board_height - 128)
    x, y, w, h = floor
    canvas.alpha_composite(tiled(IMAGES["floor/screen_tile.png"], (w, h)), (x, y))
    canvas.alpha_composite(tiled(IMAGES["frame/side_left_segment.png"], (48, board_height - 144)), (0, safe_top + 72))
    canvas.alpha_composite(tiled(IMAGES["frame/side_right_segment.png"], (48, board_height - 144)), (492, safe_top + 72))
    canvas.alpha_composite(tiled(IMAGES["frame/top_segment.png"], (396, 64)), (72, safe_top))
    canvas.alpha_composite(tiled(IMAGES["frame/bottom_segment.png"], (396, 64)), (72, board_bottom - 64))
    for name, px, py in [("top_left", 0, safe_top), ("top_right", 468, safe_top), ("bottom_left", 0, board_bottom - 72), ("bottom_right", 468, board_bottom - 72)]:
        paste(canvas, f"frame/corner_{name}.png", px, py)
    # Rims meet the same exact rectangle supplied to game-world collision.
    canvas.alpha_composite(tiled(IMAGES["frame/screen_rim_left.png"], (6, h)), (x - 6, y))
    canvas.alpha_composite(tiled(IMAGES["frame/screen_rim_right.png"], (6, h)), (x + w, y))
    canvas.alpha_composite(tiled(IMAGES["frame/screen_rim_top.png"], (w, 6)), (x, y - 6))
    canvas.alpha_composite(tiled(IMAGES["frame/screen_rim_bottom.png"], (w, 6)), (x, y + h))
    paste(canvas, "deco/core_housing.png", 228, safe_top)
    paste(canvas, "deco/core_wisp.png", 252, safe_top + 9)
    for at_y in range(y + 154, y + h - 180, 220):
        paste(canvas, "deco/screen_data_left.png", x + 5, at_y)
        paste(canvas, "deco/screen_data_right.png", x + w - 41, at_y + 34)
    boss_pos = (92, y + 56)
    rush_pos = (92, y + 98)
    for kind, pos, amount in [("boss", boss_pos, 0.80), ("rush", rush_pos, 0.66)]:
        paste(canvas, f"hud/{kind}_meter_track.png", *pos)
        fill = IMAGES[f"hud/{kind}_meter_fill.png"]
        canvas.alpha_composite(fill.crop((0, 0, round(fill.width * amount), fill.height)), (pos[0] + 55, pos[1] + 12))
    if draw_support:
        support = [("pause_button", 12, safe_top + 9), ("score_plate", 352, safe_top + 1), ("rp_plate", 372, safe_top + 35), ("level_badge", 107, safe_top + 2), ("soul_gauge_track", 104, safe_top + 40), ("upgrade_badge", 180, safe_top + 5)]
        for name, px, py in support:
            paste(canvas, f"hud/{name}.png", px, py)
        canvas.alpha_composite(IMAGES["hud/soul_gauge_fill.png"].crop((0, 0, 58, 6)), (114, safe_top + 45))
        # Existing counters are code-rendered, never baked into exported components.
        font = ImageFont.load_default(size=12)
        draw = ImageDraw.Draw(canvas)
        draw.fontmode = "1"
        draw.text((367, safe_top + 12), "004250", font=font, fill="#EAFDFF")
        draw.text((408, safe_top + 46), "125", font=font, fill="#EAFDFF")
        draw.text((119, safe_top + 10), "7", font=font, fill="#EAFDFF")
        draw.text((190, safe_top + 13), "2", font=font, fill="#FFF1C3")
    return canvas


def make_cap_previews() -> None:
    """Preview exact 137/96 game-pixel safe bands at both requested portrait sizes."""
    reports = []
    for width, height in [(1080, 2340), (1536, 2048)]:
        unit = width / 540
        safe_top, safe_bottom = 137, 96
        top_art, bottom_art = math.ceil(safe_top / unit), math.ceil(safe_bottom / unit)
        art_height = math.ceil(height / unit)
        native = assemble(art_height, top_art, True, bottom_art, True)
        rendered = native.resize((width, height), Image.Resampling.NEAREST)
        # Ceil-rounded art caps cover the inset. Crop their outer excess and extend
        # one quiet floor row so the hardware anchors remain exactly at 137/96 px.
        crop_top = round(top_art * height / art_height) - safe_top
        crop_bottom = round(bottom_art * height / art_height) - safe_bottom
        assert crop_top >= 0 and crop_bottom >= 0
        clipped = rendered.crop((0, crop_top, width, height - crop_bottom))
        extra_rows = crop_top + crop_bottom
        if extra_rows:
            split = clipped.height // 2
            preview = Image.new("RGBA", (width, height))
            preview.paste(clipped.crop((0, 0, width, split)), (0, 0))
            row = clipped.crop((0, split, width, split + 1))
            preview.paste(row.resize((width, extra_rows), Image.Resampling.NEAREST), (0, split))
            preview.paste(clipped.crop((0, split, width, clipped.height)), (0, split + extra_rows))
        else:
            preview = clipped
        path = f"preview/caps_{width}x{height}.png"
        preview.save(ROOT / path)
        reports.append({
            "path": path, "size": [width, height], "art_size": [540, art_height],
            "safe_top_game": safe_top, "safe_bottom_game": safe_bottom,
            "safe_top_art": top_art, "safe_bottom_art": bottom_art,
            "floor_rect_art": [48, top_art + 64, 444, art_height - top_art - bottom_art - 128],
            "hardware_top_game": safe_top, "hardware_bottom_game": height - safe_bottom,
            "outer_cap_excess_cropped_game": [crop_top, crop_bottom],
            "quiet_floor_rows_extended_game": extra_rows,
        })
    MEASUREMENTS["cap_previews"] = reports


def overlay_effect(canvas: Image.Image, frame: Image.Image, origin: tuple[int, int], position: tuple[int, int], scale: int = 1) -> None:
    enlarged = frame.resize((frame.width * scale, frame.height * scale), Image.Resampling.NEAREST)
    layer = Image.new("RGBA", canvas.size)
    layer.alpha_composite(enlarged, (position[0] - origin[0] * scale, position[1] - origin[1] * scale))
    canvas.alpha_composite(layer.crop((48, 126, 492, 1106)), (48, 126))


def make_reviews(enemy: list[Image.Image], boss: list[Image.Image]) -> None:
    for height, top in [(960, 32), (1170, 62), (1280, 64)]:
        preview = assemble(height, top)
        preview.resize((1080, height * 2), Image.Resampling.NEAREST).save(ROOT / f"preview/board_1080x{height * 2}.png")
        assemble(height, top, True).resize((1080, height * 2), Image.Resampling.NEAREST).save(ROOT / f"preview/hud_1080x{height * 2}.png")
    assemble(720, 24).resize((1536, 2048), Image.Resampling.NEAREST).save(ROOT / "preview/board_1536x2048.png")
    assemble(720, 24, True).resize((1536, 2048), Image.Resampling.NEAREST).save(ROOT / "preview/hud_1536x2048.png")
    make_cap_previews()
    base = assemble(1170, 62, True)
    sample_enemy = base.copy()
    overlay_effect(sample_enemy, enemy[4], (64, 77), (270, 608))
    sample_enemy.resize((1080, 2340), Image.Resampling.NEAREST).save(ROOT / "preview/enemy_spawn_in_board.png")
    sample_boss = base.copy()
    overlay_effect(sample_boss, boss[6], (128, 128), (270, 612), 2)
    for index, at_y in enumerate(range(280, 950, 120)):
        paste(sample_boss, "anim/boss_scan_streak.png", 52 if index % 2 == 0 else 348, at_y)
        paste(sample_boss, "anim/boss_edge_signal.png", 52, at_y + 44)
        paste(sample_boss, "anim/boss_edge_signal.png", 470, at_y + 44)
    sample_boss.resize((1080, 2340), Image.Resampling.NEAREST).save(ROOT / "preview/boss_spawn_in_board.png")
    animation_frames = []
    curve = [0.12, 0.22, 0.4, 0.65, 0.85, 1.0, 1.0, 0.75, 0.55, 0.35, 0.18, 0.06]
    for frame_index, frame in enumerate(boss):
        preview = base.copy()
        overlay_effect(preview, frame, (128, 128), (270, 612), 2)
        for index, at_y in enumerate(range(280, 950, 120)):
            for key, px, py in [
                ("boss_scan_streak", (52 if index % 2 == 0 else 348) + round(8 * curve[frame_index]), at_y),
                ("boss_edge_signal", 52, at_y + 44),
                ("boss_edge_signal", 470, at_y + 44),
            ]:
                patch = IMAGES[f"anim/{key}.png"].copy()
                patch.putalpha(patch.getchannel("A").point(lambda value: round(value * curve[frame_index])))
                preview.alpha_composite(patch, (px, py))
        animation_frames.append(preview.convert("RGB"))
    animation_frames[0].save(ROOT / "preview/boss_spawn_in_board.gif", save_all=True, append_images=animation_frames[1:], duration=75, loop=0, disposal=2)
    animation_frames = []
    for frame in enemy:
        preview = base.copy()
        overlay_effect(preview, frame, (64, 77), (270, 608))
        animation_frames.append(preview.convert("RGB"))
    animation_frames[0].save(ROOT / "preview/enemy_spawn_in_board.gif", save_all=True, append_images=animation_frames[1:], duration=75, loop=0, disposal=2)
    # Repeat review is labelled outside the artwork, and uses actual exported pixels.
    repeatables = [entry for entry in FILES if entry.get("tiles")]
    sheet = Image.new("RGB", (900, ((len(repeatables) + 2) // 3) * 260), "#07111D")
    draw = ImageDraw.Draw(sheet)
    for index, entry in enumerate(repeatables):
        image = IMAGES[entry["path"]]
        across = 1 if entry["path"].startswith("frame/cap_") else 3
        repeat = tiled(image, (image.width * across, image.height * 3))
        repeat.thumbnail((270, 220), Image.Resampling.NEAREST)
        px, py = (index % 3) * 300, (index // 3) * 260
        sheet.paste(repeat, (px + 12, py + 24), repeat)
        draw.text((px + 12, py + 4), Path(entry["path"]).name, fill="#EAFDFF")
    sheet.save(ROOT / "review/tiling_check.png")
    components = [entry for entry in FILES if not entry["path"].startswith("anim/")]
    sheet = Image.new("RGB", (1200, ((len(components) + 3) // 4) * 210), "#07111D")
    draw = ImageDraw.Draw(sheet)
    for index, entry in enumerate(components):
        image = IMAGES[entry["path"]].copy()
        factor = min(2, 260 / image.width, 174 / image.height)
        image = image.resize((round(image.width * factor), round(image.height * factor)), Image.Resampling.NEAREST)
        px, py = (index % 4) * 300 + 12, (index // 4) * 210 + 28
        sheet.paste(image, (px, py), image)
        draw.text((px, py - 20), entry["path"], fill="#EAFDFF")
    sheet.save(ROOT / "review/components.png")


def write_manifest() -> None:
    manifest = {
        "board": "sci_fi_simulation_v1",
        "source_only": True,
        "art_pixel_to_game_pixel": 2,
        "board_width_art": 540,
        "floor_width_art": 444,
        "floor_x_art": 48,
        "side_width_art": 48,
        "top_beam_height_art": 64,
        "bottom_beam_height_art": 64,
        "corner_size_art": [72, 72],
        "palette": PALETTE,
        "layout": {
            "unit": "view_width / 540",
            "top_cap_art": "ceil(safe_top / unit)",
            "bottom_cap_art": "ceil(safe_bottom / unit)",
            "caps": {
                "height_range_art": [0, 128],
                "width_art": 540,
                "join_height_art": 8,
                "band_height_art": 48,
                "cap_top_join": {"path": "frame/cap_top_join.png", "anchor": "directly_above_top_hardware", "attachment_edge": "bottom", "touches": ["frame/corner_top_left.png", "frame/top_segment.png", "deco/core_housing.png", "frame/corner_top_right.png"]},
                "cap_top_band": {"path": "frame/cap_top_band.png", "anchor": "above_top_join", "repeat": "y_upward", "crop": "at_screen_top"},
                "cap_bottom_join": {"path": "frame/cap_bottom_join.png", "anchor": "directly_below_bottom_hardware", "attachment_edge": "top", "touches": ["frame/corner_bottom_left.png", "frame/bottom_segment.png", "frame/corner_bottom_right.png"]},
                "cap_bottom_band": {"path": "frame/cap_bottom_band.png", "anchor": "below_bottom_join", "repeat": "y_downward", "crop": "at_screen_bottom"},
                "short_caps": "If less than 8 art pixels high, crop the join at the screen edge; keep its hardware-facing edge.",
                "side_columns_art": {"left": [0, 48], "right": [492, 540]},
                "opaque": True,
            },
            "floor_rect_art": "[48, top_cap_art + 64, 444, floor(view_height / unit) - top_cap_art - bottom_cap_art - 128]",
            "floor_is_rectangular": True,
            "boss_meter": {"anchor": "floor_top_center", "offset": [-178, 56], "fill_rect": [55, 12, 248, 11], "color": "magenta", "baked_text": False, "show_only_with_boss": True},
            "rush_meter": {"anchor": "floor_top_center", "offset": [-178, 98], "fill_rect": [55, 12, 248, 11], "color": "amber", "baked_text": False, "segments": 6},
            "core_housing": {"anchor": "board_top_center", "offset": [-42, 0]},
            "support_hud": {
                "pause": [12, 9], "score": [352, 1], "rift_points": [372, 35], "level": [107, 2], "soul": [104, 40], "upgrade_count": [180, 5],
                "coordinates": "art pixels from board top-left after safe-area cap; preview placement, keep all existing control behavior",
            },
            "geometry_note": "This new screen has its own measured layout; it is not a drop-in BoardArenaVisual reskin. Follow the owner-approved in-screen meter placement.",
        },
        "animations": {
            "enemy_spawn": {"sheet": "anim/enemy_spawn_sheet.png", "rows": 2, "columns": 4, "frame_size": [128, 128], "frame_count": 8, "origin": [64, 77], "order": "row_major", "loop": False, "preview_duration_ms_per_frame": 75, "runtime_timing": "sample by EnemyActor telegraph progress, which already multiplies delta by world speed; no new spawn delay", "preview_scale_art": 1},
            "boss_spawn": {"sheet": "anim/boss_spawn_sheet.png", "rows": 3, "columns": 4, "frame_size": [256, 256], "frame_count": 12, "origin": [128, 128], "order": "row_major", "loop": False, "preview_duration_ms_per_frame": 75, "runtime_timing": "one cosmetic appearance sequence at _start_boss_encounter; 0.9 s is the exported preview duration, not a new gameplay lockout", "preview_scale_art": 2},
            "boss_screen_disturbance": {"pieces": ["anim/boss_scan_streak.png", "anim/boss_edge_signal.png", "anim/boss_corner_signal.png"], "timing": "same phase and cleanup as boss_spawn", "preview_alpha_by_frame": [0.12, 0.22, 0.4, 0.65, 0.85, 1.0, 1.0, 0.75, 0.55, 0.35, 0.18, 0.06], "clip": "floor rectangle", "layer": "below actors and combat telegraphs", "use": "repeat/position patches at the edges; do not stretch one phone screenshot to another aspect ratio"},
        },
        "preview_layouts": [
            {"size": [1080, 1920], "art_size": [540, 960], "safe_top_art": 32, "safe_bottom_art": 0, "floor_rect_art": [48, 96, 444, 800]},
            {"size": [1080, 2340], "art_size": [540, 1170], "safe_top_art": 62, "safe_bottom_art": 0, "floor_rect_art": [48, 126, 444, 980]},
            {"size": [1080, 2560], "art_size": [540, 1280], "safe_top_art": 64, "safe_bottom_art": 0, "floor_rect_art": [48, 128, 444, 1088]},
            {"size": [1536, 2048], "art_size": [540, 720], "safe_top_art": 24, "safe_bottom_art": 0, "floor_rect_art": [48, 88, 444, 568]},
        ],
        "cap_preview_layouts": MEASUREMENTS["cap_previews"],
        "files": FILES,
    }
    (ROOT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


def verify() -> None:
    allowed = {rgb(c) for c in COLORS}
    for entry in FILES:
        image = Image.open(ROOT / entry["path"]).convert("RGBA")
        assert list(image.size) == entry["size"]
        assert hashlib.sha256((ROOT / entry["path"]).read_bytes()).hexdigest() == entry["sha256"], entry["path"]
        pixels = np.array(image)
        assert set(np.unique(pixels[:, :, 3])).issubset({0, 255}), entry["path"]
        used = {tuple(color) for color in np.unique(pixels[pixels[:, :, 3] != 0, :3], axis=0)}
        assert used.issubset(allowed), (entry["path"], used - allowed)
        assert (255, 0, 255) not in used, entry["path"]
        axis = entry.get("tiles")
        if axis:
            checks = {}
            if "x" in axis:
                checks["x_join_band_equal"] = bool(np.array_equal(pixels[:, :2], pixels[:, -2:]))
            if "y" in axis:
                checks["y_join_band_equal"] = bool(np.array_equal(pixels[:2], pixels[-2:]))
            assert all(checks.values()), (entry["path"], checks)
            MEASUREMENTS["repeat_edges"][entry["path"]] = checks
    baseline = original_piece_hashes()
    assert len(FILES) == 58
    assert {entry["path"] for entry in FILES} == set(baseline) | {f"frame/{name}.png" for name in CAP_SIZES}
    cap_checks = {}
    for name, size in CAP_SIZES.items():
        image = IMAGES[f"frame/{name}.png"]
        assert image.size == size
        assert np.all(np.array(image)[:, :, 3] == 255), name
        cap_checks[name] = {"size": list(size), "fully_opaque": True, "palette_membership": True}
    top_join, bottom_join = IMAGES["frame/cap_top_join.png"], IMAGES["frame/cap_bottom_join.png"]
    assert np.array_equal(np.array(top_join)[-1], np.array(hardware_cap_profile("top"))[0])
    assert np.array_equal(np.array(bottom_join)[0], np.array(hardware_cap_profile("bottom"))[0])
    assert np.array_equal(np.array(top_join)[:2], np.array(IMAGES["frame/cap_top_band.png"])[-2:])
    assert np.array_equal(np.array(bottom_join)[-2:], np.array(IMAGES["frame/cap_bottom_band.png"])[:2])
    for side in ("top", "bottom"):
        band = np.array(IMAGES[f"frame/cap_{side}_band.png"])
        for rail_side, x in [("left", 0), ("right", 492)]:
            rail = match_edges(IMAGES[f"frame/side_{rail_side}_segment.png"].crop(CAP_RAIL_CROP), "y")
            assert np.array_equal(band[:, x:x + 48], np.array(rail)), (side, rail_side)
        for height in range(129):
            strip = cap_strip(side, height)
            if height == 0:
                assert strip is None
                continue
            assert strip.size == (540, height)
            assert np.all(np.array(strip)[:, :, 3] == 255)
            edge = np.array(strip)[-1 if side == "top" else 0]
            assert np.array_equal(edge, np.array(hardware_cap_profile(side))[0])
    for report in MEASUREMENTS["cap_previews"]:
        assert list(Image.open(ROOT / report["path"]).size) == report["size"]
    MEASUREMENTS["caps"] = {
        "pieces": cap_checks, "hardware_attachment_rows_equal": True,
        "join_band_edge_bands_equal": True, "side_columns_match_existing_rails": True,
        "heights_checked_art": [0, 128], "height_cases_per_side": 129,
        "all_nonempty_height_cases_fully_opaque": True,
        "existing_piece_count": len(baseline), "existing_54_byte_identical": True,
    }
    MEASUREMENTS["runtime_png_count"] = len(FILES)
    MEASUREMENTS["opaque_floor"] = bool(np.all(np.array(IMAGES["floor/screen_tile.png"])[:, :, 3] == 255))
    MEASUREMENTS["floor_mean_luminance_pct"] = round(float(np.mean(np.array(IMAGES["floor/screen_tile.png"])[:, :, :3] @ np.array([0.2126, 0.7152, 0.0722]))) / 255 * 100, 2)
    MEASUREMENTS["palette_color_count"] = len(COLORS)
    MEASUREMENTS["all_runtime_alpha_binary"] = True
    MEASUREMENTS["all_runtime_dimensions_match_manifest"] = True
    (ROOT / "review/qa_report.json").write_text(json.dumps(MEASUREMENTS, indent=2) + "\n", encoding="utf-8")
    print(f"KIT: {len(FILES)} runtime PNGs; binary alpha; {len(COLORS)}-color palette; spawn anchors and repeat edges OK")
    print("CAPS: 4 pieces; opaque; hardware and band joins OK; rail columns OK; heights 0-128 OK; existing 54 byte-identical")


def main() -> None:
    original_piece_hashes()
    cut_static()
    enemy = pack_effect("enemy", 2, 4, 128, (64, 77))
    boss = pack_effect("boss", 3, 4, 256, (128, 128))
    cut_caps()
    make_reviews(enemy, boss)
    write_manifest()
    verify()


if __name__ == "__main__":
    main()
