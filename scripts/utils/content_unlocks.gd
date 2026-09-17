class_name ContentUnlocks
extends RefCounted
## Pure story-progress and unlock rules, derived from the save's banked `rift_levels`.
##
## `rift_levels` maps a Rift id (String) to the highest level cleared there. Nothing here touches
## nodes or the save, so Main, Home, the Rift Map and Results all read the same answers
## (ADR-0013, GDD §14 #12–#13), plus the Endless pool, which ignores progress.


## Highest cleared level of a Rift, clamped to its level count; zero when nothing is cleared.
static func get_cleared_level(rift: RiftData, rift_levels: Dictionary) -> int:
	if rift == null:
		return 0
	return clampi(int(rift_levels.get(String(rift.rift_id), 0)), 0, rift.level_count)


## Whether the banked clears open this Rift.
static func is_rift_unlocked(rift: RiftData, rift_levels: Dictionary) -> bool:
	return rift != null and rift.is_unlocked(rift_levels)


## The level a story run in this Rift plays next: cleared + 1, capped at the last level.
static func get_next_level(rift: RiftData, rift_levels: Dictionary) -> int:
	if rift == null:
		return 1
	return clampi(get_cleared_level(rift, rift_levels) + 1, 1, rift.level_count)


## Whether every level of this Rift is cleared; a mastered Rift replays its last level.
static func is_mastered(rift: RiftData, rift_levels: Dictionary) -> bool:
	return rift != null and get_cleared_level(rift, rift_levels) >= rift.level_count


## Rifts whose rosters Endless waves may use: every Rift, in ladder order. Endless is never limited
## by story progress (owner decision 2026-09-15), so a fresh save meets every enemy family.
static func get_endless_roster_rift_ids(catalog: RiftCatalog) -> Array[StringName]:
	var ids: Array[StringName] = []
	if catalog == null:
		return ids
	for rift: RiftData in catalog.load_rifts():
		ids.append(rift.rift_id)
	return ids


## Bosses Endless may send: every Rift's boss, in ladder order, no repeats.
static func get_endless_boss_ids(catalog: RiftCatalog) -> Array[StringName]:
	var ids: Array[StringName] = []
	if catalog == null:
		return ids
	for rift: RiftData in catalog.load_rifts():
		if rift.boss_id not in ids:
			ids.append(rift.boss_id)
	return ids


## Rift ids that are locked under `levels_before` and open under `levels_after`, in ladder order.
static func get_newly_unlocked(
	levels_before: Dictionary,
	levels_after: Dictionary,
	catalog: RiftCatalog,
) -> Array[StringName]:
	var opened: Array[StringName] = []
	if catalog == null:
		return opened
	for rift: RiftData in catalog.load_rifts():
		if not rift.is_unlocked(levels_before) and rift.is_unlocked(levels_after):
			opened.append(rift.rift_id)
	return opened


## The Rift PLAY enters: the selection when it is open, otherwise the always-open first Rift.
##
## A locked selection can survive in a save made before clear-based unlocks, or after a reset.
static func resolve_story_rift(
	catalog: RiftCatalog,
	selected_id: StringName,
	rift_levels: Dictionary,
) -> RiftData:
	var rift: RiftData = catalog.get_rift(selected_id)
	if rift.is_unlocked(rift_levels):
		return rift
	return catalog.get_rift(RiftCatalog.DEFAULT_RIFT_ID)
