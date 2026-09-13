class_name SanctumCatalog
extends Resource
## The Soul Sanctum tree: every permanent upgrade, plus the power budget that keeps it honest.
##
## GDD §6 requires that permanent progress must not trivialise a fresh start. `validate()` enforces
## that by summing the maxed value of every node marked `is_combat_power` and failing above
## `MAX_COMBAT_POWER`. Economy and convenience nodes (shard find, XP, magnet) are excluded on
## purpose: they change how fast a player earns, not how easily they survive.

## Fractional combat power a fully maxed account may gain over a fresh one.
const MAX_COMBAT_POWER: float = 0.20
## Effect keys whose value is a flat count rather than a fraction, converted for the budget below.
const FRAGMENT_POWER: float = 0.05

## Node `.tres` paths in intended display order, roots first.
@export var node_paths: PackedStringArray = PackedStringArray()


## Loads every configured node while reporting malformed paths.
func load_nodes() -> Array[SanctumNode]:
	var nodes: Array[SanctumNode] = []
	for path: String in node_paths:
		var resource: Resource = load(path)
		if resource is SanctumNode:
			nodes.append(resource as SanctumNode)
		else:
			push_error("SanctumCatalog could not load SanctumNode: %s" % path)
	return nodes


## Finds one node by identifier, or null when it is unknown.
func get_node_by_id(node_id: StringName) -> SanctumNode:
	for node: SanctumNode in load_nodes():
		if node.node_id == node_id:
			return node
	return null


## Total shards required to max every node in the tree.
func get_total_cost() -> int:
	var total: int = 0
	for node: SanctumNode in load_nodes():
		total += node.get_total_cost()
	return total


## Combat power a fully maxed tree grants, as a fraction over a fresh account.
##
## Nodes measured in %% contribute their fraction directly. Everything else is a flat amount
## (a bonus Soul Fragment, extra invulnerability seconds) and is weighted by FRAGMENT_POWER,
## because survivability is not linear with the three fragments the player starts with.
func get_maxed_combat_power() -> float:
	var total: float = 0.0
	for node: SanctumNode in load_nodes():
		if not node.is_combat_power:
			continue
		var value: float = node.get_value(node.max_level)
		total += value * FRAGMENT_POWER if node.unit != "%" else value * 0.01
	return total


## Whether a node's prerequisite chain is satisfied by the player's purchased levels.
func is_unlocked(node: SanctumNode, levels: Dictionary) -> bool:
	if node == null:
		return false
	if node.prerequisite_id.is_empty():
		return true
	var required: SanctumNode = get_node_by_id(node.prerequisite_id)
	if required == null:
		return false
	return int(levels.get(String(required.node_id), 0)) >= required.max_level


## Returns duplicate, dangling-prerequisite, cycle, power-budget and per-node authoring failures.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	var nodes: Array[SanctumNode] = load_nodes()
	if nodes.is_empty():
		failures.append("catalog has no nodes")
	var seen: Dictionary[StringName, bool] = {}
	for node: SanctumNode in nodes:
		if seen.has(node.node_id):
			failures.append("duplicate node id %s" % node.node_id)
		seen[node.node_id] = true
		for failure: String in node.validate():
			failures.append("%s: %s" % [node.node_id, failure])
	for node: SanctumNode in nodes:
		if node.prerequisite_id.is_empty():
			continue
		if not seen.has(node.prerequisite_id):
			failures.append("%s requires unknown node %s" % [node.node_id, node.prerequisite_id])
			continue
		# Walk the chain; a cycle would otherwise hang every unlock query.
		var visited: Dictionary[StringName, bool] = {node.node_id: true}
		var cursor: SanctumNode = get_node_by_id(node.prerequisite_id)
		while cursor != null:
			if visited.has(cursor.node_id):
				failures.append("%s is part of a prerequisite cycle" % node.node_id)
				break
			visited[cursor.node_id] = true
			if cursor.prerequisite_id.is_empty():
				break
			cursor = get_node_by_id(cursor.prerequisite_id)
	var power: float = get_maxed_combat_power()
	if power > MAX_COMBAT_POWER:
		failures.append(
			"maxed combat power %.3f exceeds the %.2f budget (GDD §6)" % [power, MAX_COMBAT_POWER]
		)
	return failures
