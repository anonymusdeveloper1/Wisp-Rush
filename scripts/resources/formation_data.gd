class_name FormationData
extends Resource
## Data-driven normalized enemy and optional hazard placement for one readable encounter.

const VALID_ENEMY_KINDS: Array[StringName] = [&"soul_wisp", &"shard_wraith", &"bone_mote"]
const VALID_HAZARD_KINDS: Array[StringName] = [
	&"",
	&"split_crystal",
	&"spike_bloom",
	&"blade_ring",
]
const MINIMUM_MARGIN: float = 0.08
const MINIMUM_SEPARATION: float = 0.065
const HAZARD_MARGIN: float = 0.18

## Stable identifier used in logs and validation output.
@export var formation_id: StringName
## First one-based wave allowed to select this formation.
@export_range(1, 99, 1) var minimum_wave: int = 1
## Amount removed from the current wave threat budget when selected.
@export_range(1, 30, 1) var threat_cost: int = 1
## Enemy archetype identifiers paired by index with [member normalized_positions].
@export var enemy_kinds: Array[StringName] = []
## Viewport-normalized enemy points kept inside readable margins.
@export var normalized_positions: PackedVector2Array = PackedVector2Array()
## Optional single hazard identifier; empty means no hazard.
@export var hazard_kind: StringName = &""
## Viewport-normalized location for the optional hazard.
@export var hazard_position: Vector2 = Vector2(0.5, 0.5)
## Whether the director may reflect this pattern horizontally.
@export var allow_mirror: bool = true
## Whether the director may rotate this pattern in quarter turns.
@export var allow_rotation: bool = true


## Returns validation failures; an empty result means the formation is spawn-safe.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if formation_id.is_empty():
		failures.append("formation_id is empty")
	if enemy_kinds.is_empty() or enemy_kinds.size() != normalized_positions.size():
		failures.append("enemy_kinds and normalized_positions must have equal non-zero size")
	if enemy_kinds.size() > 8:
		failures.append("formation exceeds the eight-enemy readability cap")
	for index: int in enemy_kinds.size():
		if enemy_kinds[index] not in VALID_ENEMY_KINDS:
			failures.append("enemy %d has invalid kind %s" % [index, enemy_kinds[index]])
		if not _inside_margin(normalized_positions[index], MINIMUM_MARGIN):
			failures.append("enemy %d is outside the safe spawn margin" % index)
		for other_index: int in range(index):
			if normalized_positions[index].distance_to(normalized_positions[other_index]) < MINIMUM_SEPARATION:
				failures.append("enemies %d and %d overlap" % [other_index, index])
	if hazard_kind not in VALID_HAZARD_KINDS:
		failures.append("invalid hazard kind %s" % hazard_kind)
	elif not hazard_kind.is_empty():
		if not _inside_margin(hazard_position, HAZARD_MARGIN):
			failures.append("hazard does not preserve safe edge destinations")
		for index: int in normalized_positions.size():
			if normalized_positions[index].distance_to(hazard_position) < 0.12:
				failures.append("enemy %d overlaps the hazard warning area" % index)
	return failures


## Returns enemy points after an authored mirror and zero-to-three quarter turns.
func get_transformed_positions(mirrored: bool, quarter_turns: int) -> PackedVector2Array:
	var transformed := PackedVector2Array()
	for source_position: Vector2 in normalized_positions:
		transformed.append(_transform_point(source_position, mirrored, quarter_turns))
	return transformed


## Returns the optional hazard point under the same formation transform.
func get_transformed_hazard_position(mirrored: bool, quarter_turns: int) -> Vector2:
	return _transform_point(hazard_position, mirrored, quarter_turns)


func _transform_point(source: Vector2, mirrored: bool, quarter_turns: int) -> Vector2:
	var point: Vector2 = source
	if mirrored and allow_mirror:
		point.x = 1.0 - point.x
	var turns: int = posmod(quarter_turns, 4) if allow_rotation else 0
	for _turn: int in turns:
		point = Vector2(1.0 - point.y, point.x)
	return point


func _inside_margin(point: Vector2, margin: float) -> bool:
	return (
		point.x >= margin
		and point.x <= 1.0 - margin
		and point.y >= margin
		and point.y <= 1.0 - margin
	)
