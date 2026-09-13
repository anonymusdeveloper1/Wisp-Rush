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


## Returns count, duplicate, ordering, default-Rift and per-resource authoring failures.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	var rifts: Array[RiftData] = load_rifts()
	var seen_ids: Dictionary[StringName, bool] = {}
	if rifts.size() != REQUIRED_RIFT_COUNT:
		failures.append("catalog requires exactly %d rifts" % REQUIRED_RIFT_COUNT)
	var previous_wave: int = -1
	var previous_tier: int = 0
	for rift: RiftData in rifts:
		if seen_ids.has(rift.rift_id):
			failures.append("duplicate rift id %s" % rift.rift_id)
		seen_ids[rift.rift_id] = true
		# The map draws the ladder in catalog order, so gates must not go backwards.
		if rift.unlock_wave < previous_wave:
			failures.append("%s unlock wave decreases" % rift.rift_id)
		previous_wave = rift.unlock_wave
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
	else:
		for rift: RiftData in rifts:
			if rift.rift_id == DEFAULT_RIFT_ID and rift.unlock_wave != 0:
				failures.append("%s must be unlocked from the start" % DEFAULT_RIFT_ID)
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
