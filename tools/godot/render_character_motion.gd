extends Node2D
## Visual-QA fixture: one character through a scripted gameplay timeline, for frame-by-frame review.
##
## A real WispPlayer (the production controller) wears the character on a plain arena and is driven
## through spawn, a touch aim and swipe, dash kills, a mid-dash turn, a straight-down dash, a hit,
## a boss-victory pulse and death. Every frame prints `[Motion]` with the player's position,
## controller state, visual state and heading so `tools/art/motion_contact_sheet.py` can crop the
## frames.
##
## WISP_MOTION_SCALE slows the capture (0.25 = quarter speed; one physics tick still lands on every
## captured frame, so the dash stays smooth); WISP_MOTION_CLIP=1 runs the shorter
## dash-showcase timeline (launch, kill accent, mid-dash turn, dive and landing) with a zoomed camera
## and an on-screen state label, for a slow-motion clip.
##
## Usage (WISP_CHARACTER = veyra | rook | morrow | any form id):
##   WISP_CHARACTER=rook "$GODOT" --path . --resolution 540x960 --fixed-fps 60 \
##     --write-movie logs/motion/rook/frame.png --quit-after 440 \
##     res://tools/godot/render_character_motion.tscn
##   python3 tools/art/motion_contact_sheet.py rook

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/wisp_player.tscn")
const CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
const FEEL: RunFeelTuning = preload("res://data/feel/default_run_feel_tuning.tres")
const ARENA := Rect2(140.0, 420.0, 800.0, 1100.0)

var _player: WispPlayer
var _frame: int = 0
## Clip mode: game time since the fixture started, and the events still to fire.
var _clip: bool = false
var _time: float = 0.0
var _pending: Array = []
var _label: Label
var _camera: Camera2D
## Screen point the scripted swipe starts from; only the drag vector matters to the controller.
var _drag_origin: Vector2 = Vector2.ZERO
var _character: String = "veyra"
var _slow: float = 1.0


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.09, 0.09, 0.14)
	background.size = Vector2(1080.0, 1920.0)
	add_child(background)
	var outline := Line2D.new()
	outline.points = PackedVector2Array([
		ARENA.position, Vector2(ARENA.end.x, ARENA.position.y), ARENA.end,
		Vector2(ARENA.position.x, ARENA.end.y), ARENA.position,
	])
	outline.width = 3.0
	outline.default_color = Color(0.3, 0.3, 0.42)
	add_child(outline)
	var form_id := StringName(OS.get_environment("WISP_CHARACTER"))
	if form_id.is_empty():
		form_id = &"veyra"
	var form: FormData = CATALOG.get_form(form_id)
	_character = form.display_name
	_player = PLAYER_SCENE.instantiate() as WispPlayer
	add_child(_player)
	_player.set_arena_rect(ARENA)
	_player.set_momentum_presentation(FEEL, form.tint)
	_player.set_cosmetic_form(form.texture, form.tint, form.visual_scene)
	_slow = maxf(0.05, float(OS.get_environment("WISP_MOTION_SCALE")) if not OS.get_environment(
		"WISP_MOTION_SCALE"
	).is_empty() else 1.0)
	# Godot already scales the physics delta by the time scale, so at --fixed-fps 60 this is still one
	# physics tick per captured frame: the dash travels as smoothly as the rig animates.
	Engine.time_scale = _slow
	_clip = OS.get_environment("WISP_MOTION_CLIP") == "1"
	if _clip:
		_build_clip_stage(form)
	print("[Motion] character=%s slow=%.2f clip=%s" % [form.form_id, _slow, _clip])


func _physics_process(delta: float) -> void:
	if _clip:
		_advance_clip(delta)
		return
	_frame += 1
	var start: Vector2 = _player.global_position
	match _frame:
		40:
			_touch(start, true)
		41, 44, 47, 50, 53:
			_drag(start + Vector2(0.4, -1.0).normalized() * (_frame - 38) * 12.0)
		60:
			_touch(start + Vector2(0.4, -1.0).normalized() * 180.0, false)
		68:
			_player.play_attack_visual()
		110:
			_player.request_dash(Vector2(-1.0, -0.35))
		117:
			_player.redirect_dash(Vector2(-0.2, 1.0))
		120, 121:
			_player.play_attack_visual()
		160:
			_player.request_dash(Vector2.UP)
		195:
			# From the top edge: a straight-down dash turns the character upside down.
			_player.request_dash(Vector2.DOWN)
		240:
			_player.request_dash(Vector2.RIGHT)
		245:
			_player.take_hazard_damage(Vector2(ARENA.end.x - 60.0, ARENA.get_center().y))
		300:
			_player.play_victory(0.9)
		370:
			_player.request_dash(Vector2(0.3, 1.0))
		385:
			(_player.get_node("%HealthComponent") as HealthComponent).apply_damage(99)
	var visual: PlayableCharacterVisual = _player.get_character_visual()
	print("[Motion] frame=%d pos=%.1f,%.1f state=%s visual=%s heading=%.3f" % [
		_frame, _player.global_position.x, _player.global_position.y,
		WispPlayer.State.keys()[_player.state],
		visual.get_current_visual_state() if visual != null else &"-",
		visual.rotation if visual != null else 0.0,
	])


func _touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = at
	event.pressed = pressed
	get_viewport().push_input(event)


func _drag(at: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = at
	get_viewport().push_input(event)


## Camera, caption and event list of the dash showcase.
func _build_clip_stage(form: FormData) -> void:
	# A close camera that trails the player: the clip is for judging the rig, not the arena.
	_drag_origin = Vector2(540.0, 1200.0)
	_camera = Camera2D.new()
	_camera.position = _player.global_position
	_camera.zoom = Vector2(2.6, 2.6)
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 7.0
	add_child(_camera)
	var layer := CanvasLayer.new()
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(48.0, 48.0)
	_label.add_theme_font_size_override(&"font_size", 44)
	_label.add_theme_color_override(&"font_color", form.tint.lightened(0.4))
	layer.add_child(_label)
	# [game seconds, what happens]: hold to aim (the pre-attack coil), release into a dive, a
	# mid-dash turn, then a climb to the ceiling and a drop back to the floor.
	_pending = [
		# The finger goes down only after the spawn finishes, or the controller is not aiming yet.
		[0.60, "press", Vector2.ZERO],
		[0.68, "drag", Vector2(0.45, -1.0)],
		[0.78, "drag", Vector2(0.45, -1.0)],
		[0.92, "drag", Vector2(0.5, -1.0)],
		[1.25, "release", Vector2(0.5, -1.0)],
		[1.35, "kill", Vector2.ZERO],
		[1.95, "dash", Vector2(-1.0, -0.25)],
		[2.05, "turn", Vector2(0.1, 1.0)],
		[2.13, "kill", Vector2.ZERO],
		[2.80, "dash", Vector2.UP],
		[3.50, "dash", Vector2.DOWN],
	]


func _advance_clip(delta: float) -> void:
	_time += delta
	while not _pending.is_empty() and _time >= float(_pending[0][0]):
		var event: Array = _pending.pop_front()
		var what: String = event[1]
		var direction: Vector2 = event[2]
		match what:
			"dash":
				_player.request_dash(direction)
			"turn":
				_player.redirect_dash(direction)
			"kill":
				_player.play_attack_visual()
			"press":
				_touch(_drag_origin, true)
			"drag":
				_drag(_drag_origin + direction.normalized() * 260.0)
			"release":
				_touch(_drag_origin + direction.normalized() * 260.0, false)
	_camera.position = _player.global_position
	var visual: PlayableCharacterVisual = _player.get_character_visual()
	_label.text = "%s   ·   %d× slow motion   ·   %s" % [
		_character, roundi(1.0 / _slow),
		visual.get_current_visual_state() if visual != null else &"-",
	]
