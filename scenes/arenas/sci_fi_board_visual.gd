class_name SciFiBoardVisual
extends ArenaVisual
## The sci-fi simulation board: a portrait screen in a graphite frame that holds the run's HUD and
## draws enemy arrivals and a boss's appearance on its screen (owner 2026-10-04, GDD §14 #73,
## ADR-0025).
##
## Built at run time from the kit's pieces under [member art_dir] (from
## `concept_art/boards_v1/sci_fi_simulation_v1/`, copied unchanged by `tools/art/make_board.py`) on
## one grid of [constant BOARD_WIDTH] art pixels across the screen, nearest filtering, laid out as
## the kit's `manifest.json` and the assembly in its `build_kit.py`: the navy screen tile over the
## floor, side rails, top and bottom hardware and corners, the cyan rim just outside the floor, the
## wisp core at the top and low-contrast data marks on the screen. The safe top and bottom insets
## are kept as whole art pixels above and below the frame and filled with the kit's caps, the frame
## continued (GDD §14 #74). [method fit] returns the floor; the walls are the rim's inner edge.
##
## The HUD, fed by GameWorld through [method set_board_hud]: pause, the level badge over the soul
## gauge, the upgrade badge (its count from 1 up), score and Rift Points in the top hardware; the
## magenta boss meter (only in a boss fight) and the amber RUSH meter inside the screen. Every fill
## is its full texture cropped to the value, never stretched. Counters use the game's pixel font,
## sized to their sockets. Only the pause button takes input.
##
## Spawn effects, clipped to the floor, over the screen and under the meters and every actor: an
## enemy's amber arrival follows its own arrival countdown, and a boss's magenta appearance, with
## patches at the floor's edges and corners, follows its intro (GameWorld hands over both progress
## readers, [method show_enemy_arrival] and [method show_boss_appearance]). Pausable. Under Reduced
## Motion an arrival holds one frame for its whole countdown, the boss's pattern holds one frame,
## and the patches stay hidden.

## Art pixels across the screen: one art pixel is 2 design pixels on a 1080-wide screen.
const BOARD_WIDTH: float = 540.0
## The frame, in art pixels (manifest): side rails, top and bottom hardware, corners, the rim.
const SIDE_WIDTH: float = 48.0
const TOP_HEIGHT: float = 64.0
const BOTTOM_HEIGHT: float = 64.0
const CORNER_SIZE: float = 72.0
const RIM: float = 6.0
## The caps that fill the safe insets above and below the board (manifest `layout.caps`): an 8 px
## join against the hardware and a 48 px band repeated out to the screen's edge.
const CAP_JOIN_HEIGHT: float = 8.0
const CAP_BAND_HEIGHT: float = 48.0
## Where the hardware pieces sit, in art pixels from the board's top-left under the safe top
## (manifest `layout`, build_kit.py): the core housing and its wisp, then the HUD pieces.
const CORE_POS := Vector2(228.0, 0.0)
const CORE_WISP_POS := Vector2(24.0, 9.0)
const PAUSE_POS := Vector2(12.0, 9.0)
const SCORE_POS := Vector2(352.0, 1.0)
const RP_POS := Vector2(372.0, 35.0)
const LEVEL_POS := Vector2(107.0, 2.0)
const SOUL_POS := Vector2(104.0, 40.0)
const UPGRADE_POS := Vector2(180.0, 5.0)
## The meters' tracks, from the floor's top centre, and where a fill runs inside a track (manifest).
const BOSS_METER_OFFSET := Vector2(-178.0, 56.0)
const RUSH_METER_OFFSET := Vector2(-178.0, 98.0)
const METER_FILL := Rect2(55.0, 12.0, 248.0, 11.0)
const SOUL_FILL := Rect2(10.0, 5.0, 88.0, 6.0)
## Empty rectangles inside the pieces (manifest `text_rect`, `icon_socket`), in art pixels.
const SCORE_TEXT := Rect2(12.0, 11.0, 104.0, 17.0)
const RP_TEXT := Rect2(36.0, 10.0, 60.0, 16.0)
const RP_ICON := Rect2(12.0, 10.0, 17.0, 16.0)
const LEVEL_TEXT := Rect2(8.0, 8.0, 20.0, 20.0)
const UPGRADE_TEXT := Rect2(8.0, 8.0, 8.0, 9.0)
## The screen's data marks (build_kit.py): the first row under the floor's top, the margin the last
## keeps from its bottom, the step, and the left and right marks' insets (the right one drops a
## little).
const DATA_FIRST: float = 154.0
const DATA_END_MARGIN: float = 180.0
const DATA_STEP: float = 220.0
const DATA_LEFT_X: float = 5.0
const DATA_RIGHT_X: float = 41.0
const DATA_RIGHT_DROP: float = 34.0
## Counter fonts: sizes on the 11 grid (ui_design_system.md), the largest that fits its socket.
## Pixelify's digits are about 0.65 em tall (71 px at 110 px, measured).
const FONT_STEP: int = 11
const MAX_FONT_SIZE: int = 66
const DIGIT_HEIGHT_EM: float = 0.65
## Enemy arrival (manifest `animations.enemy_spawn`): a 4 × 2 sheet of 128 px cells, drawn at one
## art pixel per sheet pixel, its scan ring's centre on the enemy.
const ENEMY_SHEET: String = "anim/enemy_spawn_sheet"
const ENEMY_CELL: float = 128.0
const ENEMY_COLUMNS: int = 4
const ENEMY_FRAMES: int = 8
const ENEMY_ORIGIN := Vector2(64.0, 77.0)
const ENEMY_SCALE: float = 1.0
## Boss appearance (manifest `animations.boss_spawn`): a 4 × 3 sheet of 256 px cells at two art
## pixels per sheet pixel, centred on the boss.
const BOSS_SHEET: String = "anim/boss_spawn_sheet"
const BOSS_CELL: float = 256.0
const BOSS_COLUMNS: int = 4
const BOSS_FRAMES: int = 12
const BOSS_ORIGIN := Vector2(128.0, 128.0)
const BOSS_SCALE: float = 2.0
## The frames Reduced Motion holds: the kit's own stills of each effect (its
## `*_spawn_in_board.png`).
const ENEMY_STILL_FRAME: int = 4
const BOSS_STILL_FRAME: int = 6
## Seconds per boss frame for a boss that does not report its intro: the kit preview's frame time.
const FALLBACK_FRAME_SECONDS: float = 0.075
## The boss patches' opacity at each boss frame (manifest `boss_screen_disturbance`).
const PATCH_ALPHA: Array[float] = [
	0.12, 0.22, 0.4, 0.65, 0.85, 1.0, 1.0, 0.75, 0.55, 0.35, 0.18, 0.06,
]
## Where the boss patches sit on the floor (build_kit.py's boss preview): rows from the floor's top
## and the margin the last keeps from its bottom, the step; a scan streak per row, alternately at
## the left and the right wall, sliding right with the opacity; an edge signal at each wall under
## it; and a corner mark at each corner, mirrored, along the top and bottom walls (the reference's
## top-left one).
const PATCH_FIRST: float = 154.0
const PATCH_END_MARGIN: float = 156.0
const PATCH_STEP: float = 120.0
const STREAK_LEFT_X: float = 4.0
const STREAK_RIGHT_X: float = 144.0
const STREAK_SLIDE: float = 8.0
const EDGE_LEFT_X: float = 4.0
const EDGE_RIGHT_X: float = 22.0
const EDGE_DROP: float = 44.0
const CORNER_INSET: float = 7.0

## The kit's pieces (`floor/`, `frame/`, `hud/`, `anim/`, `deco/`).
@export_dir var art_dir: String = "res://assets/art/environment/boards/sci_fi_simulation_v1"

var _textures: Dictionary[String, Texture2D] = {}
var _enemy_frames: Array[Texture2D] = []
var _boss_frames: Array[Texture2D] = []
var _unit: float = 2.0
## The floor in art pixels.
var _floor_art: Rect2 = Rect2()
var _hud: Dictionary = {}
## Drawn in this order: the screen (cap, floor, data marks), the spawn effects clipped to the floor,
## the frame and HUD art, then the counters at design-pixel size.
var _screen: Control
var _spawn_layer: Control
var _art: Control
var _text: Control
var _boss_track: TextureRect
var _boss_fill: Control
var _rush_fill: Control
var _soul_fill: Control
var _rp_icon: TextureRect
var _score_label: Label
var _rp_label: Label
var _level_label: Label
var _upgrade_label: Label
## Each counter's socket in design pixels.
var _sockets: Dictionary[Label, Rect2] = {}
## Enemies arriving (weak references), their progress readers and the sprite drawing each; idle
## sprites wait in the pool.
var _arrivals: Array[WeakRef] = []
var _arrival_progress: Array[Callable] = []
var _arrival_sprites: Array[TextureRect] = []
var _sprite_pool: Array[TextureRect] = []
## The boss appearing (a weak reference, null when none), its progress reader, its pattern, its
## patches and their clock.
var _boss_ref: WeakRef
var _boss_progress: Callable
var _boss_sprite: TextureRect
var _patches: Control
var _streaks: Array[TextureRect] = []
var _streak_x: Array[float] = []
var _boss_clock: float = 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_screen = _layer("Screen")
	_spawn_layer = _layer("SpawnEffects")
	_spawn_layer.clip_contents = true
	_art = _layer("Board")
	_text = _layer("BoardText")
	_boss_sprite = TextureRect.new()
	_boss_sprite.name = "BossAppearance"
	_boss_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_sprite.visible = false
	_spawn_layer.add_child(_boss_sprite)
	_patches = Control.new()
	_patches.name = "BossPatches"
	_patches.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_patches.visible = false
	_spawn_layer.add_child(_patches)
	_enemy_frames = _sheet_frames(ENEMY_SHEET, ENEMY_CELL, ENEMY_COLUMNS, ENEMY_FRAMES)
	_boss_frames = _sheet_frames(BOSS_SHEET, BOSS_CELL, BOSS_COLUMNS, BOSS_FRAMES)


func _process(delta: float) -> void:
	if not _arrivals.is_empty():
		_update_arrivals()
	if _boss_ref != null:
		_update_boss_appearance(delta)


func fit(view_size: Vector2, safe_top: float) -> Rect2:
	_unit = view_size.x / BOARD_WIDTH
	var height: float = floorf(view_size.y / _unit)
	var top: float = ceilf(safe_top / _unit)
	var bottom: float = ceilf(_safe_bottom / _unit)
	_floor_art = Rect2(
		SIDE_WIDTH, top + TOP_HEIGHT,
		BOARD_WIDTH - 2.0 * SIDE_WIDTH, height - top - bottom - TOP_HEIGHT - BOTTOM_HEIGHT,
	)
	_build(height, top, bottom)
	_floor_rect = Rect2(_floor_art.position * _unit, _floor_art.size * _unit)
	set_board_hud(_hud)
	_update_arrivals()
	_update_boss_appearance(0.0)
	return _floor_rect


func has_board_hud() -> bool:
	return true


func set_board_hud(state: Dictionary) -> void:
	_hud = state
	if _score_label == null:
		return
	_set_text(_score_label, str(state.get("score", "")))
	_set_text(_rp_label, str(state.get("rift_points", "")))
	_set_text(_level_label, str(state.get("level", "")))
	var upgrades: int = int(state.get("upgrades", 0))
	_set_text(_upgrade_label, str(upgrades) if upgrades > 0 else "")
	_rp_icon.texture = state.get("rp_icon", null) as Texture2D
	_boss_track.visible = bool(state.get("boss", false))
	_set_fill(_boss_fill, METER_FILL.size.x, float(state.get("boss_health", 0.0)))
	_set_fill(_rush_fill, METER_FILL.size.x, float(state.get("rush", 0.0)))
	_set_fill(_soul_fill, SOUL_FILL.size.x, float(state.get("soul", 0.0)))


func show_enemy_arrival(enemy: Node2D, progress: Callable) -> bool:
	if enemy == null or not progress.is_valid() or float(progress.call()) >= 1.0:
		return false
	_arrivals.append(weakref(enemy))
	_arrival_progress.append(progress)
	_arrival_sprites.append(_take_sprite())
	_update_arrivals()
	return true


func show_boss_appearance(boss: Node2D, progress: Callable) -> void:
	_clear_boss_appearance()
	if boss == null:
		return
	_boss_ref = weakref(boss)
	_boss_progress = progress
	_boss_clock = 0.0
	_boss_sprite.visible = true
	_patches.visible = not _reduced_motion
	_update_boss_appearance(0.0)


func clear_spawn_effects() -> void:
	for sprite: TextureRect in _arrival_sprites:
		_release_sprite(sprite)
	_arrivals.clear()
	_arrival_progress.clear()
	_arrival_sprites.clear()
	_clear_boss_appearance()


func _apply_reduced_motion() -> void:
	_update_arrivals()
	if _boss_ref != null:
		_patches.visible = not _reduced_motion
		_update_boss_appearance(0.0)


## Shows each arriving enemy's frame for how far its countdown has run, and lets go of the sprite
## once the enemy is active, gone or cleared.
func _update_arrivals() -> void:
	for index: int in range(_arrivals.size() - 1, -1, -1):
		var enemy := _arrivals[index].get_ref() as Node2D
		var reader: Callable = _arrival_progress[index]
		var sprite: TextureRect = _arrival_sprites[index]
		var progress: float = 1.0
		if enemy != null and not enemy.is_queued_for_deletion() and reader.is_valid():
			progress = float(reader.call())
		if progress >= 1.0:
			_release_sprite(sprite)
			_arrivals.remove_at(index)
			_arrival_progress.remove_at(index)
			_arrival_sprites.remove_at(index)
			continue
		var frame: int = mini(ENEMY_FRAMES - 1, floori(progress * float(ENEMY_FRAMES)))
		sprite.texture = _enemy_frames[ENEMY_STILL_FRAME if _reduced_motion else frame]
		_place(sprite, enemy.global_position, ENEMY_ORIGIN, ENEMY_SCALE)


## Shows the boss's appearance frame for how far its intro has run, with the patches at that frame's
## opacity, and clears it all once the intro is over or the boss is gone.
func _update_boss_appearance(delta: float) -> void:
	if _boss_ref == null:
		return
	var boss := _boss_ref.get_ref() as Node2D
	if boss == null or boss.is_queued_for_deletion():
		_clear_boss_appearance()
		return
	var progress: float = float(_boss_progress.call()) if _boss_progress.is_valid() else -1.0
	if progress < 0.0:
		_boss_clock += delta
		progress = _boss_clock / (FALLBACK_FRAME_SECONDS * float(BOSS_FRAMES))
	if progress >= 1.0:
		_clear_boss_appearance()
		return
	var frame: int = mini(BOSS_FRAMES - 1, floori(progress * float(BOSS_FRAMES)))
	_boss_sprite.texture = _boss_frames[BOSS_STILL_FRAME if _reduced_motion else frame]
	_place(_boss_sprite, boss.global_position, BOSS_ORIGIN, BOSS_SCALE)
	var alpha: float = PATCH_ALPHA[frame]
	_patches.modulate.a = alpha
	for i: int in _streaks.size():
		_streaks[i].position.x = _streak_x[i] + roundf(STREAK_SLIDE * alpha)


func _clear_boss_appearance() -> void:
	_boss_ref = null
	_boss_progress = Callable()
	if _boss_sprite != null:
		_boss_sprite.visible = false
		_patches.visible = false


## Puts an effect's [param origin] (sheet pixels, drawn [param art_scale] art pixels each) on [param
## world_position], on the floor's art-pixel grid.
func _place(
		sprite: TextureRect, world_position: Vector2, origin: Vector2, art_scale: float
	) -> void:
	var local: Vector2 = get_global_transform().affine_inverse() * world_position
	var art: Vector2 = (local / _unit - _floor_art.position).round()
	sprite.scale = Vector2(art_scale, art_scale)
	sprite.position = art - origin * art_scale


func _take_sprite() -> TextureRect:
	var sprite: TextureRect
	if _sprite_pool.is_empty():
		sprite = TextureRect.new()
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_spawn_layer.add_child(sprite)
	else:
		sprite = _sprite_pool.pop_back()
	sprite.visible = true
	return sprite


func _release_sprite(sprite: TextureRect) -> void:
	sprite.visible = false
	_sprite_pool.append(sprite)


func _build(height: float, top: float, bottom: float) -> void:
	for layer: Control in [_screen, _art, _text]:
		for child: Node in layer.get_children():
			child.free()
	for child: Node in _patches.get_children():
		child.free()
	_streaks.clear()
	_streak_x.clear()
	_sockets.clear()
	for layer: Control in [_screen, _art, _spawn_layer]:
		layer.scale = Vector2(_unit, _unit)
	var floor_art: Rect2 = _floor_art
	var board_bottom: float = height - bottom
	var over: float = ceilf(backdrop_overscan / _unit)
	# Behind everything, so screen shake past the board's sides shows the frame's dark metal.
	_tile(_screen, "frame/outer_cap_segment",
		Rect2(-over, -over, BOARD_WIDTH + 2.0 * over, height + 2.0 * over + 1.0))
	_build_caps(height, top, board_bottom, over)
	_tile(_screen, "floor/screen_tile", floor_art)
	var y: float = floor_art.position.y + DATA_FIRST
	while y < floor_art.end.y - DATA_END_MARGIN:
		_piece(_screen, "deco/screen_data_left", Vector2(floor_art.position.x + DATA_LEFT_X, y))
		_piece(_screen, "deco/screen_data_right",
			Vector2(floor_art.end.x - DATA_RIGHT_X, y + DATA_RIGHT_DROP))
		y += DATA_STEP
	_spawn_layer.position = floor_art.position * _unit
	_spawn_layer.size = floor_art.size
	_build_patches(floor_art.size)
	_build_meters(floor_art)
	var right: float = BOARD_WIDTH - SIDE_WIDTH
	var middle: float = BOARD_WIDTH - 2.0 * CORNER_SIZE
	var rail_height: float = board_bottom - top - 2.0 * CORNER_SIZE
	_tile(_art, "frame/side_left_segment", Rect2(0.0, top + CORNER_SIZE, SIDE_WIDTH, rail_height))
	_tile(_art, "frame/side_right_segment",
		Rect2(right, top + CORNER_SIZE, SIDE_WIDTH, rail_height))
	_tile(_art, "frame/top_segment", Rect2(CORNER_SIZE, top, middle, TOP_HEIGHT))
	_tile(_art, "frame/bottom_segment",
		Rect2(CORNER_SIZE, board_bottom - BOTTOM_HEIGHT, middle, BOTTOM_HEIGHT))
	_piece(_art, "frame/corner_top_left", Vector2(0.0, top))
	_piece(_art, "frame/corner_top_right", Vector2(BOARD_WIDTH - CORNER_SIZE, top))
	_piece(_art, "frame/corner_bottom_left", Vector2(0.0, board_bottom - CORNER_SIZE))
	_piece(_art, "frame/corner_bottom_right",
		Vector2(BOARD_WIDTH - CORNER_SIZE, board_bottom - CORNER_SIZE))
	# The rim sits just outside the floor, so the floor keeps its whole size.
	_tile(_art, "frame/screen_rim_left",
		Rect2(floor_art.position.x - RIM, floor_art.position.y, RIM, floor_art.size.y))
	_tile(_art, "frame/screen_rim_right",
		Rect2(floor_art.end.x, floor_art.position.y, RIM, floor_art.size.y))
	_tile(_art, "frame/screen_rim_top",
		Rect2(floor_art.position.x, floor_art.position.y - RIM, floor_art.size.x, RIM))
	_tile(_art, "frame/screen_rim_bottom",
		Rect2(floor_art.position.x, floor_art.end.y, floor_art.size.x, RIM))
	var core := Vector2(CORE_POS.x, top + CORE_POS.y)
	_piece(_art, "deco/core_housing", core)
	_piece(_art, "deco/core_wisp", core + CORE_WISP_POS)
	_build_hud(top)


## The caps in the safe insets (owner 2026-10-04, GDD §14 #74): each join touches the hardware, and
## its band repeats away from the board until it passes the screen's edge (and the shake overscan),
## so the last repeat is cropped there; a cap shorter than the join crops the join the same way.
func _build_caps(height: float, top: float, board_bottom: float, over: float) -> void:
	var top_join: float = top - CAP_JOIN_HEIGHT
	_piece(_screen, "frame/cap_top_join", Vector2(0.0, top_join))
	var above: float = top_join + over
	if above > 0.0:
		var band_height: float = ceilf(above / CAP_BAND_HEIGHT) * CAP_BAND_HEIGHT
		_tile(_screen, "frame/cap_top_band",
			Rect2(0.0, top_join - band_height, BOARD_WIDTH, band_height))
	var bottom_band: float = board_bottom + CAP_JOIN_HEIGHT
	_piece(_screen, "frame/cap_bottom_join", Vector2(0.0, board_bottom))
	var below: float = height + 1.0 + over - bottom_band
	if below > 0.0:
		var band_height: float = ceilf(below / CAP_BAND_HEIGHT) * CAP_BAND_HEIGHT
		_tile(_screen, "frame/cap_bottom_band", Rect2(0.0, bottom_band, BOARD_WIDTH, band_height))


## The magenta boss meter (hidden outside a boss fight) and the amber RUSH meter, inside the screen.
func _build_meters(floor_art: Rect2) -> void:
	var centre := Vector2(floor_art.get_center().x, floor_art.position.y)
	_boss_track = _piece(_art, "hud/boss_meter_track", centre + BOSS_METER_OFFSET)
	_boss_fill = _fill(_boss_track, "hud/boss_meter_fill", METER_FILL)
	var rush_track: TextureRect = _piece(_art, "hud/rush_meter_track", centre + RUSH_METER_OFFSET)
	_rush_fill = _fill(rush_track, "hud/rush_meter_fill", METER_FILL)


func _build_hud(top: float) -> void:
	var pause := TextureButton.new()
	pause.name = "Pause"
	pause.texture_normal = _tex("hud/pause_button")
	pause.ignore_texture_size = true
	pause.stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	pause.focus_mode = Control.FOCUS_NONE
	# The floating HUD's touch target, in whole art pixels round the icon, so the icon stays on the
	# grid.
	var touch: float = 2.0 * ceilf(GameWorld.HUD_PAUSE_SIZE / _unit * 0.5)
	var icon_size: Vector2 = pause.texture_normal.get_size()
	var icon_centre: Vector2 = Vector2(PAUSE_POS.x, top + PAUSE_POS.y) + icon_size * 0.5
	pause.position = icon_centre - Vector2(touch, touch) * 0.5
	pause.size = Vector2(touch, touch)
	pause.pressed.connect(func() -> void: hud_pause_pressed.emit())
	_art.add_child(pause)
	var level := Vector2(LEVEL_POS.x, top + LEVEL_POS.y)
	_piece(_art, "hud/level_badge", level)
	_level_label = _label(level, LEVEL_TEXT, &"ValueLabel")
	var soul := Vector2(SOUL_POS.x, top + SOUL_POS.y)
	var soul_track: TextureRect = _piece(_art, "hud/soul_gauge_track", soul)
	_soul_fill = _fill(soul_track, "hud/soul_gauge_fill", SOUL_FILL)
	var upgrade := Vector2(UPGRADE_POS.x, top + UPGRADE_POS.y)
	_piece(_art, "hud/upgrade_badge", upgrade)
	_upgrade_label = _label(upgrade, UPGRADE_TEXT, &"AmberValueLabel")
	var score := Vector2(SCORE_POS.x, top + SCORE_POS.y)
	_piece(_art, "hud/score_plate", score)
	_score_label = _label(score, SCORE_TEXT, &"ValueLabel")
	var rp := Vector2(RP_POS.x, top + RP_POS.y)
	var rp_plate: TextureRect = _piece(_art, "hud/rp_plate", rp)
	_rp_icon = TextureRect.new()
	_rp_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rp_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_rp_icon.position = RP_ICON.position
	_rp_icon.size = RP_ICON.size
	_rp_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rp_plate.add_child(_rp_icon)
	_rp_label = _label(rp, RP_TEXT, &"ValueLabel")


## The boss's screen patches over a floor of [param floor_size] art pixels; they show only while a
## boss appears.
func _build_patches(floor_size: Vector2) -> void:
	var row: int = 0
	var y: float = PATCH_FIRST
	while y < floor_size.y - PATCH_END_MARGIN:
		var x: float = STREAK_LEFT_X if row % 2 == 0 else floor_size.x - STREAK_RIGHT_X
		_streaks.append(_piece(_patches, "anim/boss_scan_streak", Vector2(x, y)))
		_streak_x.append(x)
		_piece(_patches, "anim/boss_edge_signal", Vector2(EDGE_LEFT_X, y + EDGE_DROP))
		_piece(_patches, "anim/boss_edge_signal",
			Vector2(floor_size.x - EDGE_RIGHT_X, y + EDGE_DROP))
		y += PATCH_STEP
		row += 1
	var corner_size: Vector2 = _tex("anim/boss_corner_signal").get_size()
	var corners: Array[Vector2] = [Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN, Vector2.ONE]
	for corner: Vector2 in corners:
		var spot := Vector2(
			lerpf(CORNER_INSET, floor_size.x - CORNER_INSET - corner_size.x, corner.x),
			lerpf(0.0, floor_size.y - corner_size.y, corner.y),
		)
		var mark: TextureRect = _piece(_patches, "anim/boss_corner_signal", spot)
		mark.flip_h = corner.x > 0.5
		mark.flip_v = corner.y > 0.5


func _tex(path: String) -> Texture2D:
	if not _textures.has(path):
		var texture := load(art_dir.path_join(path + ".png")) as Texture2D
		if texture == null:
			push_error("[SciFiBoardVisual] missing board piece %s" % path)
		_textures[path] = texture
	return _textures[path]


## The frames of a one-shot sheet, read row by row, each an [AtlasTexture] made once.
func _sheet_frames(path: String, cell: float, columns: int, count: int) -> Array[Texture2D]:
	var sheet: Texture2D = _tex(path)
	var frames: Array[Texture2D] = []
	for index: int in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		var cell_position := Vector2(float(index % columns), floorf(float(index) / float(columns)))
		atlas.region = Rect2(cell_position * cell, Vector2(cell, cell))
		frames.append(atlas)
	return frames


func _layer(layer_name: String) -> Control:
	var layer := Control.new()
	layer.name = layer_name
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	return layer


## A piece at its own size under [param parent], its top-left at [param at] (art pixels).
func _piece(parent: Control, path: String, at: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = _tex(path)
	rect.position = at
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect


## A piece repeated over [param area] (art pixels) under [param parent]; the last repeat is cropped.
func _tile(parent: Control, path: String, area: Rect2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = _tex(path)
	rect.stretch_mode = TextureRect.STRETCH_TILE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.position = area.position
	rect.size = area.size
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rect)
	return rect


## A fill inside [param track] at [param socket]: the whole fill texture in a clipping box whose
## width [method _set_fill] sets, so the value crops it and never stretches it.
func _fill(track: TextureRect, path: String, socket: Rect2) -> Control:
	var clip := Control.new()
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.position = socket.position
	clip.size = Vector2(0.0, socket.size.y)
	track.add_child(clip)
	var fill := TextureRect.new()
	fill.texture = _tex(path)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(fill)
	return clip


## Shows [param ratio] (clamped to 0..1) of a fill [param width] art pixels wide, in whole art
## pixels.
func _set_fill(clip: Control, width: float, ratio: float) -> void:
	clip.size.x = roundf(width * clampf(ratio, 0.0, 1.0))


## A counter over [param socket] of the piece at [param piece] (art pixels), drawn unscaled in
## design pixels with the game's font; [method _set_text] sizes it.
func _label(piece: Vector2, socket: Rect2, variation: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_child(label)
	_sockets[label] = Rect2((piece + socket.position) * _unit, socket.size * _unit)
	return label


## Sets a counter's text and the largest font size on the 11 grid whose digits fit its socket, with
## the line centred on the socket.
func _set_text(label: Label, text: String) -> void:
	if label.text == text and label.has_theme_font_size_override(&"font_size"):
		return
	label.text = text
	var socket: Rect2 = _sockets[label]
	var font: Font = label.get_theme_font(&"font")
	var font_size: int = MAX_FONT_SIZE
	while font_size > FONT_STEP:
		var fits_height: bool = float(font_size) * DIGIT_HEIGHT_EM <= socket.size.y
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
		var fits_width: bool = width <= socket.size.x
		if fits_height and fits_width:
			break
		font_size -= FONT_STEP
	label.add_theme_font_size_override(&"font_size", font_size)
	var line: float = maxf(socket.size.y, font.get_height(font_size))
	label.position = Vector2(socket.position.x, socket.get_center().y - line * 0.5)
	label.size = Vector2(socket.size.x, line)
