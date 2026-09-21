extends SceneTree
## Ilyra (whole-frame sprite): pose selection, cycles, wall poses, anchors, menus and a real run.
##
## The shared `test_playable_character_visual.gd` already holds her to the rig contract every
## character shares. This checks what is specific to a whole-pose sprite character: that each state
## shows the painting the pack was reviewed with, that the cycles run at the authored rate, that the
## four screen-space wall poses are picked from the wall's inward normal and drawn upright, that the
## generated [CharacterPoseSheet] is what the runtime actually applies, and that no state change
## moves the painting's anchor or changes its size by more than the smoothness contract allows.
##
##     Godot --headless --path . --script res://tools/godot/test_ilyra_visual.gd

const CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
const SHEET: CharacterPoseSheet = preload("res://data/characters/ilyra_poses.tres")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/wisp_player.tscn")
const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const HOME_SCENE: PackedScene = preload("res://scenes/screens/home_screen.tscn")
const SHOP_SCENE: PackedScene = preload("res://scenes/screens/shop_screen.tscn")
const ENDLESS_CATALOG: EndlessCatalog = preload("res://data/endless/default_endless_catalog.tres")
const FORM_ID: StringName = &"ilyra"
const ARENA := Rect2(140.0, 420.0, 800.0, 1100.0)

## The pose every state was reviewed with (`concept_art/ilyra_2_sprite_test/README.md`); a cycling
## state lists its first frame here and is checked frame by frame in [method _check_cycles].
## The painting each state resolves onto. Five animations and no more (owner, 2026-09-20): the
## dash states share the dash paintings, and every other state is the wall she is resting against -
## here the floor, because a rig that has been told nothing else stands on it.
const EXPECTED_POSES: Dictionary[StringName, StringName] = {
	PlayableCharacterVisual.IDLE_HOVER: &"wall_bottom",
	PlayableCharacterVisual.MOVE_FLY: &"wall_bottom",
	PlayableCharacterVisual.AIM_CHARGE: &"wall_bottom",
	PlayableCharacterVisual.DASH_START: &"dash_loop_00",
	PlayableCharacterVisual.DASH_LOOP: &"dash_loop_00",
	PlayableCharacterVisual.DASH_END: &"wall_bottom",
	PlayableCharacterVisual.ATTACK: &"dash_loop_00",
	PlayableCharacterVisual.HIT_REACTION: &"wall_bottom",
	PlayableCharacterVisual.DEATH: &"wall_bottom",
	PlayableCharacterVisual.REVIVE_SPAWN: &"wall_bottom",
	PlayableCharacterVisual.VICTORY: &"wall_bottom",
	PlayableCharacterVisual.CHARACTER_SELECTED: &"wall_bottom",
	PlayableCharacterVisual.CHARACTER_UNLOCKED: &"wall_bottom",
}
## Inward wall normal to the pose painted for resting against that wall.
const EXPECTED_WALLS: Dictionary[Vector2, StringName] = {
	Vector2.UP: &"wall_bottom",
	Vector2.DOWN: &"wall_top",
	Vector2.RIGHT: &"wall_left",
	Vector2.LEFT: &"wall_right",
}
## Largest anchor move and size change a pose swap may draw, in source pixels and scale units. Both
## sit under the shared rig smoothness contract (40 px and 0.30 per frame at 60 fps).
const MAX_ANCHOR_STEP: float = 30.0
const MAX_SCALE_STEP: float = 0.25
const PARTICLE_BUDGET: int = 40
## States that step through more than one painting, so a single sample may catch either frame.
const CYCLING_STATES: Array[StringName] = [
	PlayableCharacterVisual.DASH_START,
	PlayableCharacterVisual.DASH_LOOP,
	PlayableCharacterVisual.ATTACK,
]

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	Engine.max_fps = 60
	_check_sheet()
	await _check_scene_contract()
	await _check_state_poses()
	await _check_menu_loop()
	await _check_cycles()
	await _check_surface_poses()
	await _check_aura()
	await _check_reduced_motion()
	await _check_controller_run()
	await _check_home()
	await _check_shop()
	await _check_game_world()
	if _failures == 0:
		print("ilyra_visual: poses, cycles, walls, anchors, menus and a live run passed")
	quit(_failures)


func _fail(message: String) -> void:
	_failures += 1
	push_error("ilyra_visual: %s" % message)


func _form() -> FormData:
	return CATALOG.get_form(FORM_ID)


func _spawn() -> IlyraVisual:
	var visual := _form().visual_scene.instantiate() as IlyraVisual
	if visual == null:
		_fail("the form's visual scene is not an IlyraVisual")
	else:
		root.add_child(visual)
	return visual


## The generated sheet is well formed and stays inside the budgets the runtime relies on.
func _check_sheet() -> void:
	for failure: String in SHEET.validate():
		_fail("pose sheet: %s" % failure)
	if SHEET.pose_names.size() != 20:
		_fail("pose sheet holds %d poses, expected the pack's 20" % SHEET.pose_names.size())
	if not is_equal_approx(SHEET.frame_size, 627.0):
		_fail("pose sheet frame size is %.0f, expected 627" % SHEET.frame_size)
	if SHEET.get_scale_spread() > MAX_SCALE_STEP:
		_fail("pose scales span %.2f, more than one frame may change" % SHEET.get_scale_spread())
	# The padded ceiling pose is the one the pack's review flags as drawn small.
	if SHEET.get_scale(&"wall_top") <= 1.0:
		_fail("wall_top is not scaled up, so it would hang smaller than every other pose")
	for pose: StringName in SHEET.get_pose_names():
		if pose != &"wall_top" and not is_equal_approx(SHEET.get_scale(pose), 1.0):
			_fail("%s is rescaled, but only wall_top was measured to need it" % pose)
		if SHEET.get_offset(pose).length() > MAX_ANCHOR_STEP:
			_fail("%s is drawn %.0f px off its anchor" % [pose, SHEET.get_offset(pose).length()])


## The scene carries exactly the pack, holds no collision and stays inside the particle budget.
func _check_scene_contract() -> void:
	var visual: IlyraVisual = _spawn()
	if visual == null:
		return
	await process_frame
	var sprite := visual.get_node(^"%PoseSprite") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		_fail("the scene has no pose sprite")
		visual.queue_free()
		await process_frame
		return
	var painted: Array[StringName] = []
	painted.assign(sprite.sprite_frames.get_animation_names())
	painted.sort()
	var listed: Array[StringName] = SHEET.get_pose_names()
	# The scene also holds the four menu frames, which are a different canvas and so are not in the
	# generated gameplay sheet.
	listed.append_array(IlyraVisual.MENU_POSES)
	listed.sort()
	if painted != listed:
		_fail("the scene's paintings %s do not match the sheet %s" % [painted, listed])
	if (
		not visual.find_children("*", "CollisionShape2D", true, false).is_empty()
		or not visual.find_children("*", "CollisionObject2D", true, false).is_empty()
	):
		_fail("the visual scene contains collision")
	var particles: int = 0
	for node: Node in visual.find_children("*", "GPUParticles2D", true, false):
		particles += (node as GPUParticles2D).amount
	if particles == 0 or particles > PARTICLE_BUDGET:
		_fail("%d particles is outside the 1..%d budget" % [particles, PARTICLE_BUDGET])
	# Apparent height is only consistent because every painting shares one canvas: the runtime scale
	# corrects the figure inside it, and nothing may have been resampled on the way in.
	var side := Vector2(SHEET.frame_size, SHEET.frame_size)
	for pose: StringName in SHEET.get_pose_names():
		var texture: Texture2D = sprite.sprite_frames.get_frame_texture(pose, 0)
		if texture == null or texture.get_size() != side:
			_fail("%s is not a %.0f px canvas" % [pose, SHEET.frame_size])
		if sprite.sprite_frames.get_frame_count(pose) != 1:
			_fail("%s should be one painting, not a strip" % pose)
	visual.queue_free()
	await process_frame


## Every state in the vocabulary shows the painting it was reviewed with, at the sheet's placement.
func _check_state_poses() -> void:
	var visual: IlyraVisual = _spawn()
	if visual == null:
		return
	await process_frame
	# Gameplay mode: a menu character holds her storefront rest instead, which `_check_menu_loop`
	# covers. Here the dash states show the dash paintings and every other state is her wall.
	visual.set_preview_mode(false)
	# The vocabulary is walked in its authored order on purpose: death only releases the rig to
	# revive_spawn, and every other one-shot has to run out before the next request may start.
	for state: StringName in PlayableCharacterVisual.STATES:
		if not EXPECTED_POSES.has(state):
			_fail("%s has no reviewed pose" % state)
			continue
		visual.request_state(state)
		await process_frame
		var showing: StringName = visual.get_current_pose()
		var cycles: bool = state in CYCLING_STATES
		_check_pose_placement(visual, state, showing if cycles else EXPECTED_POSES[state])
		if cycles and not SHEET.has_pose(showing):
			_fail("%s shows the unknown painting %s" % [state, showing])
		if state not in PlayableCharacterVisual.LOOPS:
			await create_timer(visual.get_state_length(state) + 0.06).timeout
	visual.queue_free()
	await process_frame


## The painting on screen is the reviewed one, placed and sized exactly as the sheet says.
func _check_pose_placement(
	visual: IlyraVisual, moment: StringName, expected: StringName
) -> void:
	var pose: StringName = visual.get_current_pose()
	if pose != expected:
		_fail("%s shows %s, expected %s" % [moment, pose, expected])
		return
	var drawn: Transform2D = visual.get_pose_transform()
	var wanted_offset: Vector2 = SHEET.get_offset(pose) * SHEET.get_scale(pose)
	if drawn.origin.distance_to(wanted_offset) > 0.01:
		_fail("%s is drawn at %s, but the sheet says %s" % [pose, drawn.origin, wanted_offset])
	if absf(drawn.get_scale().x - SHEET.get_scale(pose)) > 0.01:
		_fail("%s is drawn at scale %.3f, but the sheet says %.3f" % [
			pose, drawn.get_scale().x, SHEET.get_scale(pose),
		])
	if visual.get_layer_bounds().size.is_zero_approx():
		_fail("%s reports an empty silhouette" % pose)


## In a menu she plays her ready-stance video (ADR-0016), on Home and on a Shop card, and keeps
## playing it when the card is picked or bought. It is drawn through the shared packed-alpha player
## in the square the intake placed it in, pauses while its card is hidden, restarts after its screen
## is re-attached, and gives way to her held welcome painting under Reduced Motion.
func _check_menu_loop() -> void:
	var visual: IlyraVisual = _spawn()
	if visual == null:
		return
	await process_frame
	visual.set_preview_mode(true)
	visual.request_state(PlayableCharacterVisual.IDLE_HOVER)
	for _frame: int in 20:
		await process_frame
	var player: VideoStreamPlayer = visual.get_menu_video_player()
	if player == null or visual.get_current_pose() != IlyraVisual.MENU_VIDEO:
		_fail("a menu preview shows %s, expected her menu video" % visual.get_current_pose())
		visual.queue_free()
		return
	var data: MenuVideoData = visual.menu_video
	if player.stream != data.stream or not player.loop:
		_fail("the menu video is not her looping clip")
	if player.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("the menu video would swallow taps meant for the card")
	var material := player.material as ShaderMaterial
	if material == null or material.shader != CharacterMenuVideo.PACKED_ALPHA_SHADER:
		_fail("the menu video is not drawn through the packed-alpha shader")
	if not player.size.is_equal_approx(Vector2.ONE * data.side):
		_fail("the menu video is %s, the intake placed it at %.1f" % [player.size, data.side])
	if (player.position + player.size * 0.5).distance_to(data.offset) > 0.5:
		_fail("the menu video is not centred where the intake placed it")
	if absf(player.get_stream_length() - data.loop_seconds) > 0.1:
		_fail("the clip is %.2f s, the intake cut a %.2f s loop" % [
			player.get_stream_length(), data.loop_seconds,
		])
	var sprite := visual.get_node(^"%PoseSprite") as CanvasItem
	var aura := visual.get_node_or_null(^"%Aura") as CanvasItem
	if sprite.visible or (aura != null and aura.visible):
		_fail("the painting or the ornament ring is still drawn over the menu video")
	var started: float = player.stream_position
	for _frame: int in 20:
		await process_frame
	if not visual.is_menu_video_playing() or player.stream_position <= started:
		_fail("the menu video is not advancing")
	# The storefront reactions were cut (owner, 2026-09-20): picking or buying her card leaves the
	# clip playing rather than throwing a flourish.
	for event: StringName in [
		PlayableCharacterVisual.CHARACTER_SELECTED, PlayableCharacterVisual.CHARACTER_UNLOCKED,
	]:
		if event == PlayableCharacterVisual.CHARACTER_SELECTED:
			visual.play_character_selected()
		else:
			visual.play_character_unlocked()
		for _frame: int in 30:
			await process_frame
			if visual.get_current_pose() != IlyraVisual.MENU_VIDEO:
				_fail("%s took the card off her video onto %s" % [event, visual.get_current_pose()])
				break
	# A hidden card keeps its character in the tree; the clip must stop decoding and come back.
	visual.visible = false
	await process_frame
	if not player.paused:
		_fail("a hidden menu video kept playing")
	visual.visible = true
	await process_frame
	if player.paused:
		_fail("the menu video did not resume when its card came back")
	# Main keeps one Home and detaches it; a video player stops itself when it leaves the tree.
	root.remove_child(visual)
	for _frame: int in 5:
		await process_frame
	root.add_child(visual)
	for _frame: int in 3:
		await process_frame
	var resumed: float = player.stream_position
	for _frame: int in 20:
		await process_frame
	if not visual.is_menu_video_playing() or player.stream_position <= resumed:
		_fail("the menu video stayed stopped after its screen was detached and re-attached")
	# Reduced Motion never plays a video: her welcome painting is held instead, at the menu scale.
	visual.set_reduced_motion(true)
	await process_frame
	if visual.get_menu_video_player() != null or visual.get_current_pose() != IlyraVisual.MENU_REST:
		_fail("Reduced Motion showed %s instead of the held %s" % [
			visual.get_current_pose(), IlyraVisual.MENU_REST,
		])
	var drawn: float = visual.get_pose_transform().get_scale().x
	if absf(drawn - IlyraVisual.MENU_SCALE) > 0.01:
		_fail("the held menu rest is drawn at %.3f, expected the menu scale %.3f" % [
			drawn, IlyraVisual.MENU_SCALE,
		])
	visual.set_reduced_motion(false)
	await process_frame
	if visual.get_menu_video_player() == null:
		_fail("turning Reduced Motion off did not bring the video back")
	visual.queue_free()
	await process_frame


## The dash steps through its two paintings at the authored rate; the second is the contact frame.
func _check_cycles() -> void:
	var visual: IlyraVisual = _spawn()
	if visual == null:
		return
	await process_frame
	visual.set_preview_mode(false)
	# Sampled over two full cycles, so both paintings have to come round more than once.
	var fps: float = IlyraVisual.DASH_FPS
	visual.request_state(PlayableCharacterVisual.IDLE_HOVER)
	await process_frame
	visual.request_state(PlayableCharacterVisual.DASH_LOOP)
	await process_frame
	if visual.get_current_pose() != &"dash_loop_00":
		_fail("the dash opens on %s, expected dash_loop_00" % visual.get_current_pose())
	var swaps: int = 0
	var previous: StringName = visual.get_current_pose()
	var seen: Dictionary[StringName, bool] = {}
	var elapsed: float = 0.0
	while elapsed < 2.4 / fps:
		visual.request_state(PlayableCharacterVisual.DASH_LOOP)
		await process_frame
		elapsed += root.get_process_delta_time()
		var pose: StringName = visual.get_current_pose()
		seen[pose] = true
		if pose != previous:
			swaps += 1
			previous = pose
	for frame: StringName in [&"dash_loop_00", &"dash_loop_01_attack"]:
		if not seen.has(frame):
			_fail("the dash never showed %s at %.0f fps" % [frame, fps])
	if swaps < 2:
		_fail("the dash swapped paintings %d times in two cycles at %.0f fps" % [swaps, fps])
	visual.queue_free()
	await process_frame


## A live character resting on a boundary shows that wall's painting, upright on screen; a menu
## preview keeps the hovering idle whatever wall it is told about.
func _check_surface_poses() -> void:
	var visual: IlyraVisual = _spawn()
	if visual == null:
		return
	await process_frame
	for normal: Vector2 in EXPECTED_WALLS:
		visual.sync_controller(
			627.0, 1.0, PlayableCharacterVisual.IDLE_HOVER, Vector2.ZERO, 0.0, normal, 0.0
		)
		await process_frame
		if visual.get_current_pose() != EXPECTED_WALLS[normal]:
			_fail("resting on %s shows %s, expected %s" % [
				normal, visual.get_current_pose(), EXPECTED_WALLS[normal],
			])
		# Settle the heading spring and the counter-rotation, then check the painting is upright.
		for _frame: int in 75:
			visual.sync_controller(
				627.0, 1.0, PlayableCharacterVisual.IDLE_HOVER, Vector2.ZERO, 0.0, normal, 0.0
			)
			await process_frame
		var standing: float = absf(angle_difference(visual.rotation, visual.get_standing_heading()))
		if standing > 0.08:
			_fail("resting on %s left the rig %.2f rad off the wall" % [normal, standing])
		var sprite := visual.get_node(^"%PoseSprite") as Node2D
		var upright: float = absf(angle_difference(sprite.global_rotation, 0.0))
		if upright > 0.08:
			_fail("the %s painting is turned %.2f rad instead of screen-upright" % [
				EXPECTED_WALLS[normal], upright,
			])
	visual.set_preview_mode(true)
	for normal: Vector2 in EXPECTED_WALLS:
		visual.surface_normal = normal
		visual.request_state(PlayableCharacterVisual.IDLE_HOVER)
		await process_frame
		# A menu character rests against nothing: she performs her video, whatever wall she is told
		# about.
		if visual.get_current_pose() != IlyraVisual.MENU_VIDEO:
			_fail("a menu preview on %s shows the wall pose %s" % [
				normal, visual.get_current_pose(),
			])
	visual.queue_free()
	await process_frame


## The ring of star motes drifts on its own, outside the body motion, and stops for Reduced Motion.
func _check_aura() -> void:
	var visual: IlyraVisual = _spawn()
	if visual == null:
		return
	await process_frame
	var aura := visual.get_node_or_null(^"%Aura") as CharacterAura
	if aura == null:
		_fail("she has no aura")
		visual.queue_free()
		await process_frame
		return
	if aura.get_mote_count() <= 0:
		_fail("the aura built no motes")
	# Outside %MotionRoot on purpose: the body's squash and dash heading must not drag the ring.
	if visual.get_node(^"%MotionRoot").is_ancestor_of(aura):
		_fail("the aura sits inside the body motion")
	visual.set_preview_mode(true)
	var before: Array[Vector2] = _mote_positions(aura)
	for _frame: int in 30:
		await process_frame
	var after: Array[Vector2] = _mote_positions(aura)
	var moved: float = 0.0
	for index: int in mini(before.size(), after.size()):
		moved = maxf(moved, before[index].distance_to(after[index]))
	if moved < 1.0:
		_fail("the aura never drifted")
	visual.set_reduced_motion(true)
	await process_frame
	var stilled: Array[Vector2] = _mote_positions(aura)
	for _frame: int in 20:
		await process_frame
	if _mote_positions(aura) != stilled:
		_fail("reduced motion still drifts the aura")
	visual.queue_free()
	await process_frame


func _mote_positions(aura: CharacterAura) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for node: Node in aura.get_children():
		if node is Sprite2D:
			points.append((node as Sprite2D).position)
	return points


## Reduced Motion stills the cycles and the blink and stops the particles, but keeps a readable pose
## for the state and still picks the wall the character rests on.
func _check_reduced_motion() -> void:
	var visual: IlyraVisual = _spawn()
	if visual == null:
		return
	await process_frame
	visual.set_reduced_motion(true)
	for held: Array in [
		[PlayableCharacterVisual.IDLE_HOVER, &"wall_bottom"],
		[PlayableCharacterVisual.DASH_LOOP, &"dash_loop_00"],
	]:
		visual.set_preview_mode(false)
		visual.request_state(held[0])
		await process_frame
		for _frame: int in 40:
			visual.request_state(held[0])
			await process_frame
			if visual.get_current_pose() != held[1]:
				_fail("reduced motion still cycles %s (%s)" % [held[0], visual.get_current_pose()])
				break
	# The menu loop has to hold one frame too, not keep breathing.
	visual.set_preview_mode(true)
	visual.request_state(PlayableCharacterVisual.IDLE_HOVER)
	await process_frame
	var held: StringName = visual.get_current_pose()
	if held not in IlyraVisual.MENU_POSES:
		_fail("reduced motion left a menu preview on %s" % held)
	for _frame: int in 60:
		await process_frame
		if visual.get_current_pose() != held:
			_fail("reduced motion still runs the menu loop (%s)" % visual.get_current_pose())
			break
	for node: Node in visual.find_children("*", "GPUParticles2D", true, false):
		if (node as GPUParticles2D).emitting:
			_fail("reduced motion still emits particles")
	# Surface poses survive Reduced Motion: they are the pose, not the animation.
	visual.set_preview_mode(false)
	for normal: Vector2 in EXPECTED_WALLS:
		visual.sync_controller(
			627.0, 1.0, PlayableCharacterVisual.IDLE_HOVER, Vector2.ZERO, 0.0, normal, 0.0
		)
		await process_frame
		if visual.get_current_pose() != EXPECTED_WALLS[normal]:
			_fail("reduced motion lost the %s pose" % EXPECTED_WALLS[normal])
	visual.queue_free()
	await process_frame


## The real controller drives her through a run: every state is reached with its painting, and no
## single frame moves the painting's anchor or changes its size more than the budget.
func _check_controller_run() -> void:
	var player := PLAYER_SCENE.instantiate() as WispPlayer
	root.add_child(player)
	await process_frame
	player.set_arena_rect(ARENA)
	var form: FormData = _form()
	player.set_cosmetic_form(form.texture, form.tint, form.visual_scene)
	var visual := player.get_character_visual() as IlyraVisual
	if visual == null:
		_fail("WispPlayer did not load the sprite character")
		player.queue_free()
		await process_frame
		return
	var seen: Dictionary[StringName, bool] = {}
	var previous: Transform2D = visual.get_pose_transform()
	var steps: int = 0
	var worst_move: float = 0.0
	var worst_resize: float = 0.0
	# The straight dashes come first and from the floor's middle: a diagonal one parks her against a
	# side wall, and from there every later landing picks that same wall again. Each dash also needs
	# its flight and landing to finish before the next request, or the controller refuses it.
	var script: Array[Callable] = [
		func() -> void: pass,
		func() -> void: player.request_dash(Vector2.UP),
		func() -> void: player.request_dash(Vector2.DOWN),
		func() -> void: player.request_dash(Vector2(0.4, -1.0)),
		func() -> void: player.play_attack_visual(),
		func() -> void: pass,
		# A run starts on one Soul Fragment, so the hit below would be fatal and neither the hurt nor
		# the victory pose would ever play: stock up first.
		func() -> void:
			player.increase_maximum_health(3, 3)
			player.take_hazard_damage(Vector2(ARENA.end.x - 60.0, ARENA.get_center().y)),
		func() -> void: player.play_victory(0.6),
	]
	var beats: Array[int] = [40, 60, 60, 3, 3, 55, 40, 60]
	for index: int in beats.size():
		script[index].call()
		for _frame: int in beats[index]:
			await process_frame
			steps += 1
			seen[visual.get_current_pose()] = true
			var now: Transform2D = visual.get_pose_transform()
			worst_move = maxf(worst_move, previous.origin.distance_to(now.origin))
			worst_resize = maxf(
				worst_resize, absf(previous.get_scale().x - now.get_scale().x)
			)
			previous = now
	if worst_move > MAX_ANCHOR_STEP:
		_fail("a state change moved the painting %.1f px in one frame" % worst_move)
	if worst_resize > MAX_SCALE_STEP:
		_fail("a state change resized the painting by %.2f in one frame" % worst_resize)
	if steps < 240:
		_fail("only %d frames were measured" % steps)
	for pose: StringName in [
		&"dash_loop_00", &"dash_loop_01_attack", &"wall_top", &"wall_bottom",
	]:
		if not seen.has(pose):
			_fail("a full run never showed %s" % pose)
	player.queue_free()
	await process_frame


## Home shows her live, on the hovering idle rather than a wall pose.
func _check_home() -> void:
	var home := HOME_SCENE.instantiate() as HomeScreen
	home.setup({
		&"rift_points": 0,
		&"ads_removed": false,
		&"settings": {&"reduced_motion": false},
	}, _form())
	root.add_child(home)
	await process_frame
	await process_frame
	var preview := home.get_node(^"%CharacterPreview") as PlayableCharacterPreview
	var visual: IlyraVisual = null
	if preview != null:
		visual = preview.get_visual() as IlyraVisual
	if visual == null:
		_fail("Home did not show her live")
	else:
		# Home holds her menu rest rather than a wall pose: a menu character is not resting against
		# anything. The storefront reactions were cut on 2026-09-20, so nothing else may show here.
		await create_timer(1.1).timeout
		var settled: StringName = visual.get_current_pose()
		if settled != IlyraVisual.MENU_VIDEO:
			_fail("Home settles on %s instead of her menu video" % settled)
	home.queue_free()
	await process_frame


## Her Shop card animates, celebrates a purchase and answers an equip.
func _check_shop() -> void:
	var snapshot: Dictionary = {
		&"rift_points": 0,
		&"owned_forms": ["void"],
		&"equipped_form": "void",
		&"owned_dash_styles": ["soul"],
		&"equipped_dash_style": "soul",
		&"owned_arena_skins": [],
		&"equipped_arena_skin": ENDLESS_CATALOG.default_skin_id,
		&"bosses_defeated": 0,
		&"settings": {&"reduced_motion": false},
		&"store_available": false,
	}
	var shop := SHOP_SCENE.instantiate() as ShopScreen
	shop.setup(snapshot, ShopScreen.TAB_WISPS)
	root.add_child(shop)
	await process_frame
	await process_frame
	# The Shop opens on the equipped character, which here is Void, so her card is built but asleep:
	# only the focused card and its neighbours are live (character_sprite_frames.md §9c). What must
	# hold is that her card exists and wakes when she is bought or equipped, which is what follows.
	if shop.find_child("Card_%s" % FORM_ID, true, false) == null:
		_fail("her Shop card was never built")
	if _card_preview(shop) != null:
		_fail("her Shop card is live while Void is focused; the lazy window is not holding")
	var card: PlayableCharacterPreview = null
	var bought: Dictionary = snapshot.duplicate(true)
	bought[&"owned_forms"] = ["void", "ilyra"]
	bought[&"equipped_form"] = "ilyra"
	shop.setup(bought, ShopScreen.TAB_WISPS)
	await process_frame
	await process_frame
	card = _card_preview(shop)
	if card == null or card.get_visual() == null:
		_fail("her Shop card vanished after the purchase")
	elif card.get_visual().get_current_visual_state() in [PlayableCharacterVisual.CHARACTER_SELECTED, PlayableCharacterVisual.CHARACTER_UNLOCKED]:
		_fail("buying her played the %s bounce" % card.get_visual().get_current_visual_state())
	elif (card.get_visual() as IlyraVisual).get_current_pose() != IlyraVisual.MENU_VIDEO:
		_fail("buying her showed %s; a bought card keeps breathing" % [
			(card.get_visual() as IlyraVisual).get_current_pose(),
		])
	var equipped: Dictionary = bought.duplicate(true)
	equipped[&"equipped_form"] = "void"
	shop.setup(equipped, ShopScreen.TAB_WISPS)
	await process_frame
	await process_frame
	equipped[&"equipped_form"] = "ilyra"
	shop.setup(equipped, ShopScreen.TAB_WISPS)
	await process_frame
	await process_frame
	card = _card_preview(shop)
	if card == null or card.get_visual() == null:
		_fail("her Shop card vanished after the equip")
	elif card.get_visual().get_current_visual_state() in [PlayableCharacterVisual.CHARACTER_SELECTED, PlayableCharacterVisual.CHARACTER_UNLOCKED]:
		_fail("equipping her played the %s bounce" % card.get_visual().get_current_visual_state())
	elif (card.get_visual() as IlyraVisual).get_current_pose() != IlyraVisual.MENU_VIDEO:
		_fail("equipping her showed %s; an equipped card keeps breathing" % [
			(card.get_visual() as IlyraVisual).get_current_pose(),
		])
	shop.queue_free()
	await process_frame


## A production GameWorld loads her rig onto the player without touching the collider.
func _check_game_world() -> void:
	var skin: ArenaSkinData = ENDLESS_CATALOG.get_skin(ENDLESS_CATALOG.default_skin_id)
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.auto_pause_on_focus_loss = false
	game.configure_run(RunProfile.tutorial(ENDLESS_CATALOG, skin, _form()))
	root.add_child(game)
	await create_timer(0.6).timeout
	var player := game.get_node_or_null(^"WorldContent/PlayerLayer/WispPlayer") as WispPlayer
	var visual: IlyraVisual = null
	if player != null:
		visual = player.get_character_visual() as IlyraVisual
	if visual == null:
		_fail("GameWorld did not load her rig")
	else:
		if visual.get_scene_file_path() != _form().visual_scene.resource_path:
			_fail("GameWorld loaded the wrong rig")
		var circle := (player.get_node(^"%CollisionShape") as CollisionShape2D).shape as CircleShape2D
		if circle == null or not is_equal_approx(player.get_collision_radius(), circle.radius):
			_fail("GameWorld's collider disagrees with the controller")
		if not SHEET.has_pose(visual.get_current_pose()):
			_fail("GameWorld shows the unknown painting %s" % visual.get_current_pose())
	game.queue_free()
	await process_frame


func _card_preview(shop: ShopScreen) -> PlayableCharacterPreview:
	var card: Node = shop.find_child("Card_%s" % FORM_ID, true, false)
	if card == null:
		return null
	# Since 2026-09-20 only the focused card and its neighbours are live, and a live card's preview
	# is named LivePortrait; a sleeping card keeps a still TextureRect called Portrait.
	return card.find_child("LivePortrait", true, false) as PlayableCharacterPreview
