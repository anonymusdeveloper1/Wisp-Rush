"""Build the source-only Wisp Rush icon with its two-line game name."""
from collections import Counter
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent
RAW = ROOT / "icon_named_generated_raw.png"
HOME_WORDMARK = ROOT.parent / "wisp_rush_home_pixel_v1" / "wisp_rush_logo_clean.png"
ICON = ROOT / "wisp_rush_app_icon_1024_v3_named.png"
PREVIEW = ROOT / "wisp_rush_app_icon_preview_128_v3_named.png"

CANVAS_ART_PX = 256
CONTENT_ART_PX = 220
GRID_SCALE = 4
BACKGROUND = (11, 17, 22)
ALPHA_THRESHOLD = 128


def build() -> None:
    """Center and palette-limit the named icon, then enlarge on a 4 px grid."""
    source = Image.open(RAW).convert("RGBA")
    visible = source.getchannel("A").point(
        lambda value: 255 if value >= ALPHA_THRESHOLD else 0
    )
    assert visible.getbbox() is not None
    artwork = source.crop(visible.getbbox())
    artwork.thumbnail((CONTENT_ART_PX, CONTENT_ART_PX), Image.Resampling.BOX)
    hard_alpha = artwork.getchannel("A").point(
        lambda value: 255 if value >= ALPHA_THRESHOLD else 0
    )
    artwork.putalpha(hard_alpha)

    canvas = Image.new("RGBA", (CANVAS_ART_PX, CANVAS_ART_PX), BACKGROUND + (255,))
    offset = ((CANVAS_ART_PX - artwork.width) // 2,
              (CANVAS_ART_PX - artwork.height) // 2)
    canvas.alpha_composite(artwork, offset)

    wordmark = Image.open(HOME_WORDMARK).convert("RGBA")
    counts = Counter((r, g, b) for r, g, b, alpha in wordmark.getdata()
                     if alpha > 127)
    colors = [BACKGROUND] + [rgb for rgb, _ in counts.most_common()
                             if rgb != BACKGROUND]
    assert len(colors) <= 64
    palette = Image.new("P", (1, 1))
    padded = colors + [BACKGROUND] * (256 - len(colors))
    palette.putpalette([channel for rgb in padded for channel in rgb])
    limited = canvas.convert("RGB").quantize(
        palette=palette, dither=Image.Dither.NONE
    ).convert("RGB")

    final = limited.resize((CANVAS_ART_PX * GRID_SCALE,
                            CANVAS_ART_PX * GRID_SCALE), Image.Resampling.NEAREST)
    final.save(ICON, optimize=True)
    limited.resize((128, 128), Image.Resampling.NEAREST).save(PREVIEW, optimize=True)
    print(f"built {ICON.name}: {final.width}x{final.height}, "
          f"{len(final.getcolors(final.width * final.height) or [])} colors")


if __name__ == "__main__":
    build()
