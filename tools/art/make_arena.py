"""Turn an arena's source image into the game's background and Shop thumbnail.

    python tools/art/make_arena.py quarry_titan
    python tools/art/make_arena.py --guide          # the layout guide image for artists

Reads `concept_art/arenas_v2/<id>/arena.json` and the image it names, and writes
`assets/art/environment/arenas/<id>.png` (the full-size background, lossless, opaque) and
`assets/art/environment/arenas/thumbnails/<id>.png` (THUMBNAIL_SCALE of it, for Shop cards that
are not focused). It prints the arena's floor rectangle in texture UV, which is what
`data/endless/default_endless_catalog.tres` holds as `floor_rect` and `floor_polygon` - or, for an
arena kept with its floor elsewhere (ADR-0020), what its skin holds as its own `floor_rect`.

The art contract - canvas, safe zone, bleed and where the floor sits - is
docs/guides/arena_art.md. Never hand-edit the outputs; re-run this.
"""
import json
import sys
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[2]
SOURCES = REPO / "concept_art/arenas_v2"
OUTPUT = REPO / "assets/art/environment/arenas"
## Thumbnail size as a share of the background: 941x1672 becomes 282x502, the old card size.
THUMBNAIL_SCALE = 0.3

# The arena contract (docs/guides/arena_art.md), in pixels of the contract canvas.
## Portrait 20:9: the tallest common phone shows all of it at 1080 design px wide.
CANVAS = (1080, 2400)
## What a 16:9 phone shows; everything that matters lives here. Above and below is bleed.
SAFE_ZONE = (0, 240, 1080, 2160)
## Keep anything important this far from the sides: phones taller than 20:9 trim them.
SIDE_MARGIN = 60
## The playable floor - the Quarry Titan's, scaled to 1080 wide and moved down by the bleed.
FLOOR = (174, 659, 904, 1747)
## The rim painted just outside the floor, in px; its inner edge is the wall.
RIM = 40
## How far a delivered floor edge may sit from FLOOR, in px, before the art is refitted.
FLOOR_TOLERANCE = 6
## Inside the floor, this band along every edge is where the character rests and enemies arrive.
EDGE_BAND = 150
## Where the run HUD sits on a 16:9 phone (header, and the RUSH bar at the bottom).
HUD_TOP = (240, 560)
HUD_BOTTOM = (2040, 2160)
GUIDE = SOURCES / "_layout" / "arena_layout_guide.png"
## White floor, grey rim, black everywhere else: an inpainting mask and a check overlay.
MASK = SOURCES / "_layout" / "arena_floor_mask.png"
## The same numbers as JSON, for an agent or a checker to read.
SPEC = SOURCES / "_layout" / "arena_spec.json"


def make_arena(arena_id: str) -> None:
	folder = SOURCES / arena_id
	manifest = json.loads((folder / "arena.json").read_text(encoding="utf-8"))
	image = Image.open(folder / manifest["source"]).convert("RGB")
	width, height = image.size
	left, top, right, bottom = manifest["floor_rect_px"]
	if not (0 <= left < right <= width and 0 <= top < bottom <= height):
		raise SystemExit("%s: floor_rect_px %s is outside the %dx%d image" % (
			arena_id, manifest["floor_rect_px"], width, height))
	(OUTPUT / "thumbnails").mkdir(parents=True, exist_ok=True)
	image.save(OUTPUT / ("%s.png" % arena_id), optimize=True)
	thumbnail = image.resize(
		(round(width * THUMBNAIL_SCALE), round(height * THUMBNAIL_SCALE)), Image.LANCZOS)
	thumbnail.save(OUTPUT / "thumbnails" / ("%s.png" % arena_id), optimize=True)
	u0, v0, u1, v1 = left / width, top / height, right / width, bottom / height
	print("ARENA: %s %dx%d -> %s (+ %dx%d thumbnail)" % (
		arena_id, width, height, (OUTPUT / ("%s.png" % arena_id)).relative_to(REPO),
		thumbnail.width, thumbnail.height))
	print("  floor_rect = Rect2(%.5f, %.5f, %.5f, %.5f)" % (u0, v0, u1 - u0, v1 - v0))
	print("  floor_polygon = PackedVector2Array(%.5f, %.5f, %.5f, %.5f, %.5f, %.5f, %.5f, %.5f)" % (
		u0, v0, u1, v0, u1, v1, u0, v1))


def make_guide() -> None:
	"""The contract drawn on its canvas, over the Quarry Titan as the worked example."""
	from PIL import ImageDraw, ImageFont

	guide = Image.new("RGB", CANVAS, (24, 26, 38))
	example = Image.open(SOURCES / "quarry_titan" / "source.webp").convert("RGB")
	example = example.resize((CANVAS[0], round(example.height * CANVAS[0] / example.width)), Image.LANCZOS)
	guide.paste(example, (0, SAFE_ZONE[1]))
	overlay = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
	draw = ImageDraw.Draw(overlay)
	width, height = CANVAS
	for top, bottom in ((0, SAFE_ZONE[1]), (SAFE_ZONE[3], height)):
		draw.rectangle((0, top, width, bottom), fill=(220, 60, 60, 110))
	for top, bottom in (HUD_TOP, HUD_BOTTOM):
		draw.rectangle((0, top, width, bottom), fill=(240, 200, 60, 70))
	draw.rectangle((0, 0, SIDE_MARGIN, height), fill=(220, 60, 60, 60))
	draw.rectangle((width - SIDE_MARGIN, 0, width, height), fill=(220, 60, 60, 60))
	draw.rectangle(FLOOR, fill=(60, 220, 120, 70), outline=(60, 255, 140, 255), width=6)
	draw.rectangle(SAFE_ZONE, outline=(255, 255, 255, 255), width=4)
	guide = Image.alpha_composite(guide.convert("RGBA"), overlay)
	text = ImageDraw.Draw(guide)
	font = ImageFont.load_default(size=34)
	notes = [
		((24, 90), "BLEED  y 0-240: sky only - cut on 16:9 phones"),
		((24, SAFE_ZONE[1] + 20), "SAFE ZONE  1080 x 1920, y 240-2160: always visible"),
		((24, HUD_TOP[0] + 90), "HUD band on 16:9 (header)"),
		((FLOOR[0] + 20, FLOOR[1] + 20), "FLOOR  x %d-%d  y %d-%d  (%d x %d)" % (
			FLOOR[0], FLOOR[2], FLOOR[1], FLOOR[3], FLOOR[2] - FLOOR[0], FLOOR[3] - FLOOR[1])),
		((FLOOR[0] + 20, FLOOR[1] + 60), "plain, calm floor - the playfield"),
		((24, HUD_BOTTOM[0] + 40), "RUSH bar on 16:9"),
		((24, SAFE_ZONE[3] + 90), "BLEED  y 2160-2400: ground only - cut on 16:9 phones"),
		((SIDE_MARGIN + 8, height // 2), "60 px"),
	]
	for position, line in notes:
		text.text(position, line, fill=(255, 255, 255, 255), font=font, stroke_width=3,
				  stroke_fill=(0, 0, 0, 255))
	GUIDE.parent.mkdir(parents=True, exist_ok=True)
	guide.convert("RGB").save(GUIDE, optimize=True)
	print("GUIDE: %s (%dx%d)" % (GUIDE.relative_to(REPO), width, height))
	rim = (FLOOR[0] - RIM, FLOOR[1] - RIM, FLOOR[2] + RIM, FLOOR[3] + RIM)
	mask = Image.new("L", CANVAS, 0)
	mask_draw = ImageDraw.Draw(mask)
	mask_draw.rectangle((rim[0], rim[1], rim[2] - 1, rim[3] - 1), fill=128)
	mask_draw.rectangle((FLOOR[0], FLOOR[1], FLOOR[2] - 1, FLOOR[3] - 1), fill=255)
	mask.save(MASK, optimize=True)
	SPEC.write_text(json.dumps({
		"about": "The Endless arena image contract - docs/guides/arena_art.md. Pixels of the canvas; "
				 "rectangles are [left, top, right, bottom], right/bottom exclusive.",
		"canvas": list(CANVAS),
		"safe_zone": list(SAFE_ZONE),
		"bleed_top": [0, 0, CANVAS[0], SAFE_ZONE[1]],
		"bleed_bottom": [0, SAFE_ZONE[3], CANVAS[0], CANVAS[1]],
		"side_margin": SIDE_MARGIN,
		"floor": list(FLOOR),
		"floor_size": [FLOOR[2] - FLOOR[0], FLOOR[3] - FLOOR[1]],
		"floor_tolerance_px": FLOOR_TOLERANCE,
		"rim_width": RIM,
		"rim_outer": list(rim),
		"floor_edge_band": EDGE_BAND,
		"hud_top_on_16x9": [0, HUD_TOP[0], CANVAS[0], HUD_TOP[1]],
		"hud_bottom_on_16x9": [0, HUD_BOTTOM[0], CANVAS[0], HUD_BOTTOM[1]],
		"mask": MASK.name,
		"guide": GUIDE.name,
	}, indent=2) + "\n", encoding="utf-8")
	print("MASK: %s  SPEC: %s" % (MASK.relative_to(REPO), SPEC.relative_to(REPO)))


if __name__ == "__main__":
	if len(sys.argv) < 2:
		raise SystemExit(__doc__)
	if sys.argv[1] == "--guide":
		make_guide()
	else:
		for name in sys.argv[1:]:
			make_arena(name)
