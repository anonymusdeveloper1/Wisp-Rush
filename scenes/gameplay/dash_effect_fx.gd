class_name DashEffectFx
extends Node2D
## Draws the equipped character's dash signature: a ribbon along the travel line, a launch flash and
## optional sparks, in the shape its [DashEffectData] asks for.
##
## Every signature is built here in code — a [Line2D] with a generated gradient and width curve,
## pooled [CPUParticles2D] sparks. There is
## no new art and no shader; it shares [VfxPool]'s one additive material so the whole signature
## stays in a single 2D batch.
##
## It is a persistent pool, so it lives as a sibling of `EffectsLayer` next to [VfxPool] and
## [WallSplashFx]; `EffectsLayer` holds only transient per-effect nodes and code counts on that.
## Presentation only: it never reads or writes anything a dash does to the world.

## Ribbons, reused in a flat round-robin. Six covers a twin-arc leg (which takes two) overlapping
## with the two legs before it, which is the most a redirect chain can have fading at once.
const RIBBON_POOL_SIZE: int = 6
## Spark emitters reused round-robin.
const SPARK_POOL_SIZE: int = 3
## Points along a ribbon. The width curve is sampled per point, so too few of them facet the
## taper into visible steps; 24 is smooth at phone scale and still one small array per leg.
const RIBBON_POINTS: int = 24
## Seconds a spark lives.
const SPARK_LIFETIME: float = 0.42
## Spark launch speed range at full momentum, in design px/s.
const SPARK_SPEED_MIN: float = 120.0
const SPARK_SPEED_MAX: float = 460.0
## The spark picture. Untextured CPUParticles2D draw plain squares, which read as dirt rather than
## as light; this is the sparkle the collectibles already use.
const SPARK_TEXTURE: Texture2D = preload("res://assets/art/vfx/12_collectible_sparkle.png")
## Side of that texture, so a spark can be sized in arena pixels rather than in texture multiples.
const SPARK_SOURCE_SIZE: float = 362.0
## Drawn spark size, as a share of the Wisp's collision radius.
const SPARK_SIZE_MIN: float = 0.16
const SPARK_SIZE_MAX: float = 0.42
## Design width every distance above is authored against.
const DESIGN_WIDTH: float = 1080.0
## Reduced Motion keeps the dash readable but calm: a shorter, thinner ribbon and no sparks.
const REDUCED_RIBBON_SECONDS: float = 0.12
const REDUCED_RIBBON_WIDTH: float = 0.55

var _ribbons: Array[Line2D] = []
## Seconds left on each ribbon, and how long its fade was, so `_process` can drive the alpha.
var _ribbon_left: PackedFloat32Array = PackedFloat32Array()
var _ribbon_total: PackedFloat32Array = PackedFloat32Array()
var _ribbon_slot: int = 0
var _sparks: Array[CPUParticles2D] = []
var _spark_slot: int = 0


func _ready() -> void:
	# Absolute z 0 = the VFX pool's depth, so the signature sits with the other dash trails
	# instead of over them. The player root is at absolute 24, so it still draws under the Wisp.
	z_as_relative = false
	z_index = 0
	for index: int in RIBBON_POOL_SIZE:
		var ribbon := _make_ribbon()
		add_child(ribbon)
		_ribbons.append(ribbon)
	_ribbon_left.resize(_ribbons.size())
	_ribbon_total.resize(_ribbons.size())
	for index: int in SPARK_POOL_SIZE:
		var sparks := _make_sparks()
		add_child(sparks)
		_sparks.append(sparks)
	set_process(true)


## Clears every live ribbon and spark, for the run-start hold and for a scene reset.
func clear() -> void:
	for index: int in _ribbons.size():
		_ribbon_left[index] = 0.0
		_ribbons[index].visible = false
	for emitter: CPUParticles2D in _sparks:
		emitter.emitting = false


## Draws one throwaway ribbon and one spark puff off screen, so the first real dash of a run
## does not pay their first-draw cost ([method GameWorld.warm_up_render]).
func warm_up(origin: Vector2) -> void:
	for ribbon: Line2D in _ribbons:
		ribbon.points = PackedVector2Array([origin, origin + Vector2(1.0, 0.0)])
		ribbon.visible = true
		ribbon.modulate = Color(1.0, 1.0, 1.0, 0.0)
	for emitter: CPUParticles2D in _sparks:
		emitter.position = origin
		emitter.amount = 1
		emitter.restart()
		emitter.emitting = true


## Draws one dash leg's signature from [param origin] to [param destination].
##
## [param radius] is the Wisp's collision radius, [param level] its 0..1 momentum (which RUSH pins
## to 1) and [param effect] the equipped character's signature. [param viewport_width] scales the
## authored speeds to the live arena and [param reduced_motion] shortens the ribbon and drops the
## sparks. Does nothing without an effect, so a character that has none keeps the shared
## dash-style trail alone.
func play(
		effect: DashEffectData,
		origin: Vector2,
		destination: Vector2,
		radius: float,
		level: float,
		viewport_width: float,
		reduced_motion: bool,
	) -> void:
	if effect == null or origin.distance_to(destination) < 1.0:
		return
	var viewport_scale: float = maxf(0.1, viewport_width / DESIGN_WIDTH)
	var along: Vector2 = (destination - origin).normalized()
	var across := Vector2(-along.y, along.x)
	var width: float = radius * effect.ribbon_width * lerpf(0.8, 1.35, level)
	var seconds: float = effect.ribbon_seconds
	if reduced_motion:
		width *= REDUCED_RIBBON_WIDTH
		seconds = minf(seconds, REDUCED_RIBBON_SECONDS)
	match effect.signature:
		DashEffectData.Signature.TWIN_ARC:
			var spread: float = radius * effect.arc_spread
			_draw_ribbon(effect, origin, destination, across * spread, width * 0.7, seconds)
			_draw_ribbon(effect, origin, destination, across * -spread, width * 0.7, seconds)
		DashEffectData.Signature.BLADE_ARC:
			_draw_ribbon(effect, origin, destination, Vector2.ZERO, width * 0.55, seconds * 1.25)
		DashEffectData.Signature.SOUL_FLARE:
			_draw_ribbon(effect, origin, destination, Vector2.ZERO, width * 1.2, seconds * 0.75)
		_:
			_draw_ribbon(effect, origin, destination, Vector2.ZERO, width, seconds)
	_throw_sparks(effect, origin, destination, along, radius, level, viewport_scale, reduced_motion)


## Every ribbon this pool owns, for the tests and the QA fixtures.
func get_ribbons() -> Array[Line2D]:
	return _ribbons.duplicate()


## Every spark emitter this pool owns.
func get_emitters() -> Array[CPUParticles2D]:
	return _sparks.duplicate()


func _process(delta: float) -> void:
	for index: int in _ribbons.size():
		if _ribbon_left[index] <= 0.0:
			continue
		_ribbon_left[index] = maxf(0.0, _ribbon_left[index] - delta)
		var ribbon: Line2D = _ribbons[index]
		var share: float = _ribbon_left[index] / maxf(0.01, _ribbon_total[index])
		ribbon.modulate.a = share * share
		if _ribbon_left[index] <= 0.0:
			ribbon.visible = false


## Lays one ribbon along the leg, bowed by [param bow] at its middle so a twin arc reads as two
## blades rather than two parallel lines.
func _draw_ribbon(
		effect: DashEffectData,
		origin: Vector2,
		destination: Vector2,
		bow: Vector2,
		width: float,
		seconds: float,
	) -> void:
	var ribbon: Line2D = _ribbons[_ribbon_slot]
	_ribbon_slot = (_ribbon_slot + 1) % _ribbons.size()
	var points := PackedVector2Array()
	for step: int in RIBBON_POINTS:
		var travel: float = float(step) / float(RIBBON_POINTS - 1)
		# sin gives zero bow at both ends, so the ribbon still starts and lands on the dash line.
		points.append(origin.lerp(destination, travel) + bow * sin(travel * PI))
	ribbon.points = points
	ribbon.width = maxf(1.0, width)
	# A Line2D ignores `default_color` once it has a gradient, so the gradient stays a pure
	# white alpha ramp and `modulate` carries the character's colour and the fade.
	ribbon.modulate = Color(effect.trail_tint.r, effect.trail_tint.g, effect.trail_tint.b, 1.0)
	ribbon.visible = true
	var index: int = _ribbons.find(ribbon)
	_ribbon_left[index] = seconds
	_ribbon_total[index] = seconds


## Throws the signature's sparks. They leave from along the leg, not from one point, so a long dash
## sheds light the whole way instead of puffing once at the launch.
func _throw_sparks(
		effect: DashEffectData,
		origin: Vector2,
		destination: Vector2,
		along: Vector2,
		radius: float,
		level: float,
		viewport_scale: float,
		reduced_motion: bool,
	) -> void:
	if reduced_motion or effect.spark_count <= 0:
		return
	var emitter: CPUParticles2D = _sparks[_spark_slot]
	_spark_slot = (_spark_slot + 1) % _sparks.size()
	var lagging: bool = effect.signature == DashEffectData.Signature.RUNE_WAKE
	var radial: bool = effect.signature == DashEffectData.Signature.SOUL_FLARE
	emitter.position = origin if radial else origin.lerp(destination, 0.45)
	emitter.amount = maxi(1, effect.spark_count)
	emitter.lifetime = SPARK_LIFETIME * (1.35 if lagging else 1.0)
	emitter.color = effect.spark_tint
	emitter.emission_rect_extents = Vector2(
		4.0 if radial else origin.distance_to(destination) * 0.5, radius * 0.5
	)
	# A radial flare throws outward from the launch point; every other signature sheds backwards.
	emitter.direction = Vector2.RIGHT if radial else -along
	emitter.spread = 180.0 if radial else (58.0 if effect.signature
		== DashEffectData.Signature.DUST_WAKE else 26.0)
	emitter.initial_velocity_min = SPARK_SPEED_MIN * viewport_scale * lerpf(0.7, 1.0, level)
	emitter.initial_velocity_max = SPARK_SPEED_MAX * viewport_scale * lerpf(0.7, 1.0, level)
	emitter.scale_amount_min = radius * SPARK_SIZE_MIN / SPARK_SOURCE_SIZE
	emitter.scale_amount_max = radius * SPARK_SIZE_MAX / SPARK_SOURCE_SIZE
	emitter.restart()
	emitter.emitting = true


func _make_ribbon() -> Line2D:
	var ribbon := Line2D.new()
	ribbon.visible = false
	ribbon.joint_mode = Line2D.LINE_JOINT_ROUND
	ribbon.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ribbon.end_cap_mode = Line2D.LINE_CAP_ROUND
	ribbon.antialiased = true
	# The head is thick and the tail thins to nothing, which is what makes it read as a streak.
	var taper := Curve.new()
	taper.add_point(Vector2(0.0, 0.08))
	taper.add_point(Vector2(0.72, 0.85))
	taper.add_point(Vector2(1.0, 1.0))
	ribbon.width_curve = taper
	var fade := Gradient.new()
	fade.set_offset(0, 0.0)
	fade.set_color(0, Color(1.0, 1.0, 1.0, 0.0))
	fade.set_offset(1, 1.0)
	fade.set_color(1, Color(1.0, 1.0, 1.0, 1.0))
	fade.add_point(0.55, Color(1.0, 1.0, 1.0, 0.7))
	ribbon.gradient = fade
	# The one shared additive material: a material per node would break 2D batching.
	ribbon.material = VfxPool.get_additive_material()
	return ribbon


func _make_sparks() -> CPUParticles2D:
	var emitter := CPUParticles2D.new()
	emitter.texture = SPARK_TEXTURE
	emitter.emitting = false
	emitter.one_shot = true
	emitter.explosiveness = 0.9
	emitter.local_coords = false
	emitter.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	emitter.gravity = Vector2.ZERO
	emitter.damping_min = 180.0
	emitter.damping_max = 420.0
	emitter.angle_min = -180.0
	emitter.angle_max = 180.0
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.0))
	emitter.scale_amount_curve = shrink
	var fade := Gradient.new()
	fade.set_offset(0, 0.0)
	fade.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	fade.set_offset(1, 1.0)
	fade.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	emitter.color_ramp = fade
	emitter.material = VfxPool.get_additive_material()
	return emitter
