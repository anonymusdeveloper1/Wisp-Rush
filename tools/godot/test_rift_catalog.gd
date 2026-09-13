extends SceneTree
## Rift catalog, unlock ladder, backdrop geometry and Rift persistence checks.

const CATALOG: RiftCatalog = preload("res://data/rifts/default_catalog.tres")
## Every Rift backdrop must match the original arena art exactly, or GameWorld.ARENA_FLOOR_UV
## (ADR-0006) maps the playfield onto the wrong part of the image.
const REQUIRED_BACKGROUND_SIZE := Vector2(941, 1672)
const EXPECTED_UNLOCK_WAVES: Array[int] = [0, 5, 10, 15, 20]


func _initialize() -> void:
	var failures: int = 0

	for failure: String in CATALOG.validate():
		failures += 1
		push_error("rift_catalog: %s" % failure)

	var rifts: Array[RiftData] = CATALOG.load_rifts()
	if rifts.size() != RiftCatalog.REQUIRED_RIFT_COUNT:
		failures += 1
		push_error("rift_catalog: expected %d rifts, found %d" % [
			RiftCatalog.REQUIRED_RIFT_COUNT, rifts.size(),
		])
	else:
		for index: int in rifts.size():
			var rift: RiftData = rifts[index]
			if rift.unlock_wave != EXPECTED_UNLOCK_WAVES[index]:
				failures += 1
				push_error("rift_catalog: %s unlock wave %d, expected %d" % [
					rift.rift_id, rift.unlock_wave, EXPECTED_UNLOCK_WAVES[index],
				])
			if rift.background != null and rift.background.get_size() != REQUIRED_BACKGROUND_SIZE:
				failures += 1
				push_error("rift_catalog: %s backdrop is %s, expected %s" % [
					rift.rift_id, rift.background.get_size(), REQUIRED_BACKGROUND_SIZE,
				])
			# Every Rift past the baseline must actually change how the arena plays.
			if index > 0 and rift.rule_key == &"none":
				failures += 1
				push_error("rift_catalog: %s has no rule twist" % rift.rift_id)

	# Difficulty ladder: every Rift opens easy, later Rifts ramp harder and end harder.
	var previous_final: float = 0.0
	for rift: RiftData in rifts:
		if rift.get_threat_multiplier(1) > RiftCatalog.MAX_LEVEL_ONE_THREAT:
			failures += 1
			push_error("rift_catalog: %s does not open easy" % rift.rift_id)
		var final_multiplier: float = rift.get_threat_multiplier(rift.level_count)
		if final_multiplier <= previous_final:
			failures += 1
			push_error("rift_catalog: %s does not end harder than the previous Rift" % rift.rift_id)
		previous_final = final_multiplier
		# Levels must strictly escalate inside a Rift, and clamp past the last one.
		if rift.get_threat_multiplier(2) <= rift.get_threat_multiplier(1):
			failures += 1
			push_error("rift_catalog: %s levels do not escalate" % rift.rift_id)
		if not is_equal_approx(
			rift.get_threat_multiplier(rift.level_count + 5), final_multiplier
		):
			failures += 1
			push_error("rift_catalog: %s does not clamp past its last level" % rift.rift_id)
		if rift.substitute_enemy(&"soul_wisp").is_empty():
			failures += 1
			push_error("rift_catalog: %s enemy substitution returned empty" % rift.rift_id)

	if CATALOG.get_rift(&"invalid").rift_id != RiftCatalog.DEFAULT_RIFT_ID:
		failures += 1
		push_error("rift_catalog: invalid id did not fall back to the baseline rift")

	var court: RiftData = CATALOG.get_rift(&"reapers_court")
	if court.is_unlocked(19) or not court.is_unlocked(20):
		failures += 1
		push_error("rift_catalog: Reaper's Court unlock gate is wrong")

	# Absolute paths do not resolve from a --script SceneTree; reuse the autoload relative to root.
	var save := root.get_node_or_null(^"SaveManager") as SaveManagerService
	if save == null:
		failures += 1
		push_error("rift_catalog: SaveManager autoload is missing")
	elif not save.uses_isolated_storage():
		failures += 1
		push_error("rift_catalog: refusing to write the owner's real save")
	else:
		if save.select_rift(&"not_a_rift"):
			failures += 1
			push_error("rift_catalog: SaveManager accepted an unknown rift id")
		if not save.select_rift(&"frozen_choir"):
			failures += 1
			push_error("rift_catalog: SaveManager rejected a valid rift id")
		elif str(save.get_snapshot().get(&"selected_rift", "")) != "frozen_choir":
			failures += 1
			push_error("rift_catalog: selected rift did not persist")
		save.record_run({&"score": 1234, &"wave": 3, &"rift": "frozen_choir"})
		var bests: Dictionary = save.get_snapshot().get(&"rift_bests", {}) as Dictionary
		if int(bests.get("frozen_choir", 0)) != 1234:
			failures += 1
			push_error("rift_catalog: per-rift best was not recorded")
		# A worse run must never lower an existing best.
		save.record_run({&"score": 10, &"wave": 2, &"rift": "frozen_choir"})
		bests = save.get_snapshot().get(&"rift_bests", {}) as Dictionary
		if int(bests.get("frozen_choir", 0)) != 1234:
			failures += 1
			push_error("rift_catalog: a worse run overwrote the per-rift best")
		# Level clearing banks the deepest level and never regresses.
		save.record_run({
			&"score": 500, &"wave": 9, &"rift": "frozen_choir", &"rift_levels_cleared": 3,
		})
		if save.get_rift_level(&"frozen_choir") != 3:
			failures += 1
			push_error("rift_catalog: cleared rift level was not banked")
		save.record_run({
			&"score": 500, &"wave": 4, &"rift": "frozen_choir", &"rift_levels_cleared": 1,
		})
		if save.get_rift_level(&"frozen_choir") != 3:
			failures += 1
			push_error("rift_catalog: a shallower run lowered the cleared rift level")
		save.select_rift(RiftCatalog.DEFAULT_RIFT_ID)

	if failures == 0:
		print("rift_catalog: five rifts, unlock ladder, backdrops and persistence validated")
	quit(failures)
