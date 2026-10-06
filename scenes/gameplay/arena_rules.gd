class_name ArenaRules
extends RefCounted
## The one seam GameWorld reads for everything an arena decides: its scene (and so its floor), boss
## cadence and pick, and difficulty. Which enemies come is the run's `EnemyRamp`, not the arena's.
##
## Built by `RunProfile.create_arena_rules()`. `EndlessArenaRules` wraps the Endless catalog, a skin
## and a pool (Endless, the daily run and the tutorial). This base class is the neutral arena used
## when a run has no profile (F6 runs, fixtures): the game's one arena, SIMULATION (owner 2026-10-05,
## ADR-0027), and the Reaper every four waves.

## Boss cadence of the neutral arena.
const DEFAULT_BOSS_WAVE_INTERVAL: int = 4
## The game's one arena (SIMULATION), which the neutral arena plays on too. Loaded when asked, not
## preloaded: its script names GameWorld, which names this class.
const DEFAULT_ARENA_PATH: String = "res://scenes/arenas/sci_fi_simulation_v1.tscn"


## The arena's scene (an `ArenaVisual`), which a run shows and takes its floor from.
func get_visual_scene() -> PackedScene:
	return load(DEFAULT_ARENA_PATH) as PackedScene


## Waves between boss encounters; the boss arrives on every multiple.
func get_boss_wave_interval() -> int:
	return DEFAULT_BOSS_WAVE_INTERVAL


## WaveDirector threat multiplier after `cycle` bosses have been beaten.
func get_threat_multiplier(_cycle: int) -> float:
	return 1.0


## Enemy movement-speed multiplier after `cycle` bosses have been beaten.
func get_enemy_speed_scale(_cycle: int) -> float:
	return 1.0


## Boss id for the zero-based `boss_index`-th encounter of a run seeded `run_seed`.
func get_boss_id(_boss_index: int, _run_seed: int) -> StringName:
	return &"reaper"


## Arena skin id for the run summary; empty for the neutral arena.
func get_skin_id() -> StringName:
	return &""
