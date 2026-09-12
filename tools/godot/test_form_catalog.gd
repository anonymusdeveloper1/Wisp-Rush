extends SceneTree
## Form catalog count, prices, art and unlock rule checks.

const CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")


func _init() -> void:
	var failures: int = 0
	var validation: PackedStringArray = CATALOG.validate()
	if not validation.is_empty():
		failures += validation.size()
		for failure: String in validation:
			push_error("form_catalog: %s" % failure)
	var forms: Array[FormData] = CATALOG.load_forms()
	var expected_prices: Array[int] = [0, 250, 500, 800, 1200, 2000]
	if forms.size() == expected_prices.size():
		for index: int in forms.size():
			if forms[index].price != expected_prices[index]:
				failures += 1
				push_error("form_catalog: incorrect price for %s" % forms[index].form_id)
	if CATALOG.get_form(&"invalid").form_id != &"void":
		failures += 1
		push_error("form_catalog: invalid id did not fall back to Void")
	if forms.size() == 6 and not forms[5].requires_boss_victory:
		failures += 1
		push_error("form_catalog: Eclipse did not require a boss victory")
	if failures == 0:
		print("form_catalog: six supplied cosmetic forms validated")
	quit(failures)
