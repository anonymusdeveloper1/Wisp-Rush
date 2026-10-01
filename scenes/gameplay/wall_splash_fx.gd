class_name WallSplashFx
extends Node2D
## A splash where the Wisp hits a wall: droplets burst off the wall and a splat flattens against it.
## A character whose [DashEffectData] asks for [constant DashEffectData.Landing.DUST] gets the same
## splash made of dust instead (Patchvile, owner 2026-09-24): grains burst off the wall exactly as the
## droplets do, a dust splat flattens against it and a lighter puff marks the contact - normal blend
## in the dust colour, none of the cyan art.
##
## No wall highlight - the effect lives only at the point of impact (owner request). Droplets fan
## out along the inward normal, so they fly back into the floor and never through the wall, which
## keeps the splash reading correctly on the slanted and curved floors of ADR-0011. Emitters are
## pooled, so a fast chain of ricochets never allocates per impact.

## Droplet emitters, used round-robin.
const EMITTER_POOL_SIZE: int = 3
## Droplets per splash at strength 1.
const DROPLETS: int = 26
## Fan width, in degrees, centred on the inward normal. Wide enough that droplets splash out
## sideways along the wall, which is what makes it read as a splash rather than a sparkle.
const SPREAD_DEGREES: float = 124.0
## Seconds a droplet lives.
const DROPLET_LIFETIME: float = 0.46
## Droplet launch speed at strength 1, in design px/s.
const SPEED_MIN: float = 440.0
const SPEED_MAX: float = 1180.0
## Droplet size range at strength 1, in design pixels.
const SIZE_MIN: float = 6.0
const SIZE_MAX: float = 15.0
## The splat is this much wider along the wall than it is deep, so it reads as flattening on impact.
const SPLAT_STRETCH: float = 3.1
## Reduced Motion keeps the impact readable but small and calm.
const REDUCED_DROPLETS: float = 0.4
const REDUCED_SPEED: float = 0.55
## Design width everything above is authored against.
const DESIGN_WIDTH: float = 1080.0
## Source frame size of the pooled VFX sprites.
const VFX_SOURCE_SIZE: float = 362.0
const SPLAT_TEXTURE: Texture2D = preload("res://assets/art/vfx/03_wall_impact_small.png")
## Dust grains are the droplets' size at strength 1 on a soft 16 px dot, so a share of it; they live
## a little longer than droplets, hanging in the air before they settle.
const GRAIN_SIZE_MIN: float = 0.55
const GRAIN_SIZE_MAX: float = 1.15
const GRAIN_LIFETIME: float = 0.55
## Seconds the dust splat and the contact puff take to spread and fade.
const DUST_SPLAT_SECONDS: float = 0.34
const DUST_PUFF_SECONDS: float = 0.2
## Splat sprites in the pool, used round-robin like the emitters.
const DUST_SPLAT_POOL: int = 6
const FLASH_TEXTURE: Texture2D = preload("res://assets/art/vfx/07_enemy_hit.png")

var _emitters: Array[CPUParticles2D] = []
var _next_emitter: int = 0
var _dust_emitters: Array[CPUParticles2D] = []
var _next_dust: int = 0
## Soft dust sprites for the splat and the contact puff, and the shared 64 px puff texture.
var _dust_splats: Array[Sprite2D] = []
var _next_splat: int = 0
var _puff_texture: GradientTexture2D
var _vfx: VfxPool
var _last_origin: Vector2 = Vector2.ZERO


func _ready() -> void:
	for _index: int in EMITTER_POOL_SIZE:
		_emitters.append(_make_emitter())
		_dust_emitters.append(_make_dust_emitter())
	for _index: int in DUST_SPLAT_POOL:
		var splat := Sprite2D.new()
		splat.texture = _soft_dot(64)
		splat.visible = false
		add_child(splat)
		_dust_splats.append(splat)


## Supplies the shared sprite pool used for the splat and the contact flash.
func setup(vfx: VfxPool) -> void:
	_vfx = vfx


## Plays one splash.
##
## [param contact] is the Wisp's centre at impact and [param normal] points into the floor; the
## splash is pushed [param wall_offset] pixels back toward the wall so it lands on the wall surface
## rather than on the Wisp. [param strength] grows with the dash's kills. [param effect] is the
## character's dash effect; its landing style picks splash or dust.
func play(
		contact: Vector2,
		normal: Vector2,
		strength: float,
		tint: Color,
		viewport_width: float,
		reduced_motion: bool,
		wall_offset: float = 0.0,
		effect: DashEffectData = null,
	) -> bool:
	if normal.is_zero_approx():
		return false
	var inward: Vector2 = normal.normalized()
	var scale_factor: float = maxf(0.1, viewport_width / DESIGN_WIDTH)
	var power: float = clampf(strength, 0.5, 3.0)
	var origin: Vector2 = contact - inward * maxf(0.0, wall_offset)
	_last_origin = origin
	if effect != null and effect.landing == DashEffectData.Landing.DUST:
		_play_dust(origin, inward, power, scale_factor, effect.dust_tint, reduced_motion)
		return true
	_play_droplets(origin, inward, power, scale_factor, tint, reduced_motion)
	_play_splat(origin, inward, power, scale_factor, tint, reduced_motion)
	return true


## Where the most recent splash was centred, for tests.
func get_last_origin() -> Vector2:
	return _last_origin


## The droplet emitters, for tests.
func get_emitters() -> Array[CPUParticles2D]:
	return _emitters


## The dust grain emitters, for tests.
func get_dust_emitters() -> Array[CPUParticles2D]:
	return _dust_emitters


func _play_droplets(
		origin: Vector2,
		inward: Vector2,
		power: float,
		scale_factor: float,
		tint: Color,
		reduced_motion: bool,
	) -> void:
	var emitter: CPUParticles2D = _emitters[_next_emitter]
	_next_emitter = (_next_emitter + 1) % EMITTER_POOL_SIZE
	var count_scale: float = REDUCED_DROPLETS if reduced_motion else 1.0
	var speed_scale: float = (REDUCED_SPEED if reduced_motion else 1.0) * scale_factor
	emitter.global_position = origin
	emitter.direction = inward
	emitter.amount = maxi(4, int(round(float(DROPLETS) * clampf(power, 1.0, 2.2) * count_scale)))
	emitter.initial_velocity_min = SPEED_MIN * speed_scale
	emitter.initial_velocity_max = SPEED_MAX * speed_scale * sqrt(power)
	# High damping: droplets burst out fast, then hang and fade instead of drifting away.
	emitter.damping_min = 900.0 * scale_factor
	emitter.damping_max = 1450.0 * scale_factor
	emitter.scale_amount_min = SIZE_MIN * scale_factor
	emitter.scale_amount_max = SIZE_MAX * scale_factor * sqrt(power)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(Palette.SOUL_WHITE, 1.0))
	ramp.set_color(1, Color(tint, 0.0))
	ramp.add_point(0.3, Color(tint, 1.0))
	emitter.color_ramp = ramp
	emitter.restart()
	emitter.emitting = true


func _play_splat(
		origin: Vector2,
		inward: Vector2,
		power: float,
		scale_factor: float,
		tint: Color,
		reduced_motion: bool,
	) -> void:
	if _vfx == null:
		return
	var size: float = 220.0 * scale_factor * sqrt(power) * (0.6 if reduced_motion else 1.0)
	var unit: float = size / VFX_SOURCE_SIZE
	# Rotated so its long axis lies along the wall: grows wide across the surface, stays shallow.
	var along_wall: float = inward.angle() + PI * 0.5
	_vfx.play(
		SPLAT_TEXTURE,
		origin,
		along_wall,
		Vector2(unit * 0.8, unit * 0.5),
		Vector2(unit * SPLAT_STRETCH, unit * 0.9),
		0.26,
		Color(tint, 0.55 if reduced_motion else 0.95),
	)
	_vfx.play(
		FLASH_TEXTURE,
		origin + inward * size * 0.15,
		0.0,
		Vector2.ONE * unit * 0.4,
		Vector2.ONE * unit * 1.1,
		0.16,
		Color(Palette.SOUL_WHITE, 0.45 if reduced_motion else 0.85),
	)


## The splash in dust: grains fanned off the wall like the droplets, then the splat and the puff.
func _play_dust(
		origin: Vector2,
		inward: Vector2,
		power: float,
		scale_factor: float,
		tint: Color,
		reduced_motion: bool,
	) -> void:
	var grains: CPUParticles2D = _dust_emitters[_next_dust]
	_next_dust = (_next_dust + 1) % EMITTER_POOL_SIZE
	var count_scale: float = REDUCED_DROPLETS if reduced_motion else 1.0
	var speed_scale: float = (REDUCED_SPEED if reduced_motion else 1.0) * scale_factor
	grains.global_position = origin
	grains.direction = inward
	grains.amount = maxi(4, int(round(float(DROPLETS) * clampf(power, 1.0, 2.2) * count_scale)))
	grains.initial_velocity_min = SPEED_MIN * speed_scale
	grains.initial_velocity_max = SPEED_MAX * speed_scale * sqrt(power)
	grains.damping_min = 900.0 * scale_factor
	grains.damping_max = 1450.0 * scale_factor
	grains.scale_amount_min = GRAIN_SIZE_MIN * scale_factor
	grains.scale_amount_max = GRAIN_SIZE_MAX * scale_factor * sqrt(power)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(tint.lightened(0.25), 0.95))
	ramp.set_color(1, Color(tint.darkened(0.2), 0.0))
	ramp.add_point(0.3, Color(tint, 0.85))
	grains.color_ramp = ramp
	grains.restart()
	grains.emitting = true
	var size: float = 220.0 * scale_factor * sqrt(power) * (0.6 if reduced_motion else 1.0)
	var unit: float = size / 64.0
	# The splat lies along the wall like the splash's: grows wide across the surface, stays shallow.
	_play_dust_sprite(
		origin, inward.angle() + PI * 0.5, Vector2(unit * 0.8, unit * 0.5),
		Vector2(unit * SPLAT_STRETCH, unit * 0.9), DUST_SPLAT_SECONDS,
		Color(tint, 0.5 if reduced_motion else 0.85),
	)
	_play_dust_sprite(
		origin + inward * size * 0.15, 0.0, Vector2.ONE * unit * 0.4, Vector2.ONE * unit * 1.1,
		DUST_PUFF_SECONDS, Color(tint.lightened(0.35), 0.45 if reduced_motion else 0.8),
	)


## One pooled dust sprite: grows from [param from_scale] to [param to_scale] while it fades.
func _play_dust_sprite(
		origin: Vector2,
		rotation_radians: float,
		from_scale: Vector2,
		to_scale: Vector2,
		seconds: float,
		colour: Color,
	) -> void:
	var splat: Sprite2D = _dust_splats[_next_splat]
	_next_splat = (_next_splat + 1) % _dust_splats.size()
	splat.global_position = origin
	splat.rotation = rotation_radians
	splat.scale = from_scale
	splat.modulate = colour
	splat.visible = true
	var tween: Tween = splat.create_tween().set_parallel()
	tween.tween_property(splat, ^"scale", to_scale, seconds).set_ease(Tween.EASE_OUT) \
		.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(splat, ^"modulate:a", 0.0, seconds).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(func() -> void: splat.visible = false)


func _make_dust_emitter() -> CPUParticles2D:
	var emitter := CPUParticles2D.new()
	emitter.emitting = false
	emitter.one_shot = true
	emitter.explosiveness = 0.95
	emitter.lifetime = GRAIN_LIFETIME
	emitter.spread = SPREAD_DEGREES
	emitter.gravity = Vector2.ZERO
	emitter.local_coords = false
	emitter.texture = _soft_dot(16)
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.35))
	emitter.scale_amount_curve = shrink
	add_child(emitter)
	return emitter


## A white radial dot fading to clear, [param size] px across; the 64 px one is shared.
func _soft_dot(size: int) -> GradientTexture2D:
	if size == 64 and _puff_texture != null:
		return _puff_texture
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var dot := GradientTexture2D.new()
	dot.gradient = gradient
	dot.width = size
	dot.height = size
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(1.0, 0.5)
	if size == 64:
		_puff_texture = dot
	return dot


func _make_emitter() -> CPUParticles2D:
	var emitter := CPUParticles2D.new()
	emitter.emitting = false
	emitter.one_shot = true
	emitter.explosiveness = 0.95
	emitter.lifetime = DROPLET_LIFETIME
	emitter.spread = SPREAD_DEGREES
	emitter.gravity = Vector2.ZERO
	# Droplets must stay where they were thrown, not follow the emitter to the next impact.
	emitter.local_coords = false
	# Shrink over life so droplets read as splash, not as floating dots.
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.15))
	emitter.scale_amount_curve = shrink
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	emitter.material = additive
	add_child(emitter)
	return emitter
