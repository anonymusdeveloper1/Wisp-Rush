#!/usr/bin/env python3
"""Turn a generated storefront-idle video into the looping, transparent menu video the game plays.

Image-to-video models export opaque MP4 only, so a character is generated on one flat key colour
(`concept_art/<pack>/VIDEO_PROMPT.md`) and this pass cuts it back out. The key is chosen per
character as the colour it never uses - magenta for Shade, who is green; green for Ilyra, whose
skin and fans are violet - and every formula below goes through `keyness` and `despill`:

1. **Loop.** Plays frames ``0 .. loop_frames - 1``. A take rarely ends on its own first frame, so
   ``loop_frames`` is the frame that comes closest and the first ``crossfade`` frames are blended
   from the take's own continuation past that point back into its opening. Every step around the
   seam is then a normal frame step.
2. **Key.** The matte comes from how much a pixel looks like the key (``min(R, B) - G`` for
   magenta, ``G - max(R, B)`` for green). The colour under a partly transparent pixel is unmixed
   from the measured background, then any leftover key colour is removed (despill), so a soft edge
   keeps its own colour instead of a key-coloured fringe.
3. **Masks.** Rectangles forced fully transparent: the generator's corner label, which sits on
   background the character never reaches. The untouched take stays in the pack's ``source/``.
4. **Pack.** Godot's only core codec, Ogg Theora, has no alpha, so each frame is written as
   premultiplied colour on the left and the matte as grey on the right, for
   ``assets/shaders/packed_alpha_video.gdshader`` to recombine.
5. **Place.** Writes ``data/characters/<id>_menu_video.tres`` (``MenuVideoData``): the stream and the
   square it is drawn in, sized so the character stands exactly as tall as the sprite loop it
   replaces.

Requirements: Python 3.7+, Pillow, numpy, scipy, ffmpeg on PATH (it only *decodes* the take) and
``GODOT_PATH`` pointing at the Godot 4.7 editor binary, whose Movie Maker writes the Theora stream in a
throwaway project (a window opens for a few seconds; it needs a real renderer).

    python tools/art/extract_menu_video.py                  # every video pack
    python tools/art/extract_menu_video.py verdant_shade    # only this one

QA sheets land in ``logs/menu_video/``. Never hand-edit the outputs; re-run this.
"""
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import numpy as np
from PIL import Image
from scipy import ndimage


REPO = Path(__file__).resolve().parents[2]
OUTPUT = REPO / "assets/art/characters/playable"
LOGS = REPO / "logs/menu_video"

Box = Tuple[int, int, int, int]

## Default rig height a match frame's whole canvas is drawn at: a `WholeFrameCharacterVisual` menu
## cell (448 px at `MENU_SCALE`, 384 rig px). A pack whose visual draws differently sets
## `match_canvas_rig_px` (Ilyra's `IlyraVisual` draws her 627 px canvas at 627 rig px).
MENU_RIG_HEIGHT = 384.0
## Keyness (`min(R, B) - G`) at or below which a pixel is fully opaque, and the margin under the
## measured background keyness at which it becomes fully transparent. Compression noise on the
## background sits a few levels either side of its mean; the margin keeps it at alpha 0.
OPAQUE_KEYNESS = 12.0
TRANSPARENT_MARGIN = 40.0
## Alpha below which a pixel is dropped outright. Stray compression specks in the background never
## reach it; the faintest real glow does.
ALPHA_CUTOFF = 0.02
## Colour decontamination: alpha above which a pixel counts as solid, and how far (px, Gaussian
## sigma) solid colour is spread outward into the soft edge around it.
SOLID_ALPHA = 0.95
DECONTAMINATE_SIGMA = 3.0
## A source pixel whose red and blue both exceed its green by more than this is carrying magenta
## from the background, and pixels this far inside the solid edge are trusted as clean interior.
CONTAMINATION_TINT = 4.0
INTERIOR_ERODE = 2
## Matte choke: the share of alpha taken off the bottom of the ramp. The take's 4:2:0 chroma smears
## every edge over ~2 px, leaving a ring that is mostly background but keys at ~40 %; at the size a
## Shop card draws the video, 0.2 removes that ring and keeps the flames' soft glow (0.35 thins it).
MATTE_CHOKE = 0.2
## Calibration of the decoded matte (see `calibrate`): background further than this many px from the
## character counts as pure background, and the floor and ceiling are clamped to these limits so a
## bad take cannot eat the soft edges or leave the body see-through.
CALIBRATION_REACH = 3
MAX_ALPHA_FLOOR = 0.1
MIN_ALPHA_CEILING = 0.85

VIDEO_PACKS: Dict[str, Dict[str, object]] = {
	"verdant_shade": {
		"source": REPO
		/ "concept_art/verdant_shade_storefront_video_v1/source/shade_storefront_take1.mp4",
		# Frame 80 is the one that comes back closest to frame 0 (mean difference 2.7 against a
		# normal step of ~2), so the loop is frames 0..79 and 80..87 fade back into 0..7.
		"loop_frames": 80,
		"crossfade": 8,
		# The generator's "AI" content label, top left (the box around it spans ~17..50 x 17..45 at
		# 640 px). Shade's closest approach to that corner is x 164, y 76, so this cannot touch her.
		"masks": [(0, 0, 72, 64)],
		"fps": 24,
		# Unused since Movie Maker took over the encode (see `encode`); kept for a future encoder.
		"quality": 9,
		# The sprite loop this replaces: Shade is drawn as tall as she stands in this frame.
		"match_frame": REPO
		/ "concept_art/verdant_shade_sprite_v1/frames/verdant_shade/storefront/storefront_idle_00.png",
		"video": OUTPUT / "verdant_shade/verdant_shade_menu.ogv",
		"resource": REPO / "data/characters/verdant_shade_menu_video.tres",
		"key": "magenta",
	},
	"ilyra": {
		# Take 2, the ready stance the owner approved on 2026-09-21 (take 1 snapped its fans).
		"source": REPO / "concept_art/ilyra_storefront_video_v1/source/ilyra_ready_take2.mp4",
		# Frame 72 comes back closest to frame 0 (4.6 against a 3.4 median step; the raw end
		# jumps 15.8), so the loop is frames 0..71 and 72..79 fade back into 0..7.
		"loop_frames": 72,
		"crossfade": 8,
		# The same "AI" label, top left (x 24..41, y 23..36). Ilyra never comes nearer than x 80,
		# y 106, so the box cannot touch her.
		"masks": [(0, 0, 72, 64)],
		"fps": 24,
		"quality": 9,
		# The painting the take was generated from, drawn at its gameplay scale: her 627 px canvas
		# is 627 rig px in `IlyraVisual`, and so are her 724 px menu paintings at `MENU_SCALE`.
		"match_frame": REPO / "assets/art/characters/playable/ilyra/aim_charge.png",
		"match_canvas_rig_px": 627.0,
		"video": OUTPUT / "ilyra/ilyra_menu.ogv",
		"resource": REPO / "data/characters/ilyra_menu_video.tres",
		# Green: 0.0 % of her solid pixels are greenish, against 6.5 % magenta-ish in this pose.
		"key": "green",
	},
}


def keyness(pixels: np.ndarray, key_colour: str) -> np.ndarray:
	"""How much each pixel looks like the key colour: high on the background, <= 0 on the character."""
	r, g, b = pixels[..., 0], pixels[..., 1], pixels[..., 2]
	if key_colour == "magenta":
		return np.minimum(r, b) - g
	if key_colour == "green":
		return g - np.maximum(r, b)
	raise SystemExit("unknown key colour %r (magenta or green)" % key_colour)


def despill(colour: np.ndarray, key_colour: str) -> None:
	"""Removes leftover key colour in place: the character never legitimately contains it."""
	spill = np.clip(keyness(colour, key_colour), 0.0, None)
	if key_colour == "magenta":
		colour[..., 0] -= spill
		colour[..., 2] -= spill
	else:
		colour[..., 1] -= spill


def decode(path: Path) -> Tuple[np.ndarray, int, int]:
	"""Every frame of ``path`` as one ``(frames, h, w, 3)`` uint8 array, audio ignored."""
	probe = subprocess.run(
		["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
		 "stream=width,height", "-of", "csv=p=0", str(path)],
		check=True, capture_output=True, text=True).stdout.strip().split(",")
	width, height = int(probe[0]), int(probe[1])
	raw = subprocess.run(
		["ffmpeg", "-v", "error", "-i", str(path), "-an", "-f", "rawvideo", "-pix_fmt", "rgb24",
		 "-"], check=True, capture_output=True).stdout
	frames = np.frombuffer(raw, np.uint8).reshape(-1, height, width, 3)
	return frames, width, height


def build_loop(frames: np.ndarray, length: int, fade: int) -> np.ndarray:
	"""Frames ``0 .. length-1`` with the opening blended in from the take's own continuation."""
	if frames.shape[0] < length + fade:
		raise SystemExit("the take has %d frames; a %d-frame loop with a %d-frame fade needs %d" % (
			frames.shape[0], length, fade, length + fade))
	loop = frames[:length].astype(np.float32)
	for index in range(fade):
		t = index / fade
		w = t * t * (3.0 - 2.0 * t)  # smoothstep: leaves the continuation gently, arrives gently
		loop[index] = frames[length + index] * (1.0 - w) + frames[index] * w
	return loop


def background_colour(frames: np.ndarray, key_colour: str) -> np.ndarray:
	"""Mean colour of the pixels that are strongly the key colour in every frame."""
	always = (keyness(frames.astype(np.int16), key_colour) > 120).all(axis=0)
	# Accumulated in float64: tens of millions of samples summed in float32 saturate and read ~140.
	return frames[:, always].reshape(-1, 3).mean(axis=0, dtype=np.float64).astype(np.float32)


def key(loop: np.ndarray, bg: np.ndarray, masks: List[Box],
		key_colour: str = "magenta") -> Tuple[np.ndarray, np.ndarray]:
	"""Premultiplied colour and alpha for every frame, key colour and masks removed."""
	bg_keyness = float(keyness(bg, key_colour))
	transparent = bg_keyness - TRANSPARENT_MARGIN
	alpha = np.clip((transparent - keyness(loop, key_colour)) / (transparent - OPAQUE_KEYNESS),
					0.0, 1.0)
	alpha[alpha < ALPHA_CUTOFF] = 0.0
	for x0, y0, x1, y1 in masks:
		alpha[:, y0:y1, x0:x1] = 0.0
	a = alpha[..., None]
	# Unmix: C = a*F + (1-a)*B  ->  F = (C - (1-a)*B) / a, for every pixel that is not background.
	colour = np.where(a > 0.0, (loop - (1.0 - a) * bg) / np.maximum(a, 1e-3), 0.0)
	colour = np.clip(colour, 0.0, 255.0)
	# Despill: nothing on the character is legitimately the key colour, so any of it left is the
	# background showing through. Removing it leaves a neutral edge, not a key-coloured one.
	despill(colour, key_colour)
	decontaminate(colour, alpha, loop, key_colour)
	alpha = np.clip((alpha - MATTE_CHOKE) / (1.0 - MATTE_CHOKE), 0.0, 1.0)
	return colour * alpha[..., None], alpha


def decontaminate(colour: np.ndarray, alpha: np.ndarray, source: np.ndarray,
				  key_colour: str = "magenta") -> None:
	"""Gives the character's edge the colour of the clean interior beside it, in place.

	Two kinds of edge pixel come back the wrong colour. Soft ones: unmixing assumes the character
	under a half-transparent pixel is only as dark as its keyness says, which a bright glow is not,
	so a flame's outer edge turns grey. And tinted ones: the take's 4:2:0 chroma smears magenta about
	two pixels into the character, giving mauve pixels like (146, 105, 119) that are not magenta
	enough to key out, so they pass as *solid* and fed the first fix a brown rim to copy.

	So the fill colour is spread outward from clean interior pixels only (solid, untinted, and two
	pixels inside the edge), and every soft or tinted pixel outside that interior takes it. A solid,
	untinted edge - the bright rim painted on a leaf - is left alone.
	"""
	for index in range(alpha.shape[0]):
		a, src = alpha[index], source[index]
		clean = keyness(src, key_colour) <= CONTAMINATION_TINT
		interior = ndimage.binary_erosion(a > SOLID_ALPHA, iterations=INTERIOR_ERODE) & clean
		solid = interior.astype(np.float32)
		weight = ndimage.gaussian_filter(solid, DECONTAMINATE_SIGMA)
		fill = np.stack([
			ndimage.gaussian_filter(colour[index, ..., c] * solid, DECONTAMINATE_SIGMA)
			for c in range(3)
		], axis=-1) / np.maximum(weight, 1e-4)[..., None]
		recolour = (a > 0.0) & ~interior & ((a <= SOLID_ALPHA) | ~clean) & (weight > 1e-3)
		colour[index][recolour] = fill[recolour]


def pack(premultiplied: np.ndarray, alpha: np.ndarray) -> np.ndarray:
	"""Colour | matte, side by side, as uint8 frames twice as wide as they are tall."""
	matte = np.repeat((alpha * 255.0)[..., None], 3, axis=-1)
	return np.clip(np.concatenate([premultiplied, matte], axis=2) + 0.5, 0, 255).astype(np.uint8)


## Movie Maker settings for the throwaway encoder project. Quality 0.9 is the top of the range
## Godot's docs recommend; encoding speed 1 is the slowest, most efficient setting.
ENCODER_QUALITY = 0.9
ENCODER_SPEED = 1
ENCODER_KEYFRAME_INTERVAL = 64

ENCODER_SCRIPT = """extends TextureRect
## Shows packed frame N on render N, so Movie Maker writes exactly one video frame per image.
var _files: PackedStringArray = PackedStringArray()
var _index: int = 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	stretch_mode = TextureRect.STRETCH_SCALE
	var dir: String = ProjectSettings.globalize_path("res://frames")
	_files = DirAccess.get_files_at(dir)
	_files.sort()

func _process(_delta: float) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://frames").path_join(_files[_index]))
	texture = ImageTexture.create_from_image(image)
	size = Vector2(image.get_width(), image.get_height())
	_index += 1
	# Quit on the frame that shows the last image: the iteration still renders and records it, and
	# waiting one more would record the last image twice - a hold at the loop point.
	if _index >= _files.size():
		get_tree().quit()
"""


def godot_binary() -> str:
	"""The Godot editor binary, from GODOT_PATH. Movie Maker's OGV writer exists only in editor builds."""
	path = os.environ.get("GODOT_PATH", "")
	if not path:
		raise SystemExit("set GODOT_PATH to the Godot 4.7 editor binary (it writes the Theora stream)")
	# Git Bash hands a Windows process "/d/..."; subprocess needs "d:/...".
	if os.name == "nt" and len(path) > 2 and path[0] == "/" and path[2] == "/":
		path = path[1] + ":" + path[2:]
	return path


def encode(frames: np.ndarray, path: Path, fps: int, quality: int) -> None:
	"""Ogg Theora, video only, written by Godot's own Movie Maker.

	Not ffmpeg: Godot's docs warn that Windows 64-bit ffmpeg builds write Theora with artifacts, and
	this machine's did exactly that - ffmpeg's own decoder rejected 91 % of the packets it wrote
	(``error in unpack_block_qpis``) and Godot showed the frames as broken macroblocks. Movie Maker
	encodes with the libtheora Godot decodes with, so what it writes is what the game can play.
	``quality`` is kept for the pack table but unused; Movie Maker takes ``ENCODER_QUALITY``.
	"""
	del quality
	path.parent.mkdir(parents=True, exist_ok=True)
	height, width = frames.shape[1], frames.shape[2]
	with tempfile.TemporaryDirectory(prefix="menu_video_encoder_") as root:
		project = Path(root)
		(project / "frames").mkdir()
		for index, frame in enumerate(frames):
			Image.fromarray(frame).save(project / "frames" / ("%04d.png" % index))
		(project / "encode.gd").write_text(ENCODER_SCRIPT, encoding="utf-8", newline="\n")
		(project / "encode.tscn").write_text(
			'[gd_scene load_steps=2 format=3]\n\n'
			'[ext_resource type="Script" path="res://encode.gd" id="1_script"]\n\n'
			'[node name="Encode" type="TextureRect"]\n'
			'script = ExtResource("1_script")\n', encoding="utf-8", newline="\n")
		(project / "project.godot").write_text(
			"config_version=5\n\n"
			"[application]\n"
			'config/name="Menu video encoder"\n'
			'run/main_scene="res://encode.tscn"\n\n'
			"[display]\n"
			"window/size/viewport_width=%d\n" % width
			+ "window/size/viewport_height=%d\n" % height
			+ "window/size/resizable=false\n"
			'window/stretch/mode="disabled"\n\n'
			"[editor]\n"
			"movie_writer/fps=%d\n" % fps
			+ "movie_writer/video_quality=%s\n" % ENCODER_QUALITY
			+ "movie_writer/ogv/encoding_speed=%d\n" % ENCODER_SPEED
			+ "movie_writer/ogv/keyframe_interval=%d\n\n" % ENCODER_KEYFRAME_INTERVAL
			+ "[rendering]\n"
			'renderer/rendering_method="gl_compatibility"\n', encoding="utf-8", newline="\n")
		out = project / "out.ogv"
		result = subprocess.run(
			# --fixed-fps as well as the project setting: the setting alone left the stream stamped
			# at the default 60 fps, so an 80-frame loop played in 1.33 s instead of 3.33 s.
			[godot_binary(), "--path", str(project), "--write-movie", str(out),
			 "--fixed-fps", str(fps)],
			capture_output=True, text=True)
		if result.returncode != 0 or not out.exists():
			raise SystemExit("Godot's Movie Maker failed:\n%s\n%s" % (result.stdout, result.stderr))
		shutil.copyfile(out, path)


def calibrate(video: Path, alpha: np.ndarray) -> Tuple[float, float, int, float]:
	"""Decodes the written stream and measures where its matte really lands.

	Compression lifts a little noise onto the background and pulls some solid pixels below full
	opacity (on Shade's first take: nothing further than 3 px from her above 18/255, and 99.99 % of her
	body at 239 or more). The floor is set just above the background noise and the ceiling at the
	body's 0.01st percentile, so the shader shows neither a faint box nor a see-through speck.
	Returns the floor, the ceiling, the decoded frame count and the mean round-trip error.
	"""
	decoded = decode(video)[0]
	half = decoded.shape[2] // 2
	noise, body = [], []
	for index in range(min(len(decoded), len(alpha))):
		matte = decoded[index, :, half:, 0]
		near = ndimage.binary_dilation(alpha[index] > 0.0, iterations=CALIBRATION_REACH)
		noise.append(matte[~near])
		body.append(matte[alpha[index] >= 0.999])
	floor = min((float(np.concatenate(noise).max()) + 1.0) / 255.0, MAX_ALPHA_FLOOR)
	ceiling = max(float(np.percentile(np.concatenate(body), 0.01)) / 255.0, MIN_ALPHA_CEILING)
	return floor, ceiling, len(decoded), 0.0


def stream_rate(video: Path) -> float:
	"""Frame rate the written stream is stamped at, which is what the game plays it back at."""
	rate = subprocess.run(
		["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=r_frame_rate",
		 "-of", "csv=p=0", str(video)], check=True, capture_output=True, text=True).stdout.strip()
	numerator, _, denominator = rate.partition("/")
	return float(numerator) / float(denominator or 1)


def silhouette(alpha: np.ndarray) -> Box:
	ys, xs = np.nonzero(alpha > 0.5)
	return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def placement(alpha0: np.ndarray, match_frame: Path,
			  canvas_rig_px: float = MENU_RIG_HEIGHT) -> Tuple[float, Tuple[float, float]]:
	"""Square side and centre offset, in rig px, that stand the video as tall as the sprite loop."""
	sprite = np.asarray(Image.open(match_frame).convert("RGBA"))[..., 3] / 255.0
	canvas = sprite.shape[0]
	sx0, sy0, sx1, sy1 = silhouette(sprite)
	rig_per_sprite_px = canvas_rig_px / canvas
	target_height = (sy1 - sy0) * rig_per_sprite_px
	target_centre = (
		((sx0 + sx1) / 2.0 - canvas / 2.0) * rig_per_sprite_px,
		((sy0 + sy1) / 2.0 - canvas / 2.0) * rig_per_sprite_px,
	)
	size = alpha0.shape[0]
	vx0, vy0, vx1, vy1 = silhouette(alpha0)
	side = target_height / ((vy1 - vy0) / size)
	rig_per_video_px = side / size
	video_centre = (
		((vx0 + vx1) / 2.0 - size / 2.0) * rig_per_video_px,
		((vy0 + vy1) / 2.0 - size / 2.0) * rig_per_video_px,
	)
	return side, (target_centre[0] - video_centre[0], target_centre[1] - video_centre[1])


def write_resource(path: Path, video: Path, side: float, offset: Tuple[float, float],
				   seconds: float, alpha_floor: float, alpha_ceiling: float) -> None:
	stream = video.relative_to(REPO).as_posix()
	path.parent.mkdir(parents=True, exist_ok=True)
	path.write_text(
		'[gd_resource type="Resource" script_class="MenuVideoData" load_steps=3 format=3]\n'
		"\n"
		'[ext_resource type="Script" path="res://scripts/resources/menu_video_data.gd" id="1_script"]\n'
		'[ext_resource type="VideoStreamTheora" path="res://%s" id="2_stream"]\n' % stream
		+ "\n"
		"[resource]\n"
		'script = ExtResource("1_script")\n'
		'stream = ExtResource("2_stream")\n'
		+ "side = %.1f\n" % side
		+ "offset = Vector2(%.1f, %.1f)\n" % offset
		+ "alpha_floor = %.3f\n" % alpha_floor
		+ "alpha_ceiling = %.3f\n" % alpha_ceiling
		+ "loop_seconds = %.3f\n" % seconds,
		encoding="utf-8",
		newline="\n",
	)


def contact_sheet(name: str, premultiplied: np.ndarray, alpha: np.ndarray) -> Path:
	"""Six evenly spaced frames over the Shop card's purple and over white, plus the seam pair."""
	LOGS.mkdir(parents=True, exist_ok=True)
	picks = list(np.linspace(0, len(alpha) - 1, 6).astype(int)) + [len(alpha) - 1, 0]
	cell = 256
	sheet = Image.new("RGB", (cell * len(picks), cell * 2), (0, 0, 0))
	for row, backdrop in enumerate([(38, 24, 52), (255, 255, 255)]):
		back = np.array(backdrop, np.float32)
		for column, index in enumerate(picks):
			a = alpha[index][..., None]
			over = premultiplied[index] + (1.0 - a) * back
			tile = Image.fromarray(np.clip(over + 0.5, 0, 255).astype(np.uint8)).resize(
				(cell, cell), Image.LANCZOS)
			sheet.paste(tile, (column * cell, row * cell))
	path = LOGS / ("%s_contact.png" % name)
	sheet.save(path)
	return path


def ingest(name: str) -> None:
	spec = VIDEO_PACKS[name]
	frames, width, height = decode(Path(str(spec["source"])))
	length, fade = int(spec["loop_frames"]), int(spec["crossfade"])  # type: ignore[arg-type]
	loop = build_loop(frames, length, fade)
	key_colour = str(spec.get("key", "magenta"))
	bg = background_colour(frames, key_colour)
	premultiplied, alpha = key(loop, bg, list(spec["masks"]), key_colour)  # type: ignore[arg-type]
	video, resource = Path(str(spec["video"])), Path(str(spec["resource"]))
	fps = int(spec["fps"])  # type: ignore[arg-type]
	encode(pack(premultiplied, alpha), video, fps, int(spec["quality"]))  # type: ignore[arg-type]
	side, offset = placement(alpha[0], Path(str(spec["match_frame"])),
							 float(spec.get("match_canvas_rig_px", MENU_RIG_HEIGHT)))  # type: ignore[arg-type]
	floor, ceiling, written, _ = calibrate(video, alpha)
	if written != length:
		raise SystemExit("the encoder wrote %d frames for a %d-frame loop" % (written, length))
	stamped = stream_rate(video)
	if abs(stamped - fps) > 0.01:
		raise SystemExit("the encoder stamped the stream at %g fps; the loop is %d fps" % (stamped, fps))
	write_resource(resource, video, side, offset, length / fps, floor, ceiling)

	steps = [np.abs(loop[i] - loop[i + 1]).mean() for i in range(length - 1)]
	seam = float(np.abs(loop[-1] - loop[0]).mean())
	# Label pixels: everything inside a mask box that is not the flat background.
	masked = sum(int((keyness(frames[:length, y0:y1, x0:x1].astype(np.int16), key_colour)
					  < float(keyness(bg, key_colour)) - 40).sum())
				 for x0, y0, x1, y1 in spec["masks"])  # type: ignore[union-attr]
	x0, y0, x1, y1 = silhouette(alpha.max(axis=0))
	print("MENU VIDEO: %s %dx%d, %d-frame loop (%.2f s at %d fps) -> %s" % (
		name, width, height, length, length / fps, fps, video.relative_to(REPO)))
	print("  BACKGROUND: %s key, measured (%.0f, %.0f, %.0f)" % (key_colour, *bg))
	print("  LOOP: seam %.2f against a median step of %.2f (max %.2f)" % (
		seam, float(np.median(steps)), float(max(steps))))
	print("  MASKS: %d label pixels removed; character envelope x %d..%d, y %d..%d" % (
		masked, x0, x1, y0, y1))
	print("  PLACE: side %.1f rig px, offset (%.1f, %.1f) -> %s" % (
		side, offset[0], offset[1], resource.relative_to(REPO)))
	print("  MATTE: decoded %d frames at %g fps; floor %.3f, ceiling %.3f" % (
		written, stamped, floor, ceiling))
	print("  FILE: %.2f MB" % (video.stat().st_size / 1e6))
	print("  CONTACT: %s" % contact_sheet(name, premultiplied, alpha))


def main(names: Optional[List[str]] = None) -> None:
	for name in names or list(VIDEO_PACKS):
		if name not in VIDEO_PACKS:
			raise SystemExit("Unknown video pack %r (known: %s)" % (name, ", ".join(VIDEO_PACKS)))
		ingest(name)


if __name__ == "__main__":
	main(sys.argv[1:])
