class_name ArenaParticleEmitter
extends Resource
## One soft glow-particle stream in an Endless skin's scenery (embers, snow, ash, motes, stardust).
##
## Particles spawn only at `points_uv`, which tools/art/endless_scenery.py samples from scenery
## pixels whose whole drift path (speed, spread, gravity, lifetime) stays outside the floor
## template plus rim tolerance; `EndlessCatalog.validate()` re-checks every point and its path.
## `ArenaAmbience` also fades each particle by the mask's scenery weight, so none can ever show over
## the floor (GDD §8). All lengths are background-texture pixels (941x1672 canvas).

## Sprite drawn per particle: a generated soft dot, or the collectible sparkle.
enum Sprite { SOFT_DOT, SPARKLE }

## Sample offsets along the lifetime used to check a particle's drift path.
const PATH_STEPS: PackedFloat32Array = [0.25, 0.5, 0.75, 1.0]

## Readable name for docs and debugging.
@export var emitter_name: String = ""
## Spawn positions in background UV.
@export var points_uv: PackedVector2Array = PackedVector2Array()
## Particles alive at once.
@export_range(1, 128, 1) var amount: int = 12
## Seconds each particle lives.
@export_range(0.2, 30.0, 0.1) var lifetime: float = 4.0
## Initial travel direction (normalised at runtime).
@export var direction: Vector2 = Vector2.UP
## Half-angle of the direction cone, in degrees.
@export_range(0.0, 180.0, 0.5) var spread_degrees: float = 20.0
## Initial speed range in px/s (x = min, y = max).
@export var speed_px: Vector2 = Vector2(8.0, 20.0)
## Constant acceleration in px/s².
@export var gravity_px: Vector2 = Vector2.ZERO
## Diameter range in px (x = min, y = max).
@export var size_px: Vector2 = Vector2(3.0, 7.0)
## Colour at birth and at death; alpha envelope fades in and out over the life.
@export var color: Color = Color.WHITE
@export var end_color: Color = Color.WHITE
## Peak opacity.
@export_range(0.0, 1.0, 0.01) var alpha: float = 1.0
## Extra brightness pulses over the life (fireflies, twinkling dust); 0 = one smooth fade.
@export_range(0, 6, 1) var pulses: int = 0
## Additive light (embers, snow glow) or normal blend (smoke).
@export var additive: bool = true
## Particle sprite.
@export var sprite: Sprite = Sprite.SOFT_DOT
## Maximum spin in degrees per second (sparkles).
@export_range(0.0, 720.0, 1.0) var spin_degrees: float = 0.0
## Seed so captures are repeatable.
@export var random_seed: int = 1


## Positions (background px) a particle born at `origin_px` can reach: both speed limits, the cone
## edges and centre, sampled along its life. Mirrors `path_samples` in endless_scenery.py.
func get_path_samples(origin_px: Vector2) -> PackedVector2Array:
	var samples := PackedVector2Array()
	var base: float = direction.angle() if direction != Vector2.ZERO else -PI * 0.5
	var spread: float = deg_to_rad(spread_degrees)
	for angle: float in [base - spread, base, base + spread]:
		for speed: float in [speed_px.x, speed_px.y]:
			for step: float in PATH_STEPS:
				var time: float = lifetime * step
				samples.append(
					origin_px + Vector2.from_angle(angle) * speed * time + gravity_px * 0.5 * time * time
				)
	return samples


## Returns authoring failures (points, ranges); the floor keep-out is checked by
## `EndlessCatalog.validate()`.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if points_uv.is_empty():
		failures.append("%s has no emission points" % emitter_name)
	for point: Vector2 in points_uv:
		if point.x < 0.0 or point.y < 0.0 or point.x > 1.0 or point.y > 1.0:
			failures.append("%s point %s leaves UV space" % [emitter_name, point])
			break
	if speed_px.x > speed_px.y or size_px.x > size_px.y or size_px.x <= 0.0:
		failures.append("%s has an inverted speed or size range" % emitter_name)
	return failures
