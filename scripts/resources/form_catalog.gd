class_name FormCatalog
extends Resource
## Ordered registry of the playable characters, all whole-frame sprite characters since Morrow, the
## last bone rig, was removed (owner 2026-10-05).
##
## Every entry is cosmetic only - collision, stats and controls never change with the character.

## Number of catalog entries; the Statistics screen counts collected characters against it.
const REQUIRED_FORM_COUNT: int = 5
## The character every save owns and equips first, and the fallback for an unknown id: Patchvile
## (owner, 2026-09-25; Void held this until it was removed).
const DEFAULT_FORM_ID: StringName = &"patchvile"

## Form `.tres` paths in intended collection-screen order.
@export var form_paths: PackedStringArray = PackedStringArray()

## Loaded characters, kept for the session. The Shop rebuilds its cards on every tab switch and an
## animated character's rig carries a dozen textures, so dropping them would reload art each time.
var _loaded: Array[FormData] = []


## Loads every configured character (cached) while reporting malformed paths.
func load_forms() -> Array[FormData]:
	if not _loaded.is_empty():
		return _loaded.duplicate()
	for path: String in form_paths:
		var resource: Resource = load(path)
		if resource is FormData:
			_loaded.append(resource as FormData)
		else:
			push_error("FormCatalog could not load FormData: %s" % path)
	return _loaded.duplicate()


## Returns count, duplicate, required-default and per-resource authoring failures.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	var forms: Array[FormData] = load_forms()
	var seen_ids: Dictionary[StringName, bool] = {}
	if forms.size() != REQUIRED_FORM_COUNT:
		failures.append("catalog requires exactly %d forms" % REQUIRED_FORM_COUNT)
	for form: FormData in forms:
		if seen_ids.has(form.form_id):
			failures.append("duplicate form id %s" % form.form_id)
		seen_ids[form.form_id] = true
		for failure: String in form.validate():
			failures.append("%s: %s" % [form.form_id, failure])
	if not seen_ids.has(DEFAULT_FORM_ID):
		failures.append("catalog requires the default form %s" % DEFAULT_FORM_ID)
	else:
		for form: FormData in forms:
			if form.form_id == DEFAULT_FORM_ID and form.price != 0:
				failures.append("the default form %s must be free" % DEFAULT_FORM_ID)
	return failures


## Finds a form by persistent identifier, falling back to the default form for corrupt input.
func get_form(form_id: StringName) -> FormData:
	var fallback: FormData
	for form: FormData in load_forms():
		if form.form_id == DEFAULT_FORM_ID:
			fallback = form
		if form.form_id == form_id:
			return form
	assert(fallback != null, "FormCatalog requires the default form as its fallback")
	return fallback
