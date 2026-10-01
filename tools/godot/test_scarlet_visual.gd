extends SceneTree
## Scarlet (whole-frame sprite, AutoSprite, 2026-09-26): the pack contract, the one-shot dash
## attack (a fan swing with an airy blue reap, drawn side-on), state and wall mapping, the storefront menu,
## Reduced Motion, and the frame-set split that keeps the Shop affordable.
##
## The animation order, frame counts, rates and loop flags are asserted against the agreed contract
## in [constant CONTRACT], so a regenerated pack that quietly changes a count fails here.
##
##   Godot --headless --path . --script res://tools/godot/test_scarlet_visual.gd

const CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
const FORM_ID: StringName = &"scarlet"
const GAMEPLAY_FRAMES: String = "res://data/characters/scarlet_gameplay.tres"
const MENU_FRAMES: String = "res://data/characters/scarlet_menu.tres"
## The dash frame that lands the reap: the attack flash peaks on it and Reduced Motion holds it.
const CONTACT_FRAME: int = 4
## The approved animation order: name, frame count, **authored** rate and whether it loops. Written out here on
## purpose rather than read back from the pack's manifest — `concept_art/` is `.gdignore`d and, more
## to the point, a generated resource checked against its own generator proves nothing. This is the
## contract both the art pack and `extract_playable_characters.py` have to keep meeting.
const CONTRACT: Array[Array] = [
	[&"dash_loop", 8, 28.0, false],
	[&"wall_bottom", 24, 12.0, true],
	[&"wall_top", 24, 12.0, true],
	[&"wall_left", 25, 12.0, true],
	[&"storefront_idle", 25, 12.0, true],
]
## Every frame the contract promises, summed.
const CONTRACT_FRAMES: int = 106
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
## The storefront's own budget. In the middle of its loop Scarlet waves her big fan (owner, 2026-09-26),
## and the fan is as wide as she is tall, so its swing moves the silhouette's bounds while she stands
## still: measured 26.1 px (frames 12 and 24) on 2026-09-26, against 4.7-5.5 px on the walls.
const STOREFRONT_DRIFT: float = 30.0

var _failures: int = 0


func _initialize() -> void:
	_run()


func _run() -> void:
	await _check_pack_contract()
	await _check_one_shot_dash()
	await _check_states()
	await _check_walls()
	await _check_aim_is_inert()
	await _check_menu()
	await _check_no_menu_video()
	await _check_frame_set_split()
	await _check_reduced_motion()
	if _failures > 0:
		push_error("scarlet_visual: %d failures" % _failures)
		quit(1)
		return
	print("scarlet_visual: pack, one-shot dash, states, walls, menu, split and reduced motion passed")
	quit()


func _fail(message: String) -> void:
	_failures += 1
	push_error("scarlet_visual: %s" % message)


func _spawn(menu: bool = false) -> ScarletVisual:
	var form: FormData = CATALOG.get_form(FORM_ID)
	if form == null or form.visual_scene == null:
		_fail("the catalog has no %s with a visual scene" % FORM_ID)
		return null
	var visual := form.visual_scene.instantiate() as ScarletVisual
	if visual == null:
		_fail("the %s scene is not a ScarletVisual" % FORM_ID)
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
	visual: ScarletVisual, state: StringName, animation: StringName, frames: int = 180
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
		var rate: float = float(spec[2])
		if absf(frames.get_animation_speed(state) - rate) > 0.01:
			_fail("%s plays at %.2f fps, expected %.2f" % [
				state, frames.get_animation_speed(state), rate,
			])
		if frames.get_animation_loop(state) != bool(spec[3]):
			_fail("%s loops %s, the contract says %s" % [
				state, frames.get_animation_loop(state), bool(spec[3]),
			])
		total += expected
	if total != CONTRACT_FRAMES:
		_fail("the pack came to %d frames, not the %d it documents" % [total, CONTRACT_FRAMES])
	# None of the cut animations may creep back onto a sheet.
	for cut: StringName in CUT_ANIMATIONS:
		for key: String in sets:
			if sets[key] != null and sets[key].has_animation(cut):
				_fail("the %s set still carries %s; the contract is five animations" % [key, cut])
	# `FormData.menu_frames_path` is what `Main` warms behind the boot screen. Scarlet's menus play
	# the storefront frames, so they are warmed like Patchvile's.
	var form: FormData = CATALOG.get_form(FORM_ID)
	if form != null and form.menu_frames_path != MENU_FRAMES:
		_fail("the form warms '%s', not the storefront frames" % form.menu_frames_path)
	var sheet: CharacterPoseSheet = load("res://data/characters/scarlet_frames.tres")
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
			var budget: float = STOREFRONT_DRIFT if spec[0] == &"storefront_idle" else MAX_LOOP_DRIFT
			if spread > budget:
				_fail("%s wanders %.1f px across its own frames, over the %.0f px budget" % [
					spec[0], spread, budget,
				])
	await process_frame


## The dash is one attack, not a loop (owner, #40): it plays once from the launch, holds its last
## frame until the landing, restarts on a redirect, and carries the attack look.
func _check_one_shot_dash() -> void:
	var visual: ScarletVisual = _spawn()
	if visual == null:
		return
	var sprite := visual.get_node(^"%PoseSprite") as AnimatedSprite2D
	if not await _settles_on(visual, PlayableCharacterVisual.DASH_LOOP, &"dash_loop"):
		_fail("a dash does not show the dash")
	if sprite.sprite_frames.get_animation_loop(&"dash_loop"):
		_fail("the dash still loops")
	var last: int = sprite.sprite_frames.get_frame_count(&"dash_loop") - 1
	if CONTACT_FRAME > last or visual.attack_contact_frame != CONTACT_FRAME:
		_fail("the contact frame is %d, expected %d of %d" % [
			visual.attack_contact_frame, CONTACT_FRAME, last + 1,
		])
	for _frame: int in 45:
		visual.sync_controller(235.0, 1.0, PlayableCharacterVisual.DASH_LOOP, Vector2.ZERO, 0.0,
			Vector2.UP, 0.0)
		await process_frame
	if sprite.frame != last or sprite.is_playing():
		_fail("the dash did not hold its last frame (frame %d, playing %s)" % [
			sprite.frame, sprite.is_playing(),
		])
	visual.restart_dash()
	await process_frame
	if sprite.frame > 1 or not sprite.is_playing():
		_fail("a redirect did not restart the attack (frame %d)" % sprite.frame)
	if visual.attack_glow.a <= 0.0:
		_fail("the dash attack has no attack look (attack_glow is transparent)")
	# The attack is drawn side-on, flying left; `dash_head_up` mirrors it on rightward flights so it
	# never flies upside down (character guide §6).
	if not visual.dash_head_up:
		_fail("the side-drawn dash does not keep its head up (dash_head_up is off)")
	visual.queue_free()
	await process_frame


## Every gameplay state selects its own animation; the dash contact frame is where the pack put it.
func _check_states() -> void:
	var visual: ScarletVisual = _spawn()
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
	var visual: ScarletVisual = _spawn()
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
	var visual: ScarletVisual = _spawn()
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


## A menu character rests on its storefront loop on Home and on a Shop card, and keeps resting on
## it when the card is focused, equipped or bought.
func _check_menu() -> void:
	var visual: ScarletVisual = _spawn(true)
	if visual == null:
		return
	await process_frame
	visual.request_state(PlayableCharacterVisual.IDLE_HOVER)
	await process_frame
	var rest: StringName = visual.menu_idle_animation
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


## Scarlet has no menu video: a menu preview builds no video player and shows the storefront
## frames.
func _check_no_menu_video() -> void:
	var visual: ScarletVisual = _spawn(true)
	if visual == null:
		return
	for _frame: int in 10:
		await process_frame
	if visual.menu_video != null or visual.get_menu_video_player() != null:
		_fail("a menu preview still plays the menu video")
	var sprite := visual.get_node(^"%PoseSprite") as AnimatedSprite2D
	if not sprite.visible or not visual.is_menu_frame_set():
		_fail("a menu preview does not show the storefront frames")
	visual.queue_free()
	await process_frame


## The whole point of the two resources: a run never holds the menu sheet and a menu never holds the
## run sheet. A Shop full of whole-frame characters cannot afford both.
func _check_frame_set_split() -> void:
	var playing: ScarletVisual = _spawn()
	var menu: ScarletVisual = _spawn(true)
	if playing == null or menu == null:
		return
	await process_frame
	if playing.is_menu_frame_set():
		_fail("a gameplay character loaded the menu frame set")
	if not menu.is_menu_frame_set():
		_fail("a menu preview did not load the menu frame set")
	# Switching a live rig between the two swaps the resource rather than holding both.
	playing.set_preview_mode(true)
	await process_frame
	if not playing.is_menu_frame_set():
		_fail("switching to preview mode did not swap in the menu frame set")
	playing.set_preview_mode(false)
	await process_frame
	if playing.is_menu_frame_set():
		_fail("switching back to gameplay left the menu frame set loaded")
	playing.queue_free()
	menu.queue_free()
	await process_frame


## Reduced Motion holds one readable frame instead of playing, and keeps the wall it picked.
func _check_reduced_motion() -> void:
	var visual: ScarletVisual = _spawn()
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
