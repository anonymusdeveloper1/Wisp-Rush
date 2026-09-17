class_name RunProfile
extends RefCounted
## Everything a run needs before it starts: mode, Rift and level or skin and pool, seed, daily
## identity and cosmetics.
##
## Main builds every profile and hands it to `GameWorld.configure_run`; GameWorld never decides
## which level, skin or pool to play. A story run plays exactly one level; Endless and the daily run share
## Endless rules (ADR-0013). `create_arena_rules()` is the single seam GameWorld reads.

## One Rift level; its final boss ends the run in victory.
const MODE_STORY: StringName = &"story"
## Today's seeded run on Endless rules with the fixed daily pool and the arena of the day.
const MODE_DAILY: StringName = &"daily"
## The never-ending mode: equipped skin, pool from cleared Rifts, harder every boss cycle.
const MODE_ENDLESS: StringName = &"endless"
## The Tutorial screen's scripted arena: Endless floor template, no waves, boss cadence, run end or
## recording; its TutorialDirector spawns everything through GameWorld's scripted-run hooks.
const MODE_TUTORIAL: StringName = &"tutorial"

## `MODE_STORY`, `MODE_DAILY`, `MODE_ENDLESS` or `MODE_TUTORIAL`.
var mode: StringName = MODE_STORY
## Story only: Rift whose backdrop, rule twist, roster and boss the run uses.
var rift: RiftData
## Endless and daily: the catalog holding the floor template and tuning.
var endless_catalog: EndlessCatalog
## Endless and daily: the arena skin shown.
var skin: ArenaSkinData
## Endless and daily: Rifts whose rosters waves draw from, in ladder order.
var roster_rifts: Array[RiftData] = []
## Endless and daily: boss ids encounters draw from.
var boss_ids: Array[StringName] = []
## One-based level played in `rift`.
var level: int = 1
## Deterministic seed; zero lets GameWorld derive one from the clock.
var run_seed: int = 0
## YYYY-MM-DD of the daily run; empty otherwise.
var daily_date_key: String = ""
## Equipped cosmetic form.
var form: FormData
## Equipped dash style; it tints the dash trail and launch burst only. Null plays the SOUL look.
## Main sets it after building the profile.
var dash_style: DashStyleData
## True when `level` is above the banked cleared level, so a victory pays the first-clear bonus.
var first_clear_possible: bool = false


## A story run of one `level` in `story_rift`, with first-clear eligibility read from `rift_levels`.
static func story(
	story_rift: RiftData,
	story_level: int,
	rift_levels: Dictionary,
	cosmetic_form: FormData,
) -> RunProfile:
	var profile := RunProfile.new()
	profile.mode = MODE_STORY
	profile.rift = story_rift
	var level_count: int = story_rift.level_count if story_rift != null else 1
	profile.level = clampi(story_level, 1, maxi(1, level_count))
	profile.first_clear_possible = (
		profile.level > ContentUnlocks.get_cleared_level(story_rift, rift_levels)
	)
	profile.form = cosmetic_form
	return profile


## An Endless run on `arena_skin` with the pool of Rifts the player has cleared.
static func endless(
	catalog: EndlessCatalog,
	arena_skin: ArenaSkinData,
	pool_rifts: Array[RiftData],
	pool_boss_ids: Array[StringName],
	cosmetic_form: FormData,
) -> RunProfile:
	var profile := RunProfile.new()
	profile.mode = MODE_ENDLESS
	profile.endless_catalog = catalog
	profile.skin = arena_skin
	profile.roster_rifts = pool_rifts
	profile.boss_ids = pool_boss_ids
	profile.form = cosmetic_form
	return profile


## Today's daily run: Endless rules with the date seed, the daily pool and the arena of the day.
static func daily(
	catalog: EndlessCatalog,
	arena_skin: ArenaSkinData,
	pool_rifts: Array[RiftData],
	pool_boss_ids: Array[StringName],
	date_key: String,
	daily_seed: int,
	cosmetic_form: FormData,
) -> RunProfile:
	var profile := endless(catalog, arena_skin, pool_rifts, pool_boss_ids, cosmetic_form)
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
	var no_rosters: Array[RiftData] = []
	var reaper_only: Array[StringName] = [&"reaper"]
	var profile := endless(catalog, arena_skin, no_rosters, reaper_only, cosmetic_form)
	profile.mode = MODE_TUTORIAL
	return profile


## The arena rules this profile plays under; the neutral arena when nothing is set.
func create_arena_rules() -> ArenaRules:
	if mode == MODE_STORY:
		return RiftArenaRules.new(rift, level) if rift != null else ArenaRules.new()
	return EndlessArenaRules.new(endless_catalog, skin, roster_rifts, boss_ids)


## Whether this is a story run, which ends on its level's final boss.
func is_story() -> bool:
	return mode == MODE_STORY


## Whether this is the tutorial's scripted arena: no waves, bosses on cue, never ends or records.
func is_scripted() -> bool:
	return mode == MODE_TUTORIAL


## Whether this run plays on Endless rules (Endless or the daily run).
func uses_endless_rules() -> bool:
	return mode == MODE_ENDLESS or mode == MODE_DAILY
