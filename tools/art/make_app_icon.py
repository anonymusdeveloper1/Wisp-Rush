#!/usr/bin/env python3
"""Build launcher icons and smaller startup logos from the pixel-art sources.

Run ``python tools/art/make_app_icon.py`` from the repository root. The source lives in
``concept_art/`` and is never modified. Outputs in ``assets/art/branding/app_icon/`` are generated;
do not edit those PNGs by hand.
"""
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[2]
SOURCE = (
    REPO
    / "concept_art/wisp_rush_app_icon_pixel_v1/"
    / "wisp_rush_app_icon_1024_v4_background.png"
)
SPLASH_SOURCE = (
    REPO / "concept_art/wisp_rush_home_pixel_v1/wisp_rush_logo_clean.png"
)
OUT = REPO / "assets/art/branding/app_icon"
GODOT_SPLASH_OUT = REPO / "assets/art/branding/wisp_rush_splash_logo.png"

ART_GRID = 256
MASTER_SIZE = 1024
ADAPTIVE_SIZE = 432
# Android displays the middle 288 px of each adaptive layer. A 264 px icon gives the
# lettering room inside that window and its circular mask.
ADAPTIVE_ART_SIZE = 264
ANDROID_SPLASH_ART_WIDTH = 168
GODOT_SPLASH_CANVAS = (1440, 960)
GODOT_SPLASH_ART_WIDTH = 1080
BACKGROUND = (11, 17, 22)


def _nearest(art: Image.Image, size: int) -> Image.Image:
    """Resize from the logical art grid without introducing blended edge pixels."""
    return art.resize((size, size), Image.Resampling.NEAREST)


def _splash_art(logo: Image.Image, width: int) -> Image.Image:
    """Scale a cropped logo to a smaller, uniform 4 px pixel grid."""
    height = round(logo.height * width / logo.width / 4) * 4
    small = logo.resize((width // 4, height // 4), Image.Resampling.NEAREST)
    return small.resize((width, height), Image.Resampling.NEAREST)


def _center_on_canvas(art: Image.Image, canvas_size: tuple[int, int]) -> Image.Image:
    """Place pixel art on a transparent canvas without shifting its 4 px grid."""
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    x = ((canvas_size[0] - art.width) // 8) * 4
    y = ((canvas_size[1] - art.height) // 8) * 4
    canvas.alpha_composite(art, (x, y))
    return canvas


def main() -> None:
    """Regenerate launcher icons and the backgroundless Android system splash icon."""
    master = Image.open(SOURCE).convert("RGB")
    if master.size != (MASTER_SIZE, MASTER_SIZE):
        raise ValueError(f"Expected {MASTER_SIZE}x{MASTER_SIZE} icon, got {master.size}")
    art = _nearest(master, ART_GRID)
    OUT.mkdir(parents=True, exist_ok=True)

    foreground = Image.new("RGBA", (ADAPTIVE_SIZE, ADAPTIVE_SIZE), (0, 0, 0, 0))
    inset = (ADAPTIVE_SIZE - ADAPTIVE_ART_SIZE) // 2
    foreground.paste(_nearest(art, ADAPTIVE_ART_SIZE), (inset, inset))

    splash_logo = Image.open(SPLASH_SOURCE).convert("RGBA")
    bounds = splash_logo.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError("The splash logo has no visible pixels")
    splash_logo = splash_logo.crop(bounds)
    android_splash = _center_on_canvas(
        _splash_art(splash_logo, ANDROID_SPLASH_ART_WIDTH),
        (ADAPTIVE_SIZE, ADAPTIVE_SIZE),
    )
    godot_splash = _center_on_canvas(
        _splash_art(splash_logo, GODOT_SPLASH_ART_WIDTH),
        GODOT_SPLASH_CANVAS,
    )

    outputs = {
        "app_icon_512.png": _nearest(art, 512),
        "launcher_192.png": _nearest(art, 192),
        "adaptive_foreground_432.png": foreground,
        "adaptive_background_432.png": Image.new(
            "RGB", (ADAPTIVE_SIZE, ADAPTIVE_SIZE), BACKGROUND
        ),
        "android_splash_icon_432.png": android_splash,
    }
    for name, image in outputs.items():
        image.save(OUT / name, optimize=True)
        print(f"APP ICON: {name} {image.width}x{image.height}")
    godot_splash.save(GODOT_SPLASH_OUT, optimize=True)
    print(f"SPLASH: {GODOT_SPLASH_OUT.name} "
          f"{godot_splash.width}x{godot_splash.height}")


if __name__ == "__main__":
    main()
