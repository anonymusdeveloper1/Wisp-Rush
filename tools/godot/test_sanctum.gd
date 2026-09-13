extends SceneTree
## Soul Sanctum tree, power budget, prerequisite gating, purchase flow and effect resolution.

const CATALOG: SanctumCatalog = preload("res://data/sanctum/default_catalog.tres")

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _fail(message: String) -> void:
	_failures += 1
	push_error("sanctum: %s" % message)


func _run() -> void:
	for failure: String in CATALOG.validate():
		_fail(failure)

	var nodes: Array[SanctumNode] = CATALOG.load_nodes()
	if nodes.is_empty():
		_fail("catalog is empty")
		quit(_failures)
		return

	# GDD §6: permanent progress must not trivialise a fresh start.
	var power: float = CATALOG.get_maxed_combat_power()
	if power > SanctumCatalog.MAX_COMBAT_POWER:
		_fail("maxed combat power %.3f exceeds the budget" % power)
	if power <= 0.0:
		_fail("the tree grants no combat power at all")

	# The tree must be a meaningful long-term shard sink without dwarfing the six forms (4,750).
	var total: int = CATALOG.get_total_cost()
	if total < 2000 or total > 12000:
		_fail("total tree cost %d is outside a sane range" % total)

	for node: SanctumNode in nodes:
		# Costs must rise, and a maxed node must refuse further purchase.
		if node.max_level > 1 and node.get_cost(1) <= node.get_cost(0):
			_fail("%s cost does not increase per level" % node.node_id)
		if node.get_cost(node.max_level) != -1:
			_fail("%s did not report itself maxed" % node.node_id)
		if not is_equal_approx(node.get_value(node.max_level + 3), node.get_value(node.max_level)):
			_fail("%s value does not clamp past max level" % node.node_id)
		if node.get_next_description(0).contains("{value}"):
			_fail("%s description left the placeholder unresolved" % node.node_id)

	# Prerequisite gating: a sealed node stays sealed until its root is fully maxed.
	var gated: SanctumNode = null
	for node: SanctumNode in nodes:
		if not node.prerequisite_id.is_empty():
			gated = node
			break
	if gated == null:
		_fail("the tree has no gated node, so it is a flat list")
	else:
		var root_node: SanctumNode = CATALOG.get_node_by_id(gated.prerequisite_id)
		if CATALOG.is_unlocked(gated, {}):
			_fail("%s was unlocked with no progress" % gated.node_id)
		var partial: Dictionary = {String(root_node.node_id): maxi(1, root_node.max_level - 1)}
		if root_node.max_level > 1 and CATALOG.is_unlocked(gated, partial):
			_fail("%s unlocked before its root was maxed" % gated.node_id)
		var full: Dictionary = {String(root_node.node_id): root_node.max_level}
		if not CATALOG.is_unlocked(gated, full):
			_fail("%s stayed sealed after its root was maxed" % gated.node_id)

	# Effect resolution: a maxed tree must produce every authored effect key.
	var maxed: Dictionary = {}
	for node: SanctumNode in nodes:
		maxed[String(node.node_id)] = node.max_level
	var effects := SanctumEffects.new(CATALOG, maxed)
	for node: SanctumNode in nodes:
		if is_zero_approx(effects.get_value(node.effect_key)):
			_fail("effect %s resolved to zero on a maxed tree" % node.effect_key)
	if effects.get_multiplier(&"blade_width_bonus") <= 1.0:
		_fail("blade width multiplier did not exceed 1.0")
	# Levels above max, or unknown ids, must never leak into the totals.
	var absurd: Dictionary = {String(nodes[0].node_id): 999, "not_a_node": 5}
	var clamped := SanctumEffects.new(CATALOG, absurd)
	if not is_equal_approx(
		clamped.get_value(nodes[0].effect_key), nodes[0].get_value(nodes[0].max_level)
	):
		_fail("an over-large saved level was not clamped to max")

	await _check_purchase_flow()

	if _failures == 0:
		print("sanctum: %d nodes, power %.3f, cost %d, gating and effects validated" % [
			nodes.size(), power, total,
		])
	quit(_failures)


func _check_purchase_flow() -> void:
	var save := root.get_node_or_null(^"SaveManager") as SaveManagerService
	if save == null:
		_fail("SaveManager autoload is missing")
		return
	if not save.uses_isolated_storage():
		_fail("refusing to write the owner's real save")
		return

	var node: SanctumNode = CATALOG.load_nodes()[0]
	var cost: int = node.get_cost(0)

	# Broke players buy nothing.
	if save.purchase_sanctum_level(node.node_id, cost, node.max_level):
		if int(save.get_snapshot()[&"soul_shards"]) < 0:
			_fail("a purchase drove the shard balance negative")
	save.refund_sanctum(0)

	save.add_soul_shards(cost * 2)
	var before: int = int(save.get_snapshot()[&"soul_shards"])
	if not save.purchase_sanctum_level(node.node_id, cost, node.max_level):
		_fail("an affordable purchase was rejected")
	if save.get_sanctum_level(node.node_id) != 1:
		_fail("the purchased level was not stored")
	if int(save.get_snapshot()[&"soul_shards"]) != before - cost:
		_fail("the purchase did not deduct exactly its cost")
	# Buying past the cap must be refused outright.
	for _index: int in node.max_level + 2:
		save.purchase_sanctum_level(node.node_id, node.get_cost(
			save.get_sanctum_level(node.node_id)
		), node.max_level)
	if save.get_sanctum_level(node.node_id) > node.max_level:
		_fail("a node was bought past its maximum level")
	save.refund_sanctum(0)
	if not save.get_sanctum_levels().is_empty():
		_fail("the reset left Sanctum levels behind")
