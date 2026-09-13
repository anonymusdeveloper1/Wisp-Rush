class_name HomeScreen
extends Control
## Home: a calm top bar, the wordmark, a living hero Wisp, one PLAY and a bottom navigation dock.
##
## Minimal, Material-inspired structure in the stone-and-cyan style (owner request 2026-09-13):
## one dominant action, everything else one thumb-tap away in a bottom navigation bar, no stack of
## competing buttons. The screen feels alive through three layers of motion - the equipped Wisp
## floats, breathes and sways with a pulsing glow, soul sparks orbit it, and HomeAmbience adds
## brazier flicker, rune pulses, drifting mist and rising motes over the painted backdrop.
## Reduced Motion stills all of it. All styling comes from theme type variations and Palette.

## Emitted when the primary Play button is activated.
signal play_requested
## Emitted when the player opens the cosmetic collection.
signal forms_requested
## Emitted when the player opens today's deterministic Rift.
signal daily_requested
## The player asked to open the Rift map to pick an arena.
signal rift_map_requested
## The player asked to open the Soul Sanctum.
signal sanctum_requested
## The player asked to open the Trials ladder.
signal trials_requested
## Emitted when the player opens lifetime statistics.
signal statistics_requested
## Emitted when the player opens Settings.
signal settings_requested

## Centre of the Wisp painted into home_background.png, as a fraction of the texture size.
const PAINTED_WISP_CENTER := Vector2(0.49, 0.466)
## Hero preview edge in background-texture pixels (covers the painted Wisp and its flame).
const PAINTED_WISP_SIZE := 400.0
## Size of the dark pocket behind the preview, relative to the preview edge.
const HERO_POCKET_SCALE := 1.35
## Pocket opacity at its centre and at half its radius (fades to 0 at the edge).
const POCKET_CORE_ALPHA := 0.62
const POCKET_MID_ALPHA := 0.38
## Hero glow: size relative to the preview edge, and its steady and pulsing alpha.
const HERO_GLOW_SCALE := 1.9
const HERO_GLOW_ALPHA := 0.5
const HERO_GLOW_PULSE := 0.16
## Hero motion. Float is a fraction of the preview edge; breathe is scale; sway is radians.
const FLOAT_AMOUNT := 0.035
const FLOAT_SPEED := 1.55
const BREATHE_AMOUNT := 0.03
const BREATHE_SPEED := 2.3
const SWAY_AMOUNT := 0.035
const SWAY_SPEED := 1.05
## Orbit radius relative to the preview edge, and how far below the Wisp's centre the ring sits.
## Lowered and widened so the front arc passes beneath the body instead of across the face.
const ORBIT_SCALE := 0.74
const ORBIT_DROP := 0.2
## Height of the darkening gradient behind the PLAY button and nav dock, as a fraction of the screen.
const BOTTOM_SHADE_SHARE := 0.4
## Screen margins in the 1080-wide design space before the device safe area is added.
const BASE_MARGIN_SIDE := 36.0
const BASE_MARGIN_TOP := 40.0
const BASE_MARGIN_BOTTOM := 32.0

## Ordered Rift registry, used to name the Rift PLAY will enter.
@export var rift_catalog: RiftCatalog

var _animation_time: float = 0.0
var _best_score: int = 0
var _soul_shards: int = 0
var _reduced_motion: bool = false
var _equipped_texture: Texture2D = null
var _equipped_tint: Color = Palette.SOUL_CYAN
var _rift_id: StringName = RiftCatalog.DEFAULT_RIFT_ID
var _rift_level: int = 1
var _hero_rest: Vector2 = Vector2.ZERO
var _hero_edge: float = 0.0

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
@onready var _rift_caption: Label = %RiftCaption
@onready var _play_button: Button = %PlayButton
@onready var _rifts_nav: Button = %RiftsNav
@onready var _forms_nav: Button = %FormsNav
@onready var _sanctum_nav: Button = %SanctumNav
@onready var _trials_nav: Button = %TrialsNav
@onready var _daily_nav: Button = %DailyNav
@onready var _stats_button: Button = %StatsButton
@onready var _settings_button: Button = %SettingsButton
@onready var _best_label: Label = %BestLabel
@onready var _shards_label: Label = %ShardsLabel


func _ready() -> void:
	var pocket_stops: Array[Color] = [
		Color(Palette.VOID_CHARCOAL, POCKET_CORE_ALPHA),
		Color(Palette.VOID_CHARCOAL, POCKET_MID_ALPHA),
		Color(Palette.VOID_CHARCOAL, 0.0),
	]
	_hero_pocket.texture = _radial_texture(pocket_stops)
	var glow_stops: Array[Color] = [Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)]
	_hero_glow.texture = _radial_texture(glow_stops)
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_hero_glow.material = additive
	for orbit: OrbitMotes in [_orbit_back, _orbit_front]:
		orbit.material = additive
	_bottom_shade.texture = _bottom_shade_texture()
	_ambience.background = _background.texture
	_play_button.pressed.connect(func() -> void: play_requested.emit())
	_rifts_nav.pressed.connect(func() -> void: rift_map_requested.emit())
	_forms_nav.pressed.connect(func() -> void: forms_requested.emit())
	_sanctum_nav.pressed.connect(func() -> void: sanctum_requested.emit())
	_trials_nav.pressed.connect(func() -> void: trials_requested.emit())
	_daily_nav.pressed.connect(func() -> void: daily_requested.emit())
	_stats_button.pressed.connect(func() -> void: statistics_requested.emit())
	_settings_button.pressed.connect(func() -> void: settings_requested.emit())
	_hero_area.item_rect_changed.connect(_layout_hero)
	_apply_safe_area()
	_layout_bottom_shade()
	_refresh()
	_play_button.grab_focus()
	_layout_hero.call_deferred()
	print("[Home] ready")


func _process(delta: float) -> void:
	_animation_time += delta
	_animate_hero()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_safe_area()
		_layout_bottom_shade()
		_layout_hero()


## Refreshes the profile summary, the equipped form and the Rift PLAY will enter.
func setup(snapshot: Dictionary, equipped_form: FormData) -> void:
	_best_score = int(snapshot.get(&"best_score", 0))
	_soul_shards = int(snapshot.get(&"soul_shards", 0))
	var settings: Variant = snapshot.get(&"settings", {})
	if settings is Dictionary:
		_reduced_motion = bool((settings as Dictionary).get(&"reduced_motion", false))
	if equipped_form != null:
		_equipped_texture = equipped_form.texture
		_equipped_tint = equipped_form.tint
	var stored_rift: String = str(snapshot.get(&"selected_rift", ""))
	_rift_id = StringName(stored_rift) if not stored_rift.is_empty() else RiftCatalog.DEFAULT_RIFT_ID
	var levels: Variant = snapshot.get(&"rift_levels", {})
	var cleared: int = int((levels as Dictionary).get(String(_rift_id), 0)) if levels is Dictionary else 0
	_rift_level = cleared + 1
	if is_node_ready():
		_refresh()


## The two halves of the hero orbit, for tests.
func get_orbits() -> Array[OrbitMotes]:
	return [_orbit_back, _orbit_front]


## Whether the hero and background are animating (false under Reduced Motion).
func is_animating() -> bool:
	return is_processing() and _ambience.is_active()


## Text currently shown above PLAY, for tests.
func get_rift_caption() -> String:
	return _rift_caption.text


func _refresh() -> void:
	if _equipped_texture != null:
		_wisp_preview.texture = _equipped_texture
	_best_label.text = _group_digits(_best_score)
	_shards_label.text = _group_digits(_soul_shards)
	_hero_glow.self_modulate = Color(_equipped_tint, 1.0)
	for orbit: OrbitMotes in [_orbit_back, _orbit_front]:
		orbit.tint = _equipped_tint
	_rift_caption.text = _describe_rift()
	# Reduced Motion stills the hero, the orbit and the living background (style guide).
	set_process(not _reduced_motion)
	for orbit: OrbitMotes in [_orbit_back, _orbit_front]:
		orbit.set_process(not _reduced_motion)
		orbit.visible = not _reduced_motion
	_ambience.set_active(not _reduced_motion)
	_animation_time = 0.0
	_animate_hero()


func _describe_rift() -> String:
	if rift_catalog == null:
		return ""
	var rift: RiftData = rift_catalog.get_rift(_rift_id)
	var level: int = clampi(_rift_level, 1, rift.level_count)
	if _rift_level > rift.level_count:
		return "%s  •  ENDLESS" % rift.display_name
	return "%s  •  LEVEL %d" % [rift.display_name, level]


## Places the preview over the painted Wisp of the cover-scaled background, inside HeroArea.
func _layout_hero() -> void:
	if _background.texture == null:
		return
	var texture_size: Vector2 = _background.texture.get_size()
	var cover: float = maxf(size.x / texture_size.x, size.y / texture_size.y)
	var image_size: Vector2 = texture_size * cover
	var image_origin: Vector2 = (size - image_size) * 0.5
	var painted_center: Vector2 = image_origin + image_size * PAINTED_WISP_CENTER
	var area_origin: Vector2 = _hero_area.global_position - global_position
	var area_size: Vector2 = _hero_area.size
	# Leave headroom for the float so the Wisp never drifts out of its area.
	var usable: Vector2 = area_size * Vector2(1.0, 1.0 - FLOAT_AMOUNT * 2.4)
	var edge: float = minf(PAINTED_WISP_SIZE * cover, minf(usable.x, usable.y))
	if edge <= 0.0:
		return
	var preview_size := Vector2(edge, edge)
	var center: Vector2 = (painted_center - area_origin).clamp(
		preview_size * 0.5,
		area_size - preview_size * 0.5,
	)
	_hero_edge = edge
	_hero_rest = center
	_wisp_preview.size = preview_size
	_wisp_preview.pivot_offset = preview_size * 0.5
	var pocket_size: Vector2 = preview_size * HERO_POCKET_SCALE
	_hero_pocket.size = pocket_size
	_hero_pocket.position = center - pocket_size * 0.5
	var glow_size: Vector2 = preview_size * HERO_GLOW_SCALE
	_hero_glow.size = glow_size
	_hero_glow.pivot_offset = glow_size * 0.5
	for orbit: OrbitMotes in [_orbit_back, _orbit_front]:
		orbit.radius = edge * ORBIT_SCALE
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
	_wisp_preview.scale = Vector2.ONE * breathe
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


## Darkens the lower screen so PLAY and the nav dock stay legible over the painted stairs.
func _layout_bottom_shade() -> void:
	_bottom_shade.offset_top = -size.y * BOTTOM_SHADE_SHARE


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


## Vertical void-charcoal fade, transparent at the top and deep at the bottom.
func _bottom_shade_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	gradient.colors = PackedColorArray([
		Color(Palette.VOID_CHARCOAL, 0.0),
		Color(Palette.VOID_CHARCOAL, 0.55),
		Color(Palette.VOID_CHARCOAL, 0.82),
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
