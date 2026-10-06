extends SceneTree
## Real Main/Shop purchase buttons, held-run spending and persistent double-tap Ward consumption.

const MAIN: PackedScene = preload("res://scenes/main/main.tscn")
var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		push_error("pickup_shop_flow: %s" % message)


func _run() -> void:
	var save := root.get_node(^"SaveManager") as SaveManagerService
	_check(save.uses_isolated_storage(), "real save must be isolated")
	save.configure_storage_paths("user://test_runs/pickup_shop_flow.json",
		"user://test_runs/pickup_shop_flow.tmp.json", "user://test_runs/pickup_shop_flow.backup.json")
	save.reset_save()
	save.mark_tutorial_completed()
	save.add_rift_points(5000)
	var main: Node = MAIN.instantiate()
	root.add_child(main)
	for frame: int in 600:
		await process_frame
		if main.get_child_count() > 0 and main.get_child(0) is HomeScreen:
			break
	main.call(&"_show_shop", ShopScreen.TAB_SHOP)
	await process_frame
	var shop := main.get_child(0) as ShopScreen
	_check(shop != null, "Items Shop did not open")
	if shop == null:
		quit(_failures)
		return
	var page := shop.get_node(^"%ItemsPage") as RunItemShopPage
	var expected: int = 0
	for index: int in RunItemCatalog.PACK_SIZES.size():
		(page._buy_buttons[RunItemCatalog.SOUL_WARD][index] as Button).pressed.emit()
		expected += RunItemCatalog.PACK_SIZES[index]
		_check(save.get_item_count(RunItemCatalog.SOUL_WARD) == expected, "pack button quantity")
	_check(save.get_rift_points() == 3360, "pack button price")
	(page._buy_buttons[RunItemCatalog.RIFT_MAGNET][0] as Button).pressed.emit()
	page._boost_buttons[RunItemCatalog.RIFT_MAGNET].pressed.emit()
	_check(str(save.get_snapshot()[&"next_run_item"]) == "rift_magnet", "selection not saved")
	_check(save.get_item_count(RunItemCatalog.RIFT_MAGNET) == 1, "selection spent early")
	var profile := RunProfile.new()
	var held := main.call(&"_build_game", profile) as GameWorld
	held.hold_start()
	held.auto_pause_on_focus_loss = false
	main.call(&"_replace_screen", held)
	await create_timer(0.6).timeout
	_check(save.get_item_count(RunItemCatalog.RIFT_MAGNET) == 1, "held run spent boost")
	_check(not held.get_run_items().is_active(RunItemCatalog.RIFT_MAGNET), "held boost active")
	held.release_start()
	for frame: int in 180:
		await process_frame
		if held.get_run_items().is_active(RunItemCatalog.RIFT_MAGNET):
			break
	_check(save.get_item_count(RunItemCatalog.RIFT_MAGNET) == 0, "run did not spend boost")
	_check(held.get_run_items().is_active(RunItemCatalog.RIFT_MAGNET), "run boost not applied")
	_check(str(save.get_snapshot()[&"next_run_item"]).is_empty(), "run selection not cleared")
	held.debug_quiet_arena()
	await process_frame
	var player: WispPlayer = held._player
	var count: int = save.get_item_count(RunItemCatalog.SOUL_WARD)
	# Phone dispatch order: emulated mouse press owns the pointer before its touch duplicate.
	for tap: int in 2:
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.position = player.global_position
		mouse.pressed = true
		player._unhandled_input(mouse)
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = mouse.position
		touch.pressed = true
		player._unhandled_input(touch)
		mouse.pressed = false
		player._unhandled_input(mouse)
		touch.pressed = false
		player._unhandled_input(touch)
	_check(player.has_soul_ward(), "emulated double tap did not protect")
	_check(save.get_item_count(RunItemCatalog.SOUL_WARD) == count - 1, "tap spent wrong stock")
	_check(held.get_soul_ward_stock() == count - 1, "HUD stock not synchronized")
	main.call(&"_on_soul_ward_requested", held)
	_check(save.get_item_count(RunItemCatalog.SOUL_WARD) == count - 1, "active shield spent again")
	# Physical drop uses Main's persistent collection path exactly once.
	held.spawn_scripted_item(RunItemCatalog.SOUL_WARD, player.global_position)
	await physics_frame
	await physics_frame
	_check(save.get_item_count(RunItemCatalog.SOUL_WARD) == count, "Ward drop not saved once")
	save.reload()
	_check(save.get_item_count(RunItemCatalog.SOUL_WARD) == count, "stock did not persist")
	main.queue_free()
	await process_frame
	print("pickup_shop_flow: pack buttons, held boost, emulated taps and persisted drops checked")
	quit(_failures)
