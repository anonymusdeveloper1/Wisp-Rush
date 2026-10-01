class_name ArenaRules
extends RefCounted
## The one seam GameWorld reads for everything an arena decides: backdrop, floor, boss cadence
## and pick, and difficulty. Which enemies come is the run's `EnemyRamp`, not the arena's.
##
## Built by `RunProfile.create_arena_rules()`. `EndlessArenaRules` wraps the Endless catalog, a skin
## and a pool (Endless, the daily run and the tutorial). This base class is the neutral arena used
## when a run has no profile (F6 runs, fixtures): the scene's own backdrop, the legacy floor
## rectangle, the Reaper every four waves.

## Boss cadence of the neutral arena.
const DEFAULT_BOSS_WAVE_INTERVAL: int = 4


## Full-bleed backdrop, or null to keep the scene's own.
func get_background() -> Texture2D:
	return null


## A layered or 3D arena's scene (an `ArenaVisual`, ADR-0021, ADR-0023), shown instead of the
## background and giving the floor; null (a painted backdrop) by default.
func get_visual_scene() -> PackedScene:
	return null


## Animated scenery over the background (`ArenaAmbience`); null (none) by default.
func get_scenery() -> ArenaSceneryData:
	return null


## Playable floor in background UV space; empty means the legacy rectangle.
func get_floor_polygon() -> PackedVector2Array:
	return PackedVector2Array()


## Rectangle formations, hazards and the playfield's scale are laid out over, in background UV
## space. Empty means `GameWorld.ARENA_FLOOR_UV`, measured on the arenas' shared 941x1672 canvas.
func get_floor_rect_uv() -> Rect2:
	return Rect2()


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
