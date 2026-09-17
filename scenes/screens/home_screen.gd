class_name HomeScreen
extends Control
## Home: top bar and wordmark, a living hero Wisp between two button columns, then PLAY and Rifts.
##
## Layout (owner decisions 2026-09-13 and 2026-09-15): the top bar and logo stay; the equipped Wisp
## floats in the middle and tapping it opens the Shop; Trials and Daily sit in a column on the left,
## Shop and Remove Ads on the right; below the Wisp, clear of every animation, a caption and a large
## animated PLAY, centred between an empty balance slot on its left and the Rifts button on its
## right. PLAY always starts Endless (caption `ENDLESS  •  BEST WAVE n`, top bar BEST = the Endless
## best); the story Rifts are entered only through RIFTS and the Rift Map. The screen feels alive
## through the Wisp's float, breathe, sway and glow, the orbiting soul sparks, HomeAmbience over the
## painted backdrop, PLAY's glow pulse and light sweep, and the turning Rift portal. The orbit and
## glow shrink to the room between the columns, so no animation ever passes over a button. Reduced
## Motion stills all of it. All styling comes from theme type variations and Palette.

## Emitted when PLAY is activated; the host starts an Endless run with the equipped skin.
signal play_requested
## Emitted when the player taps the hero Wisp; Main opens the Shop's WISPS tab.
signal wisps_requested
## Emitted when the player opens today's deterministic Rift.
signal daily_requested
## The player asked to open the Rift map to pick an arena.
signal rift_map_requested
## The player asked to open the Trials ladder.
signal trials_requested
## Emitted when the player opens lifetime statistics.
signal statistics_requested
## Emitted when the player opens Settings.
signal settings_requested
## The player asked to open the Shop.
signal shop_requested
## The player tapped Remove Ads; the host opens the Shop on that product.
signal remove_ads_requested

## Centre of the Wisp painted into home_background.png, as a fraction of the texture size.
const PAINTED_WISP_CENTER := Vector2(0.49, 0.466)
## Hero preview edge in background-texture pixels (covers the painted Wisp and its flame).
const PAINTED_WISP_SIZE := 400.0
## Size of the dark pocket behind the preview, relative to the preview edge.
const HERO_POCKET_SCALE := 1.35
## Pocket opacity at its centre and at half its radius (fades to 0 at the edge).
const POCKET_CORE_ALPHA := 0.62
const POCKET_MID_ALPHA := 0.38
## Hero glow: largest size relative to the preview edge, and its steady and pulsing alpha.
const HERO_GLOW_SCALE := 1.9
const HERO_GLOW_ALPHA := 0.5
const HERO_GLOW_PULSE := 0.16
## Share of the glow's radius that is visibly lit; the soft tail beyond it is negligible.
const GLOW_VISIBLE_SHARE := 0.8
## Hero motion. Float is a fraction of the preview edge; breathe is scale; sway is radians.
const FLOAT_AMOUNT := 0.035
const FLOAT_SPEED := 1.55
const BREATHE_AMOUNT := 0.03
const BREATHE_SPEED := 2.3
const SWAY_AMOUNT := 0.035
const SWAY_SPEED := 1.05
## Largest orbit radius relative to the preview edge, and how far below the Wisp's centre the ring
## sits. Lowered so the front arc passes beneath the body instead of across the face.
const ORBIT_SCALE := 0.74
const ORBIT_DROP := 0.2
## Design pixels kept between the hero's furthest animated pixel and the side button columns.
const HERO_SIDE_CLEARANCE := 28.0
## Design pixels between the hero's lowest animated pixel and the Rift caption and PLAY row, which
## sit directly under the Wisp (owner: about 50 px or more, with no animation in the way).
const HERO_BOTTOM_CLEARANCE := 64.0
## Least gap between the bottom of a side column and the caption and PLAY row.
const COLUMN_ACTION_GAP := 24.0
## A press on the Wisp that moves further than this (design pixels) is not a tap.
const HERO_TAP_SLOP := 32.0
## Scale the Wisp and PLAY dip to while pressed.
const PRESSED_SCALE := 0.94
## PLAY motion: breathing scale, the glow behind it (size relative to the button) and the light sweep.
const PLAY_BREATHE_AMOUNT := 0.022
const PLAY_BREATHE_SPEED := 2.4
const PLAY_GLOW_SCALE := Vector2(1.3, 2.3)
const PLAY_GLOW_ALPHA := 0.32
const PLAY_GLOW_PULSE := 0.14
## Seconds between light sweeps across PLAY, and how long one sweep takes.
const PLAY_SHEEN_PERIOD := 3.4
const PLAY_SHEEN_SWEEP := 0.8
const PLAY_SHEEN_WIDTH := 90.0
const PLAY_SHEEN_ALPHA := 0.38
const PLAY_SHEEN_TILT := 0.36
## Rift portal icon: box relative to the Rifts button, turn speed (radians/second) and pulse.
const RIFT_ICON_SHARE := 0.6
const RIFT_ICON_TOP_SHARE := 0.07
const RIFT_ICON_SPIN := 0.9
const RIFT_ICON_PULSE := 0.06
const RIFT_ICON_PULSE_SPEED := 2.0
## Design pixels above the Rift caption where the darkening gradient behind the PLAY row begins.
const BOTTOM_SHADE_LEAD := 300.0
## Screen margins in the 1080-wide design space before the device safe area is added.
const BASE_MARGIN_SIDE := 36.0
const BASE_MARGIN_TOP := 40.0
const BASE_MARGIN_BOTTOM := 32.0

var _animation_time: float = 0.0
var _rift_points: int = 0
var _reduced_motion: bool = false
var _ads_removed: bool = false
var _equipped_texture: Texture2D = null
var _equipped_tint: Color = Palette.SOUL_CYAN
var _endless_best_score: int = 0
var _endless_best_wave: int = 0
var _hero_rest: Vector2 = Vector2.ZERO
var _hero_edge: float = 0.0
var _orbit_radius: float = 0.0
var _glow_edge: float = 0.0
var _hero_press_scale: float = 1.0
var _hero_pressed: bool = false
var _hero_press_origin: Vector2 = Vector2.ZERO
var _play_press_scale: float = 1.0
var _hero_press_tween: Tween
var _play_press_tween: Tween

@onready var _background: TextureRect = %Background
@onready var _ambience: HomeAmbience = %Ambience
@onready var _bottom_shade: TextureRect = %BottomShade
@onready var _content_margin: MarginContainer = %ContentMargin
@onready var _hero_area: Control = %HeroArea
@onready var _hero_pocket: TextureRect = %HeroPocket
@onready var _hero_glow: TextureRect = %HeroGlow
@onready var _wisp_preview: TextureRect = %WispPreview
@onready var _orbit_back: OrbitMotes = %OrbitBack
@onready var _orbit_front: OrbitMotes = %OrbitFront
@onready var _left_column: VBoxContainer = %LeftColumn
@onready var _right_column: VBoxContainer = %RightColumn
@onready var _trials_button: Button = %TrialsButton
@onready var _daily_button: Button = %DailyButton
@onready var _shop_button: Button = %ShopButton
@onready var _remove_ads_button: Button = %RemoveAdsButton
@onready var _remove_ads_strike: ColorRect = %RemoveAdsStrike
@onready var _action_block: VBoxContainer = %ActionBlock
@onready var _rift_caption: Label = %RiftCaption
@onready var _play_button: Button = %PlayButton
@onready var _play_glow: TextureRect = %PlayGlow
@onready var _play_sheen_clip: Control = %PlaySheenClip
@onready var _play_sheen: TextureRect = %PlaySheen
@onready var _rifts_button: Button = %RiftsButton
@onready var _rifts_icon: TextureRect = %RiftsIcon
@onready var _stats_button: Button = %StatsButton
@onready var _settings_button: Button = %SettingsButton
@onready var _best_label: Label = %BestLabel
@onready var _rift_points_label: Label = %RiftPointsLabel


func _ready() -> void:
	var pocket_stops: Array[Color] = [
		Color(Palette.VOID_CHARCOAL, POCKET_CORE_ALPHA),
		Color(Palette.VOID_CHARCOAL, POCKET_MID_ALPHA),
		Color(Palette.VOID_CHARCOAL, 0.0),
	]
	_hero_pocket.texture = _radial_texture(pocket_stops)
	var glow_stops: Array[Color] = [Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)]
	var glow_texture: GradientTexture2D = _radial_texture(glow_stops)
	_hero_glow.texture = glow_texture
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_hero_glow.material = additive
	for orbit: OrbitMotes in [_orbit_back, _orbit_front]:
		orbit.material = additive
	_play_glow.texture = glow_texture
	_play_glow.material = additive
	_play_glow.self_modulate = Palette.SOUL_CYAN
	_play_sheen.texture = _sheen_texture()
	_play_sheen.material = additive
	_play_sheen.rotation = PLAY_SHEEN_TILT
	_play_sheen.modulate = Color(Palette.SOUL_WHITE, PLAY_SHEEN_ALPHA)
	_remove_ads_strike.color = Palette.WARNING_AMBER
	_bottom_shade.texture = _bottom_shade_texture()
	_ambience.background = _background.texture
	_play_button.pressed.connect(func() -> void: play_requested.emit())
	_rifts_button.pressed.connect(func() -> void: rift_map_requested.emit())
	_trials_button.pressed.connect(func() -> void: trials_requested.emit())
	_daily_button.pressed.connect(func() -> void: daily_requested.emit())
	_shop_button.pressed.connect(func() -> void: shop_requested.emit())
	_remove_ads_button.pressed.connect(func() -> void: remove_ads_requested.emit())
	_stats_button.pressed.connect(func() -> void: statistics_requested.emit())
	_settings_button.pressed.connect(func() -> void: settings_requested.emit())
	# PLAY breathes by scale, so it owns its press dip instead of UiJuice's scale tween.
	_play_button.set_meta(UiJuice.BOUND_META, true)
	_play_button.button_down.connect(_tween_play_press.bind(PRESSED_SCALE, 0.06))
	_play_button.button_up.connect(_tween_play_press.bind(1.0, 0.16))
	_wisp_preview.gui_input.connect(_on_wisp_preview_gui_input)
	_hero_area.item_rect_changed.connect(_layout_hero)
	for control: Control in [_play_button, _play_sheen_clip, _rifts_button]:
		control.resized.connect(_layout_actions)
	_apply_safe_area()
	_refresh()
	_play_button.grab_focus()
	_layout_hero.call_deferred()
	_layout_actions.call_deferred()
	print("[Home] ready")


func _process(delta: float) -> void:
	_animation_time += delta
	_animate_hero()
	_animate_actions()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			if is_node_ready():
				_apply_safe_area()
				_layout_hero()
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_EXIT_TREE:
			_cancel_hero_press()


## Refreshes Rift Points, best, the equipped form, the Rift PLAY will enter, ENDLESS and Remove Ads.
func setup(snapshot: Dictionary, equipped_form: FormData) -> void:
	_rift_points = int(snapshot.get(&"rift_points", 0))
	_ads_removed = bool(snapshot.get(&"ads_removed", false))
	var settings: Variant = snapshot.get(&"settings", {})
	if settings is Dictionary:
		_reduced_motion = bool((settings as Dictionary).get(&"reduced_motion", false))
	if equipped_form != null:
		_equipped_texture = equipped_form.texture
		_equipped_tint = equipped_form.tint
	_endless_best_score = int(snapshot.get(&"endless_best_score", 0))
	_endless_best_wave = int(snapshot.get(&"endless_best_wave", 0))
	if is_node_ready():
		_refresh()
	# Main keeps one Home and re-shows it, so _ready's focus grab only covers the first visit.
	if is_inside_tree() and get_viewport().gui_get_focus_owner() == null:
		_play_button.grab_focus.call_deferred()


## The two halves of the hero orbit, for tests.
func get_orbits() -> Array[OrbitMotes]:
	return [_orbit_back, _orbit_front]


## Whether the hero and background are animating (false under Reduced Motion).
func is_animating() -> bool:
	return is_processing() and _ambience.is_active()


## Text currently shown above PLAY, for tests.
func get_play_caption() -> String:
	return _rift_caption.text


## Global rectangle that every hero animation stays inside at its extremes, for tests.
##
## Covers the swaying, breathing, floating Wisp, the orbit sparks with their halos and the visible
## glow to either side and below. Only the Wisp bounds the top: the glow may spill onto the logo.
func get_hero_motion_rect() -> Rect2:
	var extent: Vector2 = OrbitMotes.get_extent_ratio()
	var preview_half: float = _hero_edge * _preview_half_share()
	var glow_reach: float = _glow_edge * 0.5 * _glow_reach_share()
	var float_offset: float = _hero_edge * FLOAT_AMOUNT
	var half_width: float = maxf(preview_half, maxf(extent.x * _orbit_radius, glow_reach))
	var below: float = float_offset + maxf(
		preview_half,
		maxf(_hero_edge * ORBIT_DROP + extent.y * _orbit_radius, glow_reach),
	)
	var above: float = preview_half + float_offset
	var centre: Vector2 = _hero_area.global_position + _hero_rest
	return Rect2(centre.x - half_width, centre.y - above, half_width * 2.0, above + below)


func _refresh() -> void:
	if _equipped_texture != null:
		_wisp_preview.texture = _equipped_texture
	_best_label.text = _group_digits(_endless_best_score)
	_rift_points_label.text = RiftPoints.group_digits(_rift_points)
	_hero_glow.self_modulate = Color(_equipped_tint, 1.0)
	for orbit: OrbitMotes in [_orbit_back, _orbit_front]:
		orbit.tint = _equipped_tint
	_rift_caption.text = _describe_play()
	# Nothing left to sell once ads are removed; the Shop stays reachable for restores.
	_remove_ads_button.visible = not _ads_removed
	# Reduced Motion stills the hero, the orbit, PLAY, the portal and the living background.
	set_process(not _reduced_motion)
	for orbit: OrbitMotes in [_orbit_back, _orbit_front]:
		orbit.set_process(not _reduced_motion)
		orbit.visible = not _reduced_motion
	_ambience.set_active(not _reduced_motion)
	_animation_time = 0.0
	_animate_hero()
	_animate_actions()
	_layout_hero.call_deferred()


## What PLAY starts: Endless, with the best wave reached there once there is one.
func _describe_play() -> String:
	if _endless_best_wave <= 0:
		return "ENDLESS"
	return "ENDLESS  •  BEST WAVE %d" % _endless_best_wave

## Places the hero over the painted Wisp, the button columns beside it and PLAY under it.
##
## The preview keeps covering the Wisp painted into the backdrop, so its size follows the art. The
## orbit and glow then shrink to the room left between the columns, the group rises when needed to
## leave room below, and the caption and PLAY row sit HERO_BOTTOM_CLEARANCE under its lowest
## animated pixel, so no animation ever passes over a button.
func _layout_hero() -> void:
	if _background.texture == null or not is_node_ready():
		return
	var area_size: Vector2 = _hero_area.size
	var left_size: Vector2 = _left_column.get_combined_minimum_size()
	var right_size: Vector2 = _right_column.get_combined_minimum_size()
	var action_size: Vector2 = _action_block.get_combined_minimum_size()
	var usable_height: float = area_size.y - action_size.y - HERO_BOTTOM_CLEARANCE
	var free_width: float = area_size.x - left_size.x - right_size.x - HERO_SIDE_CLEARANCE * 2.0
	if usable_height <= 0.0 or free_width <= 0.0:
		return
	var texture_size: Vector2 = _background.texture.get_size()
	var cover: float = maxf(size.x / texture_size.x, size.y / texture_size.y)
	var image_size: Vector2 = texture_size * cover
	var image_origin: Vector2 = (size - image_size) * 0.5
	var area_origin: Vector2 = _hero_area.global_position - global_position
	var painted_center: Vector2 = image_origin + image_size * PAINTED_WISP_CENTER - area_origin

	var extent: Vector2 = OrbitMotes.get_extent_ratio()
	var above_share: float = _preview_half_share() + FLOAT_AMOUNT
	# Sized against the largest orbit and glow, so the smaller ones chosen below always fit too.
	var below_share_max: float = FLOAT_AMOUNT + maxf(
		_preview_half_share(),
		maxf(ORBIT_DROP + extent.y * ORBIT_SCALE, HERO_GLOW_SCALE * 0.5 * _glow_reach_share()),
	)
	# The swaying, breathing preview is wider than its edge, so cap the edge by that animated width.
	var edge: float = minf(PAINTED_WISP_SIZE * cover, free_width / (2.0 * _preview_half_share()))
	edge = minf(edge, usable_height / (above_share + below_share_max))
	if edge <= 0.0:
		return

	var left_limit: float = left_size.x + HERO_SIDE_CLEARANCE
	var right_limit: float = area_size.x - right_size.x - HERO_SIDE_CLEARANCE
	var centre_x: float = clampf(
		painted_center.x,
		left_limit + edge * _preview_half_share(),
		right_limit - edge * _preview_half_share(),
	)
	var room: float = maxf(0.0, minf(centre_x - left_limit, right_limit - centre_x))
	var orbit_scale: float = minf(ORBIT_SCALE, room / (extent.x * edge))
	var glow_scale: float = minf(HERO_GLOW_SCALE, room * 2.0 / (edge * _glow_reach_share()))
	var below_share: float = FLOAT_AMOUNT + maxf(
		_preview_half_share(),
		maxf(ORBIT_DROP + extent.y * orbit_scale, glow_scale * 0.5 * _glow_reach_share()),
	)
	var centre_y: float = clampf(
		painted_center.y,
		edge * above_share,
		maxf(edge * above_share, usable_height - edge * below_share),
	)

	_hero_edge = edge
	_orbit_radius = edge * orbit_scale
	_glow_edge = edge * glow_scale
	_hero_rest = Vector2(centre_x, centre_y)
	var preview_size := Vector2(edge, edge)
	_wisp_preview.size = preview_size
	_wisp_preview.pivot_offset = preview_size * 0.5
	var pocket_size: Vector2 = preview_size * HERO_POCKET_SCALE
	_hero_pocket.size = pocket_size
	_hero_pocket.position = _hero_rest - pocket_size * 0.5
	var glow_size := Vector2(_glow_edge, _glow_edge)
	_hero_glow.size = glow_size
	_hero_glow.pivot_offset = glow_size * 0.5
	for orbit: OrbitMotes in [_orbit_back, _orbit_front]:
		orbit.radius = _orbit_radius

	var action_top: float = centre_y + edge * below_share + HERO_BOTTOM_CLEARANCE
	_action_block.position = Vector2(0.0, action_top)
	_action_block.size = Vector2(area_size.x, action_size.y)
	_layout_bottom_shade(area_origin.y + action_top)

	# Columns share one top edge beside the Wisp; the taller left column is centred on it.
	var column_height: float = maxf(left_size.y, right_size.y)
	var column_top: float = clampf(
		centre_y - left_size.y * 0.5,
		0.0,
		maxf(0.0, action_top - COLUMN_ACTION_GAP - column_height),
	)
	_left_column.position = Vector2(0.0, column_top)
	_left_column.size = left_size
	_right_column.position = Vector2(area_size.x - right_size.x, column_top)
	_right_column.size = right_size
	_animate_hero()


## Float, breathe, sway and glow pulse. At time zero (Reduced Motion) this is the resting pose.
func _animate_hero() -> void:
	if _hero_edge <= 0.0:
		return
	var t: float = _animation_time
	var float_offset: float = sin(t * FLOAT_SPEED) * _hero_edge * FLOAT_AMOUNT
	var breathe: float = 1.0 + sin(t * BREATHE_SPEED) * BREATHE_AMOUNT
	var centre: Vector2 = _hero_rest + Vector2(0.0, float_offset)
	_wisp_preview.position = centre - _wisp_preview.size * 0.5
	_wisp_preview.scale = Vector2.ONE * breathe * _hero_press_scale
	_wisp_preview.rotation = sin(t * SWAY_SPEED) * SWAY_AMOUNT
	_hero_glow.position = centre - _hero_glow.size * 0.5
	_hero_glow.scale = Vector2.ONE * (1.0 + (breathe - 1.0) * 2.0)
	_hero_glow.modulate.a = HERO_GLOW_ALPHA + sin(t * BREATHE_SPEED) * HERO_GLOW_PULSE
	# The orbit follows the Wisp's float but not its sway, so the ring stays level. Both halves run
	# one clock, so a spark leaving the back half reappears exactly where the front half picks it up.
	var ring_centre: Vector2 = centre + Vector2(0.0, _hero_edge * ORBIT_DROP)
	_orbit_back.position = ring_centre
	_orbit_front.position = ring_centre
	_orbit_front.sync_time(_orbit_back.get_time())


## Sizes PLAY's glow and light sweep and the Rift portal icon to their buttons.
func _layout_actions() -> void:
	if not is_node_ready():
		return
	var play_size: Vector2 = _play_button.size
	var glow_size: Vector2 = play_size * PLAY_GLOW_SCALE
	_play_glow.size = glow_size
	_play_glow.position = (play_size - glow_size) * 0.5
	var clip_size: Vector2 = _play_sheen_clip.size
	# Tall enough that the tilted band still spans the clip from top to bottom.
	_play_sheen.size = Vector2(PLAY_SHEEN_WIDTH, clip_size.y * 2.2)
	_play_sheen.pivot_offset = _play_sheen.size * 0.5
	_play_sheen.position.y = (clip_size.y - _play_sheen.size.y) * 0.5
	var rifts_size: Vector2 = _rifts_button.size
	var icon_edge: float = rifts_size.x * RIFT_ICON_SHARE
	_rifts_icon.size = Vector2(icon_edge, icon_edge)
	_rifts_icon.pivot_offset = _rifts_icon.size * 0.5
	_rifts_icon.position = Vector2((rifts_size.x - icon_edge) * 0.5, rifts_size.y * RIFT_ICON_TOP_SHARE)
	_animate_actions()


## PLAY breathing, glow pulse and periodic light sweep, and the turning Rift portal.
##
## At time zero (Reduced Motion) this is the resting pose: no sweep, steady glow, still portal.
func _animate_actions() -> void:
	var t: float = _animation_time
	var wave: float = sin(t * PLAY_BREATHE_SPEED)
	_play_button.pivot_offset = _play_button.size * 0.5
	_play_button.scale = Vector2.ONE * (1.0 + wave * PLAY_BREATHE_AMOUNT) * _play_press_scale
	_play_glow.modulate.a = PLAY_GLOW_ALPHA + wave * PLAY_GLOW_PULSE
	var phase: float = fmod(t, PLAY_SHEEN_PERIOD)
	_play_sheen.visible = not _reduced_motion and phase < PLAY_SHEEN_SWEEP
	if _play_sheen.visible:
		var progress: float = ease(phase / PLAY_SHEEN_SWEEP, -1.8)
		_play_sheen.position.x = lerpf(
			-_play_sheen.size.x * 1.5,
			_play_sheen_clip.size.x + _play_sheen.size.x * 0.5,
			progress,
		)
	_rifts_icon.rotation = t * RIFT_ICON_SPIN
	_rifts_icon.scale = Vector2.ONE * (1.0 + sin(t * RIFT_ICON_PULSE_SPEED) * RIFT_ICON_PULSE)


## A tap on the hero Wisp opens the Shop's WISPS tab; a drag or a cancelled touch does not.
##
## Mouse events only: a touch arrives as an emulated mouse press, so handling both would act twice.
func _on_wisp_preview_gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	_wisp_preview.accept_event()
	if button.pressed:
		_hero_pressed = true
		_hero_press_origin = button.position
		_tween_hero_press(PRESSED_SCALE, 0.06)
		return
	if not _hero_pressed:
		return
	var tapped: bool = (
		not button.canceled
		and button.position.distance_to(_hero_press_origin) <= HERO_TAP_SLOP
		and Rect2(Vector2.ZERO, _wisp_preview.size).has_point(button.position)
	)
	_hero_pressed = false
	_tween_hero_press(1.0, 0.16)
	if tapped:
		SoundFx.play(&"ui_confirm")
		wisps_requested.emit()


## Drops a press in progress without acting on it (focus loss, pause, leaving the tree).
func _cancel_hero_press() -> void:
	if not _hero_pressed:
		return
	_hero_pressed = false
	# A dip still in flight would otherwise finish at the pressed scale and leave the Wisp shrunk.
	if _hero_press_tween != null:
		_hero_press_tween.kill()
	_apply_hero_press(1.0)


## Replaces any press tween still running, so a quick re-press never races an older spring-back.
func _tween_hero_press(target: float, duration: float) -> void:
	if _hero_press_tween != null:
		_hero_press_tween.kill()
	if not is_inside_tree():
		_apply_hero_press(target)
		return
	_hero_press_tween = create_tween()
	_hero_press_tween.tween_method(
		_apply_hero_press, _hero_press_scale, target, duration
	).set_trans(Tween.TRANS_BACK if target >= 1.0 else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _apply_hero_press(value: float) -> void:
	_hero_press_scale = value
	_animate_hero()


## PLAY's own press dip; `pressed` fires before `button_up`, so Home may already be leaving the tree.
func _tween_play_press(target: float, duration: float) -> void:
	if _play_press_tween != null:
		_play_press_tween.kill()
	if not is_inside_tree():
		_play_press_scale = target
		return
	_play_press_tween = create_tween()
	_play_press_tween.tween_method(
		_apply_play_press, _play_press_scale, target, duration
	).set_trans(Tween.TRANS_BACK if target >= 1.0 else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _apply_play_press(value: float) -> void:
	_play_press_scale = value
	_animate_actions()


## Half the preview's on-screen extent per edge unit, with breathing and sway at their peaks.
func _preview_half_share() -> float:
	return 0.5 * (1.0 + BREATHE_AMOUNT) * (cos(SWAY_AMOUNT) + sin(SWAY_AMOUNT))


## Visible glow radius per unit of glow half-size, with the breathing scale at its peak.
func _glow_reach_share() -> float:
	return (1.0 + BREATHE_AMOUNT * 2.0) * GLOW_VISIBLE_SHARE


## Darkens the screen from just above the caption down, so it and PLAY stay legible over the art.
func _layout_bottom_shade(caption_top: float) -> void:
	_bottom_shade.offset_top = -(size.y - maxf(0.0, caption_top - BOTTOM_SHADE_LEAD))


## Adds the device safe-area insets (notch, home indicator) to the base content margins.
func _apply_safe_area() -> void:
	var insets := Vector4.ZERO
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		var safe_area: Rect2i = DisplayServer.get_display_safe_area()
		var window_size: Vector2i = DisplayServer.window_get_size()
		if safe_area.size.x > 0 and safe_area.size.y > 0 and window_size.x > 0 and window_size.y > 0:
			var to_design: Vector2 = size / Vector2(window_size)
			insets = Vector4(
				maxf(0.0, float(safe_area.position.x) * to_design.x),
				maxf(0.0, float(safe_area.position.y) * to_design.y),
				maxf(0.0, float(window_size.x - safe_area.end.x) * to_design.x),
				maxf(0.0, float(window_size.y - safe_area.end.y) * to_design.y),
			)
	_set_margin(&"margin_left", BASE_MARGIN_SIDE + insets.x)
	_set_margin(&"margin_top", BASE_MARGIN_TOP + insets.y)
	_set_margin(&"margin_right", BASE_MARGIN_SIDE + insets.z)
	_set_margin(&"margin_bottom", BASE_MARGIN_BOTTOM + insets.w)


func _set_margin(constant: StringName, value: float) -> void:
	var rounded: int = roundi(value)
	if _content_margin.get_theme_constant(constant) != rounded:
		_content_margin.add_theme_constant_override(constant, rounded)


## Soft radial texture from three colour stops: centre, half radius, edge.
func _radial_texture(stops: Array[Color]) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray(stops)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 128
	texture.height = 128
	return texture


## Horizontal white band that fades out to both sides, for the light sweep across PLAY.
func _sheen_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 4
	return texture


## Vertical void-charcoal fade, transparent at the top and deep at the bottom.
func _bottom_shade_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	# Ramps early, so the caption a little way into the fade already reads over the lit stairs.
	gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	gradient.colors = PackedColorArray([
		Color(Palette.VOID_CHARCOAL, 0.0),
		Color(Palette.VOID_CHARCOAL, 0.62),
		Color(Palette.VOID_CHARCOAL, 0.85),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	texture.width = 4
	texture.height = 128
	return texture


## Formats a count with thousands separators ("12,480") for the tabular value labels.
static func _group_digits(value: int) -> String:
	var digits: String = str(absi(value))
	var grouped: String = ""
	while digits.length() > 3:
		grouped = "," + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + grouped
