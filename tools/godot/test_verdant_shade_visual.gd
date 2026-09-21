extends SceneTree
## Verdant Shade (whole-frame sprite): the pack contract, state and wall mapping, the menu
## performance, Reduced Motion, and the frame-set split that keeps the Shop affordable.
##
## The animation order, frame counts, rates and loop flags are asserted against the agreed contract
## in [constant CONTRACT], so a regenerated pack that quietly changes a count fails here.
##
##   Godot --headless --path . --script res://tools/godot/test_verdant_shade_visual.gd

const CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
const FORM_ID: StringName = &"verdant_shade"
const GAMEPLAY_FRAMES: String = "res://data/characters/verdant_shade_gameplay.tres"
const MENU_FRAMES: String = "res://data/characters/verdant_shade_menu.tres"
## Shade's menus play a video (ADR-0016); the menu frame set is only the Reduced Motion fallback.
const MENU_VIDEO: MenuVideoData = preload("res://data/characters/verdant_shade_menu_video.tres")
## How much faster than the pack authored them the looping animations actually play. Owner feedback
## on the phone, 2026-09-20: the idles read as steps. The one-shots are not scaled, because their
## rates are matched to [constant PlayableCharacterVisual.STATE_LENGTHS].
const LOOP_FPS_SCALE: float = 1.4
## The approved animation order: name, frame count, **authored** rate and whether it loops. Written out here on
## purpose rather than read back from the pack's manifest — `concept_art/` is `.gdignore`d and, more
## to the point, a generated resource checked against its own generator proves nothing. This is the
## contract both the art pack and `extract_playable_characters.py` have to keep meeting.
const CONTRACT: Array[Array] = [
	[&"dash_loop", 4, 12.5, true],
	[&"wall_bottom", 8, 6.7, true],
	[&"wall_top", 8, 6.7, true],
	[&"wall_left", 8, 6.7, true],
	[&"storefront_idle", 12, 6.0, true],
]
## The animations the set used to carry, cut on 2026-09-20 (owner): the dash is also the attack, the
## wall loops are the landing and the rest, and a hit or a death plays out through the controller's
## blink, edge reset and alpha dissolve. They are still in `concept_art/`, so this list is what
## stops one drifting back onto a sheet by accident rather than by decision.
const CUT_ANIMATIONS: Array[StringName] = [
	&"aim_charge", &"idle_hover", &"move_fly", &"dash_start", &"dash_end", &"attack",
	&"hit_reaction", &"death", &"revive_spawn", &"victory",
	&"storefront_flourish", &"storefront_unlock",
]
## How far a *looping* animation's painted silhouette may wander between its own frames, in pack
## pixels. The anchor is the cell centre by construction, so this is not measuring the anchor: it is
## measuring whether a loop the player watches for seconds at a time sits still. It is deliberately
## checked per animation rather than across the pack, because a state that is *supposed* to move the
## silhouette a long way - `death` dissolves, `revive_spawn` assembles - would otherwise set the
## budget for everything.
const MAX_LOOP_DRIFT: float = 26.0

var _failures: int = 0


func _initialize() -> void:
	_run()


func _run() -> void:
	await _check_pack_contract()
	await _check_states()
	await _check_walls()
	await _check_aim_is_inert()
	await _check_menu()
	await _check_menu_video()
	await _check_frame_set_split()
	await _check_reduced_motion()
	if _failures > 0:
		push_error("verdant_shade_visual: %d failures" % _failures)
		quit(1)
		return
	print("verdant_shade_visual: pack, states, walls, menu, split and reduced motion passed")
	quit()


func _fail(message: String) -> void:
	_failures += 1
	push_error("verdant_shade_visual: %s" % message)


func _spawn(menu: bool = false) -> VerdantShadeVisual:
	var form: FormData = CATALOG.get_form(FORM_ID)
	if form == null or form.visual_scene == null:
		_fail("the catalog has no %s with a visual scene" % FORM_ID)
		return null
	var visual := form.visual_scene.instantiate() as VerdantShadeVisual
	if visual == null:
		_fail("the %s scene is not a VerdantShadeVisual" % FORM_ID)
		return null
	root.add_child(visual)
	visual.set_preview_mode(menu)
	return visual


## Drives the rig the way the controller does - through `sync_controller`, resting on the floor -
## until it is actually showing [param animation]. A one-shot is an interrupt that has to finish
## before the next request is honoured, so a single frame is not enough: the preceding state would
## still be on screen. Going through the controller contract rather than [method request_state] is
## also what gives the rig its gameplay state, and that is what decides the loop a finished one-shot
## falls back to - a `dash_start` left to fall back on its own lands on the idle, not the dash.
func _settles_on(
	visual: VerdantShadeVisual, state: StringName, animation: StringName, frames: int = 180
) -> bool:
	for _frame: int in frames:
		visual.sync_controller(235.0, 1.0, state, Vector2.ZERO, 0.0, Vector2.UP, 0.0)
		await process_frame
		if visual.get_current_animation() == animation:
			return true
	return false


## Every animation the approved pack promises exists, with its frame count, rate and loop flag, in
## whichever of the two generated frame sets it belongs to.
func _check_pack_contract() -> void:
	var sets: Dictionary[String, SpriteFrames] = {
		"gameplay": load(GAMEPLAY_FRAMES) as SpriteFrames,
		"menu": load(MENU_FRAMES) as SpriteFrames,
	}
	var total: int = 0
	for spec: Array in CONTRACT:
		var state: StringName = spec[0]
		var frames: SpriteFrames = null
		var carriers: int = 0
		for key: String in sets:
			if sets[key] != null and sets[key].has_animation(state):
				carriers += 1
				frames = sets[key]
		# The two sets are exclusive: a run never pays for the storefront loop, and a Shop card
		# never pays for the dash and wall frames.
		if carriers > 1:
			_fail("%s is in both frame sets; the split must be exclusive" % state)
		if frames == null:
			_fail("no frame set carries %s" % state)
			continue
		var expected: int = int(spec[1])
		if frames.get_frame_count(state) != expected:
			_fail("%s has %d frames, the pack promises %d" % [
				state, frames.get_frame_count(state), expected,
			])
		var rate: float = float(spec[2]) * (LOOP_FPS_SCALE if bool(spec[3]) else 1.0)
		if absf(frames.get_animation_speed(state) - rate) > 0.01:
			_fail("%s plays at %.2f fps, expected %.2f (authored %.2f%s)" % [
				state, frames.get_animation_speed(state), rate, float(spec[2]),
				" x%.2f" % LOOP_FPS_SCALE if bool(spec[3]) else "",
			])
		if frames.get_animation_loop(state) != bool(spec[3]):
			_fail("%s loops %s, the contract says %s" % [
				state, frames.get_animation_loop(state), bool(spec[3]),
			])
		total += expected
	if total != 40:
		_fail("the pack came to %d frames, not the 40 it documents" % total)
	# None of the cut animations may creep back onto a sheet.
	for cut: StringName in CUT_ANIMATIONS:
		for key: String in sets:
			if sets[key] != null and sets[key].has_animation(cut):
				_fail("the %s set still carries %s; the contract is five animations" % [key, cut])
	# `FormData.menu_frames_path` is what `Main` warms behind the boot screen. Shade's menus play a
	# video, so her menu sheet is only the Reduced Motion fallback and must not be warmed: that would
	# hold it for the whole session for nothing.
	var form: FormData = CATALOG.get_form(FORM_ID)
	if form != null and not form.menu_frames_path.is_empty():
		_fail("the form warms %s, but her menus play a video" % form.menu_frames_path)
	var sheet: CharacterPoseSheet = load("res://data/characters/verdant_shade_frames.tres")
	if sheet == null:
		_fail("the generated drift record is missing")
	else:
		for spec: Array in CONTRACT:
			if not bool(spec[3]):
				continue
			var drifts: Array[Vector2] = []
			for frame: int in int(spec[1]):
				drifts.append(sheet.get_residual_drift(StringName("%s_%02d" % [spec[0], frame])))
			var spread: float = 0.0
			for a: Vector2 in drifts:
				for b: Vector2 in drifts:
					spread = maxf(spread, a.distance_to(b))
			if spread > MAX_LOOP_DRIFT:
				_fail("%s wanders %.1f px across its own frames, over the %.0f px budget" % [
					spec[0], spread, MAX_LOOP_DRIFT,
				])
	await process_frame


## Every gameplay state selects its own animation; the dash contact frame is where the pack put it.
func _check_states() -> void:
	var visual: VerdantShadeVisual = _spawn()
	if visual == null:
		return
	await process_frame
	# The dash, the launch into it and the kill accent are one picture; every other state is the
	# character sitting against its wall. Each non-dash state is checked *from* the dash, so a rig
	# that simply stopped changing animation would pass nothing here.
	var expected: Dictionary[StringName, StringName] = {
		PlayableCharacterVisual.DASH_START: &"dash_loop",
		PlayableCharacterVisual.DASH_LOOP: &"dash_loop",
		PlayableCharacterVisual.ATTACK: &"dash_loop",
		PlayableCharacterVisual.MOVE_FLY: &"wall_bottom",
		PlayableCharacterVisual.DASH_END: &"wall_bottom",
		PlayableCharacterVisual.HIT_REACTION: &"wall_bottom",
		PlayableCharacterVisual.VICTORY: &"wall_bottom",
		PlayableCharacterVisual.IDLE_HOVER: &"wall_bottom",
	}
	for state: StringName in expected:
		if expected[state] != &"dash_loop" and not await _settles_on(
				visual, PlayableCharacterVisual.DASH_LOOP, &"dash_loop"):
			_fail("could not park on the dash before asking for %s" % state)
		if not await _settles_on(visual, state, expected[state]):
			_fail("%s showed %s, expected %s" % [
				state, visual.get_current_animation(), expected[state],
			])
	# Death is last: it is an interrupt that refuses every later request except the spawn, so asking
	# for anything else after it would be testing the base's death lock, not this rig.
	for state: StringName in [
		PlayableCharacterVisual.DEATH, PlayableCharacterVisual.REVIVE_SPAWN,
	]:
		if not await _settles_on(visual, state, &"wall_bottom"):
			_fail("%s showed %s, expected the wall it died against" % [
				state, visual.get_current_animation(),
			])
	visual.queue_free()
	await process_frame


## A resting character shows the wall it is on, upright to the player; the right wall is the left
## wall mirrored rather than eight more frames.
func _check_walls() -> void:
	var visual: VerdantShadeVisual = _spawn()
	if visual == null:
		return
	await process_frame
	var walls: Dictionary[Vector2, Array] = {
		Vector2.UP: [&"wall_bottom", false],
		Vector2.DOWN: [&"wall_top", false],
		Vector2.RIGHT: [&"wall_left", false],
		Vector2.LEFT: [&"wall_left", true],
	}
	var body := visual.get_node(^"%Body") as Node2D
	for normal: Vector2 in walls:
		for _frame: int in 120:
			visual.sync_controller(235.0, 1.0, PlayableCharacterVisual.IDLE_HOVER,
				Vector2.ZERO, 0.0, normal, 0.0)
			await process_frame
		if visual.get_current_animation() != walls[normal][0]:
			_fail("on %s the rig showed %s, expected %s" % [
				normal, visual.get_current_animation(), walls[normal][0],
			])
		if visual.is_mirrored() != bool(walls[normal][1]):
			_fail("on %s the rig mirrored=%s, expected %s" % [
				normal, visual.is_mirrored(), walls[normal][1],
			])
		# The wall frames are painted in screen space, so whatever the rig is rotated to stand on
		# the wall must be taken off again: the body ends upright to the player on every surface.
		var upright: float = absf(rad_to_deg(wrapf(body.global_rotation, -PI, PI)))
		if upright > 1.0:
			_fail("on %s the body sits %.1f deg off upright" % [normal, upright])
	visual.queue_free()
	await process_frame


## Holding the aim arrow must not change the character at all.
func _check_aim_is_inert() -> void:
	var visual: VerdantShadeVisual = _spawn()
	if visual == null:
		return
	await process_frame
	if not await _settles_on(visual, PlayableCharacterVisual.DASH_LOOP, &"dash_loop"):
		_fail("could not reach the dash before testing the aim state")
	var before: StringName = visual.get_current_animation()
	visual.request_state(PlayableCharacterVisual.AIM_CHARGE)
	await process_frame
	if visual.get_current_animation() != before:
		_fail("aiming changed the animation from %s to %s" % [
			before, visual.get_current_animation(),
		])
	visual.queue_free()
	await process_frame


## A menu character rests on its menu performance - for Shade, the video - on Home and on a Shop
## card, and keeps resting on it when the card is focused, equipped or bought.
func _check_menu() -> void:
	var visual: VerdantShadeVisual = _spawn(true)
	if visual == null:
		return
	await process_frame
	visual.request_state(PlayableCharacterVisual.IDLE_HOVER)
	await process_frame
	var rest: StringName = WholeFrameCharacterVisual.MENU_VIDEO
	if visual.get_current_animation() != rest:
		_fail("a menu preview rests on %s, expected %s" % [
			visual.get_current_animation(), rest,
		])
	# A menu character rests against nothing: whatever wall it is told about, it still performs.
	for normal: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		visual.sync_controller(235.0, 1.0, PlayableCharacterVisual.IDLE_HOVER,
			Vector2.ZERO, 0.0, normal, 0.0)
		await process_frame
		if visual.get_current_animation() != rest:
			_fail("a menu preview on %s showed the wall animation %s" % [
				normal, visual.get_current_animation(),
			])
	# The storefront reactions were cut with the rest of the set (owner, 2026-09-20). Picking,
	# equipping or buying a card must leave the character breathing rather than performing.
	for state: StringName in [
		PlayableCharacterVisual.CHARACTER_SELECTED,
		PlayableCharacterVisual.CHARACTER_UNLOCKED,
		PlayableCharacterVisual.ATTACK,
	]:
		visual.request_state(state)
		for _frame: int in 30:
			await process_frame
			if visual.get_current_animation() != rest:
				_fail("%s took the card off %s onto %s" % [
					state, rest, visual.get_current_animation(),
				])
				break
	visual.queue_free()
	await process_frame


## The video in a menu: it is Shade's generated clip, drawn through the packed-alpha shader in the
## square the intake placed it in, looping, never taking a tap from the card under it, paused while
## its card is hidden, and swapped for the sprite loop under Reduced Motion.
func _check_menu_video() -> void:
	var visual: VerdantShadeVisual = _spawn(true)
	if visual == null:
		return
	for _frame: int in 20:
		await process_frame
	var player: VideoStreamPlayer = visual.get_menu_video_player()
	if player == null:
		_fail("a menu preview built no video player")
		visual.queue_free()
		return
	if player.stream != MENU_VIDEO.stream:
		_fail("the menu video plays %s, not the generated clip" % player.stream)
	if not player.loop or not player.expand:
		_fail("the menu video must loop and stretch to its square (loop %s, expand %s)" % [
			player.loop, player.expand,
		])
	if player.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("the menu video would swallow taps meant for the card")
	var material := player.material as ShaderMaterial
	if material == null or material.shader != CharacterMenuVideo.PACKED_ALPHA_SHADER:
		_fail("the menu video is not drawn through the packed-alpha shader")
	if not player.size.is_equal_approx(Vector2.ONE * MENU_VIDEO.side):
		_fail("the menu video is %s, the intake placed it at %.1f" % [player.size, MENU_VIDEO.side])
	var centre: Vector2 = player.position + player.size * 0.5
	if centre.distance_to(MENU_VIDEO.offset) > 0.5:
		_fail("the menu video is centred at %s, the intake placed it at %s" % [
			centre, MENU_VIDEO.offset,
		])
	if absf(player.get_stream_length() - MENU_VIDEO.loop_seconds) > 0.1:
		_fail("the clip is %.2f s, the intake cut a %.2f s loop" % [
			player.get_stream_length(), MENU_VIDEO.loop_seconds,
		])
	var sprite := visual.get_node(^"%PoseSprite") as AnimatedSprite2D
	if sprite.visible or sprite.sprite_frames != null:
		_fail("a menu playing the video still shows or holds a sprite frame set")
	# It actually plays, rather than sitting on its first frame.
	var started: float = player.stream_position
	for _frame: int in 20:
		await process_frame
	if not visual.is_menu_video_playing() or player.stream_position <= started:
		_fail("the menu video is not advancing (%.3f -> %.3f s)" % [
			started, player.stream_position,
		])
	# A hidden card (another Shop tab) keeps its character in the tree; its video must stop decoding.
	visual.visible = false
	await process_frame
	if not player.paused:
		_fail("a hidden menu video kept playing")
	visual.visible = true
	await process_frame
	if player.paused:
		_fail("the menu video did not resume when its card came back")
	# Main keeps one Home and detaches it instead of freeing it, and a video player stops itself when
	# it leaves the tree. Coming back to Home must restart the clip (owner bug report, 2026-09-21:
	# "sometimes the animation doesn't go off" - it stood still after every trip to another screen).
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
	# Reduced Motion never plays a video: the sprite loop holds its first frame instead.
	visual.set_reduced_motion(true)
	await process_frame
	if visual.get_menu_video_player() != null:
		_fail("Reduced Motion left the menu video playing")
	if visual.get_current_animation() != visual.menu_idle_animation or not sprite.visible:
		_fail("Reduced Motion showed %s instead of the held %s" % [
			visual.get_current_animation(), visual.menu_idle_animation,
		])
	visual.set_reduced_motion(false)
	await process_frame
	if visual.get_menu_video_player() == null:
		_fail("turning Reduced Motion off did not bring the video back")
	visual.queue_free()
	await process_frame


## The whole point of the two resources: a run never holds the menu sheet and a menu never holds the
## run sheet. A Shop full of whole-frame characters cannot afford both - and a menu that plays a
## video holds no frame set at all.
func _check_frame_set_split() -> void:
	var playing: VerdantShadeVisual = _spawn()
	var menu: VerdantShadeVisual = _spawn(true)
	if playing == null or menu == null:
		return
	await process_frame
	if playing.is_menu_frame_set():
		_fail("a gameplay character loaded the menu frame set")
	if playing.get_menu_video_player() != null:
		_fail("a gameplay character started the menu video")
	var menu_sprite := menu.get_node(^"%PoseSprite") as AnimatedSprite2D
	if menu_sprite.sprite_frames != null:
		_fail("a menu preview playing the video still loaded a frame set")
	# Switching a live rig between the two swaps the video in and out rather than holding both.
	playing.set_preview_mode(true)
	await process_frame
	if playing.get_menu_video_player() == null:
		_fail("switching to preview mode did not start the menu video")
	if (playing.get_node(^"%PoseSprite") as AnimatedSprite2D).sprite_frames != null:
		_fail("switching to preview mode kept the gameplay frame set loaded")
	playing.set_preview_mode(false)
	await process_frame
	if playing.get_menu_video_player() != null:
		_fail("switching back to gameplay left the menu video running")
	if playing.is_menu_frame_set():
		_fail("switching back to gameplay left the menu frame set loaded")
	playing.queue_free()
	menu.queue_free()
	await process_frame


## Reduced Motion holds one readable frame instead of playing, and keeps the wall it picked.
func _check_reduced_motion() -> void:
	var visual: VerdantShadeVisual = _spawn()
	if visual == null:
		return
	await process_frame
	visual.set_reduced_motion(true)
	for _frame: int in 30:
		visual.sync_controller(235.0, 1.0, PlayableCharacterVisual.DASH_LOOP,
			Vector2.ZERO, 0.0, Vector2.UP, 0.0)
		await process_frame
	var sprite := visual.get_node(^"%PoseSprite") as AnimatedSprite2D
	var held: int = sprite.frame
	if sprite.is_playing():
		_fail("reduced motion still plays %s" % visual.get_current_animation())
	for _frame: int in 30:
		await process_frame
	if sprite.frame != held:
		_fail("reduced motion advanced from frame %d to %d" % [held, sprite.frame])
	visual.queue_free()
	await process_frame
