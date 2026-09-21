class_name CharacterAura
extends Node2D
## Small lights that drift and orbit around a character, so it is never a still picture.
##
## Built in code from one texture: there is no new art and nothing to author per character except
## the numbers below. Each mote runs its own ellipse at its own speed and phase, dips behind the
## body on the far half of the orbit and passes in front on the near half, and stretches into the
## travel direction while the character is dashing. It draws no physics and reads nothing from
## gameplay.
##
## It lives **beside** the rig's [code]%MotionRoot[/code], not inside it, so the body's squash,
## recoil and dash heading never drag the motes around with it; [PlayableCharacterVisual] steps it
## once per frame and stills it for Reduced Motion.

## Picture each mote is drawn with when [member mote_textures] is empty; one serves every mote.
@export var mote_texture: Texture2D:
	set(value):
		mote_texture = value
		if is_node_ready():
			_rebuild()
## Several pictures instead of one, handed out round-robin, so a character's ring can be made of her
## own ornaments — a crown shard, a gem, two sizes of sparkle — rather than one repeated shape.
@export var mote_textures: Array[Texture2D] = []:
	set(value):
		mote_textures = value
		if is_node_ready():
			_rebuild()
## How many motes orbit the character.
@export_range(0, 24, 1) var mote_count: int = 8:
	set(value):
		mote_count = value
		if is_node_ready():
			_rebuild()
## Half-width and half-height of the orbit, in rig pixels.
@export var orbit_radius: Vector2 = Vector2(300.0, 210.0)
## Rig pixels the whole ring floats up and down by.
@export_range(0.0, 200.0, 1.0) var drift_height: float = 30.0
## Seconds one mote takes to go round, before each mote's own speed jitter.
@export_range(0.5, 30.0, 0.1) var orbit_seconds: float = 7.0
## Share of `orbit_seconds` a mote's speed may differ by, so the ring never marches in step.
@export_range(0.0, 0.9, 0.01) var speed_jitter: float = 0.35
## Smallest and largest drawn scale of a mote.
@export var mote_scale: Vector2 = Vector2(0.16, 0.34)
## Colour every mote is tinted with; its alpha is the brightest a mote reaches.
@export var tint: Color = Color(0.62, 0.86, 1.0, 0.85)
## Rig pixels the ring is lifted, so it sits around the body rather than around the feet.
@export var centre_offset: Vector2 = Vector2(0.0, -40.0)
## How far a dash stretches the ring backwards, as a share of [member orbit_radius].
@export_range(0.0, 3.0, 0.05) var dash_stretch: float = 0.9
## Seeds the per-mote phase, radius and speed, so a character's ring is the same every run.
## Not named `seed`: that would shadow the global `seed()` function.
@export var mote_seed: int = 20260919

var _motes: Array[Sprite2D] = []
var _phases: PackedFloat32Array = PackedFloat32Array()
var _rates: PackedFloat32Array = PackedFloat32Array()
var _radii: PackedFloat32Array = PackedFloat32Array()
var _scales: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0
var _still: bool = false


func _ready() -> void:
	_rebuild()


## Advances the ring. [param speed] is the character's 0..1 dash amount and [param direction]
## the way it is travelling, both straight from [PlayableCharacterVisual].
func step(delta: float, speed: float, direction: Vector2) -> void:
	if _still or _motes.is_empty():
		return
	_time += delta
	_place(speed, direction)


## Reduced Motion: parks every mote on its starting point and stops stepping.
func set_still(enabled: bool) -> void:
	_still = enabled
	if _still and not _motes.is_empty():
		_time = 0.0
		_place(0.0, Vector2.UP)


## Number of live motes, for the fixtures and the budget check.
func get_mote_count() -> int:
	return _motes.size()


func _place(speed: float, direction: Vector2) -> void:
	# A dash drags the ring out along the travel axis and pulls it in across it, so the lights read
	# as being left behind rather than as an ornament stuck to the character.
	var stretch: float = 1.0 + dash_stretch * speed
	var squeeze: float = 1.0 / maxf(0.2, stretch)
	var along: Vector2 = direction.normalized() if not direction.is_zero_approx() else Vector2.UP
	var across := Vector2(-along.y, along.x)
	var bright: float = maxf(tint.a, 0.001)
	for index: int in _motes.size():
		var turn: float = (_phases[index] + _time * _rates[index]) * TAU
		var local := Vector2(
			cos(turn) * orbit_radius.x * _radii[index],
			sin(turn) * orbit_radius.y * _radii[index] * 0.5,
		)
		var offset: Vector2 = (
			along * (local.y * stretch) + across * (local.x * squeeze) + centre_offset
		)
		offset.y += sin(turn * 0.5 + _phases[index] * TAU) * drift_height
		var mote: Sprite2D = _motes[index]
		mote.position = offset
		# sin(turn) runs -1 behind the body to +1 in front of it: the far half dims and shrinks.
		var depth: float = 0.5 + 0.5 * sin(turn)
		mote.z_index = 1 if depth > 0.5 else -1
		mote.scale = Vector2.ONE * _scales[index] * lerpf(0.72, 1.0, depth)
		mote.modulate = Color(tint.r, tint.g, tint.b, bright * lerpf(0.28, 1.0, depth))


func _rebuild() -> void:
	for mote: Sprite2D in _motes:
		mote.queue_free()
	_motes.clear()
	_phases.clear()
	_rates.clear()
	_radii.clear()
	_scales.clear()
	var pictures: Array[Texture2D] = []
	for picture: Texture2D in mote_textures:
		if picture != null:
			pictures.append(picture)
	if pictures.is_empty() and mote_texture != null:
		pictures.append(mote_texture)
	if pictures.is_empty() or mote_count <= 0:
		return
	var random := RandomNumberGenerator.new()
	random.seed = mote_seed
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for index: int in mote_count:
		var mote := Sprite2D.new()
		# Round-robin rather than random, so the ring never clumps two of the same ornament together.
		mote.texture = pictures[index % pictures.size()]
		mote.material = additive
		add_child(mote)
		_motes.append(mote)
		# Evenly spread, then nudged, so the ring is never a clump and never a perfect necklace.
		_phases.append(float(index) / float(mote_count) + random.randf_range(-0.04, 0.04))
		var jitter: float = random.randf_range(-speed_jitter, speed_jitter)
		_rates.append((1.0 + jitter) / maxf(0.1, orbit_seconds))
		_radii.append(random.randf_range(0.72, 1.0))
		_scales.append(random.randf_range(mote_scale.x, mote_scale.y))
	_place(0.0, Vector2.UP)
