class_name BoardArenaVisual
extends ArenaVisual
## A board arena: a full-screen pixel-art board whose frame holds the run's HUD (owner 2026-10-02,
## GDD §14 #71–#72, ADR-0024).
##
## The board is built at run time from its pieces under [member art_dir] (Codex's pixel art from
## `concept_art/boards_v1/<board>/`, copied by `tools/art/make_board.py`): a tiled stone floor filling
## the screen inside a wooden frame of posts, beams, corners and caps, all on one pixel grid
## ([constant BOARD_WIDTH] art pixels across the screen, nearest filtering). The frame holds the HUD:
## the pause button (top-left), the boss plate or a crest (top centre), score over Rift Points
## (top-right), the soul gauge (left post), the RUSH gauge (right post), and four lanterns that glow,
## with a count tag, while upgrades are ready. GameWorld feeds the values through
## [method set_board_hud] and opens the upgrades when the glowing character is tapped. [method fit]
## returns the floor inside the frame. Pausable; Reduced Motion holds the lanterns and the flare still.

## Art pixels across the screen: one art pixel is 2 design pixels on a 1080-wide screen.
const BOARD_WIDTH: float = 540.0
## The frame, in art pixels (the board's CODEX_PROMPT.md): posts, top beam, bottom beam, wall line.
const POST_WIDTH: float = 36.0
const TOP_BEAM_HEIGHT: float = 64.0
const BOTTOM_BEAM_HEIGHT: float = 28.0
const RIM: float = 4.0
const FLOOR_TILE: float = 96.0
## Where the HUD pieces sit on the top beam, in art pixels from its top-left.
const PAUSE_POS := Vector2(44.0, 6.0)
const CENTRE_POS := Vector2(170.0, 10.0)
const SCORE_POS := Vector2(398.0, 4.0)
const RP_POS := Vector2(398.0, 34.0)
## Empty rectangles inside the pieces, from the board's manifest.json (art pixels).
const SCORE_TEXT := Rect2(8.0, 4.0, 104.0, 18.0)
const RP_ICON := Rect2(10.0, 3.0, 20.0, 20.0)
const RP_TEXT := Rect2(40.0, 4.0, 72.0, 18.0)
const BOSS_ICON := Rect2(17.0, 6.0, 32.0, 32.0)
const BOSS_FILL := Rect2(60.0, 16.0, 132.0, 12.0)
const LEVEL_TEXT := Rect2(6.0, 4.0, 24.0, 24.0)
const TAG_TEXT := Rect2(5.0, 4.0, 14.0, 10.0)
## A gauge: its top, repeated segment and bottom pieces, and where its fill runs inside them.
const GAUGE_TOP_HEIGHT: float = 44.0
const GAUGE_SEGMENT_HEIGHT: float = 32.0
const GAUGE_BOTTOM_HEIGHT: float = 20.0
const GAUGE_FILL_X: float = 12.0
const GAUGE_FILL_WIDTH: float = 12.0
const GAUGE_TOP_FILL_Y: float = 33.0
const GAUGE_BOTTOM_FILL_END: float = 10.0
const FILL_TIP_HEIGHT: float = 8.0
## Lanterns hang at the floor's corners on the posts; the count tag hangs under the top-left one.
const LANTERN_SIZE := Vector2(28.0, 44.0)
const TAG_SIZE := Vector2(24.0, 18.0)
const FLARE_SIZE := Vector2(36.0, 64.0)

## The board's pieces (`floor/`, `frame/`, `hud/`, `anim/`, `deco/`).
@export_dir var art_dir: String = "res://assets/art/environment/boards/board_01"
## Floor of the lighter tan tile (the owner's reference value), to compare with the mid-dark one.
@export var light_floor: bool = false
## Art pixels kept under the bottom beam for the phone's gesture bar.
@export var bottom_cap: float = 20.0
## Seconds per lantern frame (the lit and glowing loops are four frames each).
@export var lantern_frame_seconds: float = 0.14
## Seed for where the floor variants and the decorations fall.
@export var layout_seed: int = 1
@export_group("Text")
## Design-pixel font sizes of the score, the Rift Points and soul level, and the upgrade tag.
@export var score_font_size: int = 32
@export var small_font_size: int = 28
@export var tag_font_size: int = 18

var _textures: Dictionary[String, Texture2D] = {}
var _unit: float = 2.0
var _hud: Dictionary = {}
var _lantern_time: float = 0.0
var _art: Control
var _text: Control
var _lanterns: Array[TextureRect] = []
var _crest: TextureRect
var _boss_plate: TextureRect
var _boss_fill: TextureRect
var _boss_icon: TextureRect
var _rp_icon: TextureRect
var _tag: TextureRect
var _flare: TextureRect
var _score_label: Label
var _rp_label: Label
var _level_label: Label
var _tag_label: Label
## Each gauge's fill, its tip, and the art-pixel rows its fill runs between (top, bottom).
var _soul_fill: TextureRect
var _soul_tip: TextureRect
var _soul_span := Vector2.ZERO
var _rush_fill: TextureRect
var _rush_tip: TextureRect
var _rush_span := Vector2.ZERO


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_art = Control.new()
	_art.name = "Board"
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	_text = Control.new()
	_text.name = "BoardText"
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)


func _process(delta: float) -> void:
	if _reduced_motion:
		return
	_lantern_time += delta
	_show_lanterns()


func fit(view_size: Vector2, safe_top: float) -> Rect2:
	_unit = view_size.x / BOARD_WIDTH
	var art_size := Vector2(BOARD_WIDTH, view_size.y / _unit)
	var top: float = ceilf(safe_top / _unit)
	var floor_top: float = top + TOP_BEAM_HEIGHT
	var floor_bottom: float = floorf(art_size.y - bottom_cap - BOTTOM_BEAM_HEIGHT)
	var floor_art := Rect2(POST_WIDTH, floor_top, BOARD_WIDTH - 2.0 * POST_WIDTH, floor_bottom - floor_top)
	_build(art_size, top, floor_art)
	_floor_rect = Rect2(floor_art.position * _unit, floor_art.size * _unit)
	set_board_hud(_hud)
	return _floor_rect


func has_board_hud() -> bool:
	return true


func set_board_hud(state: Dictionary) -> void:
	_hud = state
	if _score_label == null:
		return
	_score_label.text = str(state.get("score", ""))
	_rp_label.text = str(state.get("rift_points", ""))
	_level_label.text = str(state.get("level", ""))
	_rp_icon.texture = state.get("rp_icon", null) as Texture2D
	var boss: bool = bool(state.get("boss", false))
	_boss_plate.visible = boss
	_crest.visible = not boss
	_boss_icon.texture = state.get("boss_icon", null) as Texture2D
	_boss_fill.size.x = roundf(BOSS_FILL.size.x * clampf(float(state.get("boss_health", 0.0)), 0.0, 1.0))
	var rush: float = clampf(float(state.get("rush", 0.0)), 0.0, 1.0)
	_set_gauge(_soul_fill, _soul_tip, _soul_span, clampf(float(state.get("soul", 0.0)), 0.0, 1.0))
	_set_gauge(_rush_fill, _rush_tip, _rush_span, rush)
	_flare.visible = rush >= 1.0
	var upgrades: int = int(state.get("upgrades", 0))
	_tag.visible = upgrades > 1
	_tag_label.visible = upgrades > 1
	_tag_label.text = str(upgrades)
	_show_lanterns()


func _apply_reduced_motion() -> void:
	_show_lanterns()


func _show_lanterns() -> void:
	if _lanterns.is_empty():
		return
	var glowing: bool = int(_hud.get("upgrades", 0)) > 0
	var frame: int = 0 if _reduced_motion else int(_lantern_time / maxf(lantern_frame_seconds, 0.01)) % 4
	var texture: Texture2D = _tex("anim/lantern_%s_%d" % ["glow" if glowing else "lit", frame])
	for lantern: TextureRect in _lanterns:
		lantern.texture = texture


func _build(art_size: Vector2, top: float, floor_art: Rect2) -> void:
	for child: Node in _art.get_children():
		child.free()
	for child: Node in _text.get_children():
		child.free()
	_lanterns.clear()
	_art.scale = Vector2(_unit, _unit)
	var right_post: float = BOARD_WIDTH - POST_WIDTH
	var over: float = ceilf(backdrop_overscan / _unit)
	var bottom_beam: float = floor_art.end.y
	# Behind everything, so screen shake never shows an edge: the cap wood over the whole screen.
	_tile("frame/cap_top_segment", Rect2(-over, -over, art_size.x + 2.0 * over, art_size.y + 2.0 * over))
	_tile("frame/cap_bottom_segment",
		Rect2(-over, bottom_beam + BOTTOM_BEAM_HEIGHT, art_size.x + 2.0 * over, art_size.y - bottom_beam - BOTTOM_BEAM_HEIGHT + over))
	_build_floor(floor_art)
	_tile("frame/post_left_segment", Rect2(0.0, floor_art.position.y, POST_WIDTH, floor_art.size.y))
	_tile("frame/post_right_segment", Rect2(right_post, floor_art.position.y, POST_WIDTH, floor_art.size.y))
	_tile("frame/beam_top_segment", Rect2(POST_WIDTH, top, floor_art.size.x, TOP_BEAM_HEIGHT))
	_tile("frame/beam_bottom_segment", Rect2(POST_WIDTH, bottom_beam, floor_art.size.x, BOTTOM_BEAM_HEIGHT))
	_piece("frame/corner_top_left", Vector2(0.0, top))
	_piece("frame/corner_top_right", Vector2(right_post, top))
	_piece("frame/corner_bottom_left", Vector2(0.0, bottom_beam))
	_piece("frame/corner_bottom_right", Vector2(right_post, bottom_beam))
	# The wall line sits in the frame's inner four pixels, so the floor keeps its whole width.
	_tile("frame/rim_h", Rect2(floor_art.position.x, floor_art.position.y - RIM, floor_art.size.x, RIM))
	_tile("frame/rim_h", Rect2(floor_art.position.x, floor_art.end.y, floor_art.size.x, RIM))
	_tile("frame/rim_v", Rect2(floor_art.position.x - RIM, floor_art.position.y, RIM, floor_art.size.y))
	_tile("frame/rim_v", Rect2(floor_art.end.x, floor_art.position.y, RIM, floor_art.size.y))
	for corner: Vector2 in [
		floor_art.position - Vector2(RIM, RIM), Vector2(floor_art.end.x, floor_art.position.y - RIM),
		Vector2(floor_art.position.x - RIM, floor_art.end.y), floor_art.end,
	]:
		_piece("frame/rim_corner", corner)
	var gauge_top: float = floor_art.position.y + 76.0
	var segments: int = clampi(roundi((floor_art.size.y * 0.42 - GAUGE_TOP_HEIGHT - GAUGE_BOTTOM_HEIGHT) / GAUGE_SEGMENT_HEIGHT), 4, 14)
	var gauge_end: float = gauge_top + GAUGE_TOP_HEIGHT + GAUGE_SEGMENT_HEIGHT * float(segments) + GAUGE_BOTTOM_HEIGHT
	_build_decorations(floor_art, gauge_end)
	var soul: Dictionary = _build_gauge("soul", 0.0, gauge_top, segments)
	_soul_fill = soul["fill"] as TextureRect
	_soul_tip = soul["tip"] as TextureRect
	_soul_span = soul["span"] as Vector2
	var rush: Dictionary = _build_gauge("rush", right_post, gauge_top, segments)
	_rush_fill = rush["fill"] as TextureRect
	_rush_tip = rush["tip"] as TextureRect
	_rush_span = rush["span"] as Vector2
	_flare = _piece("hud/rush_full_flare", Vector2(right_post, gauge_top - 10.0))
	_level_label = _label(Rect2(LEVEL_TEXT.position + Vector2(0.0, gauge_top), LEVEL_TEXT.size), small_font_size)
	for spot: Vector2 in [
		Vector2(4.0, floor_art.position.y + 2.0), Vector2(right_post + 4.0, floor_art.position.y + 2.0),
		Vector2(4.0, floor_art.end.y - LANTERN_SIZE.y - 2.0), Vector2(right_post + 4.0, floor_art.end.y - LANTERN_SIZE.y - 2.0),
	]:
		_lanterns.append(_piece("anim/lantern_lit_0", spot))
	var tag_pos := Vector2(6.0, floor_art.position.y + 50.0)
	_tag = _piece("hud/upgrade_count_tag", tag_pos)
	_tag_label = _label(Rect2(tag_pos + TAG_TEXT.position, TAG_TEXT.size), tag_font_size)
	_build_top_hud(top)


func _build_floor(floor_art: Rect2) -> void:
	_tile("floor/floor_tile_a_light" if light_floor else "floor/floor_tile_a", floor_art)
	if light_floor:
		return
	# A few cracked and worn slabs among the plain ones, on the tile grid.
	var random := RandomNumberGenerator.new()
	random.seed = layout_seed
	var columns: int = ceili(floor_art.size.x / FLOOR_TILE)
	var rows: int = ceili(floor_art.size.y / FLOOR_TILE)
	for row: int in rows:
		for column: int in columns:
			var roll: float = random.randf()
			if roll > 0.3:
				continue
			var cell := Rect2(floor_art.position + Vector2(column, row) * FLOOR_TILE, Vector2(FLOOR_TILE, FLOOR_TILE))
			cell = cell.intersection(floor_art)
			if cell.has_area():
				_tile("floor/floor_tile_b" if roll < 0.15 else "floor/floor_tile_c", cell)


func _build_decorations(floor_art: Rect2, gauge_end: float) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = layout_seed + 7
	var right_post: float = BOARD_WIDTH - POST_WIDTH
	var wraps: Array[String] = ["deco/cloth_wrap_post_a", "deco/cloth_wrap_post_b", "deco/cloth_wrap_post_c"]
	var mosses: Array[String] = ["deco/moss_a", "deco/moss_b", "deco/moss_d", "deco/moss_f"]
	# Cloth wrapped round both posts, from under the gauges down to the bottom lanterns.
	var y: float = gauge_end + 24.0
	var stop: float = floor_art.end.y - LANTERN_SIZE.y - 60.0
	var index: int = 0
	while y < stop:
		_piece(wraps[index % wraps.size()], Vector2(0.0, y))
		var right := _piece(wraps[(index + 1) % wraps.size()], Vector2(right_post, y + 40.0))
		right.flip_h = true
		var moss: String = mosses[random.randi_range(0, mosses.size() - 1)]
		_piece(moss, Vector2(random.randf_range(2.0, 14.0), y + 58.0))
		index += 1
		y += 120.0
	# Cloth tails lying on the bottom beam.
	var tails: Array[String] = ["deco/cloth_tail_beam_a", "deco/cloth_tail_beam_b", "deco/cloth_tail_beam_c"]
	for i: int in tails.size():
		var x: float = floor_art.position.x + floor_art.size.x * (0.14 + 0.32 * float(i)) - 24.0
		_piece(tails[i], Vector2(roundf(x), floor_art.end.y + 2.0))


func _build_gauge(kind: String, x: float, gauge_top: float, segments: int) -> Dictionary:
	_piece("hud/%s_gauge_top" % kind, Vector2(x, gauge_top))
	var body_top: float = gauge_top + GAUGE_TOP_HEIGHT
	var body_height: float = GAUGE_SEGMENT_HEIGHT * float(segments)
	_tile("hud/%s_gauge_segment" % kind, Rect2(x, body_top, POST_WIDTH, body_height))
	var bottom_top: float = body_top + body_height
	_piece("hud/%s_gauge_bottom" % kind, Vector2(x, bottom_top))
	var span := Vector2(gauge_top + GAUGE_TOP_FILL_Y, bottom_top + GAUGE_BOTTOM_FILL_END)
	var fill := _tile("hud/%s_fill_segment" % kind, Rect2(x + GAUGE_FILL_X, span.y, GAUGE_FILL_WIDTH, 0.0))
	var tip := _piece("hud/%s_fill_top" % kind, Vector2(x + GAUGE_FILL_X, span.y))
	return {"fill": fill, "tip": tip, "span": span}


func _set_gauge(fill: TextureRect, tip: TextureRect, span: Vector2, ratio: float) -> void:
	if fill == null:
		return
	var height: float = roundf((span.y - span.x) * ratio)
	fill.position.y = span.y - height
	fill.size.y = height
	tip.visible = height >= FILL_TIP_HEIGHT * 0.5
	tip.position.y = maxf(span.x, span.y - height - FILL_TIP_HEIGHT * 0.5)


func _build_top_hud(top: float) -> void:
	var pause := TextureButton.new()
	pause.name = "Pause"
	pause.texture_normal = _tex("hud/pause_button_normal")
	pause.texture_pressed = _tex("hud/pause_button_pressed")
	pause.position = Vector2(PAUSE_POS.x, top + PAUSE_POS.y)
	pause.focus_mode = Control.FOCUS_NONE
	pause.pressed.connect(func() -> void: hud_pause_pressed.emit())
	_art.add_child(pause)
	var centre := Vector2(CENTRE_POS.x, top + CENTRE_POS.y)
	_crest = _piece("hud/crest_center", centre)
	_boss_plate = _piece("hud/boss_plate", centre)
	# The fill and the icon belong to the plate, so they show and hide with it.
	_boss_fill = _tile("hud/boss_fill_segment", Rect2(BOSS_FILL.position, Vector2(0.0, BOSS_FILL.size.y)))
	_boss_fill.reparent(_boss_plate, false)
	_boss_icon = _icon(_boss_plate, BOSS_ICON)
	var score_pos := Vector2(SCORE_POS.x, top + SCORE_POS.y)
	_piece("hud/score_plate", score_pos)
	_score_label = _label(Rect2(score_pos + SCORE_TEXT.position, SCORE_TEXT.size), score_font_size)
	var rp_pos := Vector2(RP_POS.x, top + RP_POS.y)
	var rp_plate := _piece("hud/rp_plate", rp_pos)
	_rp_icon = _icon(rp_plate, RP_ICON)
	_rp_label = _label(Rect2(rp_pos + RP_TEXT.position, RP_TEXT.size), small_font_size)


func _tex(path: String) -> Texture2D:
	if not _textures.has(path):
		var texture := load(art_dir.path_join(path + ".png")) as Texture2D
		if texture == null:
			push_error("[BoardArenaVisual] missing board piece %s" % path)
		_textures[path] = texture
	return _textures[path]


## A piece at its own size, its top-left at [param position] (art pixels).
func _piece(path: String, position: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = _tex(path)
	rect.position = position
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.add_child(rect)
	return rect


## A piece repeated over [param area] (art pixels).
func _tile(path: String, area: Rect2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = _tex(path)
	rect.stretch_mode = TextureRect.STRETCH_TILE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.position = area.position
	rect.size = area.size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.add_child(rect)
	return rect


## An icon drawn into [param socket] of [param plate] (art pixels inside the plate).
func _icon(plate: TextureRect, socket: Rect2) -> TextureRect:
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = socket.position
	icon.size = socket.size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(icon)
	return icon


## A label over [param area] (art pixels), drawn unscaled in design pixels with the game's font.
func _label(area: Rect2, font_size: int) -> Label:
	var label := Label.new()
	label.theme_type_variation = &"ValueLabel"
	label.add_theme_font_size_override(&"font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.position = area.position * _unit
	label.size = area.size * _unit
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_child(label)
	return label
