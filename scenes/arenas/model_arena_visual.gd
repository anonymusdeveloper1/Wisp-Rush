class_name ModelArenaVisual
extends ArenaVisual
## An Endless arena drawn live in 3D: a model holding the playable floor (ADR-0023).
##
## `%View` (a stretched SubViewportContainer) shows `%World`, a SubViewport with its own 3D world;
## `%Model` holds the model at the origin of that world, unmoved, so [member layout] (measured on
## the model by its build script) is in world space. `%Camera` looks straight down -Z at the
## model's floor, which faces it, and only ever moves, never turns, so the floor is always drawn as
## an exact rectangle. [method fit] makes the floor [member floor_width_share] of the screen's width,
## centres it, puts the eye [member eye_clear] under the HUD's safe top (shrinking the floor if its
## bottom would pass [member bottom_margin]), places the camera to draw it there and returns that
## rectangle.
##
## With [member zoom_intro] (owner 2026-10-01, GDD §14 #69) the arena opens on the whole model and
## its scenery, then slowly zooms in until the floor fills the whole screen, the HUD drawn over it
## ([member play_fills_screen]; or, with that off, the screen under the HUD:
## [member play_hud_clear], [member play_side_margin], [member play_bottom_margin]); that zoomed-in
## floor is what [method fit] returns. A tap skips the zoom; Reduced Motion cuts straight to it, and
## GameWorld skips it on a run started again from its own dialogs.
##
## The head breathes: its bone rises and nods slowly and steadily ([member breath_period],
## [member breath_degrees], [member breath_rise]). The arena's own script, which extends this one,
## adds the scenery and effects and reads [member _time]. Pausable; Reduced Motion holds the head at
## rest and stops the clock.

enum IntroState { WAITING, PLAYING, DONE }

## Where the floor, eye, flames and skulls are on the model.
@export var layout: ModelArenaLayout
## The floor's width as a share of the screen's width, when the screen is tall enough for it.
@export_range(0.2, 0.9) var floor_width_share: float = 0.461
## Design pixels between the HUD's safe top and the eye, so the HUD's bars stay clear of it.
@export var eye_clear: float = 230.0
## Design pixels kept between the floor's bottom and the screen's.
@export var bottom_margin: float = 40.0
## The camera's vertical field of view, in degrees: small keeps the perspective mild.
@export_range(5.0, 90.0) var fov_degrees: float = 25.0
@export_group("Zoom intro")
## Open each run on the whole model, then zoom in until the floor fills the screen under the HUD.
@export var zoom_intro: bool = false
## Seconds the opening shot holds still before the zoom starts.
@export var intro_hold: float = 0.8
## Seconds the zoom takes.
@export var intro_seconds: float = 2.5
## The model's height as a share of the screen's height in the opening shot.
@export_range(0.3, 1.0) var intro_fill: float = 0.86
## Zoomed in, the floor is as big as the whole screen allows, centred on it, with the HUD drawn over
## it (owner, 2026-10-02). Off: it fills the screen under the HUD, with the margins below.
@export var play_fills_screen: bool = true
## Zoomed in: design pixels between the HUD's safe top and the floor (the HUD's buttons reach 262).
@export var play_hud_clear: float = 280.0
## Zoomed in: design pixels kept at least between the floor and each side of the screen.
@export var play_side_margin: float = 24.0
## Zoomed in: design pixels kept between the floor's bottom and the screen's.
@export var play_bottom_margin: float = 40.0
@export_group("Breathing")
## Seconds per breath.
@export var breath_period: float = 4.8
## How far the head nods through a breath, in degrees either way.
@export var breath_degrees: float = 1.2
## How far the head rises on the in-breath, in model units.
@export var breath_rise: float = 0.004

## Seconds of motion so far: stops while paused and under Reduced Motion.
var _time: float = 0.0
## The SubViewport's size from the last [method fit] (the screen plus the overscan on every side).
var _port_size := Vector2.ZERO
var _tan_half_fov: float = 0.0
## Where the camera draws the floor at [member _floor_rect] (play), and where the opening shot starts.
var _play_camera := Vector3.ZERO
var _intro_camera := Vector3.ZERO
## The camera the scenery is laid out for: the opening shot's when there is one (it sees the most).
var _layout_camera := Vector3.ZERO
var _intro_state: IntroState = IntroState.WAITING
var _intro_time: float = 0.0
var _skeleton: Skeleton3D
var _head_index: int = -1
var _head_rest := Transform3D()
var _nod_axis := Vector3.RIGHT
var _rise_axis := Vector3.UP

@onready var _view: SubViewportContainer = %View
@onready var _world: SubViewport = %World
@onready var _camera: Camera3D = %Camera
@onready var _model: Node3D = %Model


func _ready() -> void:
	var skeletons: Array[Node] = _model.find_children("*", "Skeleton3D", true, false)
	if not skeletons.is_empty():
		_skeleton = skeletons[0] as Skeleton3D
		_head_index = _skeleton.find_bone(String(layout.head_bone)) if layout != null else -1
	if _head_index >= 0:
		_head_rest = _skeleton.get_bone_rest(_head_index)
		var global_rest: Transform3D = _skeleton.get_bone_global_rest(_head_index)
		_nod_axis = (global_rest.basis.inverse() * Vector3.RIGHT).normalized()
		var parent: int = _skeleton.get_bone_parent(_head_index)
		var parent_basis: Basis = _skeleton.get_bone_global_rest(parent).basis if parent >= 0 else Basis()
		_rise_axis = (parent_basis.inverse() * Vector3.UP).normalized()
	else:
		push_warning("[ModelArenaVisual] %s has no head bone to breathe" % name)
	if not zoom_intro:
		_intro_state = IntroState.DONE
	_apply_reduced_motion()


func _process(delta: float) -> void:
	if _intro_state == IntroState.PLAYING:
		_intro_time += delta
		_place_camera()
		if _intro_time >= intro_hold + intro_seconds:
			_finish_intro()
	if _reduced_motion:
		return
	_time += delta
	_breathe()


func fit(view_size: Vector2, safe_top: float) -> Rect2:
	if layout == null:
		return Rect2()
	var over := Vector2(backdrop_overscan, backdrop_overscan)
	_port_size = view_size + over * 2.0
	_view.position = -over
	_view.size = _port_size
	_camera.fov = fov_degrees
	_tan_half_fov = tan(deg_to_rad(fov_degrees) * 0.5)
	var floor_units: Vector2 = layout.floor_rect.size
	var unit: float
	if zoom_intro:
		# Zoomed in: the floor as big as the space allows, centred in it - the whole screen, or the
		# screen under the HUD.
		var room := Rect2(Vector2.ZERO, view_size)
		if not play_fills_screen:
			room = Rect2(
				Vector2(play_side_margin, safe_top + play_hud_clear),
				Vector2(view_size.x - 2.0 * play_side_margin,
					view_size.y - safe_top - play_hud_clear - play_bottom_margin))
		unit = minf(room.size.x / floor_units.x, room.size.y / floor_units.y)
		var floor_top: float = over.y + room.position.y + (room.size.y - floor_units.y * unit) * 0.5
		_play_camera = _camera_for(unit, floor_top)
		_intro_camera = _opening_camera(view_size)
		_layout_camera = _intro_camera
	else:
		var eye_y: float = over.y + safe_top + eye_clear
		# The eye sits above the floor's top by its height on the model, so a floor taller than this
		# would pass the bottom margin.
		var eye_above_bottom: float = layout.eye.y - layout.floor_rect.position.y
		var room_y: float = over.y + view_size.y - bottom_margin - eye_y
		var wide: float = view_size.x * floor_width_share * floor_units.y / floor_units.x
		var height: float = minf(wide, room_y * floor_units.y / eye_above_bottom)
		unit = height / floor_units.y
		var distance: float = _port_size.y * 0.5 / (unit * _tan_half_fov)
		var eye_unit: float = _port_size.y * 0.5 / ((distance + layout.floor_z - layout.eye.z) * _tan_half_fov)
		var camera_y: float = layout.eye.y - (_port_size.y * 0.5 - eye_y) / eye_unit
		_play_camera = Vector3(layout.floor_rect.get_center().x, camera_y, layout.floor_z + distance)
		_layout_camera = _play_camera
	_floor_rect = _floor_rect_from(_play_camera)
	_place_camera()
	_after_fit(view_size)
	return _floor_rect


func get_drawn_floor_rect() -> Rect2:
	return _floor_rect_from(_camera.position)


func has_intro() -> bool:
	return zoom_intro


func play_intro() -> void:
	if not zoom_intro or _intro_state == IntroState.DONE or _reduced_motion:
		_finish_intro()
		return
	_intro_state = IntroState.PLAYING
	_intro_time = 0.0
	_place_camera()


func skip_intro() -> void:
	if _intro_state != IntroState.DONE:
		_finish_intro()


## The camera that draws the floor [param unit] design pixels per model unit, centred across the
## screen, its top at [param floor_top] (a SubViewport row).
func _camera_for(unit: float, floor_top: float) -> Vector3:
	var distance: float = _port_size.y * 0.5 / (unit * _tan_half_fov)
	var camera_y: float = layout.floor_rect.end.y - (_port_size.y * 0.5 - floor_top) / unit
	return Vector3(layout.floor_rect.get_center().x, camera_y, layout.floor_z + distance)


## The opening shot: the whole model [member intro_fill] of the screen's height (or its width, if
## that is tighter), centred on screen.
func _opening_camera(view_size: Vector2) -> Vector3:
	var bounds: AABB = _model_bounds()
	if not bounds.has_volume():
		return _play_camera
	var unit: float = minf(view_size.y * intro_fill / bounds.size.y, view_size.x * intro_fill / bounds.size.x)
	var distance: float = _port_size.y * 0.5 / (unit * _tan_half_fov)
	var centre: Vector3 = bounds.get_center()
	return Vector3(centre.x, centre.y, layout.floor_z + distance)


## The model's bounds in the world, from its meshes at rest.
func _model_bounds() -> AABB:
	var bounds := AABB()
	var first: bool = true
	for node: Node in _model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds


## The floor as a camera at [param eye] draws it, in this node's coordinates.
func _floor_rect_from(eye: Vector3) -> Rect2:
	var unit: float = _port_size.y * 0.5 / ((eye.z - layout.floor_z) * _tan_half_fov)
	var left: float = _port_size.x * 0.5 + (layout.floor_rect.position.x - eye.x) * unit
	var top: float = _port_size.y * 0.5 - (layout.floor_rect.end.y - eye.y) * unit
	var over := Vector2(backdrop_overscan, backdrop_overscan)
	return Rect2((Vector2(left, top) - over).round(), (layout.floor_rect.size * unit).round())


## Puts the camera where the opening shot stands, mid-zoom or at play. The zoom eases the floor's
## drawn size (not the camera's distance) so it grows at an even pace, slow at both ends.
func _place_camera() -> void:
	var eye: Vector3 = _play_camera
	if _intro_state == IntroState.WAITING:
		eye = _intro_camera
	elif _intro_state == IntroState.PLAYING:
		var linear: float = clampf((_intro_time - intro_hold) / maxf(intro_seconds, 0.001), 0.0, 1.0)
		var eased: float = linear * linear * linear * (linear * (linear * 6.0 - 15.0) + 10.0)
		var near: float = 1.0 / (_play_camera.z - layout.floor_z)
		var far: float = 1.0 / (_intro_camera.z - layout.floor_z)
		var distance: float = 1.0 / lerpf(far, near, eased)
		var start := Vector2(_intro_camera.x, _intro_camera.y)
		var end := Vector2(_play_camera.x, _play_camera.y)
		var across: Vector2 = start.lerp(end, eased)
		eye = Vector3(across.x, across.y, layout.floor_z + distance)
	_camera.position = eye
	_camera_moved()


func _finish_intro() -> void:
	_intro_state = IntroState.DONE
	_place_camera()
	intro_finished.emit()


## The world point [param distance] in front of the camera that is drawn at [param screen], a point
## of the SubViewport (the screen plus the overscan), for the camera the scenery is laid out for.
func _plane_point(screen: Vector2, distance: float) -> Vector3:
	var per_pixel: float = 2.0 * distance * _tan_half_fov / _port_size.y
	var offset: Vector2 = (screen - _port_size * 0.5) * per_pixel
	var eye: Vector3 = _layout_camera
	return Vector3(eye.x + offset.x, eye.y - offset.y, eye.z - distance)


## The distance from the camera the scenery is laid out for to the model's floor.
func _floor_distance() -> float:
	return _layout_camera.z - layout.floor_z


## Attaches [param node] to the head bone so it moves with the head, at [param model_point] (a
## point of the model at rest). Returns false when the model has no head bone.
func _attach_to_head(node: Node3D, model_point: Vector3) -> bool:
	if _head_index < 0:
		return false
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = String(layout.head_bone)
	_skeleton.add_child(attachment)
	var in_skeleton: Vector3 = (_skeleton.global_transform.affine_inverse() * _model.global_transform) * model_point
	node.position = _skeleton.get_bone_global_rest(_head_index).affine_inverse() * in_skeleton
	attachment.add_child(node)
	return true


## Hook for the arena's script: lay out scenery that follows the screen, after [method fit] placed
## the camera.
func _after_fit(_view_size: Vector2) -> void:
	pass


## Hook for the arena's script: the camera has moved (each frame of the zoom).
func _camera_moved() -> void:
	pass


func _apply_reduced_motion() -> void:
	if _reduced_motion and _intro_state == IntroState.PLAYING:
		_finish_intro()
	if _head_index < 0:
		return
	if _reduced_motion:
		_skeleton.set_bone_pose_rotation(_head_index, _head_rest.basis.get_rotation_quaternion())
		_skeleton.set_bone_pose_position(_head_index, _head_rest.origin)
	else:
		_breathe()


func _breathe() -> void:
	if _head_index < 0 or breath_period <= 0.0:
		return
	# 0 at the bottom of the out-breath, 1 at the top of the in-breath, eased at both ends.
	var breath: float = 0.5 - 0.5 * cos(TAU * _time / breath_period)
	var angle: float = deg_to_rad(breath_degrees) * (1.0 - 2.0 * breath)
	var turn := Quaternion(_nod_axis, angle)
	_skeleton.set_bone_pose_rotation(_head_index, _head_rest.basis.get_rotation_quaternion() * turn)
	_skeleton.set_bone_pose_position(_head_index, _head_rest.origin + _rise_axis * breath_rise * breath)
