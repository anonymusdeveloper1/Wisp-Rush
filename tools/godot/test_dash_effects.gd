extends SceneTree
## Per-character dash signatures: the data, where the pool sits, and what a real dash draws.
##
## The point of this file is that the feature cannot ship inert. Every character must carry a
## [DashEffectData], every tint must clear the reserved hues, and a dash driven through the real
## controller must leave a ribbon in that character's colour — not the white a [Line2D] falls back
## to when its gradient is set and `default_color` is not.
##
##     Godot --headless --path . --script res://tools/godot/test_dash_effects.gd

const CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const ENDLESS_CATALOG: EndlessCatalog = preload("res://data/endless/default_endless_catalog.tres")
## Signatures that lay two ribbons, one per hand.
const TWIN_SIGNATURES: Array[int] = [DashEffectData.Signature.TWIN_ARC]

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	Engine.max_fps = 60
	_check_every_character_has_one()
	await _check_pool_placement()
	await _check_a_real_dash_draws_its_colour()
	await _check_redirect_draws_every_leg()
	await _check_reduced_motion()
	if _failures == 0:
		print("dash_effects: data, placement, colour, redirect legs and Reduced Motion passed")
	quit(_failures)


func _fail(message: String) -> void:
	_failures += 1
	push_error("dash_effects: %s" % message)


## Not one character may be left without a signature: a null effect is silently the old behaviour,
## which is exactly how this feature would ship looking finished and doing nothing.
func _check_every_character_has_one() -> void:
	var seen: Dictionary[StringName, bool] = {}
	for form: FormData in CATALOG.load_forms():
		var effect: DashEffectData = form.dash_effect
		if effect == null:
			_fail("%s has no dash effect" % form.form_id)
			continue
		if effect.effect_id != form.form_id:
			_fail("%s carries the dash effect %s" % [form.form_id, effect.effect_id])
		if seen.has(effect.effect_id):
			_fail("dash effect %s is shared by two characters" % effect.effect_id)
		seen[effect.effect_id] = true
		for failure: String in effect.validate():
			_fail("%s: %s" % [form.form_id, failure])
		if effect.spark_count > DashEffectData.MAX_SPARKS:
			_fail("%s asks for %d sparks" % [form.form_id, effect.spark_count])
	if seen.size() != FormCatalog.REQUIRED_FORM_COUNT:
		_fail("%d characters have a dash effect, expected %d" % [
			seen.size(), FormCatalog.REQUIRED_FORM_COUNT,
		])


## The pool is persistent, so it belongs beside EffectsLayer, not inside it — code elsewhere counts
## EffectsLayer's children. It also has to sit at the VFX pool's absolute depth rather than over it.
func _check_pool_placement() -> void:
	var game: GameWorld = await _open_run(CATALOG.get_form(&"morrow"))
	if game == null:
		return
	var effects := game.get_node(^"WorldContent/EffectsLayer") as Node2D
	var pool: DashEffectFx = game.get_dash_effect_fx()
	if pool == null:
		_fail("GameWorld built no dash effect pool")
		game.queue_free()
		await process_frame
		return
	if effects.is_ancestor_of(pool):
		_fail("the dash effect pool sits inside EffectsLayer")
	if pool.get_parent() != effects.get_parent():
		_fail("the dash effect pool is not a sibling of EffectsLayer")
	if pool.z_as_relative or pool.z_index != 0:
		_fail("the pool draws at relative z %d, expected absolute 0" % pool.z_index)
	# One shared additive material across every ribbon and emitter keeps 2D batching intact.
	var materials: Array[Material] = []
	for node: Node in pool.get_children():
		var item := node as CanvasItem
		if item != null and item.material != null and item.material not in materials:
			materials.append(item.material)
	if materials.size() != 1:
		_fail("the pool uses %d materials, expected the one shared additive" % materials.size())
	elif materials[0] != VfxPool.get_additive_material():
		_fail("the pool does not share VfxPool's additive material")
	game.queue_free()
	await process_frame


## A dash through the real controller leaves a ribbon, and it is the character's colour.
func _check_a_real_dash_draws_its_colour() -> void:
	for form_id: StringName in [&"morrow", &"ilyra", &"void"]:
		var form: FormData = CATALOG.get_form(form_id)
		var game: GameWorld = await _open_run(form)
		if game == null:
			return
		var player := game.get_node(^"WorldContent/PlayerLayer/WispPlayer") as WispPlayer
		var radius_before: float = player.get_collision_radius()
		var pool: DashEffectFx = game.get_dash_effect_fx()
		player.request_dash(Vector2.UP)
		# A ribbon lives for a third of a second, so it is caught while it is lit rather than
		# sampled after the dash has landed and it has already faded out.
		var lit: Array[Line2D] = await _catch_ribbons(pool, 90)
		if lit.is_empty():
			_fail("%s's dash left no ribbon" % form_id)
		else:
			var wanted: Color = form.dash_effect.trail_tint
			for ribbon: Line2D in lit:
				var drawn := Color(ribbon.modulate.r, ribbon.modulate.g, ribbon.modulate.b)
				if not drawn.is_equal_approx(Color(wanted.r, wanted.g, wanted.b)):
					_fail("%s's ribbon is %s, expected %s" % [
						form_id, drawn.to_html(false), wanted.to_html(false),
					])
					break
			if form.dash_effect.signature in TWIN_SIGNATURES and lit.size() < 2:
				_fail("%s cuts with two fans but drew %d ribbon(s)" % [form_id, lit.size()])
			if form.dash_effect.signature not in TWIN_SIGNATURES and lit.size() > 1:
				_fail("%s drew %d ribbons for one leg" % [form_id, lit.size()])
		# Cosmetic only: equipping a signature may not move the footprint (GDD §9).
		if not is_equal_approx(radius_before, player.get_collision_radius()):
			_fail("%s's dash effect changed the collision radius" % form_id)
		game.queue_free()
		await process_frame


## A redirect ends a leg without ever touching a wall. Each leg still gets its own ribbon.
func _check_redirect_draws_every_leg() -> void:
	var game: GameWorld = await _open_run(CATALOG.get_form(&"eclipse"))
	if game == null:
		return
	var player := game.get_node(^"WorldContent/PlayerLayer/WispPlayer") as WispPlayer
	var pool: DashEffectFx = game.get_dash_effect_fx()
	player.request_dash(Vector2.UP)
	for _frame: int in 8:
		await process_frame
	if not player.redirect_dash(Vector2.RIGHT):
		_fail("the mid-dash redirect was refused, so the leg check never ran")
	else:
		# One ribbon for the leg the redirect ended, before the second leg has landed anywhere.
		await process_frame
		if _lit_ribbons(pool).is_empty():
			_fail("a redirected leg left no ribbon")
	for _frame: int in 70:
		await process_frame
	game.queue_free()
	await process_frame


## Reduced Motion keeps the streak readable but throws no sparks.
func _check_reduced_motion() -> void:
	var game: GameWorld = await _open_run(CATALOG.get_form(&"rook"), true)
	if game == null:
		return
	var player := game.get_node(^"WorldContent/PlayerLayer/WispPlayer") as WispPlayer
	var pool: DashEffectFx = game.get_dash_effect_fx()
	player.request_dash(Vector2.UP)
	var sparked: bool = false
	var lit: Array[Line2D] = []
	for _frame: int in 90:
		await process_frame
		for emitter: CPUParticles2D in pool.get_emitters():
			sparked = sparked or emitter.emitting
		if lit.is_empty():
			lit = _lit_ribbons(pool)
	if sparked:
		_fail("reduced motion still throws dash sparks")
	if lit.is_empty():
		_fail("reduced motion left no ribbon at all; it should still read, only calmer")
	game.queue_free()
	await process_frame


## Runs up to [param frames] frames and returns the ribbons the first lit frame showed.
func _catch_ribbons(pool: DashEffectFx, frames: int) -> Array[Line2D]:
	for _frame: int in frames:
		await process_frame
		var lit: Array[Line2D] = _lit_ribbons(pool)
		if not lit.is_empty():
			return lit
	return []


func _lit_ribbons(pool: DashEffectFx) -> Array[Line2D]:
	var lit: Array[Line2D] = []
	for ribbon: Line2D in pool.get_ribbons():
		if ribbon.visible and ribbon.points.size() > 1:
			lit.append(ribbon)
	return lit


func _open_run(form: FormData, reduced_motion: bool = false) -> GameWorld:
	var skin: ArenaSkinData = ENDLESS_CATALOG.get_skin(ENDLESS_CATALOG.default_skin_id)
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.auto_pause_on_focus_loss = false
	game.configure_run(RunProfile.tutorial(ENDLESS_CATALOG, skin, form))
	root.add_child(game)
	await create_timer(0.6).timeout
	if reduced_motion:
		# The same private hook the pause menu’s settings overlay drives.
		game._apply_feel_settings({&"reduced_motion": true})
	game.debug_quiet_arena()
	if game.get_node_or_null(^"WorldContent/PlayerLayer/WispPlayer") == null:
		_fail("GameWorld did not build a player for %s" % form.form_id)
		game.queue_free()
		await process_frame
		return null
	return game
