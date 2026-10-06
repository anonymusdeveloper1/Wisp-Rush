class_name ArenaVisual
extends Control
## The arena a run is played on, drawn as a scene: the game's one arena is SIMULATION, a
## [SciFiBoardVisual] (owner 2026-10-05, ADR-0027).
##
## GameWorld shows the arena's scene ([member ArenaSkinData.visual_scene_path]) under everything else.
## [method fit] lays it out for the screen and returns the floor exactly as drawn, and GameWorld takes
## the walls, enemy placement and dash collision from that rectangle, so play never leaves the drawn
## floor. Pausable; the arena stills its motion under Reduced Motion ([method set_reduced_motion]).
##
## An arena may draw the run's HUD in itself ([method has_board_hud], ADR-0024), and enemy arrivals
## and a boss's appearance ([method show_enemy_arrival], [method show_boss_appearance], ADR-0025);
## GameWorld hands it each spawn, and the arena only reads the actor's own progress, so the effect
## never changes when anything arrives.

## A board arena's own pause button was pressed ([method has_board_hud], ADR-0024).
signal hud_pause_pressed

## Design pixels the arena reaches past the screen, so screen shake never shows its edge
## (GameWorld's BACKGROUND_OVERSCAN).
@export var backdrop_overscan: float = 16.0

var _floor_rect: Rect2 = Rect2()
var _reduced_motion: bool = false
## Design pixels kept clear at the bottom of the screen (the phone's gesture bar), for an arena that
## lays itself out against it ([method set_safe_bottom]).
var _safe_bottom: float = 0.0


## Lays the arena out for a [param view_size] screen whose HUD starts [param safe_top] below its top,
## and returns the floor in the same coordinates (this node's, which are GameWorld's).
func fit(_view_size: Vector2, _safe_top: float) -> Rect2:
	return _floor_rect


## The floor as last laid out by [method fit], in this node's coordinates.
func get_floor_rect() -> Rect2:
	return _floor_rect


## Whether the arena draws the run's HUD in itself (a board arena, ADR-0024): GameWorld then hides its
## own HUD bars and buttons and feeds [method set_board_hud] each frame.
func has_board_hud() -> bool:
	return false


## The run's HUD values for a board arena to show. Keys: `score` and `rift_points` (text), `rp_icon`
## and `boss_icon` (Texture2D), `ward_stock` (int), `ward_active` (bool), `rush` and `boss_health`
## (0..1), `boss` (bool, a boss fight is on), `pause` (bool, the pause button is offered).
func set_board_hud(_state: Dictionary) -> void:
	pass


## Where a board arena draws a HUD [param element] (`rush`, `items`), in this node's coordinates, for a
## host that points at it (the Tutorial); empty when the arena does not draw it.
func get_hud_rect(_element: StringName) -> Rect2:
	return Rect2()


## The screen's bottom safe inset in design pixels, given before [method fit]; an arena that keeps
## its frame above the gesture bar uses it (0 = none).
func set_safe_bottom(inset: float) -> void:
	_safe_bottom = maxf(0.0, inset)


## An enemy has just spawned at [param enemy]'s position and is arriving; [param progress] returns how
## far its arrival has run, 0..1, and 1 once it is over ([method EnemyActor.get_arrival_progress]).
## Returns true when this arena draws the arrival itself: GameWorld then hides the enemy's own arrival
## ring. The default draws nothing. (The arena reads the actors only through these arguments: naming
## the actor classes in the arena scripts left a resource in use at exit in `check_scripts.gd`,
## 2026-10-04.)
func show_enemy_arrival(_enemy: Node2D, _progress: Callable) -> bool:
	return false


## A boss has just been placed and configured at [param boss]'s position; [param progress] returns how
## far its appearance has run, 0..1, 1 once it is over, or a negative value when the boss does not say
## ([method BossActor.get_intro_progress]). The default draws nothing.
func show_boss_appearance(_boss: Node2D, _progress: Callable) -> void:
	pass


## Clears every spawn effect now (the run ended).
func clear_spawn_effects() -> void:
	pass


## Stills the arena's motion (true) or lets it play (false).
func set_reduced_motion(enabled: bool) -> void:
	_reduced_motion = enabled
	if is_node_ready():
		_apply_reduced_motion()


## Hook for the arena's script: apply [member _reduced_motion] to its motion.
func _apply_reduced_motion() -> void:
	pass
