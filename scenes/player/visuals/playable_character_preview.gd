class_name PlayableCharacterPreview
extends Control
## Control-hosted live preview of a [FormData]: its animated rig, or its portrait on the shared rig.
##
## Menus (Home, the Shop's CHARACTERS tab) use it so a character idles, reacts when it is picked and
## celebrates when it is bought. Presentation only; it never touches the save.

## Single-image forms animate on the shared base scene when [method set_form] asks for it.
const PORTRAIT_SCENE: PackedScene = preload(
	"res://scenes/player/visuals/playable_character_visual.tscn"
)

## Share of the shorter side the character's design height fills.
@export_range(0.1, 1.5, 0.01) var fill_ratio: float = 0.9

var _visual: PlayableCharacterVisual
var _reduced_motion: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout_visual)


## Replaces the preview with [param form]'s animated rig and returns true. A form without a rig
## shows its portrait on the shared rig when [param animate_portrait] is set; otherwise this returns
## false and the caller keeps its own static picture.
func set_form(form: FormData, animate_portrait: bool = false) -> bool:
	_clear_visual()
	if form == null:
		return false
	var scene: PackedScene = form.visual_scene
	if scene == null:
		if not animate_portrait or form.texture == null:
			return false
		scene = PORTRAIT_SCENE
	var instance: Node = scene.instantiate()
	_visual = instance as PlayableCharacterVisual
	if _visual == null:
		instance.queue_free()
		push_error("Form visual scene root must extend PlayableCharacterVisual")
		return false
	if form.visual_scene == null:
		_visual.portrait_texture = form.texture
	add_child(_visual)
	_visual.set_preview_mode(true)
	_visual.set_reduced_motion(_reduced_motion)
	_layout_visual()
	return true


## Keeps the preview legible while respecting the global Reduced Motion setting.
func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if _visual != null:
		_visual.set_reduced_motion(enabled)



## The live rig, exposed for animation tests.
func get_visual() -> PlayableCharacterVisual:
	return _visual


func _layout_visual() -> void:
	if _visual == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var available: float = minf(size.x, size.y) * fill_ratio
	var rig_scale: float = available / maxf(1.0, _visual.get_design_size())
	_visual.scale = Vector2.ONE * rig_scale
	_visual.position = size * 0.5 - _visual.preview_center * rig_scale


func _clear_visual() -> void:
	if _visual == null:
		return
	remove_child(_visual)
	_visual.queue_free()
	_visual = null
