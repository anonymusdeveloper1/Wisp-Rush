class_name FormCatalog
extends Resource
## Ordered registry of the playable characters: six single-image Wisp forms and the rigged characters.
##
## Every entry is cosmetic only - collision, stats and controls never change with the character.

## Number of catalog entries; the Statistics screen counts collected characters against it.
const REQUIRED_FORM_COUNT: int = 8

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


## Returns count, duplicate, required-Void and per-resource authoring failures.
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
	if not seen_ids.has(&"void"):
		failures.append("catalog requires the Void form")
	else:
		for form: FormData in forms:
			if form.form_id == &"void" and form.price != 0:
				failures.append("Void must be free")
	return failures


## Finds a form by persistent identifier, falling back to Void for corrupt input.
func get_form(form_id: StringName) -> FormData:
	var fallback: FormData
	for form: FormData in load_forms():
		if form.form_id == &"void":
			fallback = form
		if form.form_id == form_id:
			return form
	assert(fallback != null, "FormCatalog requires a Void fallback")
	return fallback
