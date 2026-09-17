class_name DashStyleData
extends Resource
## One purchasable dash style: it recolours the dash trail and the launch burst, nothing else.
##
## Timing, collision, sound and haptics never read this resource (GDD §9: cosmetics keep the
## hitbox). Bought and equipped in the Shop's DASHES tab.

## Hues a saturated tint must stay clear of, so a trail never reads as a telegraph or an enemy.
const RESERVED_HUES: Array[Color] = [Palette.WARNING_AMBER, Palette.RIFT_MAGENTA]
## A tint more saturated than this is checked against `RESERVED_HUES`.
const MAX_RESERVED_SATURATION: float = 0.25
## Smallest hue distance, in degrees, a saturated tint must keep from every reserved hue.
const MIN_RESERVED_HUE_DISTANCE: float = 25.0

## Stable identifier stored in the save (`owned_dash_styles`, `equipped_dash_style`).
@export var style_id: StringName
## Player-facing style name.
@export var display_name: String
## Short flavour text for the Shop.
@export_multiline var description: String
## Rift Points price; zero for the default style.
@export_range(0, 100000, 1) var price: int = 0
## Tint of the long trail left behind a dash.
@export var trail_tint: Color = Color.WHITE
## Tint of the short burst at launch.
@export var burst_tint: Color = Color.WHITE
## Play with the equipped form's tint instead of the two tints above (the default SOUL look).
## The tints still colour the Shop preview.
@export var uses_form_tint: bool = false


## Returns authoring failures for this style, including the reserved-hue rule.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if style_id.is_empty():
		failures.append("style id is empty")
	if display_name.is_empty():
		failures.append("display name is empty")
	if price < 0:
		failures.append("price is negative")
	for tint: Color in [trail_tint, burst_tint]:
		if is_reserved_tint(tint):
			failures.append("tint %s is too close to a reserved hue" % tint.to_html(false))
	return failures


## True when `tint` is saturated and within `MIN_RESERVED_HUE_DISTANCE` of amber or magenta.
static func is_reserved_tint(tint: Color) -> bool:
	if tint.s <= MAX_RESERVED_SATURATION:
		return false
	for reserved: Color in RESERVED_HUES:
		var distance: float = absf(tint.h - reserved.h) * 360.0
		if minf(distance, 360.0 - distance) < MIN_RESERVED_HUE_DISTANCE:
			return true
	return false
