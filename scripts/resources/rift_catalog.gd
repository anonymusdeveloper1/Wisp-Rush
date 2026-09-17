class_name RiftCatalog
extends Resource
## Ordered registry of the five playable Rifts, in Rift-map progression order.

const REQUIRED_RIFT_COUNT: int = 5
## The always-unlocked baseline arena every save starts on.
const DEFAULT_RIFT_ID: StringName = &"obsidian_garden"
## No Rift may open harder than this, whatever its tier.
const MAX_LEVEL_ONE_THREAT: float = 1.1

## Rift `.tres` paths in intended Rift-map order, easiest first.
@export var rift_paths: PackedStringArray = PackedStringArray()


## Loads every configured Rift while reporting malformed paths.
func load_rifts() -> Array[RiftData]:
	var rifts: Array[RiftData] = []
	for path: String in rift_paths:
		var resource: Resource = load(path)
		if resource is RiftData:
			rifts.append(resource as RiftData)
		else:
			push_error("RiftCatalog could not load RiftData: %s" % path)
	return rifts


## Returns count, duplicate, ordering, unlock-chain, default-Rift and per-resource authoring failures.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	var rifts: Array[RiftData] = load_rifts()
	var seen_ids: Dictionary[StringName, bool] = {}
	# Level count of every Rift already walked, so a requirement can only name an earlier Rift.
	var earlier_levels: Dictionary[StringName, int] = {}
	if rifts.size() != REQUIRED_RIFT_COUNT:
		failures.append("catalog requires exactly %d rifts" % REQUIRED_RIFT_COUNT)
	var previous_tier: int = 0
	for index: int in rifts.size():
		var rift: RiftData = rifts[index]
		if seen_ids.has(rift.rift_id):
			failures.append("duplicate rift id %s" % rift.rift_id)
		seen_ids[rift.rift_id] = true
		# The map draws the ladder in catalog order: the first Rift is open, every other one is
		# opened by clearing a level of a Rift before it.
		if index == 0:
			if not rift.unlock_after_rift_id.is_empty():
				failures.append("%s is first and must have no unlock requirement" % rift.rift_id)
		elif not earlier_levels.has(rift.unlock_after_rift_id):
			failures.append("%s unlock requirement %s is not an earlier rift" % [
				rift.rift_id, rift.unlock_after_rift_id,
			])
		elif rift.unlock_after_level > earlier_levels[rift.unlock_after_rift_id]:
			failures.append("%s unlock level %d is beyond %s's levels" % [
				rift.rift_id, rift.unlock_after_level, rift.unlock_after_rift_id,
			])
		earlier_levels[rift.rift_id] = rift.level_count
		if rift.difficulty_tier <= previous_tier:
			failures.append("%s difficulty tier does not increase" % rift.rift_id)
		previous_tier = rift.difficulty_tier
		# The owner's rule: every arena starts easy, so the ladder bites through the ramp.
		if rift.get_threat_multiplier(1) > MAX_LEVEL_ONE_THREAT:
			failures.append("%s level 1 is not an easy opener" % rift.rift_id)
		for failure: String in rift.validate():
			failures.append("%s: %s" % [rift.rift_id, failure])
	if not seen_ids.has(DEFAULT_RIFT_ID):
		failures.append("catalog requires the %s rift" % DEFAULT_RIFT_ID)
	elif not rifts.is_empty() and rifts[0].rift_id != DEFAULT_RIFT_ID:
		failures.append("%s must be first and unlocked from the start" % DEFAULT_RIFT_ID)
	return failures


## Finds a Rift by persistent identifier, falling back to the baseline for corrupt input.
func get_rift(rift_id: StringName) -> RiftData:
	var fallback: RiftData
	for rift: RiftData in load_rifts():
		if rift.rift_id == DEFAULT_RIFT_ID:
			fallback = rift
		if rift.rift_id == rift_id:
			return rift
	assert(fallback != null, "RiftCatalog requires a %s fallback" % DEFAULT_RIFT_ID)
	return fallback
