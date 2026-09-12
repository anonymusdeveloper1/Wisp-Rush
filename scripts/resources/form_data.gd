class_name FormData
extends Resource
## Data-driven cosmetic identity, unlock requirement, supplied art and feedback tint.

## Stable identifier stored in progression data.
@export var form_id: StringName
## Player-facing form name.
@export var display_name: String
## Short flavour text displayed beneath the preview.
@export_multiline var description: String
## Soul Shards required to purchase this form.
@export_range(0, 100000, 1) var price: int = 0
## Requires at least one lifetime Reaper victory before purchase.
@export var requires_boss_victory: bool = false
## Supplied full-resolution form illustration.
@export var texture: Texture2D
## Cosmetic feedback tint for aim, impact and surrounding UI.
@export var tint: Color = Color.WHITE


## Returns authoring failures so the full collection can be checked without opening the editor.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if form_id.is_empty():
		failures.append("form id is empty")
	if display_name.is_empty():
		failures.append("display name is empty")
	if price < 0:
		failures.append("price is negative")
	if texture == null:
		failures.append("texture is missing")
	return failures
