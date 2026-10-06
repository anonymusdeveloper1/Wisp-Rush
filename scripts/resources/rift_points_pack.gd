class_name RiftPointsPack
extends Resource
## One Rift Points pack the Shop sells for real money (owner 2026-10-05, GDD §14 #78, ADR-0028): the
## store product, the Rift Points it gives and the price shown until the store gives the real one.

## Store product id the purchase runs under.
@export var product_id: StringName
## Rift Points a completed purchase adds to the save.
@export_range(1, 1000000, 1) var rift_points: int = 1
## The price shown on the card, a placeholder until the store reports the real, localized price.
@export var price_label: String = ""
## The pack's picture on its Shop card.
@export var icon: Texture2D


## Returns authoring failures for this pack.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if product_id.is_empty():
		failures.append("product id is empty")
	if rift_points <= 0:
		failures.append("Rift Points must be positive")
	if price_label.is_empty():
		failures.append("price label is empty")
	return failures
