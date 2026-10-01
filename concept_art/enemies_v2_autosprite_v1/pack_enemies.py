"""Clean and pack the five Enemies v2 AutoSprite sheets into the game's enemy atlases and animations.

    python concept_art/enemies_v2_autosprite_v1/pack_enemies.py

Every file in `raw/<enemy>/` is the owner's export, unchanged (2026-09-28; the owner's
`Desktop/Whisbrush Enemies/` folder), renamed: `move.png` (the loop), `attack.png` (plays once),
`base.png` (the first frame, reference only) and, for the three shooters, `projectile.png`. The sheets
are 256 px cells, five to a row, transparent.

**Cleaning (owner, 2026-09-28: "some of the sheets have white parts in them, clean first").** Two kinds
of AutoSprite background leftovers were found:
- **White patches trapped inside the silhouette**, where the background removal could not reach: flat
  white between the Stone Golem's floating stones (230-320 px a frame) and a white sliver inside the
  Claw Ghost's cloth (about 250 px a frame, most attack frames). Every flat near-white patch of at
  least `blob` pixels goes, with its light anti-aliased rim. Only for those two enemies: the Bone
  Witch's skull and book pages are the same flat white and are real art. The Claw Ghost's eyes are
  white too, which is why its `blob` is larger than the eyes.
- **A light, half-transparent fringe on the outline** (Root Mask, Hooded Scribe, a little elsewhere):
  light pixels under 200 alpha next to transparency go, twice, on every sheet.
`review/<enemy>_clean.png` shows each frame before (left) and after (right) on green.

**Packing.** Every non-empty cell of both sheets, in order. Each enemy gets one frame size: a box
centred on its body (the middle of the move frames) that holds every frame of both animations, so the
node's origin is the body's middle, and mirroring the sprite to face the Wisp never moves the body.
The frame size and the body size (the move frames' bounds) are written into the `SpriteFrames` as
metadata (`frame_size`, `body_size`); `WholeFrameEnemy` scales the sprite from them. Frames sit in
one atlas per enemy with 8 px transparent gutters (the attack outline shader samples into them).

Writes `assets/art/characters/enemies_v2/<enemy>_sheet.png`, `data/enemies/<enemy>_frames.tres`,
`assets/art/characters/enemies_v2/projectiles/<enemy>_projectile.png` (the shot cleaned the same way,
cropped to its bounds and shrunk to `PROJECTILE_SIZE` on its longer side) and `review/`.
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
CELL = 256
GUTTER = 8
OUT_DIR = REPO / "assets/art/characters/enemies_v2"
## A shot's longer side in its packed picture, in px.
PROJECTILE_SIZE = 128
FRAMES_DIR = REPO / "data/enemies"

## enemy: fps of the move loop, fps of the attack, and the `blob` size of trapped white patches to
## remove (0 = keep every white patch: real white art).
ENEMIES = {
    "bone_witch": {"move_fps": 12.0, "attack_fps": 16.0, "blob": 0},
    "claw_ghost": {"move_fps": 12.0, "attack_fps": 16.0, "blob": 30},
    "hooded_scribe": {"move_fps": 12.0, "attack_fps": 14.0, "blob": 0},
    "root_mask": {"move_fps": 12.0, "attack_fps": 16.0, "blob": 0},
    "stone_golem": {"move_fps": 12.0, "attack_fps": 16.0, "blob": 20},
}

EIGHT = np.ones((3, 3), dtype=bool)


def clean(image: Image.Image, blob: int):
    """Returns the image without its white leftovers, and how many pixels went."""
    px = np.array(image.convert("RGBA")).astype(np.int16)
    rgb = px[..., :3]
    alpha = px[..., 3]
    low = rgb.min(axis=2)
    spread = rgb.max(axis=2) - low
    removed = np.zeros(alpha.shape, dtype=bool)
    if blob > 0:
        white = (alpha > 0) & (low >= 225) & (spread <= 20)
        labels, count = ndimage.label(white, structure=EIGHT)
        if count:
            sizes = ndimage.sum(white, labels, range(1, count + 1))
            keep_ids = [index + 1 for index, size in enumerate(sizes) if size >= blob]
            removed |= np.isin(labels, keep_ids)
            grown = ndimage.binary_dilation(removed, structure=EIGHT)
            removed |= grown & (alpha > 0) & (low >= 195) & (spread <= 30)
    for _ in range(2):
        clear = (alpha == 0) | removed
        near = ndimage.binary_dilation(clear, structure=EIGHT)
        removed |= near & ~clear & (alpha < 200) & (low >= 200) & (spread <= 40)
    px[removed] = 0
    return Image.fromarray(px.astype(np.uint8), "RGBA"), int(removed.sum())


def cells(sheet: Image.Image):
    columns = sheet.width // CELL
    rows = sheet.height // CELL
    out = []
    for index in range(columns * rows):
        row, column = divmod(index, columns)
        frame = sheet.crop((column * CELL, row * CELL, (column + 1) * CELL, (row + 1) * CELL))
        if frame.getchannel("A").getbbox() is not None:
            out.append((index, frame))
    return out


def bounds(frames):
    boxes = [frame.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox() for frame in frames]
    boxes = [box for box in boxes if box]
    return (min(b[0] for b in boxes), min(b[1] for b in boxes),
            max(b[2] for b in boxes), max(b[3] for b in boxes))


def crop_centred(frame: Image.Image, centre, size):
    left = int(round(centre[0] - size[0] / 2.0))
    top = int(round(centre[1] - size[1] / 2.0))
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    out.paste(frame, (-left, -top))
    return out


def review_clean(name, pairs):
    columns = 5
    tile = CELL
    rows = (len(pairs) + columns - 1) // columns
    page = Image.new("RGB", (columns * (tile * 2 + 12), rows * (tile + 18)), (16, 16, 20))
    draw = ImageDraw.Draw(page)
    for slot, (label, before, after) in enumerate(pairs):
        row, column = divmod(slot, columns)
        x = column * (tile * 2 + 12)
        y = row * (tile + 18)
        for offset, image in ((0, before), (tile, after)):
            back = Image.new("RGBA", image.size, (40, 90, 60, 255))
            back.alpha_composite(image)
            page.paste(back.convert("RGB"), (x + offset, y + 18))
        draw.text((x + 2, y + 3), label, fill=(255, 255, 0))
    out = HERE / "review"
    out.mkdir(exist_ok=True)
    page.save(out / ("%s_clean.png" % name), optimize=True)


def write_atlas(name, frames, frame_size):
    columns = max(1, int(np.ceil(np.sqrt(len(frames)))))
    rows = (len(frames) + columns - 1) // columns
    pitch_x = frame_size[0] + GUTTER * 2
    pitch_y = frame_size[1] + GUTTER * 2
    atlas = Image.new("RGBA", (columns * pitch_x, rows * pitch_y), (0, 0, 0, 0))
    spots = []
    for slot, frame in enumerate(frames):
        row, column = divmod(slot, columns)
        x, y = column * pitch_x + GUTTER, row * pitch_y + GUTTER
        atlas.paste(frame, (x, y))
        spots.append((x, y))
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    path = OUT_DIR / ("%s_sheet.png" % name)
    pixels = np.array(atlas)
    pixels[pixels[..., 3] == 0, :3] = 0
    Image.fromarray(pixels, "RGBA").save(path, optimize=True)
    print("  atlas %dx%d -> %s" % (atlas.width, atlas.height, path.relative_to(REPO)))
    return path, spots


def write_frames(name, atlas_path, animations, frame_size, body_size):
    resource = "res://" + atlas_path.relative_to(REPO).as_posix()
    subs = []
    blocks = []
    for anim_name, (spots, fps, loops) in animations.items():
        ids = []
        for order, (x, y) in enumerate(spots):
            ident = "AtlasTexture_%s_%02d" % (anim_name, order)
            subs.append('[sub_resource type="AtlasTexture" id="%s"]\natlas = ExtResource("1_sheet")\n'
                        "region = Rect2(%d, %d, %d, %d)\n" % (ident, x, y, frame_size[0], frame_size[1]))
            ids.append(ident)
        listed = ", ".join('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % ident for ident in ids)
        blocks.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.4g\n}' % (
            listed, "true" if loops else "false", anim_name, fps))
    text = ('[gd_resource type="SpriteFrames" load_steps=%d format=3]\n\n' % (len(subs) + 2)
            + '[ext_resource type="Texture2D" path="%s" id="1_sheet"]\n\n' % resource
            + "\n".join(subs) + "\n"
            + "[resource]\nanimations = [%s]\n" % ", ".join(blocks)
            + "metadata/frame_size = Vector2(%d, %d)\n" % frame_size
            + "metadata/body_size = Vector2(%d, %d)\n" % body_size)
    path = FRAMES_DIR / ("%s_frames.tres" % name)
    path.write_bytes(text.encode("utf-8"))
    print("  frames -> %s" % path.relative_to(REPO))


def write_projectile(name):
    source = HERE / "raw" / name / "projectile.png"
    if not source.exists():
        return
    image, _ = clean(Image.open(source), 0)
    box = image.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox()
    cropped = image.crop((box[0] - 2, box[1] - 2, box[2] + 2, box[3] + 2))
    # Drawn at about 64 px, so kept at twice that: less to load, and no shimmer from a big shrink.
    cropped.thumbnail((PROJECTILE_SIZE, PROJECTILE_SIZE), Image.LANCZOS)
    out = OUT_DIR / "projectiles"
    out.mkdir(parents=True, exist_ok=True)
    path = out / ("%s_projectile.png" % name)
    cropped.save(path, optimize=True)
    print("  projectile %dx%d -> %s" % (cropped.width, cropped.height, path.relative_to(REPO)))


def pack(name, settings):
    print("%s:" % name)
    sources = {}
    pairs = []
    for anim_name in ("move", "attack"):
        sheet = Image.open(HERE / "raw" / name / ("%s.png" % anim_name)).convert("RGBA")
        cleaned = []
        total = 0
        for index, frame in cells(sheet):
            after, count = clean(frame, settings["blob"])
            total += count
            cleaned.append(after)
            pairs.append(("%s %d (-%d)" % (anim_name, index, count), frame, after))
        sources[anim_name] = cleaned
        print("  %-6s %2d frames, %d leftover pixels removed" % (anim_name, len(cleaned), total))
    review_clean(name, pairs)
    body = bounds(sources["move"])
    centre = ((body[0] + body[2]) / 2.0, (body[1] + body[3]) / 2.0)
    every = bounds(sources["move"] + sources["attack"])
    half_x = max(centre[0] - every[0], every[2] - centre[0]) + 2
    half_y = max(centre[1] - every[1], every[3] - centre[1]) + 2
    frame_size = (int(np.ceil(half_x)) * 2, int(np.ceil(half_y)) * 2)
    body_size = (body[2] - body[0], body[3] - body[1])
    attack_box = bounds(sources["attack"])
    print("  body %s centre %s, attack bounds %s, frame %s" % (body_size, centre, attack_box, frame_size))
    frames = []
    counts = {}
    for anim_name in ("move", "attack"):
        placed = [crop_centred(frame, centre, frame_size) for frame in sources[anim_name]]
        counts[anim_name] = len(placed)
        frames.extend(placed)
    atlas_path, spots = write_atlas(name, frames, frame_size)
    animations = {
        "move": (spots[:counts["move"]], settings["move_fps"], True),
        "attack": (spots[counts["move"]:], settings["attack_fps"], False),
    }
    write_frames(name, atlas_path, animations, frame_size, body_size)
    write_projectile(name)


def main():
    for name, settings in ENEMIES.items():
        pack(name, settings)


if __name__ == "__main__":
    main()
