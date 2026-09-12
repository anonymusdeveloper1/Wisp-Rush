class_name DebugOverlay
extends CanvasLayer
## Debug-build-only performance overlay (toggle with F3): FPS, frame/physics time, draw calls,
## objects, nodes, orphans, memory and live entity counts.
##
## Main creates it only when `OS.is_debug_build()`, so release exports never contain it. F3 is a
## raw key check on purpose: it is QA tooling, not a player-facing input action.

const REFRESH_SECONDS: float = 0.25

var _label: Label
var _refresh_remaining: float = 0.0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.position = Vector2(24.0, 24.0)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override(&"font_size", 22)
	_label.add_theme_color_override(&"font_color", Color(0.72, 1.0, 0.82))
	_label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	_label.add_theme_constant_override(&"outline_size", 6)
	add_child(_label)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F3:
		visible = not visible
		_refresh_remaining = 0.0
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not visible:
		return
	_refresh_remaining -= delta
	if _refresh_remaining > 0.0:
		return
	_refresh_remaining = REFRESH_SECONDS
	_label.text = build_report(get_tree())


## Returns the overlay text for the current frame.
static func build_report(tree: SceneTree) -> String:
	return "\n".join([
		"FPS %d   process %.2f ms   physics %.2f ms" % [
			int(Performance.get_monitor(Performance.TIME_FPS)),
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		],
		"DRAW CALLS %d   OBJECTS %d" % [
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		],
		"NODES %d   ORPHANS %d   MEM %.1f MB" % [
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
			Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		],
		"ENEMIES %d   HAZARDS %d   PICKUPS %d" % [
			tree.get_nodes_in_group(&"enemies").size(),
			tree.get_nodes_in_group(&"hazards").size(),
			tree.get_nodes_in_group(&"pickups").size(),
		],
	])
