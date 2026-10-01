class_name EnemyRamp
extends RefCounted
## Picks which enemy each spawn slot gets, on the Enemies v2 ramp (docs/systems/wave_director.md).
##
## The owner's plan (2026-09-27, docs/specs/enemies_v2/README.md §4): each run shuffles which enemies
## appear, starts with a few of them, adds another every so often, and mixes them at random. Here a
## run shuffles every kind once from its seed, starts with [member WaveTuning.enemy_kinds_at_start]
## of them and adds the next every [member WaveTuning.waves_per_new_enemy_kind] waves; every slot then
## draws at random from those unlocked. The same seed plays the same run.

## Salt that separates the slot draws from the shuffle.
const DRAW_SALT: int = 104729

var _order: Array[StringName] = []
var _random := RandomNumberGenerator.new()
var _at_start: int = 2
var _waves_per_new: int = 2


## Shuffles [param kinds] for a run seeded [param run_seed].
func configure(kinds: Array[StringName], run_seed: int, at_start: int, waves_per_new: int) -> void:
	_order = kinds.duplicate()
	var shuffle := RandomNumberGenerator.new()
	shuffle.seed = run_seed
	for index: int in range(_order.size() - 1, 0, -1):
		var other: int = shuffle.randi_range(0, index)
		var swap: StringName = _order[index]
		_order[index] = _order[other]
		_order[other] = swap
	_random.seed = run_seed + DRAW_SALT
	_at_start = maxi(1, at_start)
	_waves_per_new = maxi(1, waves_per_new)


## How many kinds wave [param wave] (one-based) may draw from.
func get_unlocked_count(wave: int) -> int:
	var added: int = floori(float(maxi(0, wave - 1)) / float(_waves_per_new))
	return clampi(_at_start + added, 1, maxi(1, _order.size()))


## The kinds wave [param wave] may draw from, in the order they joined the run.
func get_unlocked(wave: int) -> Array[StringName]:
	return _order.slice(0, get_unlocked_count(wave))


## One enemy kind for a slot in wave [param wave]; empty when nothing is configured.
func pick(wave: int) -> StringName:
	if _order.is_empty():
		return &""
	return _order[_random.randi_range(0, get_unlocked_count(wave) - 1)]
