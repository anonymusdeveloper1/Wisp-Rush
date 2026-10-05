"""Normalize seven generated loading illustrations and build a labelled review sheet."""
from __future__ import annotations

import hashlib
import json
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parent
RUNTIME = ROOT.parents[1] / "assets" / "art" / "environment" / "loading_screens"
ART_SIZE = (270, 600)
OUTPUT_SIZE = (1080, 2400)
LABELS = {
    "loading_new_boss": "New boss",
    "loading_grimgrin": "Grimgrin",
    "loading_patchvile_grove": "Patchvile",
    "loading_shade": "Shade",
    "loading_scarlet": "Scarlet",
    "loading_rook": "Rook",
    "loading_mothmere": "Mothmere",
}
PALETTE_ANCHORS = ("111521", "263D42", "62E8F2", "EAFDFF", "F3A847", "B14CD9", "5E7D4C")


def pixel_palette(image: Image.Image) -> Image.Image:
    """Reserve bright source accents before reducing each image to at most 256 colors."""
    base = image.quantize(colors=217, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    pixels = np.array(image).reshape(-1, 3).astype(np.int16)
    colorful = (pixels.max(axis=1) > 145) & (np.ptp(pixels, axis=1) > 50)
    accents = pixels[colorful].astype(np.uint8)
    if len(accents) == 0:
        raise RuntimeError("Generated image contains no bright color accents")
    accent_image = Image.fromarray(accents.reshape(1, len(accents), 3))
    accent_palette = accent_image.quantize(
        colors=32, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE
    )
    anchors = [int(color[i:i + 2], 16) for color in PALETTE_ANCHORS for i in (0, 2, 4)]
    palette = Image.new("P", (1, 1))
    palette.putpalette(base.getpalette()[:217 * 3] + accent_palette.getpalette()[:32 * 3] + anchors)
    return palette


def main() -> None:
    manifest = json.loads((ROOT / "generation.json").read_text(encoding="utf-8"))
    RUNTIME.mkdir(parents=True, exist_ok=True)
    outputs = []
    thumbs = []
    for entry in manifest["outputs"]:
        name = entry["name"]
        source_path = ROOT / "raw" / f"{name}_source.png"
        refined_path = ROOT / "raw" / f"{name}_source_v2.png"
        if refined_path.is_file():
            source_path = refined_path
        with Image.open(source_path) as source:
            width, height = source.size
            desired = ART_SIZE[0] / ART_SIZE[1]
            if width / height > desired:
                crop_width = height * desired
                crop = [(width - crop_width) / 2, 0, (width + crop_width) / 2, height]
            else:
                crop_height = width / desired
                crop = [0, (height - crop_height) / 2, width, (height + crop_height) / 2]
            reduced = ImageOps.fit(source.convert("RGB"), ART_SIZE, Image.Resampling.BOX)
        art = reduced.quantize(palette=pixel_palette(reduced), dither=Image.Dither.NONE).convert("RGB")
        final = art.resize(OUTPUT_SIZE, Image.Resampling.NEAREST)
        path = ROOT / f"{name}.png"
        final.save(path, optimize=True)
        runtime_path = RUNTIME / path.name
        shutil.copy2(path, runtime_path)
        pixels = np.array(final)
        exact_grid = bool(np.array_equal(
            pixels, np.repeat(np.repeat(pixels[::4, ::4], 4, axis=0), 4, axis=1)
        ))
        colors = len(final.getcolors(maxcolors=OUTPUT_SIZE[0] * OUTPUT_SIZE[1]) or [])
        if not exact_grid or not 1 <= colors <= 256:
            raise RuntimeError(f"{name}: grid or palette check failed")
        outputs.append({
            "file": path.name,
            "label": LABELS[name],
            "raw_path": source_path.relative_to(ROOT).as_posix(),
            "raw_size": [width, height],
            "raw_sha256": hashlib.sha256(source_path.read_bytes()).hexdigest(),
            "center_cover_crop": [round(value, 3) for value in crop],
            "size": list(final.size),
            "mode": final.mode,
            "colors": colors,
            "opaque": True,
            "exact_4_px_grid": exact_grid,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "prompt": f"prompts/{name}.md",
            "composition_refinement": (
                f"prompts/{name}_refinement.md" if refined_path.is_file() else None
            ),
            "runtime_path": f"res://assets/art/environment/loading_screens/{name}.png",
            "runtime_matches_source": runtime_path.read_bytes() == path.read_bytes(),
        })
        thumbs.append((LABELS[name], art))
        print(f"{path.name}: 1080x2400, {colors} colors, exact 4 px grid OK")

    # Review layout only; the seven finished images remain separate, without labels.
    margin, header, columns = 12, 32, 4
    rows = (len(thumbs) + columns - 1) // columns
    tile_w, tile_h = ART_SIZE[0] + margin, ART_SIZE[1] + header + margin
    review = Image.new("RGB", (columns * tile_w + margin, rows * tile_h + margin), "#111521")
    draw = ImageDraw.Draw(review)
    font = ImageFont.load_default(size=18)
    for index, (label, art) in enumerate(thumbs):
        column, row = index % columns, index // columns
        x, y = margin + column * tile_w, margin + row * tile_h
        draw.text((x, y + 4), label, fill="#EAFDFF", font=font)
        review.paste(art, (x, y + header))
    review.save(ROOT / "preview_all.png", optimize=True)
    (ROOT / "metadata.json").write_text(json.dumps({
        "generator": manifest["generator"],
        "art_size": list(ART_SIZE),
        "output_size": list(OUTPUT_SIZE),
        "palette_entries": 256,
        "palette_method": "per image: 217 adaptive shades, 32 source accents, 7 GDD anchors",
        "processing": "center cover crop, BOX reduction, no dithering, 4x nearest enlargement",
        "outputs": outputs,
        "review": "preview_all.png (labels only on the review sheet)",
        "runtime_integration": True,
    }, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
