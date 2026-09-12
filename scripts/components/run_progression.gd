class_name RunProgression
extends Node
## Run-local XP, deterministic non-capped choices and mutation-level state.

## Emitted whenever XP or its next threshold changes.
signal experience_changed(current_xp: int, threshold: int, run_level: int)
## Emitted once when enough XP is banked for a safe post-dash choice.
signal level_ready
## Emitted after one pending level applies the chosen mutation.
signal mutation_applied(mutation_id: StringName, mutation_level: int)

## XP curve, catalog paths and shared mutation values.
@export var tuning: RunProgressionTuning

var _mutations: Array[MutationData] = []
var _levels: Dictionary[StringName, int] = {}
var _random := RandomNumberGenerator.new()
var _current_xp: int = 0
var _xp_threshold: int = 1
var _run_level: int = 1
var _pending_level: bool = false
var _offered_ids: Array[StringName] = []


func _ready() -> void:
	assert(tuning != null, "RunProgression requires RunProgressionTuning")
	_load_mutations()
	assert(_mutations.size() == 8, "RunProgression requires all eight mutation Resources")


## Resets XP and run-only mutation levels using a deterministic choice seed.
func start(seed: int) -> void:
	_random.seed = seed
	_current_xp = 0
	_run_level = 1
	_pending_level = false
	_offered_ids.clear()
	_xp_threshold = tuning.base_xp_threshold
	for mutation: MutationData in _mutations:
		_levels[mutation.mutation_id] = 0
	experience_changed.emit(_current_xp, _xp_threshold, _run_level)


## Adds non-negative XP and latches one pending safe upgrade when the threshold is reached.
func add_experience(amount: int) -> void:
	if amount <= 0:
		return
	_current_xp += amount
	experience_changed.emit(_current_xp, _xp_threshold, _run_level)
	if _current_xp >= _xp_threshold and not _pending_level:
		_pending_level = true
		level_ready.emit()


## Returns up to count distinct non-capped choices in deterministic shuffled order.
func offer_choices(count: int = 3) -> Array[MutationData]:
	var eligible: Array[MutationData] = []
	for mutation: MutationData in _mutations:
		if get_mutation_level(mutation.mutation_id) < mutation.max_level:
			eligible.append(mutation)
	for index: int in range(eligible.size() - 1, 0, -1):
		var swap_index: int = _random.randi_range(0, index)
		var held: MutationData = eligible[index]
		eligible[index] = eligible[swap_index]
		eligible[swap_index] = held
	eligible.resize(mini(maxi(0, count), eligible.size()))
	_offered_ids.clear()
	for mutation: MutationData in eligible:
		_offered_ids.append(mutation.mutation_id)
	return eligible


## Applies one valid offered mutation identifier and spends a pending run level.
func apply_choice(mutation_id: StringName) -> bool:
	if not _pending_level or mutation_id not in _offered_ids:
		return false
	var mutation: MutationData = get_mutation(mutation_id)
	if mutation == null:
		return false
	var current_level: int = get_mutation_level(mutation_id)
	if current_level >= mutation.max_level:
		return false
	_current_xp -= _xp_threshold
	_run_level += 1
	_xp_threshold = roundi(
		float(tuning.base_xp_threshold) * pow(tuning.xp_growth, float(_run_level - 1))
	)
	_levels[mutation_id] = current_level + 1
	_pending_level = _current_xp >= _xp_threshold
	_offered_ids.clear()
	mutation_applied.emit(mutation_id, current_level + 1)
	experience_changed.emit(_current_xp, _xp_threshold, _run_level)
	if _pending_level:
		level_ready.emit.call_deferred()
	return true


## Returns the current run-only level for a mutation identifier.
func get_mutation_level(mutation_id: StringName) -> int:
	return _levels.get(mutation_id, 0)


## Returns the configured MutationData for an identifier, or null when unknown.
func get_mutation(mutation_id: StringName) -> MutationData:
	for mutation: MutationData in _mutations:
		if mutation.mutation_id == mutation_id:
			return mutation
	return null


## Returns whether XP is waiting for a safe upgrade selection.
func has_pending_level() -> bool:
	return _pending_level


## Returns current XP banked toward the next run level.
func get_current_xp() -> int:
	return _current_xp


## Returns XP required for the next run level.
func get_xp_threshold() -> int:
	return _xp_threshold


## Returns the current one-based run level.
func get_run_level() -> int:
	return _run_level


## Returns a copy of all current run-only mutation levels.
func get_levels() -> Dictionary[StringName, int]:
	return _levels.duplicate()


## Returns the sum of all selected mutation levels for difficulty context.
func get_total_mutation_levels() -> int:
	var total: int = 0
	for level: int in _levels.values():
		total += level
	return total


func _load_mutations() -> void:
	_mutations.clear()
	_levels.clear()
	for path: String in tuning.mutation_paths:
		var resource: Resource = load(path)
		if resource is MutationData:
			var mutation := resource as MutationData
			assert(not _levels.has(mutation.mutation_id), "Duplicate mutation id: %s" % mutation.mutation_id)
			_mutations.append(mutation)
			_levels[mutation.mutation_id] = 0
		else:
			push_error("RunProgression could not load MutationData: %s" % path)
