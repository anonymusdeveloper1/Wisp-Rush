"""Pack the three preserved Home icon generations using the pickup icon recipe.

Requires Pillow; no NumPy. Writes only assets/art/ui/home_icons/*.png and
this pack's preview_all.png. Raw images and exact prompts remain unchanged.
"""

from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parent
REPO = ROOT.parent.parent
ICONS = [("shop", "SHOP"), ("daily", "DAILY"), ("trials", "TRIALS")]
# Exactly the palette in concept_art/pickup_items_v1/build_icons.py.
HEX = [
    "0B1116", "111521", "263D42", "4C6670", "536064", "8FB3BA",
    "62E8F2", "EAFDFF", "A78768", "FAE5C1", "F3A847", "FFD391",
]
PALETTE = [tuple(bytes.fromhex(value)) for value in HEX]
LOGICAL_SIZE = 48
# Pickup/RP pack builders fit 48 logical pixels on a 64-pixel canvas: 3/4.
BODY_SIZE = LOGICAL_SIZE * 48 // 64
GRID = 4
SIZE = LOGICAL_SIZE * GRID
SCREEN_SIZE = 96
ALPHA_THRESHOLD = 128


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pack(source: Path) -> Image.Image:
    with Image.open(source) as opened:
        image = opened.convert("RGBA")
    alpha = image.getchannel("A").point(
        lambda value: 255 if value >= ALPHA_THRESHOLD else 0
    )
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
    cache: dict[tuple[int, int, int], tuple[int, ...]] = {}
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = image.getpixel((x, y))
            if not a:
                continue
            rgb = (r, g, b)
            if rgb not in cache:
                cache[rgb] = min(
                    PALETTE,
                    key=lambda colour: sum((rgb[i] - colour[i]) ** 2 for i in range(3)),
                )
            mapped.putpixel((x, y), (*cache[rgb], 255))
    canvas = Image.new("RGBA", (LOGICAL_SIZE, LOGICAL_SIZE))
    canvas.alpha_composite(
        mapped,
        ((LOGICAL_SIZE - image.width) // 2, (LOGICAL_SIZE - image.height) // 2),
    )
    return canvas.resize((SIZE, SIZE), Image.Resampling.NEAREST)


def verify(image: Image.Image) -> None:
    if image.mode != "RGBA" or image.size != (SIZE, SIZE):
        raise ValueError("Packed icon must be 192 x 192 RGBA")
    colours = image.getcolors(SIZE * SIZE)
    if colours is None or len(colours) > len(PALETTE) + 1:
        raise ValueError("Packed icon exceeds the pickup palette")
    for _, pixel in colours:
        if pixel[3] not in (0, 255):
            raise ValueError("Packed alpha must be binary")
        if pixel[3] == 0 and pixel != (0, 0, 0, 0):
            raise ValueError("Transparent pixels must be zero RGBA")
        if pixel[3] == 255 and pixel[:3] not in PALETTE:
            raise ValueError("Packed colour is outside the pickup palette")
    logical = image.resize((LOGICAL_SIZE, LOGICAL_SIZE), Image.Resampling.NEAREST)
    if logical.resize((SIZE, SIZE), Image.Resampling.NEAREST).tobytes() != image.tobytes():
        raise ValueError("Packed icon is not on the exact 4 px grid")
    screen = image.resize((SCREEN_SIZE, SCREEN_SIZE), Image.Resampling.NEAREST)
    if logical.resize((SCREEN_SIZE, SCREEN_SIZE), Image.Resampling.NEAREST).tobytes() != screen.tobytes():
        raise ValueError("96 px display does not preserve exact 2 px logical pixels")
    box = image.getchannel("A").getbbox()
    margin = (LOGICAL_SIZE - BODY_SIZE) // 2 * GRID
    if box is None or min(box[:2]) < margin or max(box[2:]) > SIZE - margin:
        raise ValueError("Packed icon is empty or extends beyond its transparent margins")
    if max(box[2] - box[0], box[3] - box[1]) > BODY_SIZE * GRID:
        raise ValueError("Packed silhouette exceeds the reference scale")


def make_preview(images: list[Image.Image]) -> Image.Image:
    font_path = REPO / "assets/fonts/pixelify_sans/source/PixelifySans.ttf"
    title = ImageFont.truetype(str(font_path), 33)
    label = ImageFont.truetype(str(font_path), 22)
    tile_path = REPO / "assets/ui/theme/textures/caption_tile_normal.png"
    with Image.open(tile_path) as opened:
        tile = opened.convert("RGBA")
    if tile.size != (140, 164):
        raise ValueError("Home CaptionTile reference must remain 140 x 164")
    review = Image.new("RGB", (880, 850), "#0B1116")
    draw = ImageDraw.Draw(review)
    draw.fontmode = "1"
    draw.text((32, 22), "WISP RUSH / HOME ICONS", font=title, fill="#FAE5C1")
    draw.text((32, 67), "48 logical px / 192 RGBA / 96 px Home box", font=label, fill="#8FB3BA")
    for index, ((_, caption), image) in enumerate(zip(ICONS, images)):
        x = 32 + index * 286
        draw.rectangle((x, 106, x + 255, 820), fill="#111521", outline="#263D42", width=4)
        draw.text((x + 128, 119), caption, font=label, fill="#FAE5C1", anchor="mt")
        review.paste(image, (x + 32, 152), image)
        draw.text((x + 128, 351), "192 px / packed", font=label, fill="#8FB3BA", anchor="mt")
        home = tile.copy()
        screen = image.resize((SCREEN_SIZE, SCREEN_SIZE), Image.Resampling.NEAREST)
        # UI design system: 96 px Icon at y=18; caption slot y=127..151.
        home.alpha_composite(screen, (22, 18))
        home_draw = ImageDraw.Draw(home)
        home_draw.fontmode = "1"
        home_draw.text((70, 126), caption, font=label, fill="#FAE5C1", anchor="mt")
        review.paste(home, (x + 58, 390), home)
        draw.text((x + 128, 561), "96 px / Home tile", font=label, fill="#8FB3BA", anchor="mt")
        draw.rectangle((x + 80, 602, x + 175, 697), fill="#FAE5C1")
        review.paste(screen, (x + 80, 602), screen)
        draw.text((x + 128, 704), "96 px / alpha", font=label, fill="#8FB3BA", anchor="mt")
        small = image.resize((48, 48), Image.Resampling.NEAREST)
        review.paste(small, (x + 104, 746), small)
        draw.text((x + 128, 799), "48 px", font=label, fill="#8FB3BA", anchor="mt")
    return review


def build() -> None:
    generation = json.loads((ROOT / "generation.json").read_text(encoding="utf-8"))
    outputs = generation["outputs"]
    records = {record["id"]: record for record in outputs}
    if len(outputs) != len(ICONS) or set(records) != {icon_id for icon_id, _ in ICONS}:
        raise ValueError("generation.json must record exactly the three Home sources")
    images: list[Image.Image] = []
    for icon_id, _ in ICONS:
        source = ROOT / "raw" / f"{icon_id}.png"
        prompt = ROOT / "prompts" / f"{icon_id}.md"
        record = records[icon_id]
        if digest(source) != record["source_sha256"]:
            raise ValueError(f"Preserved source hash changed: {source}")
        if digest(prompt) != record["prompt_sha256"]:
            raise ValueError(f"Exact prompt hash changed: {prompt}")
        with Image.open(source) as opened:
            if opened.format != "PNG" or opened.mode != "RGBA":
                raise ValueError(f"Preserved source must be an RGBA PNG: {source}")
            if list(opened.size) != record["source_size"]:
                raise ValueError(f"Preserved source dimensions changed: {source}")
            corners = [(0, 0), (opened.width - 1, 0),
                       (0, opened.height - 1), (opened.width - 1, opened.height - 1)]
            if any(opened.getpixel(point)[3] != 0 for point in corners):
                raise ValueError(f"Source background corners must be transparent: {source}")
        image = pack(source)
        verify(image)
        images.append(image)
    # Prepare all three images and the review before writing generated outputs.
    review = make_preview(images)
    destination = REPO / "assets/art/ui/home_icons"
    destination.mkdir(parents=True, exist_ok=True)
    for (icon_id, _), image in zip(ICONS, images):
        runtime = destination / f"{icon_id}.png"
        image.save(runtime)
        with Image.open(runtime) as saved:
            verify(saved)
            if saved.tobytes() != image.tobytes():
                raise ValueError(f"Saved pixels differ: {runtime}")
        source = ROOT / "raw" / runtime.name
        prompt = ROOT / "prompts" / f"{icon_id}.md"
        if digest(source) != records[icon_id]["source_sha256"]:
            raise ValueError(f"Builder altered a preserved source: {source}")
        if digest(prompt) != records[icon_id]["prompt_sha256"]:
            raise ValueError(f"Builder altered an exact prompt: {prompt}")
        print(f"{runtime.relative_to(REPO).as_posix()}: "
              f"{SIZE} x {SIZE} RGBA, {runtime.stat().st_size} bytes")
    preview_path = ROOT / "preview_all.png"
    review.save(preview_path)
    print(f"Preview: {preview_path.relative_to(REPO).as_posix()} (880 x 850)")
    print("HOME ICONS: OK (three RGBA icons, exact 4 px grid, 2 px at 96, binary alpha)")


if __name__ == "__main__":
    build()
