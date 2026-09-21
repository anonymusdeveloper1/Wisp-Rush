extends Node2D
## Visual-QA fixture: every painting Ilyra can show, on one board, driven through the real rig.
##
## One live [IlyraVisual] per cell, each asked for a state (and, for the four wall cells, a wall to
## rest against) exactly the way the controller and the menus ask for it. A cell keeps running until
## it actually shows the painting the cell is for and then stops choosing poses, so one-shots, the
## blink and the second frame of a cycle all hold still together instead of having to be caught in
## one lucky frame. The fixture prints a `[Ilyra]` line per cell and labels any painting it could
## not reach, which is the failure worth looking for.
##
## The scripted timeline (aim, dash-as-attack, mid-dash turn, hit, death) is the shared fixture:
##   WISP_CHARACTER=ilyra "$GODOT" --path . --resolution 540x960 --fixed-fps 60 \
##     --write-movie logs/motion/ilyra/frame.png --quit-after 440 \
##     res://tools/godot/render_character_motion.tscn
##   python3 tools/art/motion_contact_sheet.py ilyra
##
## Usage:
##   tools/screenshot.sh res://tools/godot/render_ilyra_poses.tscn 260 540x960

const CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
const FORM_ID: StringName = &"ilyra"
const COLUMNS: int = 2
const ROWS: int = 4
const BOARD := Vector2(1080.0, 1920.0)
## Share of a cell the character's design height fills.
const FILL: float = 0.66
## Frames a cell may run before the fixture gives up and labels the painting it is stuck on.
const PATIENCE: int = 220

## Every cell: the painting to hold, the state to ask for, the wall to rest against (absent for a
## character that rests on nothing), whether it is a menu preview, and how long to let it settle
## before freezing — the wall cells need their heading spring and counter-rotation to arrive first.
const CELLS: Array[Dictionary] = [
	# Five animations and no more (owner, 2026-09-20): her dash, her four painted walls and her menu
	# rest. Every other state resolves onto the wall she is standing against. Unlike the sheet
	# characters her pack paints `wall_right` outright, so it is a cell of its own rather than a
	# mirror of `wall_left`.
	{"pose": &"dash_loop_00", "state": &"dash_loop"},
	{"pose": &"storefront_welcome", "state": &"idle_hover", "menu": true},
	{"pose": &"dash_loop_01_attack", "state": &"attack", "caption": "dash contact"},
	{"pose": &"wall_bottom", "state": &"idle_hover", "normal": Vector2.UP, "settle": 90},
	{"pose": &"wall_top", "state": &"idle_hover", "normal": Vector2.DOWN, "settle": 90},
	{"pose": &"wall_left", "state": &"idle_hover", "normal": Vector2.RIGHT, "settle": 90},
	{"pose": &"wall_right", "state": &"idle_hover", "normal": Vector2.LEFT, "settle": 90},
]

## Drawn height of one cell's character, in board pixels; the wall cells hand it to the controller
## contract (`sync_controller` owns the rig's scale) instead of setting the node scale themselves.
var _cell_height: float = 0.0
var _visuals: Array[IlyraVisual] = []
var _captions: Array[Label] = []
var _frozen: Array[bool] = []
var _frames: int = 0


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.07, 0.07, 0.11)
	background.size = BOARD
	add_child(background)
	var form: FormData = CATALOG.get_form(FORM_ID)
	var cell := Vector2(BOARD.x / COLUMNS, BOARD.y / ROWS)
	_cell_height = minf(cell.x, cell.y) * FILL
	for index: int in CELLS.size():
		var spec: Dictionary = CELLS[index]
		var column: int = index % COLUMNS
		var row: int = index / COLUMNS
		var visual := form.visual_scene.instantiate() as IlyraVisual
		add_child(visual)
		# Only the cells marked as menu frames preview; the rest are asked for as a live character
		# would be, because that is the only way the gameplay paintings are reachable.
		visual.set_preview_mode(bool(spec.get("menu", false)))
		visual.scale = Vector2.ONE * (_cell_height / visual.get_design_size())
		visual.position = Vector2((column + 0.5) * cell.x, (row + 0.45) * cell.y)
		_visuals.append(visual)
		_frozen.append(false)
		var caption := Label.new()
		caption.text = String(spec.get("caption", spec["pose"]))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.size = Vector2(cell.x, 34.0)
		caption.position = Vector2(column * cell.x, (row + 0.88) * cell.y)
		caption.add_theme_font_size_override(&"font_size", 26)
		caption.add_theme_color_override(&"font_color", Color(0.78, 0.86, 1.0))
		add_child(caption)
		_captions.append(caption)


func _process(_delta: float) -> void:
	_frames += 1
	for index: int in _visuals.size():
		if _frozen[index]:
			continue
		var spec: Dictionary = CELLS[index]
		var visual: IlyraVisual = _visuals[index]
		if spec.has("normal"):
			visual.sync_controller(
				_cell_height, 1.0, spec["state"], Vector2.ZERO, 0.0, spec["normal"], 0.0
			)
		else:
			visual.request_state(spec["state"])
		var settled: bool = _frames >= int(spec.get("settle", 0))
		if settled and visual.get_current_pose() == spec["pose"]:
			_hold(visual)
			_frozen[index] = true
			print("[Ilyra] %-20s held after %d frames" % [spec["pose"], _frames])
		elif _frames > PATIENCE:
			_captions[index].text = "%s MISSING (%s)" % [spec["pose"], visual.get_current_pose()]
			_captions[index].add_theme_color_override(&"font_color", Color(1.0, 0.45, 0.5))
			_frozen[index] = true
			push_warning("render_ilyra_poses: never reached %s" % spec["pose"])


## Stops the cell on the painting it just reached and parks the shared body motion at rest, so every
## cell is drawn through the same transform. Without it the timed states keep running past the pose:
## death would have faded itself out long before the board is captured.
func _hold(visual: IlyraVisual) -> void:
	visual.set_process(false)
	(visual.get_node(^"%AnimationTree") as AnimationTree).active = false
	var motion := visual.get_node(^"%MotionRoot") as Node2D
	motion.transform = Transform2D.IDENTITY
	motion.modulate = Color.WHITE
