extends Node2D
## Visual-QA fixture: every rigged character beside its reference portrait, at rest and mid-dash.
##
## Row per character: the extracted `preview.png` (the generated reference pose), the live rig in
## its menu idle, and the live rig driven like the gameplay controller in a rightward dash. Set
## WISP_LINEUP_POSE (`attack`, `hit`, `aim`, `victory`) to swap the dash column for another
## state.
##
## Usage:
##   tools/screenshot.sh res://tools/godot/render_character_lineup.tscn 90 540x960

const CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
## Row height and rig size at three rigged characters; both shrink as the roster grows so every
## character still fits one 1080x1920 sheet.
const ROW_HEIGHT: float = 600.0
const RIG_HEIGHT: float = 420.0
const DESIGN_HEIGHT: float = 1920.0


static func rigged_forms(catalog: FormCatalog) -> Array[FormData]:
	var rigged: Array[FormData] = []
	for form: FormData in catalog.load_forms():
		if form.visual_scene != null:
			rigged.append(form)
	return rigged


var _driven: Array[PlayableCharacterVisual] = []
var _pose: String = "dash"
var _rig_height: float = RIG_HEIGHT


func _ready() -> void:
	_pose = OS.get_environment("WISP_LINEUP_POSE")
	if _pose.is_empty():
		_pose = "dash"
	var background := ColorRect.new()
	background.color = Color(0.07, 0.07, 0.12)
	background.size = Vector2(1080.0, DESIGN_HEIGHT)
	add_child(background)
	var forms: Array[FormData] = rigged_forms(CATALOG)
	var fit: float = minf(1.0, DESIGN_HEIGHT / maxf(1.0, ROW_HEIGHT * float(forms.size())))
	var row_height: float = ROW_HEIGHT * fit
	var rig_height: float = RIG_HEIGHT * fit
	_rig_height = rig_height
	var row: int = 0
	for form: FormData in forms:
		var centre_y: float = row_height * 0.55 + row * row_height
		var reference := Sprite2D.new()
		reference.texture = form.texture
		reference.position = Vector2(180.0, centre_y)
		reference.scale = Vector2.ONE * (rig_height / form.texture.get_size().y)
		add_child(reference)
		var label := Label.new()
		label.text = "%s  (reference | idle | %s)" % [form.display_name, _pose]
		label.position = Vector2(30.0, centre_y - row_height * 0.48)
		label.add_theme_font_size_override(&"font_size", int(30.0 * fit))
		add_child(label)
		var idle := form.visual_scene.instantiate() as PlayableCharacterVisual
		add_child(idle)
		idle.set_preview_mode(true)
		_place(idle, Vector2(520.0, centre_y), rig_height)
		var bounds: Rect2 = idle.get_layer_bounds()
		print("[Lineup] %s bounds=%s size=%s centre=%s design_size=%.0f preview_center=%s" % [
			form.form_id, bounds, bounds.size, bounds.get_center(), idle.get_design_size(),
			idle.preview_center,
		])
		var driven := form.visual_scene.instantiate() as PlayableCharacterVisual
		add_child(driven)
		driven.position = Vector2(860.0, centre_y)
		_driven.append(driven)
		row += 1


func _process(_delta: float) -> void:
	for visual: PlayableCharacterVisual in _driven:
		var state: StringName = PlayableCharacterVisual.DASH_LOOP
		var direction := Vector2.RIGHT
		var speed: float = 1.0
		match _pose:
			"attack":
				if visual.get_current_visual_state() != PlayableCharacterVisual.ATTACK:
					visual.play_attack()
			"hit":
				state = PlayableCharacterVisual.HIT_REACTION
				speed = 0.0
			"aim":
				state = PlayableCharacterVisual.AIM_CHARGE
				direction = Vector2(0.7, -0.7)
				speed = 0.0
			"victory":
				state = PlayableCharacterVisual.VICTORY
				speed = 0.0
		visual.sync_controller(_rig_height, 1.0, state, direction, speed)


func _place(visual: PlayableCharacterVisual, centre: Vector2, rig_height: float) -> void:
	var rig_scale: float = rig_height / visual.get_design_size()
	visual.scale = Vector2.ONE * rig_scale
	visual.position = centre - visual.preview_center * rig_scale
