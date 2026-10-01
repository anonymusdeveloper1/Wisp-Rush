"""Fit the generated Wisp Bearer backplate to the Endless arena art contract.

Run from anywhere with: python concept_art/arenas_v2/wisp_bearer/build_source.py
The project layout mask defines every floor and rim pixel.
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
LAYOUT = HERE.parent / "_layout"
RAW = HERE / "generated_backplate.png"
OUT = HERE / "source.png"

def remap_axis(image, source_edges, target_edges, horizontal):
    size = (target_edges[-1], image.height) if horizontal else (image.width, target_edges[-1])
    result = Image.new("RGB", size)
    for a, b, c, d in zip(source_edges[:-1], source_edges[1:], target_edges[:-1], target_edges[1:]):
        box = (a, 0, b, image.height) if horizontal else (0, a, image.width, b)
        part = image.crop(box)
        part_size = (d - c, image.height) if horizontal else (image.width, d - c)
        result.paste(part.resize(part_size, Image.Resampling.LANCZOS),
                     (c, 0) if horizontal else (0, c))
    return result

def main():
    raw = Image.open(RAW).convert("RGB")
    if raw.size != (841, 1870):
        raise SystemExit(f"Unexpected backplate size: {raw.size}")
    mask = np.asarray(Image.open(LAYOUT / "arena_floor_mask.png").convert("L"))
    if mask.shape != (2400, 1080):
        raise SystemExit(f"Unexpected mask size: {mask.shape}")
    if set(np.unique(mask)) != {0, 128, 255}:
        raise SystemExit("The layout mask must contain only background, rim and floor")

    # Anchor the backplate's painted inner and outer edges to the art contract.
    art = remap_axis(raw, [0, 152, 181, 660, 689, 841],
                     [0, 134, 174, 904, 944, 1080], True)
    art = remap_axis(art, [0, 448, 479, 1231, 1262, 1510, 1870],
                     [0, 619, 659, 1747, 1787, 1950, 2400], False)

    # The two disposable bleed bands contain only sky and ground.
    sky = Image.new("RGB", (1080, 240))
    sky_draw = ImageDraw.Draw(sky)
    for y in range(240):
        t = y / 239
        sky_draw.line((0, y, 1079, y),
                      fill=(round(10 + 7 * t), round(17 + 10 * t), round(31 + 15 * t)))
    stars = np.random.default_rng(23)
    for x, y in zip(stars.integers(70, 1010, 36), stars.integers(15, 210, 36)):
        sky_draw.point((int(x), int(y)), fill=(70, 84, 111))
    ground = raw.crop((0, 1683, 841, 1870)).resize((1080, 240), Image.Resampling.LANCZOS)
    sky_pixels = np.asarray(sky, dtype=np.float32)
    ground_pixels = np.asarray(ground, dtype=np.float32)
    pixels = np.array(art, dtype=np.float32)

    # Subdue the HUD region with a soft lower edge, and keep the top bleed sky-only.
    for y in range(240, 560):
        shade = 0.62 if y < 500 else 0.62 + 0.38 * ((y - 500) / 60) ** 2
        pixels[y] *= shade
    pixels[:240] = sky_pixels
    sky_edge = sky_pixels[-1]
    for y in range(240, 320):
        t = ((y - 240) / 80) ** 2
        pixels[y] = sky_edge * (1 - t) + pixels[y] * t

    # Enter the ground-only lower bleed without a hard horizontal join.
    ground_edge = ground_pixels[0]
    for y in range(2080, 2160):
        t = ((y - 2080) / 80) ** 2
        pixels[y] = pixels[y] * (1 - t) + ground_edge * t
    pixels[2160:] = ground_pixels

    # The first/last 60 px are disposable: keep all bright frame art inside them.
    for x in range(100):
        strength = 1.0 if x < 60 else 0.85 * (100 - x) / 40
        pixels[240:2160, x] = pixels[240:2160, x] * (1 - strength) + np.array([13, 19, 35]) * strength
        other = 1079 - x
        pixels[240:2160, other] = pixels[240:2160, other] * (1 - strength) + np.array([13, 19, 35]) * strength
    art = Image.fromarray(np.clip(pixels, 0, 255).astype(np.uint8), "RGB")

    # Reuse the clean upper/lower stone strips to make an unobstructed 40 px rim.
    rim = np.array(art, dtype=np.uint8)
    top = art.crop((134, 619, 944, 659))
    bottom = art.crop((134, 1747, 944, 1787))
    side_left = top.transpose(Image.Transpose.ROTATE_90).resize((40, 1088), Image.Resampling.LANCZOS)
    side_right = bottom.transpose(Image.Transpose.ROTATE_270).resize((40, 1088), Image.Resampling.LANCZOS)
    rim[659:1747, 134:174] = np.asarray(side_left)
    rim[659:1747, 904:944] = np.asarray(side_right)

    # Retain the generated paving pattern while restricting value to 30-40%.
    source_floor = np.asarray(art.crop((174, 659, 904, 1747)), dtype=np.float32)
    value = 0.2126 * source_floor[..., 0] + 0.7152 * source_floor[..., 1] + 0.0722 * source_floor[..., 2]
    offset = np.clip((value - np.median(value)) * 0.40, -9, 9)
    floor = np.clip(np.array([67, 91, 98], dtype=np.float32) + offset[..., None], 0, 255).astype(np.uint8)

    final = np.array(art, dtype=np.uint8)
    final[mask == 128] = rim[mask == 128]
    final[659:1747, 174:904] = floor
    image = Image.fromarray(final, "RGB")
    image.save(OUT, optimize=True)

    floor_value = 0.2126 * floor[..., 0] + 0.7152 * floor[..., 1] + 0.0722 * floor[..., 2]
    print(f"SOURCE: {OUT} {image.width}x{image.height} {image.mode}")
    print(f"FLOOR: [174, 659, 904, 1747], brightness {floor_value.min()/255:.3f}-{floor_value.max()/255:.3f}")

if __name__ == "__main__":
    main()
