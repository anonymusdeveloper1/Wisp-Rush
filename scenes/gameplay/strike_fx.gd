class_name StrikeFx
extends Node2D
## Draws a short pixel-art strike where a dash lands a hit on an enemy or a boss (owner, 2026-09-28).
##
## Drawn in code on the pixel grid, like Grimgrin's rot: square cells in three colours (Soul White,
## the equipped character's tint and a darker shade of it), no texture, gradient or blur. It steps
## through four frames like a sprite animation: a flash and the middle of a cut across the dash; the
## whole cut with sparks bursting out; the cut thinning as the sparks fly; then only the cut's tips
## and the sparks, darkened. Reduced Motion plays the first two frames without the sparks.
##
## It is a persistent pool, so it lives as a sibling of `EffectsLayer` next to [VfxPool] and
## [DashEffectFx]; `EffectsLayer` holds only transient per-effect nodes and code counts on that.
## Presentation only: it never touches what a hit does to the world.

## Strikes on screen at once; one more replaces the oldest.
const POOL_SIZE: int = 8
## Seconds a whole strike lasts: the top of the GDD's impact timing (§8, 100–180 ms).
const LIFETIME: float = 0.18
## Frames it steps through over [constant LIFETIME].
const FRAMES: int = 4
## Frames Reduced Motion plays, without the sparks.
const REDUCED_FRAMES: int = 2
## Side of one pixel cell at the design width; the arena scales it, as it does Grimgrin's rot.
const CELL: float = 4.0
const DESIGN_WIDTH: float = 1080.0
## Half the cut's length, as a share of the Wisp's collision radius.
const CUT_REACH: float = 1.3
## The cut crosses the dash at this angle, so it reads as a blade cut and never lies along the trail.
const CUT_ANGLE: float = PI * 0.25
## Sparks, spread evenly around the hit point, none on the cut itself.
const SPARKS: int = 8
## How far out the sparks are on each frame, as a share of the cut's half length.
const SPARK_REACH: Array[float] = [0.0, 0.35, 0.7, 1.0]
## How much darker than the character's tint the last frame is.
const DARKEN: float = 0.45

## Per strike: seconds since it started ([constant LIFETIME] or more = free), where it is, the cut's
## angle, its half length in cells, the cell size, the tint and whether it is the Reduced Motion one.
var _age: PackedFloat32Array = PackedFloat32Array()
var _origin: PackedVector2Array = PackedVector2Array()
var _angle: PackedFloat32Array = PackedFloat32Array()
var _reach: PackedInt32Array = PackedInt32Array()
var _cell: PackedFloat32Array = PackedFloat32Array()
var _tint: PackedColorArray = PackedColorArray()
var _still: Array[bool] = []
var _next: int = 0


func _init() -> void:
	# Above the enemies and the bosses (Grimgrin draws at 12), under the Wisp at 20.
	z_as_relative = false
	z_index = 16
	_age.resize(POOL_SIZE)
	_age.fill(LIFETIME)
	_origin.resize(POOL_SIZE)
	_angle.resize(POOL_SIZE)
	_reach.resize(POOL_SIZE)
	_cell.resize(POOL_SIZE)
	_tint.resize(POOL_SIZE)
	_still.resize(POOL_SIZE)
	_still.fill(false)
	set_process(false)


## Plays one strike at [param world_position], its cut crossing [param dash_direction], in
## [param tint]. [param player_radius] sizes it; [param arena_width] sets the size of its pixels.
func play(
		world_position: Vector2,
		dash_direction: Vector2,
		tint: Color,
		player_radius: float,
		arena_width: float,
		reduced_motion: bool,
	) -> void:
	if not is_inside_tree():
		return
	var slot: int = _next
	_next = (_next + 1) % POOL_SIZE
	var cell: float = maxf(2.0, roundf(CELL * arena_width / DESIGN_WIDTH))
	var direction: Vector2 = Vector2.RIGHT if dash_direction.is_zero_approx() else dash_direction
	_age[slot] = 0.0
	_origin[slot] = to_local(world_position)
	_angle[slot] = direction.angle() + CUT_ANGLE
	_reach[slot] = maxi(3, roundi(CUT_REACH * player_radius / cell))
	_cell[slot] = cell
	_tint[slot] = Color(tint, 1.0)
	_still[slot] = reduced_motion
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var live: bool = false
	for slot: int in POOL_SIZE:
		if _age[slot] < LIFETIME:
			_age[slot] += delta
			live = live or _age[slot] < LIFETIME
	queue_redraw()
	if not live:
		set_process(false)


func _draw() -> void:
	for slot: int in POOL_SIZE:
		if _age[slot] >= LIFETIME:
			continue
		var frame: int = mini(FRAMES - 1, int(_age[slot] / (LIFETIME / float(FRAMES))))
		if _still[slot] and frame >= REDUCED_FRAMES:
			continue
		_draw_strike(slot, frame)


## One frame of one strike: the cut across the dash, the flash on the first frame, the sparks after.
func _draw_strike(slot: int, frame: int) -> void:
	var origin: Vector2 = _origin[slot]
	var cell: float = _cell[slot]
	var reach: int = _reach[slot]
	var along := Vector2.RIGHT.rotated(_angle[slot])
	var across: Vector2 = along.orthogonal()
	var tint: Color = _tint[slot]
	var dark: Color = tint.darkened(DARKEN)
	var core: int = floori(float(reach) * 0.5)
	for step: int in range(-reach, reach + 1):
		var distance: int = absi(step)
		var point: Vector2 = origin + along * (float(step) * cell)
		match frame:
			0:
				if distance <= core:
					_draw_cell(point, cell, Palette.SOUL_WHITE)
			1:
				if distance <= core:
					_draw_cell(point, cell, Palette.SOUL_WHITE)
					_draw_cell(point + across * cell, cell, Palette.SOUL_WHITE)
				else:
					_draw_cell(point, cell, tint)
			2:
				_draw_cell(point, cell, tint)
			_:
				if float(distance) > float(reach) * 0.6:
					_draw_cell(point, cell, dark)
	if frame == 0:
		_draw_cell(origin, cell, Palette.SOUL_WHITE, 3)
		return
	if _still[slot]:
		return
	var spark_distance: float = SPARK_REACH[frame] * float(reach) * cell
	var spark_colour: Color = dark if frame == FRAMES - 1 else tint
	var spark_size: int = 2 if frame == 1 else 1
	for index: int in SPARKS:
		var angle: float = _angle[slot] + TAU * (float(index) + 0.5) / float(SPARKS)
		_draw_cell(
			origin + Vector2.RIGHT.rotated(angle) * spark_distance, cell, spark_colour, spark_size
		)


## A square [param size] cells wide on the pixel grid, around [param point].
func _draw_cell(point: Vector2, cell: float, colour: Color, size: int = 1) -> void:
	var corner := Vector2(floorf(point.x / cell), floorf(point.y / cell)) * cell
	corner -= Vector2.ONE * cell * floorf(float(size - 1) * 0.5)
	draw_rect(Rect2(corner, Vector2.ONE * cell * float(size)), colour)
