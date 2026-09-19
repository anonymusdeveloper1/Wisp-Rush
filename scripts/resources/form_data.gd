class_name FormData
extends Resource
## One playable character (a Wisp form or a rigged character): identity, price, art and feedback tint.

## Collectible tier. Presentation only: it labels a character in the Shop and never changes
## collision, stats, controls or scoring. Everything that shipped before the Legendary and Mythic
## characters stays [constant TIER_STANDARD].
enum Tier {
	STANDARD, ## The six Wisp forms and the first three rigged characters.
	LEGENDARY, ## A fully rigged character with a deliberately restrained animation budget.
	MYTHIC, ## The richest rigs: many coordinated parts and layered follow-through.
}

## Player-facing label for each [enum Tier], in enum order.
const TIER_NAMES: Array[String] = ["", "LEGENDARY", "MYTHIC"]

## Stable identifier stored in progression data.
@export var form_id: StringName
## Player-facing form name.
@export var display_name: String
## Short flavour text displayed beneath the preview.
@export_multiline var description: String
## Rift Points required to purchase this form.
@export_range(0, 100000, 1) var price: int = 0
## Requires at least one lifetime Reaper victory before purchase.
@export var requires_boss_victory: bool = false
## Full-resolution portrait: the in-game art of a single-image form, the HUD and Home picture of a rigged one.
@export var texture: Texture2D
## Optional presentation-only animated rig (root extends [PlayableCharacterVisual]). Null keeps
## the single-image path; [member texture] is then the in-game art as well as the portrait.
@export var visual_scene: PackedScene
## Cosmetic feedback tint for aim, impact and surrounding UI.
@export var tint: Color = Color.WHITE
## Collectible tier shown on the focused Shop card; never read by gameplay.
@export var tier: Tier = Tier.STANDARD


## Player-facing tier label, empty for [constant Tier.STANDARD] so ordinary cards show no badge.
func get_tier_name() -> String:
	return TIER_NAMES[tier] if tier >= 0 and tier < TIER_NAMES.size() else ""


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
