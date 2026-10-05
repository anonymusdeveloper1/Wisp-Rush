"""Normalize the two generated backgrounds to the game's 4 px image grid."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parent
ART_SIZE = (270, 600)
OUTPUT_SIZE = (1080, 2400)
NAMES = ("loading_patchvile", "shop_gallery")


def main() -> None:
    images: list[Image.Image] = []
    sources: list[dict] = []
    for name in NAMES:
        source_path = ROOT / "raw" / f"{name}_source.png"
        refined_source = ROOT / "raw" / f"{name}_source_v2.png"
        if refined_source.is_file():
            source_path = refined_source
        with Image.open(source_path) as source:
            rgb = source.convert("RGB")
            width, height = rgb.size
            desired = ART_SIZE[0] / ART_SIZE[1]
            if width / height > desired:
                crop_width = height * desired
                crop_box = [(width - crop_width) / 2, 0, (width + crop_width) / 2, height]
            else:
                crop_height = width / desired
                crop_box = [0, (height - crop_height) / 2, width, (height + crop_height) / 2]
            images.append(ImageOps.fit(rgb, ART_SIZE, Image.Resampling.BOX))
            sources.append({
                "raw_path": str(source_path.relative_to(ROOT)).replace("\\", "/"),
                "raw_size": [width, height],
                "center_cover_crop": [round(value, 3) for value in crop_box],
            })

    palette_canvas = Image.new("RGB", (ART_SIZE[0], ART_SIZE[1] * len(images)))
    for index, image in enumerate(images):
        palette_canvas.paste(image, (0, ART_SIZE[1] * index))
    base_palette = palette_canvas.quantize(colors=233, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    source_pixels = np.array(palette_canvas).reshape(-1, 3).astype(np.int16)
    red, green, blue = source_pixels.T
    colorful = (source_pixels.max(axis=1) > 160) & (np.ptp(source_pixels, axis=1) > 50)
    cool = (green > red * 1.12) & (blue > red * 1.12)
    warm = (red > blue * 1.6) & (green > blue * 1.3)
    accents = source_pixels[colorful & (cool | warm)].astype(np.uint8)
    if len(accents) == 0:
        raise RuntimeError("No source cyan or amber accents found")
    accent_image = Image.fromarray(accents.reshape(1, len(accents), 3))
    accent_palette = accent_image.quantize(colors=16, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    canonical_colors = ("111521", "263D42", "62E8F2", "EAFDFF", "F3A847", "B14CD9", "5E7D4C")
    canonical_values = [int(color[index:index + 2], 16) for color in canonical_colors for index in (0, 2, 4)]
    palette = Image.new("P", (1, 1))
    palette.putpalette(base_palette.getpalette()[:233 * 3] + accent_palette.getpalette()[:16 * 3] + canonical_values)

    outputs: list[dict] = []
    for name, image, source_info in zip(NAMES, images, sources):
        grip_source = ROOT / "raw" / f"{name}_source_v3.png"
        if grip_source.is_file():
            with Image.open(grip_source) as corrected:
                if list(corrected.size) != source_info["raw_size"]:
                    raise RuntimeError(f"{name}: corrected image must keep the source canvas")
                image = ImageOps.fit(corrected.convert("RGB"), ART_SIZE, Image.Resampling.BOX)
            source_info = {
                **source_info,
                "palette_source": source_info["raw_path"],
                "raw_path": str(grip_source.relative_to(ROOT)).replace("\\", "/"),
            }
        art = image.quantize(palette=palette, dither=Image.Dither.NONE).convert("RGB")
        final = art.resize(OUTPUT_SIZE, Image.Resampling.NEAREST)
        output_path = ROOT / f"{name}.png"
        final.save(output_path, optimize=True)
        pixels = np.array(final)
        expanded = np.repeat(np.repeat(pixels[::4, ::4], 4, axis=0), 4, axis=1)
        grid_ok = bool(np.array_equal(pixels, expanded))
        color_count = len(final.getcolors(maxcolors=OUTPUT_SIZE[0] * OUTPUT_SIZE[1]) or [])
        if not grid_ok or color_count > 256:
            raise RuntimeError(f"{name}: pixel grid or palette check failed")
        outputs.append({
            "file": output_path.name,
            "size": list(final.size),
            "mode": final.mode,
            "colors": color_count,
            "opaque": True,
            "exact_4_px_grid": grid_ok,
            "sha256": hashlib.sha256(output_path.read_bytes()).hexdigest(),
            **source_info,
        })
        print(f"{output_path.name}: {final.width}x{final.height}, {color_count} colors, 4 px grid OK")

    report = {
        "generator": "Codex built-in image generator",
        "art_size": list(ART_SIZE),
        "output_size": list(OUTPUT_SIZE),
        "palette_entries": 256,
        "palette_method": "233 adaptive world colors, 16 source cyan/amber accent colors, 7 GDD palette anchors",
        "processing": "center cover crop, BOX reduction, shared palette without dithering, 4x nearest enlargement",
        "outputs": outputs,
        "runtime_integration": False,
    }
    (ROOT / "metadata.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()

