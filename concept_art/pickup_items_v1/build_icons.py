"""Pack the preserved item generations onto the game's four-pixel UI grid."""

from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent
ITEMS = [
    ("soul_ward", "SOUL WARD"), ("rift_magnet", "RIFT MAGNET"),
    ("fortune_star", "FORTUNE STAR"), ("stillglass", "STILLGLASS"),
    ("banish_bomb", "BANISH BOMB"), ("reapers_edge", "REAPER'S EDGE"),
    ("echo_wisp", "ECHO WISP"),
]
# Existing Palette colours; no enemy/selection magenta in friendly pickups.
HEX = ["0B1116", "111521", "263D42", "4C6670", "536064", "8FB3BA",
       "62E8F2", "EAFDFF", "A78768", "FAE5C1", "F3A847", "FFD391"]
PALETTE = [tuple(bytes.fromhex(value)) for value in HEX]
LOGICAL_SIZE = 64
BODY_SIZE = 48
GRID = 4


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pack(source: Path) -> tuple[Image.Image, tuple[int, ...]]:
    image = Image.open(source).convert("RGBA")
    alpha = image.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    box = alpha.getbbox()
    if box is None:
        raise ValueError(f"Empty icon: {source}")
    image.putalpha(alpha)
    image = image.crop(box)
    ratio = BODY_SIZE / max(image.size)
    image = image.resize((max(1, round(image.width * ratio)),
                          max(1, round(image.height * ratio))), Image.Resampling.NEAREST)
    mapped = Image.new("RGBA", image.size)
    cache = {}
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = image.getpixel((x, y))
            if not a:
                continue
            rgb = (r, g, b)
            if rgb not in cache:
                cache[rgb] = min(PALETTE, key=lambda colour:
                    sum((rgb[i] - colour[i]) ** 2 for i in range(3)))
            mapped.putpixel((x, y), (*cache[rgb], 255))
    canvas = Image.new("RGBA", (LOGICAL_SIZE, LOGICAL_SIZE))
    canvas.alpha_composite(mapped, ((LOGICAL_SIZE - image.width) // 2,
                                     (LOGICAL_SIZE - image.height) // 2))
    return canvas.resize((256, 256), Image.Resampling.NEAREST), box


def verify(image: Image.Image) -> int:
    assert image.mode == "RGBA" and image.size == (256, 256)
    colours = image.getcolors(image.width * image.height)
    assert colours is not None and len(colours) <= len(PALETTE) + 1
    assert all(pixel[3] in (0, 255) for _, pixel in colours)
    assert all(pixel == (0, 0, 0, 0) for _, pixel in colours if pixel[3] == 0)
    logical = image.resize((64, 64), Image.Resampling.NEAREST)
    assert logical.resize((256, 256), Image.Resampling.NEAREST).tobytes() == image.tobytes()
    box = image.getchannel("A").getbbox()
    assert box is not None and box[0] >= GRID and box[1] >= GRID
    assert box[2] <= 256 - GRID and box[3] <= 256 - GRID
    return len(colours)


def build() -> None:
    destination = REPO / "assets/art/ui/items"
    destination.mkdir(parents=True, exist_ok=True)
    (ROOT / "icons").mkdir(exist_ok=True)
    font_path = REPO / "assets/fonts/pixelify_sans/source/PixelifySans.ttf"
    font = ImageFont.truetype(str(font_path), 26)
    small = ImageFont.truetype(str(font_path), 18)
    review = Image.new("RGB", (800, 1640), "#0B1116")
    draw = ImageDraw.Draw(review)
    draw.text((30, 24), "WISP RUSH / PICKUP ITEMS", font=font, fill="#FAE5C1")
    draw.text((30, 61), "256 px RGBA / 4 px grid / preserved originals", font=small,
              fill="#8FB3BA")
    records = []
    for index, (item_id, name) in enumerate(ITEMS):
        source = ROOT / "raw" / f"{item_id}.png"
        before = digest(source)
        image, crop = pack(source)
        count = verify(image)
        final = ROOT / "icons" / f"{item_id}.png"
        image.save(final)
        runtime = destination / final.name
        runtime.write_bytes(final.read_bytes())
        assert digest(source) == before and runtime.read_bytes() == final.read_bytes()
        records.append({"id": item_id, "logical_size": [64, 64], "size": [256, 256],
                        "grid": GRID, "rgba_colours": count, "source_crop": crop,
                        "source_sha256": before, "final_sha256": digest(final),
                        "runtime": runtime.relative_to(REPO).as_posix(),
                        "alpha": [0, 255]})
        row, column = divmod(index, 2)
        x = 40 + column * 380 if index < 6 else 230
        y = 110 + row * 370
        draw.rectangle((x - 10, y, x + 330, y + 350), fill="#111521", outline="#263D42", width=4)
        draw.text((x + 160, y + 18), name, font=font, fill="#FAE5C1", anchor="mt")
        review.paste(image, (x + 32, y + 50), image)
        for size, offset in [(64, 10), (48, 110), (32, 200)]:
            preview = image.resize((size, size), Image.Resampling.NEAREST)
            review.paste(preview, (x + offset, y + 264), preview)
            draw.text((x + offset, y + 330), f"{size} px", font=small, fill="#8FB3BA")
    review.save(ROOT / "preview_all.png")
    (ROOT / "metadata.json").write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")
    print("ITEM ICONS: OK (seven RGBA icons, exact 4 px grid, binary alpha)")


if __name__ == "__main__":
    build()
