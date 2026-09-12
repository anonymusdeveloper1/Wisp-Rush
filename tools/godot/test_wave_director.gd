extends SceneTree
## Validates all 20 formation Resources and deterministic wave-budget transitions.

const CATALOG: FormationCatalog = preload("res://data/waves/default_catalog.tres")
const TUNING: WaveTuning = preload("res://data/waves/default_wave_tuning.tres")


func _init() -> void:
	call_deferred(&"_run_checks")


func _run_checks() -> void:
	var failures: int = 0
	var validation_failures: PackedStringArray = CATALOG.validate()
	var formations: Array[FormationData] = CATALOG.load_formations()
	if not validation_failures.is_empty():
		failures += 1
		push_error("wave_director: %s" % "; ".join(validation_failures))
	if formations.size() != 20:
		failures += 1
		push_error("wave_director: expected exactly 20 authored formations")
	for formation: FormationData in formations:
		for turns: int in 4:
			for point: Vector2 in formation.get_transformed_positions(true, turns):
				if point.x < 0.0 or point.x > 1.0 or point.y < 0.0 or point.y > 1.0:
					failures += 1

	var waves: Array[int] = []
	var requested_ids: Array[StringName] = []
	var director := WaveDirector.new()
	director.tuning = TUNING
	director.catalog = CATALOG
	root.add_child(director)
	director.wave_started.connect(
		func(wave: int, _budget: int) -> void: waves.append(wave)
	)
	director.formation_requested.connect(
		func(formation: FormationData, _mirror: bool, _turns: int) -> void:
			requested_ids.append(formation.formation_id)
	)
	director.start(77)
	director.advance(0.01, 0)
	director.advance(TUNING.wave_duration + 0.1, 0)
	if waves != [1, 2] or requested_ids.is_empty():
		failures += 1
		push_error("wave_director: deterministic wave/request sequence failed")
	if failures == 0:
		print("wave_director: 20 formations valid; deterministic budget transition passed")
	director.queue_free()
	quit(failures)
