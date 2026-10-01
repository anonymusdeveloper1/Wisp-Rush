class_name ArenaVisual
extends Control
## An Endless arena drawn as a scene instead of one painting: layered sprites or a 3D model.
##
## GameWorld shows it in place of the painted backdrop when the equipped arena has one
## ([member ArenaSkinData.visual_scene_path]; ADR-0021, ADR-0023). [method fit] lays it out for the
## screen and returns the floor exactly as drawn, and GameWorld takes the walls, enemy placement and
## dash collision from that rectangle, so play never leaves the drawn floor. Subclasses:
## [LayeredArenaVisual] (sprites on a texel grid) and [ModelArenaVisual] (a 3D model). Pausable; the
## arena stills its motion under Reduced Motion ([method set_reduced_motion]).
##
## An arena may have an opening shot before play ([method has_intro]): GameWorld then plays it with
## the Wisp and the HUD hidden and starts the run on [signal intro_finished] (the zoom of a 3D arena,
## ADR-0023).

## The opening shot has ended, played through or skipped; the floor is now drawn where [method fit]
## said.
signal intro_finished

## Design pixels the backdrop reaches past the screen, so screen shake never shows its edge
## (GameWorld's BACKGROUND_OVERSCAN).
@export var backdrop_overscan: float = 16.0

var _floor_rect: Rect2 = Rect2()
var _reduced_motion: bool = false


## Lays the arena out for a [param view_size] screen whose HUD starts [param safe_top] below its top,
## and returns the floor in the same coordinates (this node's, which are GameWorld's).
func fit(_view_size: Vector2, _safe_top: float) -> Rect2:
	return _floor_rect


## The floor as last laid out by [method fit], in this node's coordinates.
func get_floor_rect() -> Rect2:
	return _floor_rect


## The floor as it is drawn right now: [method get_floor_rect], except during an opening shot.
func get_drawn_floor_rect() -> Rect2:
	return _floor_rect


## Whether the arena opens with a shot before play.
func has_intro() -> bool:
	return false


## Starts the opening shot; [signal intro_finished] follows when it ends (at once when there is none).
func play_intro() -> void:
	intro_finished.emit()


## Ends the opening shot now, or before it starts (the player tapped, or the run skips it);
## [signal intro_finished] follows.
func skip_intro() -> void:
	pass


## Where the Wisp is, in this node's coordinates, for scenery that reacts to play.
func set_focus_point(_point: Vector2) -> void:
	pass


## Stills the arena's motion (true) or lets it play (false).
func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if is_node_ready():
		_apply_reduced_motion()


## Hook for the arena's script: apply [member _reduced_motion] to its motion.
func _apply_reduced_motion() -> void:
	pass
