extends SceneTree
## Checks the XP threshold, distinct offers, one-shot card input and mutation application.

const TUNING: RunProgressionTuning = preload(
	"res://data/progression/default_run_progression.tres"
)
const OVERLAY: PackedScene = preload("res://scenes/screens/upgrade_select.tscn")


func _init() -> void:
	call_deferred(&"_run_checks")


func _run_checks() -> void:
	var failures: int = 0
	var ready_count: Array[int] = [0]
	var progression := RunProgression.new()
	progression.tuning = TUNING
	root.add_child(progression)
	progression.level_ready.connect(func() -> void: ready_count[0] += 1)
	progression.start(91)
	progression.add_experience(TUNING.base_xp_threshold)
	var choices: Array[MutationData] = progression.offer_choices(3)
	var ids: Dictionary[StringName, bool] = {}
	for choice: MutationData in choices:
		ids[choice.mutation_id] = true
	if ready_count[0] != 1 or choices.size() != 3 or ids.size() != 3:
		failures += 1
		push_error("run_progression: level readiness or distinct offer failed")

	var selected_ids: Array[StringName] = []
	var overlay := OVERLAY.instantiate() as UpgradeSelect
	root.add_child(overlay)
	overlay.choice_selected.connect(func(id: StringName) -> void: selected_ids.append(id))
	overlay.present(choices, progression.get_levels())
	if not overlay.choose_index(0) or overlay.choose_index(0):
		failures += 1
		push_error("run_progression: overlay accepted zero or multiple selections")
	if selected_ids.size() != 1 or not progression.apply_choice(selected_ids[0]):
		failures += 1
		push_error("run_progression: selected mutation did not apply")
	elif progression.get_mutation_level(selected_ids[0]) != 1:
		failures += 1
	if failures == 0:
		print("run_progression: XP → three choices → one mutation passed")
	quit(failures)
