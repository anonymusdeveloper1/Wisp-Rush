class_name BossActor
extends Node2D
## The one interface `GameWorld` drives every boss through.
##
## `ReaperBoss` (the old Reaper and its variants) and `GrimgrinBoss` (the first boss of the new set,
## 2026-09-27) extend it. A boss owns its own behaviour, drawing and danger geometry; `GameWorld`
## feeds it the arena and the Wisp, routes the Wisp's dashes into [method try_dash_hit], checks the
## Wisp against [method get_dangerous_circles] and [method get_dangerous_lanes], and spawns what it
## asks for. Every method here is a safe default a boss may override.

## Emitted when the one-based phase changes.
signal phase_changed(phase: int)
## Asks for Soul Wisps at these world positions (the Reaper's Teleport Hunt).
signal summon_requested(world_positions: PackedVector2Array)
## Asks for [param count] random regular enemies, keeping at most [param max_live] alive.
signal spawn_requested(count: int, max_live: int)
## Emitted after configuration and each hit that lands.
signal health_changed(current_health: int, maximum_health: int)
## Emitted after the boss's defeat plays out, with the encounter rewards.
signal defeated(world_position: Vector2, score_reward: int, rp_reward: int)


## Applies a boss variant's presentation and tuning. Call before [method configure].
func configure_variant(_data: BossData) -> void:
	pass


## Places the encounter in the arena and sets its health; [param health_override] > 0 replaces the
## encounter health (the Tutorial).
func configure(
	_arena_rect: Rect2,
	_target_position: Vector2,
	_encounter_index: int,
	_seed: int,
	_health_override: int = 0,
	) -> void:
	pass


## The Wisp's live position.
func set_target_position(_world_position: Vector2) -> void:
	pass


## Live arena bounds after a layout change; keeps health and phase.
func set_arena_rect(_arena_rect: Rect2) -> void:
	pass


## The painted floor, in screen space.
func set_arena_polygon(_polygon: PackedVector2Array) -> void:
	pass


## Where the Wisp last landed on a wall.
func set_last_edge_position(_world_position: Vector2) -> void:
	pass


## The Wisp's collision radius, for danger geometry sized to it.
func set_player_radius(_radius: float) -> void:
	pass


## Skips an introductory hold when the player dashes; attacks stay unskippable.
func skip_intro() -> void:
	pass


## How far the boss's appearance (its introductory hold) has run, 0..1, and 1 once it is over; for an
## arena that draws the appearance (ADR-0025). Negative when the boss does not say.
func get_intro_progress() -> float:
	return -1.0


func get_current_health() -> int:
	return 0


func get_maximum_health() -> int:
	return 0


## Whether a dash could damage the boss right now.
func is_core_exposed() -> bool:
	return false


func get_phase() -> int:
	return 1


## The name of [param phase] shown on the boss bar.
func get_phase_name(_phase: int) -> String:
	return ""


## Current circle dangers as world x/y/radius triples.
func get_dangerous_circles() -> Array[Vector3]:
	var none: Array[Vector3] = []
	return none


## Current lane dangers as pairs of world points.
func get_dangerous_lanes() -> Array[PackedVector2Array]:
	var none: Array[PackedVector2Array] = []
	return none


## Half width of every lane danger.
func get_lane_radius() -> float:
	return 0.0


## Applies one dash segment; returns whether it hit.
func try_dash_hit(
	_segment_start: Vector2,
	_segment_end: Vector2,
	_corridor_radius: float,
	_damage: int,
	_dash_id: int,
	) -> bool:
	return false


## Seconds of the victory beat after the defeat.
func get_victory_duration() -> float:
	return 1.0


## Experience the victory grants.
func get_experience_reward() -> int:
	return 0


## The short name the victory callout uses ("<NAME> VANQUISHED").
func get_defeat_name() -> String:
	return "BOSS"
