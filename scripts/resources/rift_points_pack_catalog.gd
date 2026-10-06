class_name RiftPointsPackCatalog
extends Resource
## The Rift Points packs the Shop's SHOP page sells, in display order (owner 2026-10-05, ADR-0028).

## Every pack, smallest first.
@export var packs: Array[RiftPointsPack] = []


## The pack sold as [param product_id], or null when none is.
func get_pack(product_id: StringName) -> RiftPointsPack:
	for pack: RiftPointsPack in packs:
		if pack != null and pack.product_id == product_id:
			return pack
	return null


## Returns authoring failures: empty slots, duplicate product ids and each pack's own.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	var seen: Dictionary[StringName, bool] = {}
	for pack: RiftPointsPack in packs:
		if pack == null:
			failures.append("catalog has an empty pack slot")
			continue
		if seen.has(pack.product_id):
			failures.append("duplicate product id %s" % pack.product_id)
		seen[pack.product_id] = true
		for failure: String in pack.validate():
			failures.append("%s: %s" % [pack.product_id, failure])
	return failures
