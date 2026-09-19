extends SceneTree
## Validates the character catalog: every entry, prices, the Eclipse gate, rigs, tiers and save ids.

const CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
const RIGGED: Array[StringName] = [&"veyra", &"rook", &"morrow", &"ilyra", &"bram"]
## Characters that carry a collectible tier; everything else must stay STANDARD.
const TIERS: Dictionary[StringName, FormData.Tier] = {
	&"ilyra": FormData.Tier.MYTHIC,
	&"bram": FormData.Tier.LEGENDARY,
}


func _init() -> void:
	var failures: int = 0
	var validation: PackedStringArray = CATALOG.validate()
	if not validation.is_empty():
		failures += validation.size()
		for failure: String in validation:
			push_error("form_catalog: %s" % failure)
	var forms: Array[FormData] = CATALOG.load_forms()
	var expected_prices: Array[int] = [0, 250, 500, 800, 1200, 2000, 0, 0, 0, 0, 0]
	if forms.size() != expected_prices.size():
		failures += 1
		push_error("form_catalog: expected %d characters, got %d" % [
			expected_prices.size(), forms.size(),
		])
	else:
		for index: int in forms.size():
			if forms[index].price != expected_prices[index]:
				failures += 1
				push_error("form_catalog: unexpected price for %s" % forms[index].form_id)
		if not forms[5].requires_boss_victory:
			failures += 1
			push_error("form_catalog: Eclipse did not require a boss victory")
	if CATALOG.get_form(&"invalid").form_id != &"void":
		failures += 1
		push_error("form_catalog: invalid id did not fall back to Void")
	for form: FormData in forms:
		var rigged: bool = form.form_id in RIGGED
		if rigged != (form.visual_scene != null):
			failures += 1
			push_error("form_catalog: %s rig presence is wrong" % form.form_id)
		if form.visual_scene != null:
			var instance: Node = form.visual_scene.instantiate()
			if not instance is PlayableCharacterVisual:
				failures += 1
				push_error("form_catalog: %s rig root is not a PlayableCharacterVisual" % form.form_id)
			instance.free()
		var expected_tier: FormData.Tier = TIERS.get(form.form_id, FormData.Tier.STANDARD)
		if form.tier != expected_tier:
			failures += 1
			push_error("form_catalog: %s has the wrong tier" % form.form_id)
		if String(form.form_id) not in SaveManagerService.VALID_FORM_IDS:
			failures += 1
			push_error("form_catalog: save rejects %s" % form.form_id)
	if SaveManagerService.VALID_FORM_IDS.size() != forms.size():
		failures += 1
		push_error("form_catalog: save ids and catalog disagree")
	if failures == 0:
		print("form_catalog: %d characters validated (%d rigged)" % [forms.size(), RIGGED.size()])
	quit(failures)
