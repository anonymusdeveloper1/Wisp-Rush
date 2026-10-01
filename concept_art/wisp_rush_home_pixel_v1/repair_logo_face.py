"""Restore the Home wordmark's opaque brown stitched face.

Run from anywhere with ``python concept_art/wisp_rush_home_pixel_v1/repair_logo_face.py``.
The original generated image fills pixels lost to the alpha mask. A reference-guided
pixel-art edit supplies the brown cloth face. The clean logo supplies its limited
palette and all pixels outside the face masks.
"""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "logo_generated.png"
BROWN_EDIT = ROOT / "logo_brown_face_generated.png"
CLEAN = ROOT / "wisp_rush_logo_clean.png"
GRID = 4

# Source-image pixel coordinates. The first mask is the opening under the hood;
# the second restores the dark stitch on its left edge, also lost by GrabCut.
REPAIR_POLYGONS = (
    ((702, 164), (750, 172), (798, 190), (840, 210), (870, 235),
     (886, 265), (885, 292), (856, 316), (812, 332), (740, 336),
     (688, 328), (650, 312), (625, 290), (622, 256), (638, 220),
     (668, 192)),
    ((679, 126), (705, 120), (723, 145), (717, 178), (688, 172),
     (672, 146)),
)
BROWN_FACE_POLYGON = (
    (704, 180), (748, 186), (800, 199), (850, 225), (884, 250),
    (887, 285), (860, 309), (824, 328), (758, 335), (690, 327),
    (646, 306), (625, 282), (628, 250), (647, 222), (676, 195),
)


def main() -> None:
    """Restore opaque pixels and recolor the face on the existing pixel grid."""
    clean_full = Image.open(CLEAN).convert("RGBA")
    raw_full = Image.open(RAW).convert("RGBA")
    brown_full = Image.open(BROWN_EDIT).convert("RGBA")
    if (clean_full.size != raw_full.size or clean_full.size != brown_full.size
            or clean_full.size != (1536, 1024)):
        raise ValueError("All logo sources must be 1536x1024")

    art_size = (clean_full.width // GRID, clean_full.height // GRID)
    clean = clean_full.resize(art_size, Image.Resampling.NEAREST)
    raw = raw_full.resize(art_size, Image.Resampling.BOX)
    brown = brown_full.resize(art_size, Image.Resampling.BOX)
    mask = Image.new("1", art_size, 0)
    for polygon in REPAIR_POLYGONS:
        ImageDraw.Draw(mask).polygon(
            [(x // GRID, y // GRID) for x, y in polygon], fill=1
        )

    clean_pixels = clean.load()
    raw_pixels = raw.load()
    brown_pixels = brown.load()
    mask_pixels = mask.load()
    palette = sorted({
        clean_pixels[x, y][:3]
        for y in range(art_size[1])
        for x in range(art_size[0])
        if clean_pixels[x, y][3] == 255
    })
    restored = 0
    for y in range(art_size[1]):
        for x in range(art_size[0]):
            if not mask_pixels[x, y] or clean_pixels[x, y][3] != 0:
                continue
            source = raw_pixels[x, y]
            if source[3] < 128:
                continue
            color = min(
                palette,
                key=lambda candidate: sum(
                    (candidate[channel] - source[channel]) ** 2
                    for channel in range(3)
                ),
            )
            clean_pixels[x, y] = color + (255,)
            restored += 1

    brown_mask = Image.new("1", art_size, 0)
    ImageDraw.Draw(brown_mask).polygon(
        [(x // GRID, y // GRID) for x, y in BROWN_FACE_POLYGON], fill=1
    )
    brown_mask_pixels = brown_mask.load()
    recolored = 0
    for y in range(art_size[1]):
        for x in range(art_size[0]):
            if not brown_mask_pixels[x, y] or clean_pixels[x, y][3] != 255:
                continue
            source = brown_pixels[x, y]
            color = min(
                palette,
                key=lambda candidate: sum(
                    (candidate[channel] - source[channel]) ** 2
                    for channel in range(3)
                ),
            )
            clean_pixels[x, y] = color + (255,)
            recolored += 1

    clean.resize(clean_full.size, Image.Resampling.NEAREST).save(
        CLEAN, optimize=True
    )
    print(f"HOME LOGO: restored {restored} opaque art pixels; "
          f"recolored {recolored} brown-face art pixels")


if __name__ == "__main__":
    main()
