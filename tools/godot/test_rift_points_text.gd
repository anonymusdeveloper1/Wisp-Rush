extends SceneTree
## Rift Points wording (spec 01): no player-facing "shard" text outside the Shard Wraith, and every
## currency value on the changed screens reads RP.
##
## Three sweeps: authored text in scenes and data (`text =`, titles, descriptions), prose string
## literals in scripts, and the live text of every screen that shows currency once set up with data.
## Internal ids and file names (`shard_pickup`, `02_soul_shards.png`, `SoulShardPickup`) are not
## player-facing and are allowed; so is any text that names the Shard Wraith.

const SCREENS: Dictionary = {
	&"home": preload("res://scenes/screens/home_screen.tscn"),
	&"shop": preload("res://scenes/screens/shop_screen.tscn"),
	&"results": preload("res://scenes/screens/results_screen.tscn"),
	&"daily": preload("res://scenes/screens/daily_screen.tscn"),
	&"trials": preload("res://scenes/screens/trials_screen.tscn"),
	&"statistics": preload("res://scenes/screens/statistics_screen.tscn"),
	&"forms": preload("res://scenes/screens/forms_screen.tscn"),
	&"settings": preload("res://scenes/screens/settings_screen.tscn"),
	&"game": preload("res://scenes/gameplay/game_world.tscn"),
}
const FORM_CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
## Authored string properties that reach the player.
const TEXT_PROPERTIES: Array[String] = [
	"text", "tooltip_text", "placeholder_text", "title", "display_name", "description",
	"description_template",
]

var _failures: int = 0
## A whole label that is a digit-grouped number ("1,320").
var _grouped_number := RegEx.create_from_string("^[0-9]{1,3}(,[0-9]{3})*$")
## A digit-grouped amount with the RP unit inside a label ("+45 RP", "1,320 RP", "+50 RP FOR ...").
var _rp_value := RegEx.create_from_string("(^|\\s)\\+?[0-9]{1,3}(,[0-9]{3})* RP(\\s|$)")
var _prose_shard := RegEx.create_from_string("\"[^\"\\n]*\\b[Ss][Hh][Aa][Rr][Dd][Ss]?\\b[^\"\\n]*\"")


func _init() -> void:
	call_deferred(&"_run")


func _fail(message: String) -> void:
	_failures += 1
	push_error("rift_points_text: %s" % message)


func _run() -> void:
	for path: String in _files("res://scenes", ["tscn"]) + _files("res://data", ["tres"]):
		_check_authored_text(path)
	for path: String in _files("res://scenes", ["gd"]) + _files("res://scripts", ["gd"]):
		_check_script_literals(path)
	for definition: Dictionary in ChallengeTracker._POOL:
		_check_text("ChallengeTracker %s" % definition[&"id"], str(definition[&"title"]))
		_check_text("ChallengeTracker %s" % definition[&"id"], str(definition[&"description"]))
	await _check_live_screens()
	if _failures == 0:
		print("rift_points_text: no player-facing shard text; currency reads RP on every screen")
	quit(_failures)


func _check_text(where: String, text: String) -> void:
	var upper: String = text.to_upper()
	if upper.contains("SHARD") and not upper.contains("SHARD WRAITH"):
		_fail("%s shows '%s'" % [where, text])


func _check_authored_text(path: String) -> void:
	var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
	for index: int in lines.size():
		var line: String = lines[index]
		for property: String in TEXT_PROPERTIES:
			if line.begins_with(property + " = \""):
				_check_text("%s:%d" % [path, index + 1], line.trim_prefix(property + " = "))


func _check_script_literals(path: String) -> void:
	var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
	for index: int in lines.size():
		var line: String = lines[index].strip_edges()
		if line.begins_with("#"):
			continue
		for found: RegExMatch in _prose_shard.search_all(line):
			_check_text("%s:%d" % [path, index + 1], found.get_string())


func _check_live_screens() -> void:
	var snapshot: Dictionary = {
		&"best_score": 48210,
		&"highest_wave": 9,
		&"highest_combo": 23,
		&"total_runs": 41,
		&"total_kills": 1873,
		&"total_multi_kills": 212,
		&"bosses_defeated": 2,
		&"play_time_seconds": 5480.0,
		&"rift_points": 1320,
		&"owned_forms": ["void", "ash"],
		&"equipped_form": "ash",
		&"selected_rift": "obsidian_garden",
		&"challenge_state": {},
		&"daily_state": {&"completed_dates": [], &"best_scores": {}},
		&"settings": {&"reduced_motion": true},
	}
	var configure: Dictionary = {
		&"home": func(screen: Node) -> void:
			screen.setup(snapshot, FORM_CATALOG.get_form(&"ash")),
		&"shop": func(screen: Node) -> void: screen.setup(1320, false, false),
		&"results": func(screen: Node) -> void: screen.setup({
			&"score": 12840, &"best_score": 48210, &"rp_collected": 18, &"rp_performance": 32,
			&"rp_rewards": 115, &"rp_earned": 165, &"rift_points_total": 1353,
		}),
		&"daily": func(screen: Node) -> void:
			screen.setup("2026-09-15", ChallengeTracker.get_daily_seed("2026-09-15"), snapshot),
		&"trials": func(screen: Node) -> void: screen.setup(8, {"t08_rp_collected_m": 31}),
		&"statistics": func(screen: Node) -> void: screen.setup(snapshot),
		&"forms": func(screen: Node) -> void: screen.setup(1320, ["void", "ash"], &"ash", 2),
		&"settings": func(_screen: Node) -> void: pass,
		&"game": func(_screen: Node) -> void: pass,
	}
	# Home, Shop and the HUD show a digit-grouped number beside a static unit label.
	var value_unit_nodes: Dictionary = {
		&"home": ["%RiftPointsLabel", "ContentMargin/Content/TopBar/RiftPointsPlate/Row/Unit"],
		&"shop": ["%RiftPointsCount", "Root/Column/Header/RiftPointsPlate/Row/Unit"],
		&"game": [
			"%RiftPointsCount", "HUD/SafeHud/HealthRow/StatsColumn/RiftPointsLine/RiftPointsUnit",
		],
	}
	# Every other currency value must contain a digit-grouped number followed by RP.
	var rp_value_labels: Dictionary = {
		&"results": func(screen: Node) -> Array[Label]:
			var labels: Array[Label] = []
			for path: String in [
				"%CollectedValue", "%PerformanceValue", "%RewardsValue", "%TotalValue",
				"%BalanceValue",
			]:
				labels.append(screen.get_node(path) as Label)
			return labels,
		&"daily": func(screen: Node) -> Array[Label]:
			var labels: Array[Label] = [screen.get_node("%RewardLabel") as Label]
			labels.append_array(screen._row_rewards)
			return labels,
		&"trials": func(screen: Node) -> Array[Label]:
			var labels: Array[Label] = []
			for node: Node in screen.find_children("*", "Label", true, false):
				if (node as Label).text.contains("•"):
					labels.append(node as Label)
			return labels,
		&"forms": func(screen: Node) -> Array[Label]:
			var labels: Array[Label] = [screen.get_node("%BalanceLabel") as Label]
			return labels,
		&"statistics": func(screen: Node) -> Array[Label]:
			var labels: Array[Label] = []
			var cells: Array[Node] = screen._grid.get_children()
			for index: int in cells.size() - 1:
				if cells[index] is Label and (cells[index] as Label).text == "RIFT POINTS":
					labels.append(cells[index + 1] as Label)
			return labels,
	}
	for key: StringName in SCREENS:
		var screen: Node = (SCREENS[key] as PackedScene).instantiate()
		(configure[key] as Callable).call(screen)
		root.add_child(screen)
		for frame: int in 3:
			await process_frame
		for node: Node in screen.find_children("*", "", true, false) + [screen]:
			if node is Label:
				_check_text("%s %s" % [key, screen.get_path_to(node)], (node as Label).text)
			elif node is Button:
				_check_text("%s %s" % [key, screen.get_path_to(node)], (node as Button).text)
				_check_text("%s %s" % [key, screen.get_path_to(node)], (node as Button).tooltip_text)
		if value_unit_nodes.has(key):
			var value := screen.get_node_or_null(value_unit_nodes[key][0]) as Label
			var unit := screen.get_node_or_null(value_unit_nodes[key][1]) as Label
			if value == null or unit == null:
				_fail("%s is missing its RP value or unit label" % key)
			elif unit.text != RiftPoints.UNIT or _grouped_number.search(value.text) == null:
				_fail("%s currency reads '%s' '%s', expected a grouped number and %s" % [
					key, value.text, unit.text, RiftPoints.UNIT,
				])
		if rp_value_labels.has(key):
			var labels: Array[Label] = (rp_value_labels[key] as Callable).call(screen)
			if labels.is_empty():
				_fail("%s shows no Rift Points value to check" % key)
			for label: Label in labels:
				if _rp_value.search(label.text) == null:
					_fail("%s %s reads '%s', expected an RP value" % [
						key, screen.get_path_to(label), label.text,
					])
		screen.queue_free()
		await process_frame
	paused = false


func _files(directory: String, extensions: Array[String]) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(directory)
	if dir == null:
		return found
	for file_name: String in dir.get_files():
		if file_name.get_extension() in extensions:
			found.append(directory.path_join(file_name))
	for child: String in dir.get_directories():
		found.append_array(_files(directory.path_join(child), extensions))
	return found
