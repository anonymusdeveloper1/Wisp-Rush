"""Still graphic pieces for Wisp Rush devlog videos, animated later in Palmier Pro.

Palmier can animate, key and grade layers but cannot draw shapes, so this script draws the static
pieces an explainer needs as transparent PNGs on the 1080x1920 canvas scale: a viewer-comment card,
a dark grid backdrop, a filmstrip of frames, a red "freeze" bar, tap markers, numbered step cards on
the game's own stone panel, marker-pen arrows / circles / underlines / strike lines, and a frost
edge. Nothing here composites or edits video (owner rule: editing happens in Palmier).

Colours follow the game palette (docs/GDD.md §9); text uses the fonts bundled with Palmier Pro so a
caption set in Palmier matches. Python 3.7 + Pillow 9 (the system python3).

Usage (repo root):
  python3 tools/video/devlog_graphics.py kit OUT_DIR
  python3 tools/video/devlog_graphics.py comment OUT.png --name Playtester \
      --text "why does your game FREEZE every time i tap PLAY??" --accent FREEZE,PLAY??
  python3 tools/video/devlog_graphics.py step OUT.png --number 1 --label COVER --icon cover
  python3 tools/video/devlog_graphics.py bar OUT.png --label "BUILDING THE NEXT SCREEN" --width 900
      [--color cyan]
  python3 tools/video/devlog_graphics.py code OUT.png --number 1 --text "rush_time = 0" [--accent red]
  python3 tools/video/devlog_graphics.py meter OUT_PREFIX --label "RUSH TIMER" --color cyan
      # -> OUT_PREFIX_track.png (label + empty bar) and OUT_PREFIX_fill.png (crop it to drain)
  python3 tools/video/devlog_graphics.py preview OUT_DIR SHEET.png
  python3 tools/video/devlog_graphics.py tier OUT.png --image PAINTING.png --label MYTHIC --count "×5" --color magenta
  python3 tools/video/devlog_graphics.py outline OUT.png [--fill]          # shared Endless floor polygon
  python3 tools/video/devlog_graphics.py lightmap OUT.png --mask assets/art/environment/endless/masks/SKIN.png --channel R --color amber
  python3 tools/video/devlog_graphics.py crop SHEET.png OUT.png --box x0,y0,x1,y1
`kit` writes every generic piece (grid, strip, tap marks, arrows, circle, underline, strike, frost).
Icons for `step`: cover, build, reveal, loading, bolt, target, bend, slowmo. Tier colours: white,
cyan, amber, magenta. Bar and meter colours: red (hazard stripes on bars), cyan, amber. Code accents:
none, red, cyan.
"""

import argparse
import math
import random
import sys
from pathlib import Path
from typing import List, Sequence, Tuple

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
FONT_DIR = Path("/Applications/PalmierPro.app/Contents/Resources/Fonts")
FONTS = {
    "bold": FONT_DIR / "Poppins" / "Poppins-Bold.ttf",
    "regular": FONT_DIR / "Poppins" / "Poppins-Regular.ttf",
    "display": FONT_DIR / "Anton" / "Anton-Regular.ttf",
    "marker": FONT_DIR / "PermanentMarker" / "PermanentMarker-Regular.ttf",
}
FALLBACK_FONT = Path("/System/Library/Fonts/Supplemental/Arial Bold.ttf")
MONO_FONT = Path("/System/Library/Fonts/Menlo.ttc")
PANEL_CARD = ROOT / "assets" / "art" / "ui" / "frames" / "panel_card.png"

# Game palette (GDD §9) plus two video-only colours: freeze red and ice.
VOID = (17, 21, 33)
DEEP = (10, 13, 21)
SLATE = (38, 61, 66)
CYAN = (98, 232, 242)
SOUL_WHITE = (234, 253, 255)
AMBER = (243, 168, 71)
MAGENTA = (177, 76, 217)
RED = (255, 59, 92)
ICE = (190, 238, 255)
INK = (17, 21, 33)
GREY = (122, 132, 148)

Color = Tuple[int, int, int]


def font(kind: str, size: int) -> ImageFont.FreeTypeFont:
    path = FONTS.get(kind, FALLBACK_FONT)
    if not path.exists():
        path = FALLBACK_FONT
    return ImageFont.truetype(str(path), size)


def rgba(color: Color, alpha: int = 255) -> Tuple[int, int, int, int]:
    return (color[0], color[1], color[2], alpha)


def glow(image: Image.Image, radius: int, strength: float = 1.0) -> Image.Image:
    """The image over a blurred copy of itself: a soft light halo in the layer's own colours."""
    halo = image.filter(ImageFilter.GaussianBlur(radius))
    if strength != 1.0:
        alpha = halo.split()[3].point(lambda a: min(255, int(a * strength)))
        halo.putalpha(alpha)
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    out.alpha_composite(halo)
    out.alpha_composite(image)
    return out


def drop_shadow(image: Image.Image, offset: Tuple[int, int], radius: int, alpha: int) -> Image.Image:
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    mask = image.split()[3].point(lambda a: a * alpha // 255)
    shadow.paste((0, 0, 0, 255), (offset[0], offset[1]), mask)
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius))
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    out.alpha_composite(shadow)
    out.alpha_composite(image)
    return out


def padded(width: int, height: int, pad: int) -> Image.Image:
    return Image.new("RGBA", (width + pad * 2, height + pad * 2), (0, 0, 0, 0))


def wrap_words(draw: ImageDraw.ImageDraw, words: List[str], face, max_width: int) -> List[List[str]]:
    lines: List[List[str]] = [[]]
    for word in words:
        trial = " ".join(lines[-1] + [word])
        if lines[-1] and draw.textlength(trial, font=face) > max_width:
            lines.append([word])
        else:
            lines[-1].append(word)
    return lines


# --- pieces ---------------------------------------------------------------------------------------


def grid_background(path: Path, width: int = 1080, height: int = 1920) -> None:
    """Opaque dark backdrop: faint cyan grid, a soft centre glow and a vignette."""
    image = Image.new("RGBA", (width, height), rgba(DEEP))
    glow_layer = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow_layer)
    gd.ellipse((width * 0.05, height * 0.25, width * 0.95, height * 0.75), fill=rgba(SLATE, 150))
    image.alpha_composite(glow_layer.filter(ImageFilter.GaussianBlur(160)))
    lines = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lines)
    step = 72
    for x in range(-step // 2, width + step, step):
        ld.line((x, 0, x, height), fill=rgba(CYAN, 22), width=2)
    for y in range(0, height + step, step):
        ld.line((0, y, width, y), fill=rgba(CYAN, 22), width=2)
    image.alpha_composite(lines)
    vignette = Image.new("L", (width, height), 0)
    vd = ImageDraw.Draw(vignette)
    vd.ellipse((-width * 0.25, -height * 0.1, width * 1.25, height * 1.1), fill=255)
    vignette = vignette.filter(ImageFilter.GaussianBlur(180))
    dark = Image.new("RGBA", (width, height), rgba(DEEP))
    dark.putalpha(vignette.point(lambda v: int((255 - v) * 0.85)))
    image.alpha_composite(dark)
    image.save(path)


def comment_card(path: Path, name: str, text: str, accents: Sequence[str], subtitle: str = "") -> None:
    """A viewer comment on a white card. Generic: no platform UI, handle, badge or like counts."""
    width, pad = 940, 60
    probe = ImageDraw.Draw(Image.new("RGBA", (10, 10)))
    body = font("bold", 56)
    lines = wrap_words(probe, text.split(), body, width - 96 - 150)
    line_height = 72
    height = 150 + line_height * len(lines) + 70
    card = padded(width, height, pad)
    d = ImageDraw.Draw(card)
    d.rounded_rectangle((pad, pad, pad + width, pad + height), radius=44, fill=(255, 255, 255, 255))
    # Avatar: a neutral silhouette, never a real person.
    ax, ay, ar = pad + 48, pad + 44, 50
    d.ellipse((ax, ay, ax + ar * 2, ay + ar * 2), fill=(214, 220, 229, 255))
    d.ellipse((ax + 31, ay + 16, ax + 69, ay + 54), fill=(150, 160, 176, 255))
    d.pieslice((ax + 14, ay + 58, ax + 86, ay + 130), 180, 360, fill=(150, 160, 176, 255))
    d.text((ax + ar * 2 + 26, ay + 2), name, font=font("bold", 40), fill=rgba(INK))
    if subtitle:
        d.text((ax + ar * 2 + 26, ay + 52), subtitle, font=font("regular", 30), fill=rgba(GREY))
    accent_set = {a.strip().lower() for a in accents if a.strip()}
    y = pad + 150
    for line in lines:
        x = ax + ar * 2 + 26
        for word in line:
            color = RED if word.lower() in accent_set else INK
            d.text((x, y), word, font=body, fill=rgba(color))
            x += d.textlength(word + " ", font=body)
        y += line_height
    # A plain heart and "Reply", no counts.
    hx, hy = ax + ar * 2 + 26, y + 8
    heart = [(hx + 18, hy + 34), (hx, hy + 14), (hx + 2, hy + 4), (hx + 10, hy), (hx + 18, hy + 8),
             (hx + 26, hy), (hx + 34, hy + 4), (hx + 36, hy + 14)]
    d.line(heart + [heart[0]], fill=rgba(GREY), width=4, joint="curve")
    d.text((hx + 60, hy - 4), "Reply", font=font("bold", 30), fill=rgba(GREY))
    drop_shadow(card, (0, 14), 22, 110).save(path)


def frame_strip(path: Path, count: int = 16, box: int = 150, gap: int = 26) -> None:
    """A row of frame boxes (a filmstrip to scroll): cyan outlines on a faint fill."""
    pad = 30
    width = count * box + (count - 1) * gap
    image = padded(width, box, pad)
    d = ImageDraw.Draw(image)
    for i in range(count):
        x = pad + i * (box + gap)
        d.rounded_rectangle((x, pad, x + box, pad + box), radius=22, fill=rgba(CYAN, 34),
                            outline=rgba(CYAN, 235), width=6)
        d.rounded_rectangle((x + 26, pad + box - 34, x + box - 26, pad + box - 22), radius=6,
                            fill=rgba(CYAN, 150))
    glow(image, 10, 0.8).save(path)


BAR_COLORS = {
    "red": (RED, (255, 190, 200)),
    "cyan": (CYAN, (214, 250, 255)),
    "amber": (AMBER, (255, 222, 170)),
}


def freeze_bar(path: Path, label: str, width: int = 900, height: int = 170, color: str = "red") -> None:
    """A long glowing block: red with hazard stripes stands for one frame that takes far too long; cyan
    and amber are plain bars (a timer, a meter) to crop-animate in Palmier."""
    pad = 34
    image = padded(width, height, pad)
    d = ImageDraw.Draw(image)
    fill, edge = BAR_COLORS[color]
    d.rounded_rectangle((pad, pad, pad + width, pad + height), radius=26, fill=rgba(fill, 235),
                        outline=rgba(edge, 255), width=6)
    if color == "red":
        for i in range(0, width + height, 44):  # hazard stripes
            d.line((pad + i, pad + height, pad + i + height, pad), fill=(255, 255, 255, 28), width=16)
    face = font("bold", 46)
    tw = d.textlength(label, font=face)
    text_fill = (255, 255, 255, 255) if color == "red" else rgba(INK)
    d.text((pad + (width - tw) / 2, pad + height / 2 - 34), label, font=face, fill=text_fill)
    glow(image, 16, 0.9).save(path)


def meter_pair(prefix: Path, label: str, color: str, width: int = 760, bar: int = 80) -> None:
    """A labelled meter as two same-size PNGs: `<prefix>_track.png` (caption above an empty rounded bar)
    and `<prefix>_fill.png` (only the glowing fill). Stack the fill over the track in Palmier and crop
    the fill's right edge to drain or fill it; move both together."""
    pad, label_h = 40, 64
    size = (width + pad * 2, label_h + bar + pad * 2)
    fill_colour = BAR_COLORS[color][0]
    rect = (pad, pad + label_h, pad + width, pad + label_h + bar)
    track = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(track)
    d.text((pad + 6, pad - 2), label, font=font("bold", 38), fill=rgba(SOUL_WHITE, 235))
    d.rounded_rectangle(rect, radius=bar // 2, fill=rgba(DEEP, 225), outline=rgba(fill_colour, 150), width=5)
    drop_shadow(track, (0, 6), 10, 110).save(prefix.parent / (prefix.name + "_track.png"))
    fill = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(fill)
    inset = 12
    d.rounded_rectangle((rect[0] + inset, rect[1] + inset, rect[2] - inset, rect[3] - inset),
                        radius=(bar - inset * 2) // 2, fill=rgba(fill_colour, 255))
    glow(fill, 14, 0.9).save(prefix.parent / (prefix.name + "_fill.png"))


CODE_ACCENTS = {"none": GREY, "red": RED, "cyan": CYAN}


def code_card(path: Path, number: str, text: str, accent: str = "none", width: int = 820) -> None:
    """One line of code on a dark rounded card: a line number, Menlo text with `name(` calls in cyan and
    digits in amber, and an optional accent edge (red = the bug, cyan = the fix)."""
    height = 132
    pad = 34
    image = padded(width, height, pad)
    d = ImageDraw.Draw(image)
    edge = CODE_ACCENTS[accent]
    d.rounded_rectangle((pad, pad, pad + width, pad + height), radius=24, fill=rgba(DEEP, 240),
                        outline=rgba(edge, 255 if accent != "none" else 150), width=5)
    d.rounded_rectangle((pad, pad, pad + 96, pad + height), radius=24, fill=rgba(SLATE, 200))
    d.rectangle((pad + 70, pad, pad + 96, pad + height), fill=rgba(SLATE, 200))
    mono = ImageFont.truetype(str(MONO_FONT), 50, index=1) if MONO_FONT.exists() else font("bold", 46)
    num_w = d.textlength(number, font=mono)
    top = pad + (height - 62) / 2
    d.text((pad + 48 - num_w / 2, top), number, font=mono, fill=rgba(GREY))
    x = pad + 132
    for token in _code_tokens(text):
        colour = SOUL_WHITE
        if token.endswith("("):
            colour = CYAN
        elif token.strip().replace(".", "").isdigit():
            colour = AMBER
        d.text((x, top), token, font=mono, fill=rgba(colour))
        x += d.textlength(token, font=mono)
    image = glow(image, 12, 0.5) if accent != "none" else image
    drop_shadow(image, (0, 8), 12, 120).save(path)


def _code_tokens(text: str) -> List[str]:
    """Splits code into chunks: a call name keeps its "(" so it can be coloured."""
    tokens: List[str] = []
    word = ""
    for ch in text:
        if ch.isalnum() or ch in "_.":
            word += ch
            continue
        if word:
            tokens.append(word + "(" if ch == "(" else word)
            word = ""
            if ch == "(":
                continue
        tokens.append(ch)
    if word:
        tokens.append(word)
    return tokens


def touch_dot(path: Path, size: int = 120) -> None:
    pad = 40
    image = padded(size, size, pad)
    d = ImageDraw.Draw(image)
    d.ellipse((pad - 18, pad - 18, pad + size + 18, pad + size + 18), fill=(255, 255, 255, 60))
    d.ellipse((pad, pad, pad + size, pad + size), fill=(255, 255, 255, 235))
    glow(image, 14).save(path)


def tap_ring(path: Path, size: int = 300, stroke: int = 12) -> None:
    pad = 30
    image = padded(size, size, pad)
    ImageDraw.Draw(image).ellipse((pad, pad, pad + size, pad + size), outline=(255, 255, 255, 240),
                                  width=stroke)
    glow(image, 10).save(path)


def _marker_line(draw: ImageDraw.ImageDraw, points: List[Tuple[float, float]], color: Color,
                 width: int, rng: random.Random) -> None:
    """Three slightly shifted passes: reads as a felt-tip stroke rather than a vector line."""
    for k, alpha in enumerate((255, 200, 150)):
        shift = (rng.uniform(-2, 2), rng.uniform(-2, 2)) if k else (0.0, 0.0)
        pts = [(x + shift[0], y + shift[1]) for x, y in points]
        draw.line(pts, fill=rgba(color, alpha), width=max(2, width - k * 3), joint="curve")
        r = (width - k * 3) / 2
        for x, y in (pts[0], pts[-1]):
            draw.ellipse((x - r, y - r, x + r, y + r), fill=rgba(color, alpha))


def _curve(p0, p1, p2, steps: int, jitter: float, rng: random.Random) -> List[Tuple[float, float]]:
    pts = []
    for i in range(steps + 1):
        t = i / steps
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]
        if 0 < i < steps:
            x += rng.uniform(-jitter, jitter)
            y += rng.uniform(-jitter, jitter)
        pts.append((x, y))
    return pts


def hand_arrow(path: Path, direction: str, length: int = 320, color: Color = AMBER,
               stroke: int = 16, seed: int = 7) -> None:
    """A marker-pen arrow pointing right/left/up/down (drawn pointing right, then rotated)."""
    rng = random.Random(seed)
    pad = 50
    w, h = length, int(length * 0.42)
    image = padded(w, h, pad)
    d = ImageDraw.Draw(image)
    start = (pad + 6, pad + h * 0.78)
    end = (pad + w - 10, pad + h * 0.42)
    ctrl = (pad + w * 0.45, pad + h * 0.05)
    body = _curve(start, ctrl, end, 28, 1.6, rng)
    _marker_line(d, body, color, stroke, rng)
    angle = math.atan2(end[1] - body[-3][1], end[0] - body[-3][0])
    head = stroke * 3.4
    for spread in (2.55, -2.55):
        tip = (end[0] + math.cos(angle + spread) * head, end[1] + math.sin(angle + spread) * head)
        _marker_line(d, [end, ((end[0] + tip[0]) / 2 + rng.uniform(-2, 2), (end[1] + tip[1]) / 2), tip],
                     color, stroke, rng)
    rotation = {"right": 0, "down": -90, "left": 180, "up": 90}[direction]
    if rotation:
        image = image.rotate(rotation, expand=True, resample=Image.BICUBIC)
    drop_shadow(image, (0, 4), 6, 150).save(path)


def hand_circle(path: Path, width: int = 360, height: int = 240, color: Color = AMBER,
                stroke: int = 14, seed: int = 3) -> None:
    """A loose marker loop for circling a button (overshoots its start like a real scribble)."""
    rng = random.Random(seed)
    pad = 40
    image = padded(width, height, pad)
    d = ImageDraw.Draw(image)
    cx, cy = pad + width / 2, pad + height / 2
    pts = []
    for i in range(0, 395, 6):
        a = math.radians(i - 100)
        wobble = 1 + rng.uniform(-0.025, 0.025) + (0.05 if i > 350 else 0)
        pts.append((cx + math.cos(a) * (width / 2 - stroke) * wobble,
                    cy + math.sin(a) * (height / 2 - stroke) * wobble))
    _marker_line(d, pts, color, stroke, rng)
    drop_shadow(image, (0, 4), 6, 150).save(path)


def scribble_underline(path: Path, width: int = 560, color: Color = AMBER, stroke: int = 14,
                       seed: int = 5) -> None:
    rng = random.Random(seed)
    pad, h = 30, 60
    image = padded(width, h, pad)
    d = ImageDraw.Draw(image)
    pts = []
    for i in range(41):
        t = i / 40
        pts.append((pad + t * width, pad + h / 2 + math.sin(t * math.pi * 3.2) * 9 + rng.uniform(-2, 2)
                    - t * 8))
    _marker_line(d, pts, color, stroke, rng)
    drop_shadow(image, (0, 3), 5, 140).save(path)


def strike_line(path: Path, width: int = 520, color: Color = RED, stroke: int = 18, seed: int = 11) -> None:
    rng = random.Random(seed)
    pad, h = 30, 90
    image = padded(width, h, pad)
    d = ImageDraw.Draw(image)
    first = _curve((pad, pad + h * 0.7), (pad + width * 0.5, pad + h * 0.45), (pad + width, pad + h * 0.2),
                   16, 2.0, rng)
    _marker_line(d, first, color, stroke, rng)
    glow(image, 8, 0.7).save(path)


def frost_overlay(path: Path, width: int = 1080, height: int = 1920, seed: int = 21) -> None:
    """Icy edges and crystal streaks over a clear centre, for freeze-frames."""
    rng = random.Random(seed)
    image = Image.new("RGBA", (width, height), rgba(ICE, 26))
    edge = Image.new("L", (width, height), 255)
    ed = ImageDraw.Draw(edge)
    ed.rounded_rectangle((110, 150, width - 110, height - 150), radius=260, fill=0)
    edge = edge.filter(ImageFilter.GaussianBlur(90))
    frost = Image.new("RGBA", (width, height), rgba(ICE, 255))
    frost.putalpha(edge.point(lambda v: int(v * 0.72)))
    image.alpha_composite(frost)
    crystals = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    cd = ImageDraw.Draw(crystals)
    for _ in range(420):
        side = rng.choice(("l", "r", "t", "b"))
        depth = abs(rng.gauss(0, 120))
        if side == "l":
            x, y = depth, rng.uniform(0, height)
        elif side == "r":
            x, y = width - depth, rng.uniform(0, height)
        elif side == "t":
            x, y = rng.uniform(0, width), depth
        else:
            x, y = rng.uniform(0, width), height - depth
        length = rng.uniform(18, 70)
        a = rng.uniform(0, math.pi)
        for spoke in range(3):
            aa = a + spoke * math.pi / 3
            cd.line((x - math.cos(aa) * length / 2, y - math.sin(aa) * length / 2,
                     x + math.cos(aa) * length / 2, y + math.sin(aa) * length / 2),
                    fill=(255, 255, 255, rng.randint(60, 170)), width=rng.choice((1, 2, 2, 3)))
    image.alpha_composite(glow(crystals, 3, 0.8))
    image.save(path)


def _icon(kind: str, size: int) -> Image.Image:
    """Simple line icons in soul cyan for step cards."""
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    s = size / 160.0
    line = max(4, int(7 * s))
    phone = (48 * s, 14 * s, 112 * s, 146 * s)
    if kind in ("cover", "reveal", "loading"):
        d.rounded_rectangle(phone, radius=int(14 * s), outline=rgba(CYAN), width=line)
    if kind == "cover":
        d.rounded_rectangle((56 * s, 22 * s, 104 * s, 96 * s), radius=int(8 * s), fill=rgba(DEEP, 255))
        d.rectangle((56 * s, 90 * s, 104 * s, 96 * s), fill=rgba(CYAN, 200))
        d.line((80 * s, 104 * s, 80 * s, 132 * s), fill=rgba(CYAN), width=line)
        d.line((70 * s, 122 * s, 80 * s, 134 * s, 90 * s, 122 * s), fill=rgba(CYAN), width=line, joint="curve")
    elif kind == "build":
        blocks = [(34, 96, 78, 132), (82, 96, 126, 132), (58, 56, 102, 92), (70, 18, 114, 52)]
        for x0, y0, x1, y1 in blocks:
            d.rounded_rectangle((x0 * s, y0 * s, x1 * s, y1 * s), radius=int(6 * s), fill=rgba(CYAN, 60),
                                outline=rgba(CYAN), width=line)
        d.line((30 * s, 40 * s, 44 * s, 26 * s), fill=rgba(AMBER), width=line)
        d.line((24 * s, 60 * s, 40 * s, 58 * s), fill=rgba(AMBER), width=line)
    elif kind == "reveal":
        d.rounded_rectangle((70 * s, 26 * s, 104 * s, 134 * s), radius=int(8 * s), fill=rgba(CYAN, 110))
        for y in (54, 80, 106):
            d.line((14 * s, y * s, 38 * s, y * s), fill=rgba(AMBER), width=line)
    elif kind == "loading":
        d.rounded_rectangle((58 * s, 104 * s, 102 * s, 116 * s), radius=int(5 * s), outline=rgba(CYAN), width=int(3 * s))
        d.rounded_rectangle((60 * s, 106 * s, 88 * s, 114 * s), radius=int(4 * s), fill=rgba(CYAN))
        d.ellipse((66 * s, 44 * s, 94 * s, 72 * s), outline=rgba(CYAN), width=line)
    elif kind == "bolt":
        d.polygon([(90 * s, 10 * s), (40 * s, 90 * s), (76 * s, 90 * s), (62 * s, 150 * s),
                   (122 * s, 62 * s), (84 * s, 62 * s)], fill=rgba(AMBER))
    elif kind == "target":  # lit enemy rings along an aim line
        d.line((22 * s, 146 * s, 138 * s, 14 * s), fill=rgba(AMBER), width=line)
        for cx, cy, r in ((50, 114, 18), (80, 80, 18), (110, 46, 18)):
            d.ellipse(((cx - r) * s, (cy - r) * s, (cx + r) * s, (cy + r) * s),
                      outline=rgba(CYAN), width=line)
            d.ellipse(((cx - 6) * s, (cy - 6) * s, (cx + 6) * s, (cy + 6) * s), fill=rgba(CYAN))
    elif kind == "bend":  # a raw aim line and the assisted one, with the angle between them
        d.line((30 * s, 146 * s, 70 * s, 12 * s), fill=rgba(GREY), width=max(3, line // 2))
        d.line((30 * s, 146 * s, 118 * s, 20 * s), fill=rgba(CYAN), width=line)
        d.polygon([(118 * s, 20 * s), (96 * s, 30 * s), (112 * s, 44 * s)], fill=rgba(CYAN))
        d.arc((0, 60 * s, 110 * s, 170 * s), start=-80, end=-58, fill=rgba(AMBER), width=line)
    elif kind == "slowmo":  # an hourglass
        d.line((40 * s, 18 * s, 120 * s, 18 * s), fill=rgba(CYAN), width=line)
        d.line((40 * s, 142 * s, 120 * s, 142 * s), fill=rgba(CYAN), width=line)
        d.polygon([(50 * s, 24 * s), (110 * s, 24 * s), (84 * s, 80 * s), (110 * s, 136 * s),
                   (50 * s, 136 * s), (76 * s, 80 * s)], outline=rgba(CYAN), width=line)
        d.polygon([(60 * s, 118 * s), (100 * s, 118 * s), (104 * s, 132 * s), (56 * s, 132 * s)],
                  fill=rgba(AMBER))
    return image


def step_card(path: Path, number: str, label: str, icon: str) -> None:
    """A numbered step on the game's stone card panel."""
    scale = 1.45
    panel = Image.open(PANEL_CARD).convert("RGBA")
    panel = panel.resize((int(panel.width * scale), int(panel.height * scale)), Image.LANCZOS)
    pad = 30
    image = padded(panel.width, panel.height, pad)
    image.alpha_composite(panel, (pad, pad))
    d = ImageDraw.Draw(image)
    cx = pad + panel.width / 2
    num_face = font("display", 64)
    nw = d.textlength(number, font=num_face)
    d.text((cx - nw / 2, pad + 56), number, font=num_face, fill=rgba(AMBER))
    ic = _icon(icon, 170)
    image.alpha_composite(glow(ic, 8, 0.9), (int(cx - 85), pad + 138))
    size = 42
    face = font("bold", size)
    while d.textlength(label, font=face) > panel.width - 96 and size > 26:
        size -= 2
        face = font("bold", size)
    tw = d.textlength(label, font=face)
    d.text((cx - tw / 2, pad + panel.height - 118 + (42 - size) / 2), label, font=face, fill=rgba(SOUL_WHITE))
    drop_shadow(image, (0, 10), 14, 140).save(path)


TIER_COLORS = {
    "white": SOUL_WHITE,
    "cyan": CYAN,
    "amber": AMBER,
    "magenta": (214, 110, 255),  # rift magenta lifted so it reads as text on the dark panel
}


def tier_card(path: Path, painting: Path, label: str, count: str, color: str, focus: float = 0.18) -> None:
    """A rarity card on the game's stone panel: a painting crop (around `focus`, 0 = top), a big count and
    the tier name in the tier colour."""
    scale = 1.45
    panel = Image.open(PANEL_CARD).convert("RGBA")
    panel = panel.resize((int(panel.width * scale), int(panel.height * scale)), Image.LANCZOS)
    pad = 30
    image = padded(panel.width, panel.height, pad)
    image.alpha_composite(panel, (pad, pad))
    # Interior of panel_card.png measured at x 32-192, y 55-255 (unscaled).
    x0, x1 = int(38 * scale), int(186 * scale)
    y0, y1 = int(62 * scale), int(150 * scale)
    text_bottom = int(250 * scale)
    art = Image.open(painting).convert("RGBA")
    box_w, box_h = x1 - x0, y1 - y0
    crop_h = int(art.width * box_h / box_w)
    top = int(max(0, min(art.height - crop_h, focus * art.height - crop_h / 2)))
    art = art.crop((0, top, art.width, top + crop_h)).resize((box_w, box_h), Image.LANCZOS)
    mask = Image.new("L", (box_w, box_h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, box_w - 1, box_h - 1), radius=10, fill=255)
    image.paste(art, (pad + x0, pad + y0), mask)
    d = ImageDraw.Draw(image)
    d.rounded_rectangle((pad + x0, pad + y0, pad + x1, pad + y1), radius=10,
                        outline=rgba(TIER_COLORS[color], 200), width=3)
    cx = pad + panel.width / 2
    count_face = font("display", 64)
    label_face = font("bold", 34 if len(label) <= 7 else 29)
    # Stack the count and the label, centred in the space between the painting and the frame's base.
    count_box = d.textbbox((0, 0), count, font=count_face)
    label_box = d.textbbox((0, 0), label, font=label_face)
    gap = 10
    stack = (count_box[3] - count_box[1]) + gap + (label_box[3] - label_box[1])
    top = pad + y1 + ((text_bottom - y1) - stack) / 2
    d.text((cx - (count_box[2] + count_box[0]) / 2, top - count_box[1]), count, font=count_face,
           fill=rgba(SOUL_WHITE))
    label_top = top + (count_box[3] - count_box[1]) + gap
    label_layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    ImageDraw.Draw(label_layer).text((cx - (label_box[2] + label_box[0]) / 2, label_top - label_box[1]), label,
                                     font=label_face, fill=rgba(TIER_COLORS[color]))
    image.alpha_composite(glow(label_layer, 6, 0.9))
    drop_shadow(image, (0, 10), 14, 140).save(path)


def floor_outline(path: Path, template: Path, fill: bool = False, width: int = 1080, height: int = 1920) -> None:
    """The shared Endless floor polygon (texture UV) as a glowing soul-cyan outline on the canvas."""
    import json

    points = [(u * width, v * height) for u, v in json.loads(template.read_text())["polygon_uv"]]
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    if fill:
        d.polygon(points, fill=rgba(CYAN, 38))
    d.line(points + [points[0]], fill=rgba(CYAN, 255), width=10, joint="curve")
    for x, y in points:
        d.ellipse((x - 9, y - 9, x + 9, y + 9), fill=rgba(SOUL_WHITE, 255))
    glow(image, 18, 1.0).save(path)


def light_map(path: Path, mask_path: Path, channel: str, color: str, width: int = 1080, height: int = 1920,
              gain: float = 1.6) -> None:
    """One channel of an Endless scenery mask (R lights, G moving regions) as a coloured glow layer."""
    mask = Image.open(mask_path).convert("RGBA").resize((width, height), Image.BILINEAR)
    value = mask.split()["RGBA".index(channel)].point(lambda v: min(255, int(v * gain)))
    tint = {"amber": (255, 196, 110), "cyan": CYAN, "white": SOUL_WHITE, "magenta": MAGENTA}[color]
    layer = Image.new("RGBA", (width, height), rgba(tint, 255))
    layer.putalpha(value)
    glow(layer, 10, 1.0).save(path)


def crop_image(src: Path, out: Path, box: Tuple[int, int, int, int]) -> None:
    Image.open(src).convert("RGB").crop(box).save(out)


def kit(out: Path) -> None:
    out.mkdir(parents=True, exist_ok=True)
    grid_background(out / "bg_grid.png")
    frame_strip(out / "frame_strip.png")
    touch_dot(out / "touch_dot.png")
    tap_ring(out / "tap_ring.png")
    for direction in ("right", "left", "down", "up"):
        hand_arrow(out / "arrow_{}.png".format(direction), direction)
    hand_arrow(out / "arrow_right_long.png", "right", length=460, seed=9)
    hand_circle(out / "circle_amber.png")
    scribble_underline(out / "underline_amber.png")
    scribble_underline(out / "underline_cyan.png", color=CYAN, seed=6)
    strike_line(out / "strike_red.png")
    frost_overlay(out / "frost_overlay.png")


def preview(folder: Path, sheet: Path) -> None:
    files = sorted(p for p in folder.glob("*.png") if p.name != sheet.name)
    tile = 300
    cols = 5
    rows = (len(files) + cols - 1) // cols
    board = Image.new("RGBA", (cols * tile, rows * (tile + 30)), (60, 64, 72, 255))
    d = ImageDraw.Draw(board)
    for i, p in enumerate(files):
        im = Image.open(p).convert("RGBA")
        im.thumbnail((tile - 16, tile - 16))
        x, y = (i % cols) * tile, (i // cols) * (tile + 30)
        board.alpha_composite(im, (x + (tile - im.width) // 2, y + (tile - im.height) // 2))
        d.text((x + 6, y + tile + 4), p.name, font=font("regular", 18), fill=(255, 255, 255, 255))
    board.convert("RGB").save(sheet)


def main(argv: List[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command")
    p = sub.add_parser("kit")
    p.add_argument("out", type=Path)
    p = sub.add_parser("comment")
    p.add_argument("out", type=Path)
    p.add_argument("--name", default="Playtester")
    p.add_argument("--subtitle", default="")
    p.add_argument("--text", required=True)
    p.add_argument("--accent", default="")
    p = sub.add_parser("step")
    p.add_argument("out", type=Path)
    p.add_argument("--number", required=True)
    p.add_argument("--label", required=True)
    p.add_argument("--icon", required=True,
                   choices=("cover", "build", "reveal", "loading", "bolt", "target", "bend", "slowmo"))
    p = sub.add_parser("bar")
    p.add_argument("out", type=Path)
    p.add_argument("--label", required=True)
    p.add_argument("--width", type=int, default=900)
    p.add_argument("--color", choices=sorted(BAR_COLORS), default="red")
    p = sub.add_parser("meter")
    p.add_argument("prefix", type=Path)
    p.add_argument("--label", required=True)
    p.add_argument("--color", choices=sorted(BAR_COLORS), default="cyan")
    p.add_argument("--width", type=int, default=760)
    p = sub.add_parser("code")
    p.add_argument("out", type=Path)
    p.add_argument("--number", required=True)
    p.add_argument("--text", required=True)
    p.add_argument("--accent", choices=sorted(CODE_ACCENTS), default="none")
    p.add_argument("--width", type=int, default=820)
    p = sub.add_parser("preview")
    p.add_argument("folder", type=Path)
    p.add_argument("sheet", type=Path)
    p = sub.add_parser("tier")
    p.add_argument("out", type=Path)
    p.add_argument("--image", type=Path, required=True)
    p.add_argument("--label", required=True)
    p.add_argument("--count", required=True)
    p.add_argument("--color", choices=sorted(TIER_COLORS), required=True)
    p.add_argument("--focus", type=float, default=0.18)
    p = sub.add_parser("outline")
    p.add_argument("out", type=Path)
    p.add_argument("--template", type=Path, default=ROOT / "concept_art/wisp_rush_endless_v1/floor_template.json")
    p.add_argument("--fill", action="store_true")
    p = sub.add_parser("lightmap")
    p.add_argument("out", type=Path)
    p.add_argument("--mask", type=Path, required=True)
    p.add_argument("--channel", choices=("R", "G", "B"), default="R")
    p.add_argument("--color", choices=("amber", "cyan", "white", "magenta"), default="amber")
    p.add_argument("--gain", type=float, default=1.6)
    p = sub.add_parser("crop")
    p.add_argument("src", type=Path)
    p.add_argument("out", type=Path)
    p.add_argument("--box", required=True, help="x0,y0,x1,y1 in source pixels")
    args = parser.parse_args(argv)
    if getattr(args, "out", None) is not None:
        args.out.parent.mkdir(parents=True, exist_ok=True)
    if args.command == "kit":
        kit(args.out)
    elif args.command == "comment":
        args.out.parent.mkdir(parents=True, exist_ok=True)
        comment_card(args.out, args.name, args.text, args.accent.split(","), args.subtitle)
    elif args.command == "step":
        args.out.parent.mkdir(parents=True, exist_ok=True)
        step_card(args.out, args.number, args.label, args.icon)
    elif args.command == "bar":
        args.out.parent.mkdir(parents=True, exist_ok=True)
        freeze_bar(args.out, args.label, args.width, color=args.color)
    elif args.command == "meter":
        args.prefix.parent.mkdir(parents=True, exist_ok=True)
        meter_pair(args.prefix, args.label, args.color, args.width)
    elif args.command == "code":
        code_card(args.out, args.number, args.text, args.accent, args.width)
    elif args.command == "preview":
        preview(args.folder, args.sheet)
    elif args.command == "tier":
        tier_card(args.out, args.image, args.label, args.count, args.color, args.focus)
    elif args.command == "outline":
        floor_outline(args.out, args.template, args.fill)
    elif args.command == "lightmap":
        light_map(args.out, args.mask, args.channel, args.color, gain=args.gain)
    elif args.command == "crop":
        x0, y0, x1, y1 = (int(v) for v in args.box.split(","))
        crop_image(args.src, args.out, (x0, y0, x1, y1))
    else:
        parser.print_help()
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
