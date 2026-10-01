class_name RunProfile
extends RefCounted
## Everything a run needs before it starts: mode, skin and pool, seed, daily identity and cosmetics.
##
## Main builds every profile and hands it to `GameWorld.configure_run`; GameWorld never decides
## which skin or pool to play. Endless and the daily run share Endless rules (ADR-0013).
## `create_arena_rules()` is the single seam GameWorld reads.

## Today's seeded run on Endless rules with the fixed daily pool and the arena of the day.
const MODE_DAILY: StringName = &"daily"
## The never-ending mode: equipped skin, every enemy mix and boss, harder every boss cycle.
const MODE_ENDLESS: StringName = &"endless"
## The Tutorial screen's scripted arena: Endless floor template, no waves, boss cadence, run end or
## recording; its TutorialDirector spawns everything through GameWorld's scripted-run hooks.
const MODE_TUTORIAL: StringName = &"tutorial"

## `MODE_ENDLESS`, `MODE_DAILY` or `MODE_TUTORIAL`.
var mode: StringName = MODE_ENDLESS
## The catalog holding the floor template, tuning and enemy mixes; null plays the neutral arena.
var endless_catalog: EndlessCatalog
## The arena skin shown.
var skin: ArenaSkinData
## Enemy mixes waves draw from, in pick order.
var rosters: Array[EndlessRoster] = []
## Boss ids encounters draw from.
var boss_ids: Array[StringName] = []
## The run's first boss, outside the pool; empty draws it from [member boss_ids]. Main sets it for
## Endless only.
var opening_boss_id: StringName = &""
## Deterministic seed; zero lets GameWorld derive one from the clock.
var run_seed: int = 0
## YYYY-MM-DD of the daily run; empty otherwise.
var daily_date_key: String = ""
## Equipped cosmetic form.
var form: FormData
## Equipped dash style; it tints the dash trail and launch burst only. Null plays the SOUL look.
## Main sets it after building the profile.
var dash_style: DashStyleData


## An Endless run on `arena_skin` with these enemy mixes and bosses.
static func endless(
	catalog: EndlessCatalog,
	arena_skin: ArenaSkinData,
	pool_rosters: Array[EndlessRoster],
	pool_boss_ids: Array[StringName],
	cosmetic_form: FormData,
) -> RunProfile:
	var profile := RunProfile.new()
	profile.mode = MODE_ENDLESS
	profile.endless_catalog = catalog
	profile.skin = arena_skin
	profile.rosters = pool_rosters
	profile.boss_ids = pool_boss_ids
	profile.form = cosmetic_form
	return profile


## Today's daily run: Endless rules with the date seed, the daily pool and the arena of the day.
static func daily(
	catalog: EndlessCatalog,
	arena_skin: ArenaSkinData,
	pool_rosters: Array[EndlessRoster],
	pool_boss_ids: Array[StringName],
	date_key: String,
	daily_seed: int,
	cosmetic_form: FormData,
) -> RunProfile:
	var profile := endless(catalog, arena_skin, pool_rosters, pool_boss_ids, cosmetic_form)
	profile.mode = MODE_DAILY
	profile.run_seed = daily_seed
	profile.daily_date_key = date_key
	return profile


## The tutorial arena: the Endless floor template under `arena_skin` (the default skin), the
## Reaper as its only boss and no roster remap.
static func tutorial(
	catalog: EndlessCatalog,
	arena_skin: ArenaSkinData,
	cosmetic_form: FormData,
) -> RunProfile:
	var no_rosters: Array[EndlessRoster] = []
	var reaper_only: Array[StringName] = [&"reaper"]
	var profile := endless(catalog, arena_skin, no_rosters, reaper_only, cosmetic_form)
	profile.mode = MODE_TUTORIAL
	return profile


## The arena rules this profile plays under; the neutral arena when no catalog is set.
func create_arena_rules() -> ArenaRules:
	if endless_catalog == null:
		return ArenaRules.new()
	return EndlessArenaRules.new(endless_catalog, skin, rosters, boss_ids, opening_boss_id)


## Whether this is the tutorial's scripted arena: no waves, bosses on cue, never ends or records.
func is_scripted() -> bool:
	return mode == MODE_TUTORIAL


## Whether this run plays on Endless rules (Endless or the daily run).
func uses_endless_rules() -> bool:
	return mode == MODE_ENDLESS or mode == MODE_DAILY
