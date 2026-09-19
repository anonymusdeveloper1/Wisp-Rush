extends SceneTree
## Playable characters: rig contract, controller-driven states, smoothness, menus and GameWorld.
##
## For every rigged character: the full animation vocabulary, no collision in the rig, a particle
## budget, skinned ribbons whose weights add up, a silhouette that matches `design_size`, the real
## WispPlayer driving every gameplay state, no per-frame snaps, Reduced Motion, the Home hero, the
## Shop's animated CHARACTERS cards (selected and unlock flourishes) and a production GameWorld.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/wisp_player.tscn")
const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const HOME_SCENE: PackedScene = preload("res://scenes/screens/home_screen.tscn")
const SHOP_SCENE: PackedScene = preload("res://scenes/screens/shop_screen.tscn")
const ENDLESS_CATALOG: EndlessCatalog = preload("res://data/endless/default_endless_catalog.tres")
const CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
const RIGGED: Array[StringName] = [&"veyra", &"rook", &"morrow", &"ilyra", &"bram"]
const ARENA := Rect2(140.0, 420.0, 800.0, 1100.0)
## Largest believable change in one 1/60 s frame (scaled by the real frame time); more is a snap.
const MAX_HEADING_STEP: float = 1.45
const MAX_JOINT_STEP: float = 0.6
const MAX_OFFSET_STEP: float = 40.0
## Scale is measured as the length of the (x, y) change: the 3-frame impact squash reaches ~0.23.
const MAX_SCALE_STEP: float = 0.3
const PARTICLE_BUDGET: int = 40

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	Engine.max_fps = 60
	for form_id: StringName in RIGGED:
		var form: FormData = CATALOG.get_form(form_id)
		await _check_rig_contract(form)
		await _check_controller_flow(form)
	await _check_reduced_motion(CATALOG.get_form(&"morrow"))
	await _check_reduced_motion(CATALOG.get_form(&"ilyra"))
	await _check_reduced_motion(CATALOG.get_form(&"bram"))
	await _check_home(CATALOG.get_form(&"rook"))
	await _check_shop()
	for form_id: StringName in RIGGED:
		await _check_game_world(CATALOG.get_form(form_id))
	if _failures == 0:
		print("playable_character_visual: rigs, states, smoothness, menus and GameWorld passed")
	quit(_failures)


func _fail(message: String) -> void:
	_failures += 1
	push_error("playable_character_visual: %s" % message)


func _check_rig_contract(form: FormData) -> void:
	var id: String = form.form_id
	var visual := form.visual_scene.instantiate() as PlayableCharacterVisual
	root.add_child(visual)
	await process_frame
	if visual.get_animation_states() != PlayableCharacterVisual.STATES:
		_fail("%s: animation vocabulary changed" % id)
	for state: StringName in PlayableCharacterVisual.STATES:
		if visual.get_state_length(state) <= 0.0:
			_fail("%s: %s has no animation" % [id, state])
	if (
		not visual.find_children("*", "CollisionShape2D", true, false).is_empty()
		or not visual.find_children("*", "CollisionObject2D", true, false).is_empty()
	):
		_fail("%s: the rig contains collision" % id)
	var particles: int = 0
	for node: Node in visual.find_children("*", "GPUParticles2D", true, false):
		particles += (node as GPUParticles2D).amount
	if particles == 0 or particles > PARTICLE_BUDGET:
		_fail("%s: %d particles is outside the 1..%d budget" % [id, particles, PARTICLE_BUDGET])
	for node: Node in visual.find_children("*", "RibbonChain", true, false):
		_check_ribbon(id, node as RibbonChain)
	# Standing heading follows the wall: floor upright, ceiling inverted, side walls sideways.
	for wall: Array in [
		[Vector2.UP, 0.0], [Vector2.DOWN, PI], [Vector2.RIGHT, PI * 0.5], [Vector2.LEFT, -PI * 0.5],
	]:
		visual.surface_normal = wall[0]
		if absf(angle_difference(visual.get_standing_heading(), wall[1])) > 0.001:
			_fail("%s: standing on a %s wall faces %.2f, expected %.2f" % [
				id, wall[0], visual.get_standing_heading(), wall[1],
			])
	visual.surface_normal = Vector2.UP
	var bounds: Rect2 = visual.get_layer_bounds()
	var largest: float = maxf(bounds.size.x, bounds.size.y)
	if absf(largest / visual.get_design_size() - 1.0) > 0.12:
		_fail("%s: design_size %.0f does not fit its %.0f px silhouette" % [
			id, visual.get_design_size(), largest,
		])
	if bounds.get_center().distance_to(visual.preview_center) > visual.get_design_size() * 0.08:
		_fail("%s: preview_center %s is off the silhouette centre %s" % [
			id, visual.preview_center, bounds.get_center(),
		])
	# Every menu flourish plays and hands back to the idle loop.
	visual.set_preview_mode(true)
	for flourish: StringName in [
		PlayableCharacterVisual.CHARACTER_SELECTED, PlayableCharacterVisual.CHARACTER_UNLOCKED,
	]:
		if flourish == PlayableCharacterVisual.CHARACTER_SELECTED:
			visual.play_character_selected()
		else:
			visual.play_character_unlocked()
		if visual.get_current_visual_state() != flourish:
			_fail("%s: %s did not start" % [id, flourish])
		await create_timer(visual.get_state_length(flourish) + 0.15).timeout
		if visual.get_current_visual_state() != PlayableCharacterVisual.IDLE_HOVER:
			_fail("%s: %s did not return to idle" % [id, flourish])
	visual.queue_free()
	await process_frame


func _check_ribbon(id: String, ribbon: RibbonChain) -> void:
	var mesh: Polygon2D = ribbon.get_mesh()
	var bone_count: int = ribbon.get_bones().size()
	if mesh == null or bone_count < 2 or mesh.get_bone_count() != bone_count:
		_fail("%s: ribbon %s has no skinned bone chain" % [id, ribbon.name])
		return
	var totals := PackedFloat32Array()
	totals.resize(mesh.polygon.size())
	for bone: int in mesh.get_bone_count():
		var weights: PackedFloat32Array = mesh.get_bone_weights(bone)
		if weights.size() != totals.size():
			_fail("%s: ribbon %s weights do not cover every vertex" % [id, ribbon.name])
			return
		for vertex: int in weights.size():
			totals[vertex] += weights[vertex]
	for total: float in totals:
		if absf(total - 1.0) > 0.001:
			_fail("%s: ribbon %s has a vertex weighted %.3f" % [id, ribbon.name, total])
			return


func _check_controller_flow(form: FormData) -> void:
	var id: String = form.form_id
	var player := PLAYER_SCENE.instantiate() as WispPlayer
	root.add_child(player)
	await process_frame
	player.set_arena_rect(ARENA)
	var radius_before: float = player.get_collision_radius()
	player.set_cosmetic_form(form.texture, form.tint, form.visual_scene)
	var visual: PlayableCharacterVisual = player.get_character_visual()
	if visual == null:
		_fail("%s: WispPlayer did not load the rig" % id)
		player.queue_free()
		return
	if visual.get_current_visual_state() != PlayableCharacterVisual.REVIVE_SPAWN:
		_fail("%s: a spawning player did not play revive_spawn" % id)
	var seen: Dictionary[StringName, bool] = {}
	visual.visual_state_changed.connect(func(state: StringName) -> void: seen[state] = true)
	var probe := SmoothnessProbe.new(visual)
	await _frames(probe, 40)
	player.request_dash(Vector2(0.4, -1.0))
	await _frames(probe, 6)
	_expect(id, visual, [
		PlayableCharacterVisual.DASH_START, PlayableCharacterVisual.DASH_LOOP,
	], "dash")
	player.play_attack_visual()
	await _frames(probe, 2)
	_expect(id, visual, [PlayableCharacterVisual.ATTACK], "dash kill")
	await _frames(probe, 45)
	player.request_dash(Vector2(-1.0, -0.35))
	await _frames(probe, 7)
	if not player.redirect_dash(Vector2(-0.2, 1.0)):
		_fail("%s: mid-dash redirect was refused" % id)
	await _frames(probe, 45)
	_expect(id, visual, [PlayableCharacterVisual.IDLE_HOVER], "rest after landing")
	player.request_dash(Vector2.UP)
	await _frames(probe, 40)
	_expect_standing(id, visual, "landing on the ceiling")
	player.request_dash(Vector2.DOWN)
	await _frames(probe, 45)
	_expect_standing(id, visual, "landing on the floor")
	player.take_hazard_damage(Vector2(ARENA.end.x - 60.0, ARENA.get_center().y))
	await _frames(probe, 4)
	_expect(id, visual, [PlayableCharacterVisual.HIT_REACTION], "hazard hit")
	await _frames(probe, 60)
	player.play_victory(0.6)
	await _frames(probe, 12)
	_expect(id, visual, [PlayableCharacterVisual.VICTORY], "boss victory")
	await _frames(probe, 50)
	(player.get_node(^"%HealthComponent") as HealthComponent).apply_damage(99)
	await _frames(probe, 12)
	_expect(id, visual, [PlayableCharacterVisual.DEATH], "death")
	for state: StringName in [
		PlayableCharacterVisual.IDLE_HOVER, PlayableCharacterVisual.DASH_START,
		PlayableCharacterVisual.DASH_LOOP, PlayableCharacterVisual.ATTACK,
		PlayableCharacterVisual.DASH_END, PlayableCharacterVisual.HIT_REACTION,
		PlayableCharacterVisual.VICTORY, PlayableCharacterVisual.DEATH,
	]:
		if not seen.has(state):
			_fail("%s: the controller never reached %s" % [id, state])
	for problem: String in probe.problems:
		_fail("%s: %s" % [id, problem])
	if probe.samples < 300:
		_fail("%s: only %d frames were measured" % [id, probe.samples])
	if not is_equal_approx(radius_before, player.get_collision_radius()):
		_fail("%s: equipping the character changed the collision radius" % id)
	player.queue_free()
	await process_frame


func _check_reduced_motion(form: FormData) -> void:
	var visual := form.visual_scene.instantiate() as PlayableCharacterVisual
	root.add_child(visual)
	await process_frame
	visual.set_reduced_motion(true)
	visual.sync_controller(512.0, 1.0, PlayableCharacterVisual.DASH_LOOP, Vector2.RIGHT, 1.0)
	await process_frame
	var before: Dictionary = _local_poses(visual)
	for _frame: int in 12:
		visual.sync_controller(512.0, 1.0, PlayableCharacterVisual.DASH_LOOP, Vector2.RIGHT, 1.0)
		await process_frame
	if _local_poses(visual) != before:
		_fail("reduced motion still animates %s's parts" % form.form_id)
	for node: Node in visual.find_children("*", "GPUParticles2D", true, false):
		if (node as GPUParticles2D).emitting:
			_fail("reduced motion still emits %s particles" % form.form_id)
	visual.queue_free()
	await process_frame


func _check_home(form: FormData) -> void:
	var home := HOME_SCENE.instantiate() as HomeScreen
	home.setup({
		&"rift_points": 0,
		&"ads_removed": false,
		&"settings": {&"reduced_motion": false},
	}, form)
	root.add_child(home)
	await process_frame
	await process_frame
	var preview := home.get_node(^"%CharacterPreview") as PlayableCharacterPreview
	var portrait := home.get_node(^"%WispPreview") as TextureRect
	if preview == null or not preview.visible or preview.get_visual() == null:
		_fail("Home did not show %s's live rig" % form.form_id)
	if portrait == null or portrait.self_modulate.a > 0.01:
		_fail("Home left the static portrait over %s's rig" % form.form_id)
	home.queue_free()
	await process_frame


func _check_shop() -> void:
	var snapshot: Dictionary = {
		&"rift_points": 0,
		&"owned_forms": ["void", "veyra"],
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
	if (shop.get_node(^"%WispsTab") as Button).text != "CHARACTERS":
		_fail("the Shop's first tab is not labelled CHARACTERS")
	for form: FormData in CATALOG.load_forms():
		var preview: PlayableCharacterPreview = _card_preview(shop, form.form_id)
		if preview == null or preview.get_visual() == null:
			_fail("Shop card %s is not animated" % form.form_id)
	# Main re-reads the save after a purchase: the bought character celebrates.
	var bought: Dictionary = snapshot.duplicate(true)
	bought[&"owned_forms"] = ["void", "veyra", "rook"]
	bought[&"equipped_form"] = "rook"
	shop.setup(bought, ShopScreen.TAB_WISPS)
	await process_frame
	await process_frame
	var rook: PlayableCharacterPreview = _card_preview(shop, &"rook")
	var rook_state: StringName = &""
	if rook != null:
		rook_state = rook.get_visual().get_current_visual_state()
	if rook_state != PlayableCharacterVisual.CHARACTER_UNLOCKED:
		_fail("buying Rook did not play his unlock flourish")
	# ...and an equip plays the selected flourish.
	var equipped: Dictionary = bought.duplicate(true)
	equipped[&"equipped_form"] = "veyra"
	shop.setup(equipped, ShopScreen.TAB_WISPS)
	await process_frame
	await process_frame
	var veyra: PlayableCharacterPreview = _card_preview(shop, &"veyra")
	var veyra_state: StringName = &""
	if veyra != null:
		veyra_state = veyra.get_visual().get_current_visual_state()
	if veyra_state != PlayableCharacterVisual.CHARACTER_SELECTED:
		_fail("equipping Veyra did not play her selected flourish")
	shop.queue_free()
	await process_frame


func _check_game_world(form: FormData) -> void:
	var skin: ArenaSkinData = ENDLESS_CATALOG.get_skin(ENDLESS_CATALOG.default_skin_id)
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.auto_pause_on_focus_loss = false
	game.configure_run(RunProfile.tutorial(ENDLESS_CATALOG, skin, form))
	root.add_child(game)
	await create_timer(0.6).timeout
	var player := game.get_node(^"WorldContent/PlayerLayer/WispPlayer") as WispPlayer
	if player == null or player.get_character_visual() == null:
		_fail("GameWorld did not load %s's rig" % form.form_id)
	else:
		var circle := (player.get_node(^"%CollisionShape") as CollisionShape2D).shape as CircleShape2D
		if circle == null or not is_equal_approx(player.get_collision_radius(), circle.radius):
			_fail("GameWorld collider disagrees with the controller for %s" % form.form_id)
		var visual: PlayableCharacterVisual = player.get_character_visual()
		if not visual.get_scene_file_path() == form.visual_scene.resource_path:
			_fail("GameWorld loaded the wrong rig for %s" % form.form_id)
	game.queue_free()
	await process_frame


func _frames(probe: SmoothnessProbe, count: int) -> void:
	for _frame: int in count:
		await process_frame
		probe.sample(root.get_process_delta_time())


## After a landing the character stands on that wall: its up axis is the wall's inward normal.
func _expect_standing(id: String, visual: PlayableCharacterVisual, moment: String) -> void:
	var off: float = absf(angle_difference(visual.rotation, visual.get_standing_heading()))
	if off > 0.3:
		_fail("%s: %s left the body %.2f rad off the wall" % [id, moment, off])


func _expect(id: String, visual: PlayableCharacterVisual, states: Array, moment: String) -> void:
	if visual.get_current_visual_state() not in states:
		_fail("%s: after %s the rig shows %s, expected %s" % [
			id, moment, visual.get_current_visual_state(), states,
		])


func _card_preview(shop: ShopScreen, form_id: StringName) -> PlayableCharacterPreview:
	var card: Node = shop.find_child("Card_%s" % form_id, true, false)
	if card == null:
		return null
	return card.find_child("Portrait", true, false) as PlayableCharacterPreview


## Local transforms of every rig part, for the Reduced Motion stillness check.
func _local_poses(visual: PlayableCharacterVisual) -> Dictionary:
	var poses: Dictionary = {}
	for node: Node in visual.get_node(^"MotionRoot").find_children("*", "Node2D", true, false):
		poses[visual.get_path_to(node)] = (node as Node2D).transform
	return poses


## Measures every rig part frame by frame and records changes too large for one frame.
class SmoothnessProbe:
	var problems: PackedStringArray = PackedStringArray()
	var samples: int = 0
	var _visual: PlayableCharacterVisual
	var _parts: Array[Node2D] = []
	var _previous: Array[Transform2D] = []
	var _previous_heading: float = 0.0

	func _init(visual: PlayableCharacterVisual) -> void:
		_visual = visual
		var motion_root := visual.get_node(^"MotionRoot") as Node2D
		_parts.append(motion_root)
		for node: Node in motion_root.find_children("*", "Node2D", true, false):
			if not node is GPUParticles2D:
				_parts.append(node as Node2D)
		for part: Node2D in _parts:
			_previous.append(part.transform)
		_previous_heading = visual.rotation

	func sample(delta: float) -> void:
		if not is_instance_valid(_visual) or delta <= 0.0 or delta > 1.0 / 30.0:
			_capture()
			return
		samples += 1
		var frames: float = maxf(1.0, delta * 60.0)
		var turn: float = absf(angle_difference(_previous_heading, _visual.rotation))
		if turn > MAX_HEADING_STEP * frames:
			problems.append("heading jumped %.2f rad in one frame" % turn)
		for index: int in _parts.size():
			var part: Node2D = _parts[index]
			var before: Transform2D = _previous[index]
			var now: Transform2D = part.transform
			var spin: float = absf(angle_difference(before.get_rotation(), now.get_rotation()))
			var moved: float = before.origin.distance_to(now.origin)
			var stretched: float = (before.get_scale() - now.get_scale()).abs().length()
			if spin > MAX_JOINT_STEP * frames and problems.size() < 12:
				problems.append("%s snapped %.2f rad" % [_visual.get_path_to(part), spin])
			if moved > MAX_OFFSET_STEP * frames and problems.size() < 12:
				problems.append("%s jumped %.1f px" % [_visual.get_path_to(part), moved])
			if stretched > MAX_SCALE_STEP * frames and problems.size() < 12:
				problems.append("%s scale jumped %.2f" % [_visual.get_path_to(part), stretched])
		_capture()

	func _capture() -> void:
		if not is_instance_valid(_visual):
			return
		for index: int in _parts.size():
			_previous[index] = _parts[index].transform
		_previous_heading = _visual.rotation
