extends SceneTree
## Purchases, migration, reload, atomic failure and one-use boost stock in isolated storage.

const CATALOG: RunItemCatalog = preload("res://data/items/default_item_catalog.tres")
var _failures: int = 0

class WriteFailureSave extends SaveManagerService:
	func save_now() -> bool:
		return false


func _init() -> void:
	call_deferred(&"_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		push_error("pickup_inventory: %s" % message)


func _run() -> void:
	var save := root.get_node(^"SaveManager") as SaveManagerService
	_check(save.uses_isolated_storage(), "test must use isolated storage")
	save.configure_storage_paths("user://test_runs/pickup_inventory.json",
		"user://test_runs/pickup_inventory.tmp.json",
		"user://test_runs/pickup_inventory.backup.json")
	save.reset_save()
	_check(CATALOG.validate().is_empty(), "catalog invalid")
	_check(save.add_rift_points(10000), "could not seed balance")
	var spent: int = 0
	for item: RunItemData in CATALOG.get_shop_items():
		var expected_stock: int = 0
		for quantity: int in RunItemCatalog.PACK_SIZES:
			var price: int = item.unit_price * quantity
			_check(CATALOG.get_pack_price(item.item_id, quantity) == price, "pack price")
			_check(save.purchase_item_pack(item.item_id, quantity), "valid pack failed")
			expected_stock += quantity
			spent += price
			_check(save.get_item_count(item.item_id) == expected_stock, "pack stock")
	_check(save.get_rift_points() == 10000 - spent, "balance does not match all packs")
	var before: Dictionary = save.get_snapshot()
	for id: StringName in [&"unknown", RunItemCatalog.BANISH_BOMB]:
		_check(not save.purchase_item_pack(id, 1), "invalid item bought")
	for quantity: int in [0, -1, 2, 1000000]:
		_check(not save.purchase_item_pack(RunItemCatalog.SOUL_WARD, quantity), "invalid pack")
	_check(save.get_snapshot() == before, "refused pack changed state")
	_check(not save.select_starting_item(RunItemCatalog.SOUL_WARD), "Ward selected as boost")
	_check(save.select_starting_item(RunItemCatalog.RIFT_MAGNET), "select owned boost")
	save.reload()
	_check(save.get_item_count(RunItemCatalog.SOUL_WARD) == 41, "reload lost Ward stock")
	_check(save.consume_starting_item() == RunItemCatalog.RIFT_MAGNET, "selected boost not spent")
	_check(save.consume_starting_item().is_empty(), "boost spent twice")
	_check(save.get_item_count(RunItemCatalog.RIFT_MAGNET) == 40, "boost count wrong")
	_check(save.grant_item(RunItemCatalog.SOUL_WARD), "collected Ward not saved")
	_check(save.consume_item(RunItemCatalog.SOUL_WARD), "Ward not spent")
	save.reload()
	_check(save.get_item_count(RunItemCatalog.SOUL_WARD) == 41, "Ward grant/spend reload")
	var migrated: Dictionary = save._validate_and_migrate({
		"schema_version": 9, "rift_points": 512, "best_score": 3456,
		"equipped_form": "patchvile", "tutorial_completed": true,
	})
	_check(int(migrated[&"schema_version"]) == 10, "schema did not migrate")
	_check(int(migrated[&"rift_points"]) == 512 and int(migrated[&"best_score"]) == 3456,
		"migration changed progression")
	_check((migrated[&"item_stock"] as Dictionary).values().all(
		func(value: Variant) -> bool: return int(value) == 0), "migration grants stock")
	var corrupt: Dictionary = save._validate_and_migrate({"schema_version": 10,
		"item_stock": {"soul_ward": -5, "rift_magnet": 2.0, "fortune_star": "bad",
			"banish_bomb": 999}, "next_run_item": "fortune_star"})
	_check(int((corrupt[&"item_stock"] as Dictionary)["rift_magnet"]) == 2,
		"JSON numeric count lost")
	_check(str(corrupt[&"next_run_item"]).is_empty(), "unowned selection survived")
	# A failed persistence operation must return exactly the prior balance and stock.
	before = save.get_snapshot()
	var failing := WriteFailureSave.new()
	failing._data = before.duplicate(true)
	_check(not failing.purchase_item_pack(RunItemCatalog.SOUL_WARD, 1), "failed write succeeded")
	_check(failing.get_snapshot() == before, "failed write spent RP or granted stock")
	_check(not failing.consume_item(RunItemCatalog.SOUL_WARD), "failed consume succeeded")
	_check(failing.get_snapshot() == before, "failed consume removed stock")
	failing.free()
	save.reset_save()
	_check(not save.purchase_item_pack(RunItemCatalog.SOUL_WARD, 1), "zero RP bought pack")
	_check(not save.consume_item(RunItemCatalog.SOUL_WARD), "empty Ward spent")
	print("pickup_inventory: packs, reload, migration, one-use boosts and rollback checked")
	quit(_failures)
