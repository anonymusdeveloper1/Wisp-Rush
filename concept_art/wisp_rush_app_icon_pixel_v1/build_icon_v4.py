"""Build the Wisp Rush named icon with a brown cloth face and stone setting."""
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "icon_background_generated_raw.png"
BROWN_EDIT = ROOT / "icon_brown_face_generated_raw.png"
ICON = ROOT / "wisp_rush_app_icon_1024_v4_background.png"
PREVIEW = ROOT / "wisp_rush_app_icon_preview_128_v4_background.png"

ART_SIZE = 256
GRID_SCALE = 4
BACKGROUND = (11, 17, 22)
PALETTE_COLORS = 64
BROWN_FACE_POLYGON = (
    (330, 315), (360, 291), (397, 272), (450, 264), (510, 273),
    (566, 297), (613, 329), (645, 363), (640, 392), (604, 422),
    (560, 444), (500, 452), (425, 449), (369, 432), (328, 408),
    (310, 375),
)


def build() -> None:
    """Flatten, sample, and palette-limit the raw edit on a hard 4 px grid."""
    source = Image.open(RAW).convert("RGBA")
    canvas = Image.new("RGBA", source.size, BACKGROUND + (255,))
    canvas.alpha_composite(source)
    sampled = canvas.convert("RGB").resize(
        (ART_SIZE, ART_SIZE), Image.Resampling.BOX
    )
    limited = sampled.quantize(
        colors=PALETTE_COLORS,
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.NONE,
    ).convert("RGB")
    brown = Image.open(BROWN_EDIT).convert("RGB").resize(
        (ART_SIZE, ART_SIZE), Image.Resampling.BOX
    )
    mask = Image.new("1", (ART_SIZE, ART_SIZE), 0)
    ImageDraw.Draw(mask).polygon(
        [(x // GRID_SCALE, y // GRID_SCALE) for x, y in BROWN_FACE_POLYGON],
        fill=1,
    )
    palette = sorted(color for _, color in limited.getcolors(ART_SIZE * ART_SIZE))
    pixels = limited.load()
    brown_pixels = brown.load()
    mask_pixels = mask.load()
    for y in range(ART_SIZE):
        for x in range(ART_SIZE):
            if mask_pixels[x, y]:
                source_color = brown_pixels[x, y]
                pixels[x, y] = min(
                    palette,
                    key=lambda candidate: sum(
                        (candidate[channel] - source_color[channel]) ** 2
                        for channel in range(3)
                    ),
                )

    final = limited.resize(
        (ART_SIZE * GRID_SCALE, ART_SIZE * GRID_SCALE), Image.Resampling.NEAREST
    )
    final.save(ICON, optimize=True)
    limited.resize((128, 128), Image.Resampling.NEAREST).save(
        PREVIEW, optimize=True
    )
    print(f"built {ICON.name}: {final.width}x{final.height}, "
          f"{len(final.getcolors(final.width * final.height) or [])} colors")


if __name__ == "__main__":
    build()
