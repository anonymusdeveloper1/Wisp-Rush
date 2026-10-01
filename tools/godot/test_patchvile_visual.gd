extends SceneTree
## Patchvile's dash is one attack, not a loop (owner, 2026-09-23): it plays once from the launch,
## holds its last frame until the landing, restarts on a redirect, and carries the attack look -
## outline, contact flash, afterimages - which fades after the landing and never moves under
## Reduced Motion. (Shade's dash is a one-shot too, checked in test_verdant_shade_visual.gd.)
##
##     Godot --headless --path . --script res://tools/godot/test_patchvile_visual.gd

const CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/wisp_player.tscn")
const DASH: StringName = &"dash_loop"
const ARENA := Rect2(140.0, 420.0, 800.0, 1100.0)

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	Engine.max_fps = 60
	await _check_one_shot()
	await _check_attack_look_in_a_run()
	if _failures == 0:
		print("patchvile_visual: one-shot dash, restart, hold, attack look and Reduced Motion passed")
	quit(_failures)


func _check_one_shot() -> void:
	var visual := _make_visual(false)
	var sprite := visual.get_node(^"MotionRoot/Body/PoseSprite") as AnimatedSprite2D
	visual.request_state(PlayableCharacterVisual.DASH_START)
	await _frames(visual, PlayableCharacterVisual.DASH_LOOP, 3)
	if visual.get_current_animation() != DASH:
		_fail("a launch shows %s, not the dash" % visual.get_current_animation())
	var frames: SpriteFrames = sprite.sprite_frames
	if frames.get_animation_loop(DASH):
		_fail("the dash still loops")
	var last: int = frames.get_frame_count(DASH) - 1
	await _frames(visual, PlayableCharacterVisual.DASH_LOOP, 45)
	if sprite.frame != last or sprite.is_playing():
		_fail("the dash did not hold its last frame (frame %d, playing %s)" % [sprite.frame, sprite.is_playing()])
	visual.restart_dash()
	await _frames(visual, PlayableCharacterVisual.DASH_LOOP, 1)
	if sprite.frame > 1 or not sprite.is_playing():
		_fail("a redirect did not restart the attack (frame %d)" % sprite.frame)
	visual.queue_free()
	await process_frame


## Through the real controller: the outline rises and afterimages trail while dashing, then fade.
func _check_attack_look_in_a_run() -> void:
	for reduced: bool in [false, true]:
		var player := PLAYER_SCENE.instantiate() as WispPlayer
		root.add_child(player)
		await process_frame
		player.set_arena_rect(ARENA)
		var form: FormData = CATALOG.get_form(&"patchvile")
		player.set_cosmetic_form(form.texture, form.tint, form.visual_scene)
		var visual := player.get_character_visual() as WholeFrameCharacterVisual
		if visual == null:
			_fail("the player did not load Patchvile")
			player.queue_free()
			return
		for _frame: int in 40:
			await process_frame
		# The player re-reads the saved setting whenever it comes to rest, so set it just before the
		# dash rather than at spawn.
		player.set_reduced_motion(reduced)
		player.request_dash(Vector2(0.2, -1.0))
		var outline: float = 0.0
		var flash: float = 0.0
		var afterimages: int = 0
		for _frame: int in 14:
			await process_frame
			outline = maxf(outline, visual.get_attack_look().x)
			flash = maxf(flash, visual.get_attack_look().y)
			afterimages = maxi(afterimages, visual.get_visible_afterimages())
		var label: String = "Reduced Motion" if reduced else "a dash"
		if outline < 0.5:
			_fail("%s: the attack outline never came up (%.2f)" % [label, outline])
		if not reduced and (afterimages == 0 or flash < 0.3):
			_fail("a dash left no afterimages (%d) or no contact flash (%.2f)" % [afterimages, flash])
		if reduced and afterimages > 0:
			_fail("Reduced Motion still drops afterimages")
		for _frame: int in 90:
			await process_frame
		if visual.get_attack_look().x > 0.05 or visual.get_visible_afterimages() > 0:
			_fail("%s: the attack look did not fade after landing" % label)
		player.queue_free()
		await process_frame


func _make_visual(reduced: bool) -> WholeFrameCharacterVisual:
	var scene: PackedScene = CATALOG.get_form(&"patchvile").visual_scene
	var visual := scene.instantiate() as WholeFrameCharacterVisual
	root.add_child(visual)
	visual.set_reduced_motion(reduced)
	return visual


## Steps frames the way the controller does: the same state requested every frame.
func _frames(visual: PlayableCharacterVisual, state: StringName, count: int) -> void:
	for _frame: int in count:
		visual.request_state(state)
		await process_frame


func _fail(message: String) -> void:
	_failures += 1
	push_error("patchvile_visual: %s" % message)
