extends Node2D
## Visual-QA fixture: every animation a whole-frame character can play, on one board, through
## the real rig.
##
## One live [WholeFrameCharacterVisual] per cell, asked for a state — and, for the four wall cells, a wall
## to rest against — exactly the way the controller and the menus ask for it. A cell runs until the
## rig actually selects the animation the cell is for, then holds a nominated frame of it, so
## one-shots and loops all stand still together instead of having to be caught in one lucky frame.
## The fixture prints a `[WholeFrame]` line per cell and labels any animation it could not reach,
## which is the failure worth looking for.
##
## Usage:
##   WISP_CHARACTER=void tools/screenshot.sh \n##     res://tools/godot/render_whole_frame_states.tscn 260 540x960

const CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
## Which character the board draws; any whole-frame character in the catalog.
@export var default_form: StringName = &"verdant_shade"
const COLUMNS: int = 2
const ROWS: int = 3
const BOARD := Vector2(1080.0, 1920.0)
## Share of a cell the character's design height fills.
const FILL: float = 0.66
## Frames a cell may run before the fixture gives up and labels the animation it is stuck on.
const PATIENCE: int = 220

## Every cell: the animation to hold and which of its frames, the state to ask for, the wall to rest
## against (absent for a character resting on nothing), whether it is a menu preview, and how long
## to let it settle first — the wall cells need their counter-rotation to arrive before they freeze.
const CELLS: Array[Dictionary] = [
	{"anim": &"dash_loop", "state": &"dash_loop", "frame": 2, "caption": "dash_loop (contact)"},
	{"anim": &"storefront_idle", "state": &"idle_hover", "menu": true, "frame": 4},
	{"anim": &"wall_bottom", "state": &"idle_hover", "normal": Vector2.UP, "settle": 90},
	{"anim": &"wall_top", "state": &"idle_hover", "normal": Vector2.DOWN, "settle": 90},
	{"anim": &"wall_left", "state": &"idle_hover", "normal": Vector2.RIGHT, "settle": 90},
	{
		"anim": &"wall_left", "state": &"idle_hover", "normal": Vector2.LEFT, "settle": 90,
		"caption": "wall_right (mirrored)",
	},
]

## Drawn height of one cell's character, in board pixels; the wall cells hand it to the controller
## contract (`sync_controller` owns the rig's scale) instead of setting the node scale themselves.
var _cell_height: float = 0.0
var _visuals: Array[WholeFrameCharacterVisual] = []
var _captions: Array[Label] = []
var _frozen: Array[bool] = []
var _frames: int = 0


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.07, 0.09, 0.08)
	background.size = BOARD
	add_child(background)
	var chosen: String = OS.get_environment("WISP_CHARACTER")
	var form: FormData = CATALOG.get_form(
		StringName(chosen) if not chosen.is_empty() else default_form
	)
	var cell := Vector2(BOARD.x / COLUMNS, BOARD.y / ROWS)
	_cell_height = minf(cell.x, cell.y) * FILL
	for index: int in CELLS.size():
		var spec: Dictionary = CELLS[index]
		var column: int = index % COLUMNS
		var row: int = index / COLUMNS
		var visual := form.visual_scene.instantiate() as WholeFrameCharacterVisual
		add_child(visual)
		# Only the menu cells preview; the rest are asked for as a live character would be, because
		# that is the only way the gameplay and wall animations are reachable.
		visual.set_preview_mode(bool(spec.get("menu", false)))
		visual.scale = Vector2.ONE * (_cell_height / visual.get_design_size())
		visual.position = Vector2((column + 0.5) * cell.x, (row + 0.45) * cell.y)
		_visuals.append(visual)
		_frozen.append(false)
		var caption := Label.new()
		caption.text = String(spec.get("caption", spec["anim"]))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.size = Vector2(cell.x, 34.0)
		caption.position = Vector2(column * cell.x, (row + 0.86) * cell.y)
		caption.add_theme_font_size_override(&"font_size", 24)
		caption.add_theme_color_override(&"font_color", Color(0.72, 0.95, 0.76))
		add_child(caption)
		_captions.append(caption)


func _process(_delta: float) -> void:
	_frames += 1
	for index: int in _visuals.size():
		if _frozen[index]:
			continue
		var spec: Dictionary = CELLS[index]
		var visual: WholeFrameCharacterVisual = _visuals[index]
		if spec.has("normal"):
			visual.sync_controller(
				_cell_height, 1.0, spec["state"], Vector2.ZERO, 0.0, spec["normal"], 0.0
			)
		else:
			visual.request_state(spec["state"])
		var settled: bool = _frames >= int(spec.get("settle", 0))
		if settled and visual.get_current_animation() == spec["anim"]:
			_hold(visual, int(spec.get("frame", 0)))
			_frozen[index] = true
			print("[WholeFrame] %-22s held at frame %d after %d frames%s" % [
				visual.get_current_animation(), int(spec.get("frame", 0)), _frames,
				" (mirrored)" if visual.is_mirrored() else "",
			])
		elif _frames > PATIENCE:
			_captions[index].text = "%s MISSING (%s)" % [
				spec["anim"], visual.get_current_animation(),
			]
			_captions[index].add_theme_color_override(&"font_color", Color(1.0, 0.45, 0.5))
			_frozen[index] = true
			push_warning("render_whole_frame_states: never reached %s" % spec["anim"])


## Stops the cell on one frame of the animation it just reached and parks the shared body motion at
## rest, so every cell is drawn through the same transform. Without it the timed states keep running
## past the frame: death would have faded itself out long before the board is captured.
func _hold(visual: WholeFrameCharacterVisual, frame: int) -> void:
	var sprite := visual.get_node(^"%PoseSprite") as AnimatedSprite2D
	var count: int = sprite.sprite_frames.get_frame_count(sprite.animation)
	sprite.frame = clampi(frame, 0, maxi(0, count - 1))
	sprite.pause()
	visual.set_process(false)
	(visual.get_node(^"%AnimationTree") as AnimationTree).active = false
	var motion := visual.get_node(^"%MotionRoot") as Node2D
	motion.transform = Transform2D.IDENTITY
	motion.modulate = Color.WHITE
