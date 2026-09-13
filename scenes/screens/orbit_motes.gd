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
			&"reach": random.randf_range(0.82, 1.12),
			&"rise": random.randf_range(-0.12, 0.12),
			&"size": random.randf_range(6.0, 11.0),
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


func _draw() -> void:
	var unit: float = radius / 180.0
	for spark: Dictionary in _sparks:
		var angle: float = float(spark[&"phase"]) + _time * float(spark[&"speed"])
		var reach: float = radius * float(spark[&"reach"])
		# The orbit tilts slightly and each spark bobs, so the ring never looks mechanical.
		var point := Vector2(
			cos(angle) * reach,
			sin(angle) * reach * ORBIT_SQUASH + float(spark[&"rise"]) * reach * 0.35 * sin(_time * 0.7 + angle)
		)
		# sin(angle) > 0 is the near side of the orbit (in front of the Wisp, lower on screen).
		var near: bool = sin(angle) > 0.0
		if (side == SIDE_BACK and near) or (side == SIDE_FRONT and not near):
			continue
		var depth: float = (sin(angle) + 1.0) * 0.5
		var size: float = float(spark[&"size"]) * unit * lerpf(0.55, 1.15, depth)
		var alpha: float = lerpf(0.25, 1.0, depth)
		draw_circle(point, size * 2.4, Color(tint, 0.24 * alpha))
		draw_circle(point, size, Color(Palette.SOUL_WHITE.lerp(tint, 0.35), 0.9 * alpha))
