extends SceneTree
## Benchmark: what live character previews cost to build and to run (the Shop's CHARACTERS tab).
##
## Prints build time for every preview cold (first load of every character's art) and warm, plus the
## per-frame cost while they all animate. Compare the per-frame figure against the "nothing alive"
## baseline — in headless that baseline is the main loop itself, not the rigs.
##
## Usage:
##   WISP_ISOLATED_SAVE=1 "$GODOT" --headless --path . \
##     --script res://tools/godot/bench_character_previews.gd

const CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
const IDS: Array[StringName] = [
	&"void", &"ash", &"venom", &"bloodmoon", &"frost", &"eclipse", &"veyra", &"rook", &"morrow",
	&"ilyra", &"bram",
]


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	await _measure("baseline (nothing alive)", [])
	await _measure("all %d, cold" % IDS.size(), IDS)
	await _measure("all %d, warm (second open)" % IDS.size(), IDS)
	await _measure("all %d, warm again" % IDS.size(), IDS)
	quit(0)


func _measure(label: String, ids: Array) -> void:
	var previews: Array[PlayableCharacterPreview] = []
	var build_start: int = Time.get_ticks_usec()
	for id: StringName in ids:
		var preview := PlayableCharacterPreview.new()
		root.add_child(preview)
		preview.size = Vector2(620.0, 900.0)
		preview.set_form(CATALOG.get_form(id), true)
		previews.append(preview)
	var build_ms: float = (Time.get_ticks_usec() - build_start) / 1000.0
	for _warm: int in 10:
		await process_frame
	var start: int = Time.get_ticks_usec()
	for _frame: int in 60:
		await process_frame
	print("[Perf] %-26s build %6.1f ms | %5.2f ms/frame" % [
		label, build_ms, (Time.get_ticks_usec() - start) / 60000.0,
	])
	for preview: PlayableCharacterPreview in previews:
		preview.queue_free()
	await process_frame
	await process_frame
