"""Numbers for Palmier Pro edits: keyframe rows, image sizes and text sizes for Wisp Rush devlogs.

Palmier's `set_keyframes` wants `position` rows as the clip's TOP-LEFT corner and `scale` rows as its
normalized width/height (0-1 of the 1080x1920 canvas), so every "pop" or "ring" means corner maths.
This prints ready-to-paste JSON. Recipe and values: docs/marketing/devlog_video_recipe.md.
Python 3.7 + Pillow 9 (the system python3).

Usage (repo root):
  python3 tools/video/palmier_motion.py size 0.27 383 483
      -> {"width": .., "height": ..} for set_clip_properties transform (image 383x483 px, 0.27 wide)
  python3 tools/video/palmier_motion.py pop 0.2 0.205 0.27 383 483 280 [--out 6] [--from 0.55]
      -> {"position", "scale", "opacity"} rows: pop in at centre (0.2, 0.205), hold, shrink out
  python3 tools/video/palmier_motion.py ring 0.5 0.745 [--size 0.34] [--frames 20]
      -> an expanding, fading tap ring (square image) centred on a button
  python3 tools/video/palmier_motion.py custom 0.5 0.44 0.92 1060 556 "0:0.55:0:0:0,5:1.1:1:0:0,163:2.1:0:0:0.03"
      -> rows for frame:scale_factor:opacity:dx:dy steps around a centre
  python3 tools/video/palmier_motion.py fit-text anton "576 MS" 760 [--tracking 0]
      -> the Palmier fontSize that renders the text 760 px wide on the 1080 canvas
Fonts for fit-text: anton, poppins (Bold), marker (Permanent Marker), bebas, inter, dmsans.
"""

import argparse
import json
import sys
from pathlib import Path

CANVAS_W = 1080.0
CANVAS_H = 1920.0
# Palmier sizes text in points of a 1920-wide reference: a glyph renders this many times its PIL size
# on the 1080-wide canvas (measured on EP02: FROZEN@200 and a caption both came out ~1.77x).
TEXT_SCALE = CANVAS_H / CANVAS_W
FONT_DIR = Path("/Applications/PalmierPro.app/Contents/Resources/Fonts")
FONTS = {
    "anton": FONT_DIR / "Anton" / "Anton-Regular.ttf",
    "poppins": FONT_DIR / "Poppins" / "Poppins-Bold.ttf",
    "marker": FONT_DIR / "PermanentMarker" / "PermanentMarker-Regular.ttf",
    "bebas": FONT_DIR / "BebasNeue" / "BebasNeue-Regular.ttf",
    "inter": FONT_DIR / "Inter" / "Inter[opsz,wght].ttf",
    "dmsans": FONT_DIR / "DMSans" / "DMSans[opsz,wght].ttf",
}


def image_size(width: float, px_w: float, px_h: float):
    """Normalized (width, height) of an image shown `width` of the canvas wide, aspect kept."""
    return width, width * CANVAS_W / CANVAS_H * px_h / px_w


def rows(cx, cy, width, px_w, px_h, steps):
    """steps: (frame, scale_factor, opacity, dx, dy); returns position/scale/opacity rows."""
    position, scale, opacity = [], [], []
    for frame, factor, alpha, dx, dy in steps:
        w, h = image_size(width * factor, px_w, px_h)
        position.append([frame, round(cx + dx - w / 2, 4), round(cy + dy - h / 2, 4)])
        scale.append([frame, round(w, 4), round(h, 4)])
        opacity.append([frame, alpha])
    return {"position": position, "scale": scale, "opacity": opacity}


def pop(cx, cy, width, px_w, px_h, duration, out_frames=6, start=0.55):
    """0.55 -> 1.10 -> 0.97 -> 1.00 over 12 frames (opacity in over 5), then shrink out."""
    steps = [(0, start, 0.0, 0, 0), (5, 1.1, 1.0, 0, 0), (9, 0.97, 1.0, 0, 0), (12, 1.0, 1.0, 0, 0)]
    if out_frames > 0:
        steps += [(duration - out_frames, 1.0, 1.0, 0, 0), (duration - 1, 0.75, 0.0, 0, 0)]
    else:
        steps += [(duration - 1, 1.0, 1.0, 0, 0)]
    return rows(cx, cy, width, px_w, px_h, steps)


def ring(cx, cy, size=0.34, frames=20):
    """A square tap ring growing from 25 % to full size while it fades out."""
    return rows(cx, cy, size, 1, 1, [(0, 0.25, 1.0, 0, 0), (frames - 1, 1.0, 0.0, 0, 0)])


def fit_text(font: str, text: str, width_px: float, tracking: float = 0.0) -> int:
    from PIL import ImageFont

    face = ImageFont.truetype(str(FONTS[font]), 100)
    width_100 = face.getlength(text) + tracking * max(len(text) - 1, 0)
    return int(width_px / TEXT_SCALE / (width_100 / 100.0))


def main(argv) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command")
    p = sub.add_parser("size")
    p.add_argument("width", type=float)
    p.add_argument("px_w", type=float)
    p.add_argument("px_h", type=float)
    p = sub.add_parser("pop")
    for name in ("cx", "cy", "width", "px_w", "px_h"):
        p.add_argument(name, type=float)
    p.add_argument("duration", type=int, help="clip length in frames")
    p.add_argument("--out", type=int, default=6, help="shrink-out frames at the end (0 = none)")
    p.add_argument("--from", dest="start", type=float, default=0.55)
    p = sub.add_parser("ring")
    p.add_argument("cx", type=float)
    p.add_argument("cy", type=float)
    p.add_argument("--size", type=float, default=0.34)
    p.add_argument("--frames", type=int, default=20)
    p = sub.add_parser("custom")
    for name in ("cx", "cy", "width", "px_w", "px_h"):
        p.add_argument(name, type=float)
    p.add_argument("steps", help="frame:scale:opacity:dx:dy,...")
    p = sub.add_parser("fit-text")
    p.add_argument("font", choices=sorted(FONTS))
    p.add_argument("text")
    p.add_argument("width_px", type=float)
    p.add_argument("--tracking", type=float, default=0.0)
    args = parser.parse_args(argv)

    if args.command == "size":
        w, h = image_size(args.width, args.px_w, args.px_h)
        print(json.dumps({"width": round(w, 4), "height": round(h, 4)}))
    elif args.command == "pop":
        print(json.dumps(pop(args.cx, args.cy, args.width, args.px_w, args.px_h, args.duration, args.out, args.start)))
    elif args.command == "ring":
        print(json.dumps(ring(args.cx, args.cy, args.size, args.frames)))
    elif args.command == "custom":
        steps = []
        for part in args.steps.split(","):
            frame, factor, alpha, dx, dy = part.split(":")
            steps.append((int(frame), float(factor), float(alpha), float(dx), float(dy)))
        print(json.dumps(rows(args.cx, args.cy, args.width, args.px_w, args.px_h, steps)))
    elif args.command == "fit-text":
        print(fit_text(args.font, args.text, args.width_px, args.tracking))
    else:
        parser.print_help()
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
