class_name HomeAmbience
extends Control
## Living background for the Home screen: flickering braziers, pulsing runes, drifting mist and
## slow rising soul motes, all anchored to the features painted into home_background.png.
##
## The art itself never changes; this layer only adds light and motion over it. Every glow is
## placed in background-texture UV space and mapped through the same cover-scale the backdrop's
## TextureRect uses, so it stays on its brazier or rune at every phone aspect ratio.
## Reduced Motion freezes all of it at a calm, readable steady state.

## Painted features in home_background.png, as texture UV (measured from the art).
const BRAZIER_UVS: Array[Vector2] = [Vector2(0.183, 0.491), Vector2(0.881, 0.566)]
const RUNE_UVS: Array[Vector2] = [Vector2(0.149, 0.365), Vector2(0.915, 0.385)]
const PEDESTAL_UV := Vector2(0.524, 0.573)
## Glow radii in background-texture pixels, before cover scaling.
const BRAZIER_RADIUS: float = 95.0
const RUNE_RADIUS: float = 58.0
const PEDESTAL_RADIUS := Vector2(230.0, 95.0)
## Warm light for the braziers, cool light for the runes (STYLE_GUIDE information colours).
const BRAZIER_COLOR: Color = Palette.WARNING_AMBER
const RUNE_COLOR: Color = Palette.SOUL_CYAN
## Steady-state glow alphas, used as-is under Reduced Motion and as the base of the animation.
const BRAZIER_ALPHA: float = 0.42
const RUNE_ALPHA: float = 0.28
const PEDESTAL_ALPHA: float = 0.22
## Rising motes.
const MOTE_COUNT: int = 26
const MOTE_SPEED_MIN: float = 28.0
const MOTE_SPEED_MAX: float = 74.0
const MOTE_SIZE_MIN: float = 2.5
const MOTE_SIZE_MAX: float = 6.0
## Mist patches: size in design pixels, peak alpha, and drift.
const MIST_SIZE := Vector2(980.0, 460.0)
const MIST_ALPHA: float = 0.11
const MIST_DRIFT: float = 70.0
## Design width the pixel values above are authored against.
const DESIGN_WIDTH: float = 1080.0

## Background texture the glows are anchored to. Set by the Home screen.
var background: Texture2D:
	set(value):
		background = value
		_layout()

var _active: bool = true
var _time: float = 0.0
var _noise := FastNoiseLite.new()
var _glow_texture: GradientTexture2D
var _brazier_glows: Array[TextureRect] = []
var _rune_glows: Array[TextureRect] = []
var _pedestal_glow: TextureRect
var _mists: Array[TextureRect] = []
var _motes: MoteField


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_noise.seed = 41
	_noise.frequency = 1.6
	_glow_texture = _radial_texture()
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for _mist: int in 2:
		_mists.append(_make_glow(Color(Palette.SOUL_WHITE.lerp(Palette.SLATE_TEAL, 0.5), 1.0), null))
	_pedestal_glow = _make_glow(RUNE_COLOR, additive)
	for _rune: int in RUNE_UVS.size():
		_rune_glows.append(_make_glow(RUNE_COLOR, additive))
	for _brazier: int in BRAZIER_UVS.size():
		_brazier_glows.append(_make_glow(BRAZIER_COLOR, additive))
	_motes = MoteField.new()
	_motes.material = additive
	add_child(_motes)
	resized.connect(_layout)
	_layout()
	_apply_state(0.0)


func _process(delta: float) -> void:
	_time += delta
	_apply_state(delta)


## Turns the motion on or off. Off holds every light at its steady state and hides the motes.
func set_active(active: bool) -> void:
	_active = active
	_motes.visible = active
	for mist: TextureRect in _mists:
		mist.visible = active
	set_process(active)
	_apply_state(0.0)


## Whether the ambience is animating (false under Reduced Motion).
func is_active() -> bool:
	return _active


## Screen position of a background UV point under the current cover scaling.
func uv_to_local(uv: Vector2) -> Vector2:
	var image: Rect2 = _image_rect()
	return image.position + image.size * uv


## Current cover scale from background-texture pixels to screen pixels.
func get_cover_scale() -> float:
	if background == null:
		return 1.0
	var texture_size: Vector2 = background.get_size()
	return maxf(size.x / texture_size.x, size.y / texture_size.y)


func _apply_state(delta: float) -> void:
	for index: int in _brazier_glows.size():
		var flicker: float = 0.0
		if _active:
			# Two noise octaves at different rates read as fire rather than as a sine pulse.
			flicker = _noise.get_noise_2d(_time * 3.1, float(index) * 40.0) * 0.55 \
				+ _noise.get_noise_2d(_time * 9.0, float(index) * 40.0 + 7.0) * 0.25
		var glow: TextureRect = _brazier_glows[index]
		glow.modulate.a = clampf(BRAZIER_ALPHA * (1.0 + flicker), 0.1, 0.8)
		glow.scale = Vector2.ONE * (1.0 + flicker * 0.12)
	for index: int in _rune_glows.size():
		var pulse: float = sin(_time * 1.3 + float(index) * 2.1) if _active else 0.0
		_rune_glows[index].modulate.a = RUNE_ALPHA * (1.0 + pulse * 0.55)
	var breathe: float = sin(_time * 0.9) if _active else 0.0
	_pedestal_glow.modulate.a = PEDESTAL_ALPHA * (1.0 + breathe * 0.4)
	if _active:
		var unit: float = size.x / DESIGN_WIDTH
		for index: int in _mists.size():
			var mist: TextureRect = _mists[index]
			var phase: float = _time * (0.07 + 0.03 * float(index)) + float(index) * 2.4
			var base: Vector2 = mist.get_meta(&"base", mist.position)
			mist.position = base + Vector2(sin(phase) * MIST_DRIFT, cos(phase * 0.7) * 18.0) * unit
			mist.modulate.a = MIST_ALPHA * (0.75 + 0.25 * sin(phase * 1.3))
		_motes.advance(delta)


func _layout() -> void:
	if not is_node_ready() or background == null or size.x <= 0.0:
		return
	var cover: float = get_cover_scale()
	_place(_pedestal_glow, uv_to_local(PEDESTAL_UV), PEDESTAL_RADIUS * cover)
	for index: int in _rune_glows.size():
		_place(_rune_glows[index], uv_to_local(RUNE_UVS[index]), Vector2.ONE * RUNE_RADIUS * cover)
	for index: int in _brazier_glows.size():
		# Centred a little above the flame so the light blooms up the stone, as fire does.
		var point: Vector2 = uv_to_local(BRAZIER_UVS[index]) - Vector2(0.0, BRAZIER_RADIUS * cover * 0.2)
		_place(_brazier_glows[index], point, Vector2.ONE * BRAZIER_RADIUS * cover)
	var unit: float = size.x / DESIGN_WIDTH
	var mist_centres: Array[Vector2] = [
		Vector2(size.x * 0.32, size.y * 0.58),
		Vector2(size.x * 0.72, size.y * 0.70),
	]
	for index: int in _mists.size():
		_place(_mists[index], mist_centres[index], MIST_SIZE * 0.5 * unit)
		_mists[index].set_meta(&"base", _mists[index].position)
	_motes.configure(size, unit)


func _place(glow: TextureRect, centre: Vector2, radius: Vector2) -> void:
	glow.size = radius * 2.0
	glow.pivot_offset = radius
	glow.position = centre - radius


func _image_rect() -> Rect2:
	if background == null:
		return Rect2(Vector2.ZERO, size)
	var image_size: Vector2 = background.get_size() * get_cover_scale()
	return Rect2((size - image_size) * 0.5, image_size)


func _make_glow(colour: Color, material: Material) -> TextureRect:
	var glow := TextureRect.new()
	glow.texture = _glow_texture
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.self_modulate = Color(colour, 1.0)
	if material != null:
		glow.material = material
	add_child(glow)
	return glow


func _radial_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 128
	texture.height = 128
	return texture


## Slow soul motes rising across the whole screen. Drawn procedurally: no particle system, so it
## behaves identically in headless captures and costs one draw call.
class MoteField extends Node2D:
	var _motes: Array[Dictionary] = []
	var _area: Vector2 = Vector2.ZERO
	var _unit: float = 1.0
	var _random := RandomNumberGenerator.new()

	## Sizes the field. Any change of area respawns every mote (same seed, so captures stay
	## deterministic): old motes would sit outside a narrower screen or start below a shorter one.
	func configure(area: Vector2, unit: float) -> void:
		var changed: bool = not _area.is_equal_approx(area)
		_area = area
		_unit = unit
		if changed:
			_random.seed = 7
			_motes.clear()
			for index: int in HomeAmbience.MOTE_COUNT:
				_motes.append(_spawn(true))
		queue_redraw()

	func get_mote_count() -> int:
		return _motes.size()

	func advance(delta: float) -> void:
		for index: int in _motes.size():
			var mote: Dictionary = _motes[index]
			mote[&"age"] = float(mote[&"age"]) + delta
			if float(mote[&"age"]) >= float(mote[&"life"]):
				_motes[index] = _spawn(false)
		queue_redraw()

	func _spawn(scatter: bool) -> Dictionary:
		var life: float = _random.randf_range(6.0, 13.0)
		return {
			&"x": _random.randf_range(0.0, _area.x),
			&"y": _area.y * _random.randf_range(0.55, 1.05),
			&"speed": _random.randf_range(HomeAmbience.MOTE_SPEED_MIN, HomeAmbience.MOTE_SPEED_MAX),
			&"size": _random.randf_range(HomeAmbience.MOTE_SIZE_MIN, HomeAmbience.MOTE_SIZE_MAX),
			&"phase": _random.randf_range(0.0, TAU),
			&"life": life,
			&"age": _random.randf_range(0.0, life) if scatter else 0.0,
		}

	func _draw() -> void:
		for mote: Dictionary in _motes:
			var age: float = float(mote[&"age"])
			var life: float = float(mote[&"life"])
			var t: float = age / life
			var fade: float = smoothstep(0.0, 0.18, t) * (1.0 - smoothstep(0.7, 1.0, t))
			var y: float = float(mote[&"y"]) - float(mote[&"speed"]) * _unit * age
			var x: float = float(mote[&"x"]) + sin(age * 0.8 + float(mote[&"phase"])) * 22.0 * _unit
			var radius: float = float(mote[&"size"]) * _unit
			draw_circle(Vector2(x, y), radius * 3.0, Color(Palette.SOUL_CYAN, 0.10 * fade))
			draw_circle(Vector2(x, y), radius, Color(Palette.SOUL_WHITE, 0.75 * fade))
