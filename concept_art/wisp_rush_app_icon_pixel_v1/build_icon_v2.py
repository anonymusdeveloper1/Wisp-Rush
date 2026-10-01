"""Build the smaller-framed source-only Wisp Rush app icon revision."""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "icon_zoomout_generated_raw.png"
PALETTE_REFERENCE = ROOT / "wisp_rush_app_icon_1024.png"
ICON = ROOT / "wisp_rush_app_icon_1024_v2.png"
PREVIEW = ROOT / "wisp_rush_app_icon_preview_128_v2.png"

CANVAS_ART_PX = 256
SUBJECT_ART_PX = 180
GRID_SCALE = 4
BACKGROUND = (11, 17, 22, 255)


def build() -> None:
    """Center the edited artwork with more margin on the original icon's palette."""
    source = Image.open(RAW).convert("RGBA")
    visible = source.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    subject = source.crop(visible.getbbox())
    subject.thumbnail((SUBJECT_ART_PX, SUBJECT_ART_PX), Image.Resampling.BOX)
    hard_alpha = subject.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    subject.putalpha(hard_alpha)

    canvas = Image.new("RGBA", (CANVAS_ART_PX, CANVAS_ART_PX), BACKGROUND)
    offset = ((CANVAS_ART_PX - subject.width) // 2, (CANVAS_ART_PX - subject.height) // 2)
    canvas.alpha_composite(subject, offset)

    original = Image.open(PALETTE_REFERENCE).convert("RGB")
    counted = original.getcolors(original.width * original.height)
    assert counted is not None
    colors = [rgb for _, rgb in sorted(counted, reverse=True)]
    assert len(colors) <= 40
    palette_image = Image.new("P", (1, 1))
    padded_colors = colors + [colors[0]] * (256 - len(colors))
    palette_image.putpalette([channel for rgb in padded_colors for channel in rgb])
    limited = canvas.convert("RGB").quantize(
        palette=palette_image,
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
