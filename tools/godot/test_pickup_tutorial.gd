extends SceneTree
## The replacement tutorial lesson demonstrates a Ward and requires the player's own double tap.

const TUTORIAL: PackedScene = preload("res://scenes/tutorial/tutorial_screen.tscn")
var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		push_error("pickup_tutorial: %s" % message)


func _run() -> void:
	var save := root.get_node(^"SaveManager") as SaveManagerService
	var stock_before: int = save.get_item_count(RunItemCatalog.SOUL_WARD)
	var screen := TUTORIAL.instantiate() as TutorialScreen
	root.add_child(screen)
	await process_frame
	await process_frame
	var director: TutorialDirector = screen.get_director()
	var game: GameWorld = screen.get_game()
	var saw_demo_shield: Array[bool] = [false]
	game.shield_activated.connect(func() -> void:
		if director.get_phase() == TutorialDirector.Phase.DEMO:
			saw_demo_shield[0] = true)
	director._begin_lesson(6)
	for frame: int in 1200:
		await physics_frame
		if director.get_phase() == TutorialDirector.Phase.TRY:
			break
	_check(saw_demo_shield[0], "demo did not collect and activate a Ward")
	_check(director.get_phase() == TutorialDirector.Phase.TRY, "demo never reached try")
	_check(not game._player.has_soul_ward() and game.get_soul_ward_stock() == 0,
		"demo protection survived arena reset")
	# The rebuilt target's arrival must finish before a real swipe can slice it.
	await create_timer(0.9).timeout
	game.demo_swipe(Vector2.UP * 260)
	for frame: int in 300:
		await physics_frame
		if game.is_player_ready() and game.get_soul_ward_stock() > 0:
			break
	_check(game.get_soul_ward_stock() > 0, "try did not drop and collect Ward")
	_check(director.get_phase() == TutorialDirector.Phase.TRY, "kill passed the shield lesson")
	for tap: int in 2:
		game._player._begin_pointer(game.get_player_position(), 0)
		game._player._end_pointer(game.get_player_position(), 0)
	_check(director.get_phase() == TutorialDirector.Phase.SUCCESS, "double tap did not pass")
	_check(save.get_item_count(RunItemCatalog.SOUL_WARD) == stock_before,
		"tutorial touched persistent Ward stock")
	screen.queue_free()
	await process_frame
	print("pickup_tutorial: demo, collection, player double tap and save isolation checked")
	quit(_failures)
