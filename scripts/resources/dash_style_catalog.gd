class_name DashStyleCatalog
extends Resource
## Ordered registry of the dash styles sold in the Shop's DASHES tab.

## Style every save owns and unknown ids fall back to.
const DEFAULT_STYLE_ID: StringName = &"soul"

## Every dash style, in Shop order; the free default comes first.
@export var styles: Array[DashStyleData] = []


## The style with `style_id`, or the default when the id is unknown.
func get_style(style_id: StringName) -> DashStyleData:
	var fallback: DashStyleData = null
	for style: DashStyleData in styles:
		if style == null:
			continue
		if style.style_id == style_id:
			return style
		if style.style_id == DEFAULT_STYLE_ID:
			fallback = style
	return fallback


## Every style id, for save validation.
func get_style_ids() -> Array[String]:
	var ids: Array[String] = []
	for style: DashStyleData in styles:
		if style != null:
			ids.append(String(style.style_id))
	return ids


## Returns empty-slot, duplicate, free-default and per-style (hue rule) authoring failures.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if styles.is_empty():
		failures.append("catalog has no styles")
	var seen: Dictionary[StringName, bool] = {}
	for style: DashStyleData in styles:
		if style == null:
			failures.append("catalog has an empty style slot")
			continue
		if seen.has(style.style_id):
			failures.append("duplicate style id %s" % style.style_id)
		seen[style.style_id] = true
		for failure: String in style.validate():
			failures.append("%s: %s" % [style.style_id, failure])
		if style.style_id == DEFAULT_STYLE_ID and style.price != 0:
			failures.append("the default style must be free")
	if not seen.has(DEFAULT_STYLE_ID):
		failures.append("catalog requires the %s style" % DEFAULT_STYLE_ID)
	return failures
