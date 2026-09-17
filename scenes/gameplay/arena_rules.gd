class_name ArenaRules
extends RefCounted
## The one seam GameWorld reads for everything an arena decides: backdrop, floor, rule twist, boss
## cadence and pick, difficulty, roster and whether a boss ends the run.
##
## Built by `RunProfile.create_arena_rules()`. `RiftArenaRules` wraps a Rift level (story runs);
## `EndlessArenaRules` wraps the Endless catalog, a skin and a pool (Endless and the daily run).
## This base class is the neutral arena used when a run has no profile (F6 runs, fixtures): the
## scene's own backdrop, the legacy floor rectangle, no twist, the Reaper every four waves.

## Boss cadence of the neutral arena.
const DEFAULT_BOSS_WAVE_INTERVAL: int = 4


## Full-bleed backdrop, or null to keep the scene's own.
func get_background() -> Texture2D:
	return null


## Animated scenery over the background (`ArenaAmbience`); null (none) by default.
func get_scenery() -> ArenaSceneryData:
	return null


## Playable floor in background UV space; empty means the legacy rectangle.
func get_floor_polygon() -> PackedVector2Array:
	return PackedVector2Array()


## Mechanical twist GameWorld switches on; `&"none"` is the baseline.
func get_rule_key() -> StringName:
	return &"none"


## Waves between boss encounters; the boss arrives on every multiple.
func get_boss_wave_interval() -> int:
	return DEFAULT_BOSS_WAVE_INTERVAL


## Waves in one story level, or zero when bosses never end the run.
func get_level_waves() -> int:
	return 0


## Whether the boss of `wave` ends the run in victory.
func is_final_boss_wave(_wave: int) -> bool:
	return false


## WaveDirector threat multiplier after `cycle` bosses have been beaten.
func get_threat_multiplier(_cycle: int) -> float:
	return 1.0


## Enemy movement-speed multiplier after `cycle` bosses have been beaten.
func get_enemy_speed_scale(_cycle: int) -> float:
	return 1.0


## Maps an authored formation enemy kind onto the roster of `wave` in a run seeded `run_seed`.
func substitute_enemy(base_kind: StringName, _wave: int, _run_seed: int) -> StringName:
	return base_kind


## Player-facing name of the roster `wave` uses, or empty when the arena has a single roster.
func get_roster_name(_wave: int, _run_seed: int) -> String:
	return ""


## Boss id for the zero-based `boss_index`-th encounter of a run seeded `run_seed`.
func get_boss_id(_boss_index: int, _run_seed: int) -> StringName:
	return &"reaper"


## Rift id for the run summary and Rift bests; empty for arenas that are not a Rift.
func get_rift_id() -> StringName:
	return &""


## Arena skin id for the run summary; empty for Rifts.
func get_skin_id() -> StringName:
	return &""
