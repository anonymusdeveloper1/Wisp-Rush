"""Pack the four preserved RP generations using the pickup icon recipe.

Requires Pillow, as concept_art/pickup_items_v1/build_icons.py does.
Writes only assets/art/ui/rp_packs/*.png and this pack's preview_all.png.
"""

from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent
PACKS = [
    ("rp_pack_500", "500 RP"),
    ("rp_pack_1200", "1,200 RP"),
    ("rp_pack_2500", "2,500 RP"),
    ("rp_pack_6500", "6,500 RP"),
]
# The three opaque RGB colours measured in icon_currency.png.
CRYSTAL_HEX = ["604D40", "ECA255", "FAE5C1"]
# Existing pickup colours for the chest's dark body and hard edge highlights.
CHEST_HEX = CRYSTAL_HEX + [
    "0B1116", "111521", "263D42", "4C6670", "536064", "8FB3BA",
    "A78768", "F3A847", "FFD391",
]
LOGICAL_SIZE = 64
BODY_SIZE = 48
GRID = 4
SIZE = LOGICAL_SIZE * GRID


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def palette_for(pack_id: str) -> list[tuple[int, ...]]:
    values = CHEST_HEX if pack_id == "rp_pack_6500" else CRYSTAL_HEX
    return [tuple(bytes.fromhex(value)) for value in values]


def pack(source: Path, palette: list[tuple[int, ...]]) -> Image.Image:
    with Image.open(source) as opened:
        image = opened.convert("RGBA")
    alpha = image.getchannel("A").point(lambda value: 255 if value >= 128 else 0)
    box = alpha.getbbox()
    if box is None:
        raise ValueError(f"Empty icon: {source}")
    image.putalpha(alpha)
    image = image.crop(box)
    ratio = BODY_SIZE / max(image.size)
    image = image.resize(
        (max(1, round(image.width * ratio)), max(1, round(image.height * ratio))),
        Image.Resampling.NEAREST,
    )
    mapped = Image.new("RGBA", image.size)
    cache = {}
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = image.getpixel((x, y))
            if not a:
                continue
            rgb = (r, g, b)
            if rgb not in cache:
                cache[rgb] = min(
                    palette,
                    key=lambda colour: sum((rgb[i] - colour[i]) ** 2 for i in range(3)),
                )
            mapped.putpixel((x, y), (*cache[rgb], 255))
    canvas = Image.new("RGBA", (LOGICAL_SIZE, LOGICAL_SIZE))
    canvas.alpha_composite(
        mapped,
        ((LOGICAL_SIZE - image.width) // 2, (LOGICAL_SIZE - image.height) // 2),
    )
    return canvas.resize((SIZE, SIZE), Image.Resampling.NEAREST)


def verify(image: Image.Image, palette: list[tuple[int, ...]]) -> None:
    if image.mode != "RGBA" or image.size != (SIZE, SIZE):
        raise ValueError("Packed icon must be 256 x 256 RGBA")
    colours = image.getcolors(SIZE * SIZE)
    if colours is None or len(colours) > len(palette) + 1:
        raise ValueError("Packed icon exceeds its limited palette")
    for _, pixel in colours:
        if pixel[3] not in (0, 255):
            raise ValueError("Packed alpha must be binary")
        if pixel[3] == 0 and pixel != (0, 0, 0, 0):
            raise ValueError("Transparent pixels must be zero RGBA")
        if pixel[3] == 255 and pixel[:3] not in palette:
            raise ValueError("Packed colour is outside its palette")
    logical = image.resize((LOGICAL_SIZE, LOGICAL_SIZE), Image.Resampling.NEAREST)
    enlarged = logical.resize((SIZE, SIZE), Image.Resampling.NEAREST)
    if enlarged.tobytes() != image.tobytes():
        raise ValueError("Packed icon is not on the exact 4 px grid")
    box = image.getchannel("A").getbbox()
    if box is None or min(box[:2]) < GRID or max(box[2:]) > SIZE - GRID:
        raise ValueError("Packed icon is empty or touches its canvas edge")


def make_preview(images: list[Image.Image]) -> Image.Image:
    font_path = REPO / "assets/fonts/pixelify_sans/source/PixelifySans.ttf"
    font = ImageFont.truetype(str(font_path), 26)
    small = ImageFont.truetype(str(font_path), 18)
    review = Image.new("RGB", (800, 940), "#0B1116")
    draw = ImageDraw.Draw(review)
    draw.text((30, 24), "WISP RUSH / RIFT POINTS PACKS", font=font, fill="#FAE5C1")
    draw.text((30, 61), "256 px RGBA / 4 px grid / preserved originals",
              font=small, fill="#8FB3BA")
    for index, ((_, label), image) in enumerate(zip(PACKS, images)):
        row, column = divmod(index, 2)
        x, y = 40 + column * 380, 110 + row * 410
        draw.rectangle((x - 10, y, x + 330, y + 390),
                       fill="#111521", outline="#263D42", width=4)
        draw.text((x + 160, y + 18), label, font=font, fill="#FAE5C1", anchor="mt")
        review.paste(image, (x + 32, y + 48), image)
        for size, offset in [(64, 10), (48, 110), (32, 210)]:
            preview = image.resize((size, size), Image.Resampling.NEAREST)
            if size == 64:
                draw.rectangle((x + offset, y + 284, x + offset + 63, y + 347),
                               fill="#FAE5C1")
            review.paste(preview, (x + offset, y + 284), preview)
            draw.text((x + offset, y + 354), f"{size} px",
                      font=small, fill="#8FB3BA")
    return review


def build() -> None:
    generation = json.loads((ROOT / "generation.json").read_text(encoding="utf-8"))
    records = {record["id"]: record for record in generation["outputs"]}
    if set(records) != {pack_id for pack_id, _ in PACKS}:
        raise ValueError("generation.json must record exactly the four RP pack sources")
    images = []
    for pack_id, _ in PACKS:
        source = ROOT / "raw" / f"{pack_id}.png"
        prompt = ROOT / "prompts" / f"{pack_id}.md"
        record = records[pack_id]
        if digest(source) != record["source_sha256"]:
            raise ValueError(f"Preserved source hash changed: {source}")
        if digest(prompt) != record["prompt_sha256"]:
            raise ValueError(f"Exact prompt hash changed: {prompt}")
        with Image.open(source) as opened:
            if opened.mode != record["source_mode"] or list(opened.size) != record["source_size"]:
                raise ValueError(f"Preserved source dimensions/mode changed: {source}")
        palette = palette_for(pack_id)
        image = pack(source, palette)
        verify(image, palette)
        images.append(image)
    # Prepare all four images and the review before writing generated outputs.
    review = make_preview(images)
    destination = REPO / "assets/art/ui/rp_packs"
    destination.mkdir(parents=True, exist_ok=True)
    for (pack_id, _), image in zip(PACKS, images):
        runtime = destination / f"{pack_id}.png"
        image.save(runtime)
        with Image.open(runtime) as saved:
            verify(saved, palette_for(pack_id))
            if saved.tobytes() != image.tobytes():
                raise ValueError(f"Saved pixels differ: {runtime}")
        source = ROOT / "raw" / runtime.name
        if digest(source) != records[pack_id]["source_sha256"]:
            raise ValueError(f"Builder altered a preserved source: {source}")
        print(f"{runtime.relative_to(REPO).as_posix()}: "
              f"{SIZE} x {SIZE} RGBA, {runtime.stat().st_size} bytes")
    preview_path = ROOT / "preview_all.png"
    review.save(preview_path)
    print(f"Preview: {preview_path.relative_to(REPO).as_posix()} (800 x 940)")
    print("RP PACK ICONS: OK (four RGBA icons, exact 4 px grid, binary alpha)")


if __name__ == "__main__":
    build()
