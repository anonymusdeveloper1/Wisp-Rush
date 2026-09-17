class_name OrbitMotes
extends Node2D
## Soul sparks circling the Home hero Wisp on tilted ellipses, in the equipped form's colour.
##
## Motes on the far side of the orbit are drawn smaller and fainter than on the near side, so the
## ring reads as circling around the Wisp in depth rather than as a flat halo. For true depth, use two
## instances with the same seed: `side = SIDE_BACK` placed before the Wisp in the tree and `side = SIDE_FRONT`
## after it, so sparks pass behind the body and in front of it. Drawn procedurally, like
## HomeAmbience's motes, so it is deterministic in captures and free of particle setup.

## Which half of the orbit an instance draws: both, only behind the Wisp, or only in front of it.
const SIDE_BOTH: int = 0
const SIDE_BACK: int = 1
const SIDE_FRONT: int = 2

## Number of sparks.
const COUNT: int = 9
## Orbit radii as a fraction of `radius`: horizontal reach and vertical squash of the ellipse.
const ORBIT_SQUASH: float = 0.34
## Angular speed range, radians per second.
const SPEED_MIN: float = 0.55
const SPEED_MAX: float = 1.15
## Per-spark reach range, as a fraction of `radius`.
const REACH_MIN: float = 0.82
const REACH_MAX: float = 1.12
## Largest per-spark vertical bob, as a fraction of its reach, and how strongly the bob is applied.
const RISE_MAX: float = 0.12
const RISE_BOB: float = 0.35
## Spark core size range in pixels on an orbit of UNIT_RADIUS; sparks scale with the orbit.
const SIZE_MIN: float = 6.0
const SIZE_MAX: float = 11.0
const UNIT_RADIUS: float = 180.0
## Size multiplier on the far and near side of the orbit, and the soft halo relative to the core.
const FAR_SIZE: float = 0.55
const NEAR_SIZE: float = 1.15
const HALO_SCALE: float = 2.4

## Horizontal orbit radius in pixels; the Home screen sets it from the hero size.
var radius: float = 180.0:
	set(value):
		radius = maxf(1.0, value)
		queue_redraw()
## Half of the orbit to draw; see the class description.
@export_enum("Both", "Back", "Front") var side: int = SIDE_BOTH
## Spark colour, normally the equipped form's tint.
var tint: Color = Palette.SOUL_CYAN:
	set(value):
		tint = value
		queue_redraw()

var _time: float = 0.0
var _sparks: Array[Dictionary] = []


func _ready() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 19
	for index: int in COUNT:
		_sparks.append({
			&"phase": TAU * float(index) / float(COUNT) + random.randf_range(-0.3, 0.3),
			&"speed": random.randf_range(SPEED_MIN, SPEED_MAX),
			&"reach": random.randf_range(REACH_MIN, REACH_MAX),
			&"rise": random.randf_range(-RISE_MAX, RISE_MAX),
			&"size": random.randf_range(SIZE_MIN, SIZE_MAX),
		})


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## Number of sparks, for tests.
func get_spark_count() -> int:
	return _sparks.size()


## Keeps a paired instance's clock identical, so its sparks line up with this one's.
func sync_time(time: float) -> void:
	_time = time
	queue_redraw()


## Current orbit clock in seconds.
func get_time() -> float:
	return _time


## How far any spark, halo included, can reach from the orbit centre, in multiples of `radius`.
##
## `x` is the reach to either side; `y` is the reach below the centre, on the near side where sparks
## are largest. The Home screen uses it to keep the orbit clear of the buttons around the Wisp.
static func get_extent_ratio() -> Vector2:
	var halo: float = HALO_SCALE * SIZE_MAX * NEAR_SIZE / UNIT_RADIUS
	return Vector2(
		REACH_MAX + halo,
		REACH_MAX * (ORBIT_SQUASH + RISE_MAX * RISE_BOB) + halo,
	)


func _draw() -> void:
	var unit: float = radius / UNIT_RADIUS
	for spark: Dictionary in _sparks:
		var angle: float = float(spark[&"phase"]) + _time * float(spark[&"speed"])
		var reach: float = radius * float(spark[&"reach"])
		# The orbit tilts slightly and each spark bobs, so the ring never looks mechanical.
		var point := Vector2(
			cos(angle) * reach,
			sin(angle) * reach * ORBIT_SQUASH
					+ float(spark[&"rise"]) * reach * RISE_BOB * sin(_time * 0.7 + angle)
		)
		# sin(angle) > 0 is the near side of the orbit (in front of the Wisp, lower on screen).
		var near: bool = sin(angle) > 0.0
		if (side == SIDE_BACK and near) or (side == SIDE_FRONT and not near):
			continue
		var depth: float = (sin(angle) + 1.0) * 0.5
		var size: float = float(spark[&"size"]) * unit * lerpf(FAR_SIZE, NEAR_SIZE, depth)
		var alpha: float = lerpf(0.25, 1.0, depth)
		draw_circle(point, size * HALO_SCALE, Color(tint, 0.24 * alpha))
		draw_circle(point, size, Color(Palette.SOUL_WHITE.lerp(tint, 0.35), 0.9 * alpha))
