extends SceneTree
## Every configurable screen must survive setup() being called BEFORE it enters the tree.
##
## Main configures a screen immediately after instancing it, while its @onready references are
## still null. A screen that touches those references inside setup() crashes only on a real run —
## headless screenshot fixtures never hit it, because loading a scene standalone runs _ready()
## first. This test reproduces Main's actual call order.

const SCREENS: Dictionary = {
	&"rift_map": preload("res://scenes/screens/rift_map_screen.tscn"),
	&"sanctum": preload("res://scenes/screens/sanctum_screen.tscn"),
	&"trials": preload("res://scenes/screens/trials_screen.tscn"),
	&"forms": preload("res://scenes/screens/forms_screen.tscn"),
	&"daily": preload("res://scenes/screens/daily_screen.tscn"),
	&"statistics": preload("res://scenes/screens/statistics_screen.tscn"),
}

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _fail(message: String) -> void:
	_failures += 1
	push_error("screen_setup_order: %s" % message)


func _run() -> void:
	var snapshot: Dictionary = {
		&"highest_wave": 12,
		&"selected_rift": "ember_hollow",
		&"rift_bests": {"ember_hollow": 4200},
		&"rift_levels": {"ember_hollow": 3},
		&"soul_shards": 900,
		&"owned_forms": ["void"],
		&"equipped_form": "void",
		&"bosses_defeated": 2,
		&"best_score": 4200,
		&"total_runs": 9,
		&"total_kills": 300,
		&"total_multi_kills": 12,
		&"highest_combo": 14,
		&"play_time_seconds": 900.0,
		&"challenge_state": {},
		&"daily_state": {&"completed_dates": [], &"best_scores": {}},
	}

	# The three data-driven screens must have actually generated their rows. Asserting on the
	# generated container is the whole point: the static scene nodes exist either way, so a
	# whole-tree node count would pass even when every row failed to build.
	await _check(&"rift_map", "%Carousel", 5,
		func(screen: Node) -> void: screen.setup(snapshot))
	await _check(&"sanctum", "%NodeList", 5, func(screen: Node) -> void:
		screen.setup(900, {"keen_edge": 1})
		# Feedback before ready must also be safe, since Main shows a purchase result immediately.
		screen.show_feedback("AWAKENED", true))
	await _check(&"trials", "%TrialList", 3,
		func(screen: Node) -> void: screen.setup(3, {"t01_wave": 2}))

	# Pre-existing screens: they already worked, so just prove this call order does not break them.
	await _check(&"statistics", "", 0, func(screen: Node) -> void: screen.setup(snapshot))
	await _check(&"daily", "", 0, func(screen: Node) -> void: screen.setup("2026-09-12", 12345, snapshot))
	await _check(&"forms", "", 0,
		func(screen: Node) -> void: screen.setup(900, ["void"], &"void", 2))

	if _failures == 0:
		print("screen_setup_order: %d screens survive setup() before entering the tree"
			% SCREENS.size())
	quit(_failures)


## Instances a screen, configures it while detached, then adds it to the tree — Main's order.
##
## `list_path` names the container the screen fills at runtime; when given, it must hold at least
## `minimum_rows` children afterwards.
func _check(key: StringName, list_path: String, minimum_rows: int, configure: Callable) -> void:
	var screen: Node = (SCREENS[key] as PackedScene).instantiate()
	configure.call(screen)
	root.add_child(screen)
	# One frame so any deferred rebuild lands before we inspect the result.
	await process_frame
	if not screen.is_node_ready():
		_fail("%s never became ready" % key)
	if not list_path.is_empty():
		var list: Node = screen.get_node_or_null(list_path)
		if list == null:
			_fail("%s has no %s container" % [key, list_path])
		elif list.get_child_count() < minimum_rows:
			_fail("%s built %d rows after a pre-tree setup(), expected at least %d" % [
				key, list.get_child_count(), minimum_rows,
			])
	screen.queue_free()
	await process_frame
