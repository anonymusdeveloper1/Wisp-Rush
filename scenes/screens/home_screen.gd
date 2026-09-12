class_name HomeScreen
extends Control
## Redesign v1 Home: profile strip, wordmark, equipped-form hero, Play, Forms and Daily Rift.
##
## Layout follows board panel 1 of concept_art/wisp_rush_redesign_v1 (compact shards/best strip
## with Stats and Settings icon buttons, wordmark high in the title-safe area, the equipped form
## as the hero, one dominant Play button, then Forms and Daily). All styling comes from the project
## theme (type variations); the only colours set in code come from Palette.
## The hero preview is placed over the Wisp painted into home_background.png so the equipped form
## floats above the painted glowing pedestal on every phone aspect ratio. It is clamped inside the
## free HeroArea between the wordmark and Play, and a soft void pocket behind it mutes the painted
## Wisp so every form reads cleanly. Margins grow by the device safe area on Android/iOS.

## Emitted when the primary Play button is activated.
signal play_requested
## Emitted when the player opens the cosmetic collection.
signal forms_requested
## Emitted when the player opens today's deterministic Rift.
signal daily_requested
## Emitted when the player opens lifetime statistics.
signal statistics_requested
## Emitted when the player opens Settings.
signal settings_requested

## Centre of the Wisp painted into home_background.png, as a fraction of the texture size.
const PAINTED_WISP_CENTER := Vector2(0.49, 0.466)
## Hero preview edge in background-texture pixels (covers the painted Wisp and its flame).
const PAINTED_WISP_SIZE := 380.0
## Size of the dark pocket behind the preview, relative to the preview edge.
const HERO_POCKET_SCALE := 1.35
## Pocket opacity at its centre and at half its radius (fades to 0 at the edge).
const POCKET_CORE_ALPHA := 0.62
const POCKET_MID_ALPHA := 0.38
## Idle breathing scale amplitude (style guide: 2-3 %) and angular sway, with their speeds.
const PULSE_AMPLITUDE := 0.025
const PULSE_SPEED := 2.6
const SWAY_AMPLITUDE := 0.025
const SWAY_SPEED := 1.3
## Screen margins in the 1080-wide design space before the device safe area is added.
const BASE_MARGIN_SIDE := 40.0
const BASE_MARGIN_TOP := 44.0
const BASE_MARGIN_BOTTOM := 44.0

var _animation_time: float = 0.0
var _best_score: int = 0
var _soul_shards: int = 0
var _reduced_motion: bool = false
var _equipped_texture: Texture2D = null

@onready var _background: TextureRect = %Background
@onready var _content_margin: MarginContainer = %ContentMargin
@onready var _hero_area: Control = %HeroArea
@onready var _hero_pocket: TextureRect = %HeroPocket
@onready var _wisp_preview: TextureRect = %WispPreview
@onready var _play_button: Button = %PlayButton
@onready var _forms_button: Button = %FormsButton
@onready var _daily_button: Button = %DailyButton
@onready var _stats_button: Button = %StatsButton
@onready var _settings_button: Button = %SettingsButton
@onready var _best_label: Label = %BestLabel
@onready var _shards_label: Label = %ShardsLabel
@onready var _footer_label: Label = %Footer


func _ready() -> void:
	_footer_label.text = "WISP RUSH  •  v%s" % ProjectSettings.get_setting(
		"application/config/version",
		"0.1.0",
	)
	_hero_pocket.texture = _build_pocket_texture()
	_play_button.pressed.connect(_on_play_button_pressed)
	_forms_button.pressed.connect(func() -> void: forms_requested.emit())
	_daily_button.pressed.connect(func() -> void: daily_requested.emit())
	_stats_button.pressed.connect(func() -> void: statistics_requested.emit())
	_settings_button.pressed.connect(func() -> void: settings_requested.emit())
	_hero_area.item_rect_changed.connect(_layout_hero)
	_apply_safe_area()
	_refresh()
	_play_button.grab_focus()
	_layout_hero.call_deferred()
	print("[Home] ready")


func _process(delta: float) -> void:
	_animation_time += delta
	var pulse: float = 1.0 + sin(_animation_time * PULSE_SPEED) * PULSE_AMPLITUDE
	_wisp_preview.scale = Vector2.ONE * pulse
	_wisp_preview.rotation = sin(_animation_time * SWAY_SPEED) * SWAY_AMPLITUDE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_safe_area()
		_layout_hero()


## Refreshes the persistent profile summary and equipped form preview.
func setup(snapshot: Dictionary, equipped_form: FormData) -> void:
	_best_score = int(snapshot.get(&"best_score", 0))
	_soul_shards = int(snapshot.get(&"soul_shards", 0))
	var settings: Variant = snapshot.get(&"settings", {})
	if settings is Dictionary:
		_reduced_motion = bool((settings as Dictionary).get(&"reduced_motion", false))
	if equipped_form != null:
		_equipped_texture = equipped_form.texture
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if _equipped_texture != null:
		_wisp_preview.texture = _equipped_texture
	_best_label.text = _group_digits(_best_score)
	_shards_label.text = _group_digits(_soul_shards)
	# Reduced motion removes the repeated pulse (style guide, motion principles).
	set_process(not _reduced_motion)
	if _reduced_motion:
		_wisp_preview.scale = Vector2.ONE
		_wisp_preview.rotation = 0.0


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
	var edge: float = minf(PAINTED_WISP_SIZE * cover, minf(area_size.x, area_size.y))
	if edge <= 0.0:
		return
	var preview_size := Vector2(edge, edge)
	var center: Vector2 = (painted_center - area_origin).clamp(
		preview_size * 0.5,
		area_size - preview_size * 0.5,
	)
	_wisp_preview.size = preview_size
	_wisp_preview.position = center - preview_size * 0.5
	_wisp_preview.pivot_offset = preview_size * 0.5
	var pocket_size: Vector2 = preview_size * HERO_POCKET_SCALE
	_hero_pocket.size = pocket_size
	_hero_pocket.position = center - pocket_size * 0.5


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


## Soft radial void-charcoal pocket that mutes the painted Wisp behind the equipped form.
func _build_pocket_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([
		Color(Palette.VOID_CHARCOAL, POCKET_CORE_ALPHA),
		Color(Palette.VOID_CHARCOAL, POCKET_MID_ALPHA),
		Color(Palette.VOID_CHARCOAL, 0.0),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 128
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


func _on_play_button_pressed() -> void:
	play_requested.emit()
