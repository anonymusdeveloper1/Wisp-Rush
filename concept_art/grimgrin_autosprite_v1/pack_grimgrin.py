"""Pack Grimgrin's AutoSprite sheets into the game's boss atlas, animations and layout.

    python concept_art/grimgrin_autosprite_v1/pack_grimgrin.py

Every sheet in `raw/` is the owner's AutoSprite PNG export, unchanged (2026-09-27; the owner's
`Desktop/GrimGrin/` folder, renamed): 256 px cells, five to a row, transparent. They were checked for
AutoSprite's background leftovers (white or grey pixels, as on Rook) and have none, so nothing is
cleaned.

What this does, per animation:
- **Picks the cells** the game plays (below, with why).
- **Puts every sheet on one scale.** AutoSprite drew him at different sizes in different sheets:
  against the dash, the right-wall idle, the wall planting and the death (one size, measured by his
  eye spacing, about 11 px, and his blades, about 70 px), the floor idle is drawn about 1.2-1.35x larger
  (blades 95 px, eyes bigger) and the floor planting slightly larger (eyes 11.5-12 px). Scales picked by
  eye on a side-by-side board (2026-09-27): floor idle 0.82, floor planting 0.93, the rest 1.0.
- **Aligns every frame to one line**, so he never slides: a floor animation's feet (the lowest pixel over
  all its frames) on `FOOT_Y`, and its head axis (the middle of his eyes, measured) on the frame's
  middle, so flipping him to face the Wisp keeps his head in place; a wall animation's grip (the
  rightmost pixel, the hilt in the wall) on `GRIP_X`, centred vertically; the dash centred.

Writes `assets/art/characters/grimgrin/grimgrin_sheet.png` (one atlas, 8 px transparent gutters),
`data/bosses/grimgrin_frames.tres` (a `SpriteFrames`), `data/bosses/grimgrin_layout.tres` (a
`BossSpriteLayout`) and `review/` (every packed frame over a dark background with its line).
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
CELL = 256
COLUMNS = 5
GUTTER = 8
ATLAS_COLUMNS = 12
FOOT_Y = 244
GRIP_X = 250
ATLAS = REPO / "assets/art/characters/grimgrin/grimgrin_sheet.png"
FRAMES = REPO / "data/bosses/grimgrin_frames.tres"
LAYOUT = REPO / "data/bosses/grimgrin_layout.tres"

## name: (sheet, cells, fps, loops, kind, scale, head axis x in the source cell or None)
## - floor_idle: all 25 cells, the loop (drawn three-quarter, facing right).
## - wall_idle: all 23 cells of the trimmed export, the loop (hanging from one katana).
## - plant_floor: 5-24: kneeling, raising both katanas, the stab (cell 11), the planted hold. Cells
##   0-4 repeat the planted pose, so the animation would open with the katanas already in the floor.
## - plant_wall: 9-24: the wind-up (9-11), the swing (12), the stab and the perched hold (13-24).
##   Cells 0-8 are the hanging pose, which the wall idle already plays.
## - dash: 0-17: the flight (0-11), the slash (12-14) and the end pose (15-17); 18-24 repeat it.
## - death: 8-24: the jolt (9), the fall (10-11) and the collapse with the glow gone; 0-7 stand still.
ANIMATIONS = {
    "floor_idle": ("floor_idle_sheet.png", list(range(25)), 12.0, True, "floor", 0.82, 137.5),
    "wall_idle": ("right_wall_idle_sheet.png", list(range(23)), 12.0, True, "wall", 1.0, None),
    "plant_floor": ("plant_floor_sheet.png", list(range(5, 25)), 14.0, False, "floor", 0.93, 126.75),
    "plant_wall": ("plant_wall_sheet.png", list(range(9, 25)), 12.0, False, "wall", 1.0, None),
    "dash": ("dash_sheet.png", list(range(18)), 24.0, False, "centre", 1.0, None),
    "death": ("death_sheet.png", list(range(8, 25)), 12.0, False, "floor", 1.0, 126.5),
}


def cell(sheet: Image.Image, index: int) -> Image.Image:
    row, column = divmod(index, COLUMNS)
    return sheet.crop((column * CELL, row * CELL, (column + 1) * CELL, (row + 1) * CELL))


def union_box(images):
    boxes = [image.getchannel("A").point(lambda a: 255 if a > 16 else 0).getbbox() for image in images]
    boxes = [b for b in boxes if b]
    return (min(b[0] for b in boxes), min(b[1] for b in boxes), max(b[2] for b in boxes), max(b[3] for b in boxes))


def place(image: Image.Image, scale: float, source_point, target_point) -> Image.Image:
    """Scales `image` by `scale` about `source_point` and puts that point on `target_point`."""
    matrix = (1.0 / scale, 0.0, source_point[0] - target_point[0] / scale,
              0.0, 1.0 / scale, source_point[1] - target_point[1] / scale)
    placed = image.convert("RGBa").transform((CELL, CELL), Image.AFFINE, matrix, resample=Image.BICUBIC)
    placed = placed.convert("RGBA")
    pixels = np.array(placed)
    pixels[pixels[:, :, 3] == 0, :3] = 0
    return Image.fromarray(pixels, "RGBA")


def pack():
    packed = {}
    measures = {}
    for name, (sheet_name, cells, fps, loops, kind, scale, axis_x) in ANIMATIONS.items():
        sheet = Image.open(HERE / "raw" / sheet_name).convert("RGBA")
        sources = [cell(sheet, index) for index in cells]
        box = union_box(sources)
        if kind == "floor":
            source_point = (axis_x, box[3])
            target_point = (CELL / 2.0, FOOT_Y)
        elif kind == "wall":
            source_point = (box[2], (box[1] + box[3]) / 2.0)
            target_point = (GRIP_X, CELL / 2.0)
        else:
            source_point = ((box[0] + box[2]) / 2.0, (box[1] + box[3]) / 2.0)
            target_point = (CELL / 2.0, CELL / 2.0)
        frames = [place(image, scale, source_point, target_point) for image in sources]
        packed_box = union_box(frames)
        for index, frame in zip(cells, frames):
            alpha = np.array(frame)[:, :, 3]
            if (alpha[0] > 16).any() or (alpha[-1] > 16).any() or (alpha[:, 0] > 16).any() or (alpha[:, -1] > 16).any():
                print("  note: %s cell %d reaches the frame edge (as drawn)" % (name, index))
        packed[name] = frames
        measures[name] = packed_box
        print("PACKED: %-11s %2d frames at %.0f fps, %s, scale %.2f, bounds %s" % (
            name, len(frames), fps, "loop" if loops else "once", scale, packed_box))
    return packed, measures


def write_atlas(packed):
    count = sum(len(frames) for frames in packed.values())
    rows = (count + ATLAS_COLUMNS - 1) // ATLAS_COLUMNS
    pitch = CELL + GUTTER * 2
    atlas = Image.new("RGBA", (ATLAS_COLUMNS * pitch, rows * pitch), (0, 0, 0, 0))
    regions = {}
    slot = 0
    for name, frames in packed.items():
        regions[name] = []
        for frame in frames:
            row, column = divmod(slot, ATLAS_COLUMNS)
            x, y = column * pitch + GUTTER, row * pitch + GUTTER
            atlas.paste(frame, (x, y))
            regions[name].append((x, y))
            slot += 1
    ATLAS.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(ATLAS, optimize=True)
    print("ATLAS: %dx%d, %d frames -> %s" % (atlas.width, atlas.height, count, ATLAS.relative_to(REPO)))
    return regions


def write_frames(regions):
    resource = "res://" + ATLAS.relative_to(REPO).as_posix()
    subs = []
    blocks = []
    for name, spots in regions.items():
        fps, loops = ANIMATIONS[name][2], ANIMATIONS[name][3]
        ids = []
        for order, (x, y) in enumerate(spots):
            ident = "AtlasTexture_%s_%02d" % (name, order)
            subs.append('[sub_resource type="AtlasTexture" id="%s"]\natlas = ExtResource("1_sheet")\n'
                        "region = Rect2(%d, %d, %d, %d)\n" % (ident, x, y, CELL, CELL))
            ids.append(ident)
        listed = ", ".join('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % ident for ident in ids)
        blocks.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.4g\n}' % (
            listed, "true" if loops else "false", name, fps))
    text = ('[gd_resource type="SpriteFrames" load_steps=%d format=3]\n\n' % (len(subs) + 2)
            + '[ext_resource type="Texture2D" path="%s" id="1_sheet"]\n\n' % resource
            + "\n".join(subs) + "\n"
            + "[resource]\nanimations = [%s]\n" % ", ".join(blocks))
    FRAMES.write_bytes(text.encode("utf-8"))
    print("FRAMES: %d animations -> %s" % (len(regions), FRAMES.relative_to(REPO)))


def write_layout(measures):
    idle = measures["floor_idle"]
    standing = idle[3] - idle[1]
    wall = measures["wall_idle"]
    wall_depth = (wall[2] - wall[0]) / 2.0
    text = ('[gd_resource type="Resource" script_class="BossSpriteLayout" load_steps=2 format=3]\n\n'
            '[ext_resource type="Script" path="res://scripts/resources/boss_sprite_layout.gd" id="1_script"]\n\n'
            "[resource]\nscript = ExtResource(\"1_script\")\n"
            "cell_size = %.1f\nstanding_height = %.1f\nfloor_contact_depth = %.1f\nfloor_body_depth = %.1f\n"
            "wall_contact_depth = %.1f\nwall_body_depth = %.1f\n") % (
        CELL, standing, FOOT_Y - CELL / 2.0, standing / 2.0, GRIP_X - CELL / 2.0, wall_depth)
    LAYOUT.write_bytes(text.encode("utf-8"))
    print("LAYOUT: standing %d px, wall depth %.1f px -> %s" % (standing, wall_depth, LAYOUT.relative_to(REPO)))


def write_review(packed):
    out = HERE / "review"
    out.mkdir(exist_ok=True)
    for name, frames in packed.items():
        kind = ANIMATIONS[name][4]
        columns = 6
        rows = (len(frames) + columns - 1) // columns
        page = Image.new("RGB", (columns * (CELL + 4), rows * (CELL + 4)), (20, 18, 28))
        for index, frame in enumerate(frames):
            tile = Image.new("RGBA", (CELL, CELL), (42, 38, 54, 255))
            tile.alpha_composite(frame)
            draw = ImageDraw.Draw(tile)
            if kind == "floor":
                draw.line([(0, FOOT_Y), (CELL, FOOT_Y)], fill=(255, 200, 0, 255))
                draw.line([(CELL // 2, 0), (CELL // 2, 8)], fill=(255, 200, 0, 255))
            elif kind == "wall":
                draw.line([(GRIP_X, 0), (GRIP_X, CELL)], fill=(255, 200, 0, 255))
            draw.text((4, 4), "%s %d" % (name, index), fill=(255, 255, 0, 255))
            row, column = divmod(index, columns)
            page.paste(tile.convert("RGB"), (column * (CELL + 4), row * (CELL + 4)))
        page.save(out / ("%s.png" % name), optimize=True)


def main():
    packed, measures = pack()
    regions = write_atlas(packed)
    write_frames(regions)
    write_layout(measures)
    write_review(packed)


if __name__ == "__main__":
    main()
