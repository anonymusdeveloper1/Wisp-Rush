class_name FormationCatalog
extends Resource
## Ordered Resource paths for the complete validated encounter-template catalog.

## Formation `.tres` paths loaded in deterministic catalog order.
@export var formation_paths: PackedStringArray = PackedStringArray()


## Loads every configured FormationData Resource, reporting invalid paths as errors.
func load_formations() -> Array[FormationData]:
	var formations: Array[FormationData] = []
	for path: String in formation_paths:
		var resource: Resource = load(path)
		if resource is FormationData:
			formations.append(resource as FormationData)
		else:
			push_error("FormationCatalog could not load FormationData: %s" % path)
	return formations


## Returns catalog/resource validation failures, including duplicate identifiers.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	var seen_ids: Dictionary[StringName, bool] = {}
	var formations: Array[FormationData] = load_formations()
	if formations.size() < 20:
		failures.append("catalog requires at least 20 formations")
	for formation: FormationData in formations:
		if seen_ids.has(formation.formation_id):
			failures.append("duplicate formation id %s" % formation.formation_id)
		seen_ids[formation.formation_id] = true
		for failure: String in formation.validate():
			failures.append("%s: %s" % [formation.formation_id, failure])
	return failures
