class_name RunItemCatalog
extends Resource
## The seven pickup definitions, equal-weight enemy drop tuning and shop pack quantities.

const SOUL_WARD: StringName = &"soul_ward"
const RIFT_MAGNET: StringName = &"rift_magnet"
const FORTUNE_STAR: StringName = &"fortune_star"
const STILLGLASS: StringName = &"stillglass"
const BANISH_BOMB: StringName = &"banish_bomb"
const REAPERS_EDGE: StringName = &"reapers_edge"
const ECHO_WISP: StringName = &"echo_wisp"
## Owner-requested purchase quantities.
const PACK_SIZES: Array[int] = [1, 5, 10, 25]

@export var items: Array[RunItemData] = []
## Independent chance per regular enemy kill to drop one of the seven items, 0..1.
@export_range(0.0, 1.0, 0.01) var drop_chance: float = 0.1
## Seconds an uncollected floor item remains.
@export_range(1.0, 60.0, 0.5) var floor_lifetime: float = 14.0
## Seconds of immunity after an active Ward blocks a hit.
@export_range(0.1, 5.0, 0.1) var ward_escape_seconds: float = 0.9
## Existing RP attraction radius before a Magnet is active, in design pixels.
@export_range(0.0, 1000.0, 10.0) var base_rp_attraction_radius: float = 150.0


## Item lookup; null for unknown ids.
func get_item(item_id: StringName) -> RunItemData:
	for item: RunItemData in items:
		if item != null and item.item_id == item_id:
			return item
	return null


## The shop's three purchasable items, in catalog order.
func get_shop_items() -> Array[RunItemData]:
	var result: Array[RunItemData] = []
	for item: RunItemData in items:
		if item != null and item.shop_enabled:
			result.append(item)
	return result


## Positive RP cost of an allowed pack; -1 for unknown, unsold or invalid quantities.
func get_pack_price(item_id: StringName, quantity: int) -> int:
	var item: RunItemData = get_item(item_id)
	if item == null or not item.shop_enabled or item.unit_price <= 0 or quantity not in PACK_SIZES:
		return -1
	return item.unit_price * quantity


## Checks the identities, source icons, positive shop prices and timer data.
func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var seen: Dictionary[StringName, bool] = {}
	if items.size() != 7:
		errors.append("item catalog must contain seven items")
	for item: RunItemData in items:
		if item == null or item.item_id.is_empty() or seen.has(item.item_id):
			errors.append("null, empty or duplicate item")
			continue
		seen[item.item_id] = true
		if not ResourceLoader.exists(item.icon_path):
			errors.append("missing icon: %s" % item.item_id)
		if item.shop_enabled and item.unit_price <= 0:
			errors.append("shop price must be positive: %s" % item.item_id)
		if item.starting_boost and (not item.shop_enabled or item.duration_seconds <= 0.0):
			errors.append("invalid starting boost: %s" % item.item_id)
	return errors
