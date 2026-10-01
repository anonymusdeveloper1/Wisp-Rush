"""Build the source-only Wisp Rush app icon on a strict four-pixel grid."""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "icon_generated_raw.png"
ICON = ROOT / "wisp_rush_app_icon_1024.png"
PREVIEW = ROOT / "wisp_rush_app_icon_preview_128.png"

CANVAS_ART_PX = 256
SUBJECT_ART_PX = 216
SUBJECT_OFFSET_PX = 20
GRID_SCALE = 4
COLOR_COUNT = 40
BACKGROUND = (11, 17, 22, 255)


def build() -> None:
    """Flatten, palette-limit, and nearest-scale the generated draft."""
    source = Image.open(RAW).convert("RGBA")
    subject = source.resize((SUBJECT_ART_PX, SUBJECT_ART_PX), Image.Resampling.BOX)
    hard_alpha = subject.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    subject.putalpha(hard_alpha)

    canvas = Image.new("RGBA", (CANVAS_ART_PX, CANVAS_ART_PX), BACKGROUND)
    canvas.alpha_composite(subject, (SUBJECT_OFFSET_PX, SUBJECT_OFFSET_PX))
    limited = canvas.convert("RGB").quantize(
        colors=COLOR_COUNT,
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.NONE,
    ).convert("RGB")
    final = limited.resize(
        (CANVAS_ART_PX * GRID_SCALE, CANVAS_ART_PX * GRID_SCALE),
        Image.Resampling.NEAREST,
    )
    final.save(ICON, optimize=True)
    limited.resize((128, 128), Image.Resampling.NEAREST).save(PREVIEW, optimize=True)
    print(f"built {ICON.name}: {final.width}x{final.height}, {len(final.getcolors(final.width * final.height) or [])} colors")


if __name__ == "__main__":
    build()
