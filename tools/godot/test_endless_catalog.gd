extends SceneTree
## Endless catalog (ADR-0014, spec story_and_endless/05): 30 skins in manifest order, the frozen floor
## template, backgrounds, tier prices, arena of the day, animated scenery (masks, keep-out, particles,
## Reduced Motion) and skin saves.

const CATALOG: EndlessCatalog = preload("res://data/endless/default_endless_catalog.tres")
const MANIFEST_PATH: String = "res://concept_art/wisp_rush_endless_v1/assets/skins_manifest.json"
const TEMPLATE_PATH: String = "res://concept_art/wisp_rush_endless_v1/floor_template.json"
const EXPECTED_SKIN_COUNT: int = 30
const DEFAULT_SKIN_ID: StringName = &"astral_observatory"
## Owner decision 2026-09-15: price per tier, with the first three skins keeping their launch prices.
const TIER_PRICES: Dictionary[int, int] = {
	ArenaSkinData.Tier.SIMPLE: 300,
	ArenaSkinData.Tier.RARE: 800,
	ArenaSkinData.Tier.LEGENDARY: 2000,
	ArenaSkinData.Tier.MYTHIC: 3500,
}
const PRICE_OVERRIDES: Dictionary[StringName, int] = {
	&"astral_observatory": 0,
	&"drowned_sanctum": 800,
	&"moonpetal_shrine": 1200,
}
## Legendary scenery stays calm (sparse particles); Mythic scenery is richer.
const LEGENDARY_MAX_PARTICLES: int = 20
const MYTHIC_MIN_EMITTERS: int = 2
const MYTHIC_MIN_LIT_ZONES: int = 3
const MASK_DIR: String = "res://assets/art/environment/endless/masks/"

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run_checks")


func _run_checks() -> void:
	for failure: String in CATALOG.validate():
		_fail(failure)
	_check_skins_against_manifest()
	_check_template()
	_check_arena_of_the_day()
	_check_ambience()
	_check_rules()
	_check_saves()
	if _failures == 0:
		print("endless_catalog: 30 skins, template, backgrounds, prices, daily arena, scenery and saves validated")
	quit(_failures)


func _check_skins_against_manifest() -> void:
	var manifest: Array = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH)) as Array
	if CATALOG.skins.size() != EXPECTED_SKIN_COUNT or manifest.size() != EXPECTED_SKIN_COUNT:
		_fail("expected %d skins, catalog has %d, manifest %d" % [
			EXPECTED_SKIN_COUNT, CATALOG.skins.size(), manifest.size(),
		])
		return
	if CATALOG.default_skin_id != DEFAULT_SKIN_ID:
		_fail("default skin is %s" % CATALOG.default_skin_id)
	var tier_names: PackedStringArray = ["Simple", "Rare", "Legendary", "Mythic"]
	for index: int in EXPECTED_SKIN_COUNT:
		var skin: ArenaSkinData = CATALOG.skins[index]
		var entry: Dictionary = manifest[index] as Dictionary
		if String(skin.skin_id) != str(entry["skin_id"]):
			_fail("slot %d is %s, manifest %s" % [index, skin.skin_id, entry["skin_id"]])
			continue
		if tier_names[skin.tier] != str(entry["tier"]):
			_fail("%s tier %s, manifest %s" % [skin.skin_id, tier_names[skin.tier], entry["tier"]])
		if skin.display_name != str(entry["display_name"]).to_upper():
			_fail("%s display name %s" % [skin.skin_id, skin.display_name])
		var expected_price: int = PRICE_OVERRIDES.get(skin.skin_id, TIER_PRICES[skin.tier])
		if skin.price != expected_price:
			_fail("%s costs %d, expected %d" % [skin.skin_id, skin.price, expected_price])
		if skin.placeholder:
			_fail("%s is a placeholder" % skin.skin_id)
		var background: Texture2D = skin.load_background()
		if background == null or Vector2i(background.get_size()) != EndlessCatalog.BACKGROUND_SIZE:
			_fail("%s background is not 941x1672" % skin.skin_id)
		if skin.thumbnail == null or skin.thumbnail.get_width() > 400:
			_fail("%s needs a small Shop thumbnail" % skin.skin_id)
	if CATALOG.get_skin(DEFAULT_SKIN_ID).price != 0:
		_fail("default skin is not free")
	var save_ids: Array[String] = []
	for skin: ArenaSkinData in CATALOG.skins:
		save_ids.append(String(skin.skin_id))
	if save_ids != SaveManagerService.VALID_ARENA_SKIN_IDS:
		_fail("SaveManagerService.VALID_ARENA_SKIN_IDS does not match the catalog")


func _check_template() -> void:
	var template: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TEMPLATE_PATH)) as Dictionary
	var points: Array = template["polygon_uv"] as Array
	if points.size() != CATALOG.floor_polygon.size():
		_fail("floor polygon has %d points, template %d" % [CATALOG.floor_polygon.size(), points.size()])
		return
	for index: int in points.size():
		var pair: Array = points[index] as Array
		var delta: Vector2 = (CATALOG.floor_polygon[index] - Vector2(float(pair[0]), float(pair[1]))).abs()
		if delta.x > 1e-4 or delta.y > 1e-4:
			_fail("floor polygon point %d differs from the template" % index)
	if not is_equal_approx(float(template["rim_tolerance_px"]), EndlessCatalog.RIM_TOLERANCE_PX):
		_fail("RIM_TOLERANCE_PX differs from the template's rim_tolerance_px")


func _check_arena_of_the_day() -> void:
	var seen: Dictionary[StringName, bool] = {}
	var day: int = int(Time.get_unix_time_from_datetime_string("2026-01-01T00:00:00"))
	for offset: int in 365:
		var date_key: String = Time.get_date_string_from_unix_time(day + offset * 86400)
		var skin: ArenaSkinData = CATALOG.get_arena_of_the_day(date_key)
		if skin == null or not CATALOG.skins.has(skin) or skin.placeholder:
			_fail("arena of the day for %s is not a real catalog skin" % date_key)
			return
		if CATALOG.get_arena_of_the_day(date_key) != skin:
			_fail("arena of the day for %s is not deterministic" % date_key)
		seen[skin.skin_id] = true
	# A year of dailies should visit most of the catalog, not a handful of skins.
	if seen.size() < 20:
		_fail("a year of dailies shows only %d skins" % seen.size())


func _check_ambience() -> void:
	for skin: ArenaSkinData in CATALOG.skins:
		var scenery: ArenaSceneryData = skin.scenery
		if skin.tier < ArenaSkinData.Tier.LEGENDARY:
			if scenery != null:
				_fail("%s is %s but has animated scenery" % [skin.skin_id, skin.get_tier_name()])
			continue
		if scenery == null or scenery.mask == null:
			_fail("%s (%s) has no scenery mask" % [skin.skin_id, skin.get_tier_name()])
			continue
		_check_source_mask(skin.skin_id)
		var particles: int = 0
		for emitter: ArenaParticleEmitter in scenery.emitters:
			particles += emitter.amount
		var lit_zones: int = 0
		for zone: ArenaSceneryZone in scenery.zones:
			if zone.has_light():
				lit_zones += 1
		if skin.tier == ArenaSkinData.Tier.LEGENDARY:
			if particles > LEGENDARY_MAX_PARTICLES:
				_fail("%s (Legendary) has %d particles, calm means at most %d" % [
					skin.skin_id, particles, LEGENDARY_MAX_PARTICLES,
				])
		elif scenery.emitters.size() < MYTHIC_MIN_EMITTERS or lit_zones < MYTHIC_MIN_LIT_ZONES:
			_fail("%s (Mythic) has %d emitters and %d lit zones" % [
				skin.skin_id, scenery.emitters.size(), lit_zones,
			])
		for failure: String in CATALOG.validate_scenery(scenery, true):
			_fail("%s: %s" % [skin.skin_id, failure])
	# The keep-out checks themselves must reject the floor and accept the corner scenery.
	if CATALOG.is_region_clear_of_floor(Rect2(0.4, 0.4, 0.1, 0.1)):
		_fail("keep-out accepts a region in the middle of the floor")
	if CATALOG.is_region_clear_of_floor(Rect2(0.3, 0.2, 0.2, 0.04)):
		_fail("keep-out accepts a region inside the rim tolerance")
	if not CATALOG.is_region_clear_of_floor(Rect2(0.0, 0.0, 1.0, 0.2)):
		_fail("keep-out rejects the top scenery band")
	if CATALOG.is_point_clear_of_floor(Vector2(470.0, 800.0)):
		_fail("keep-out accepts a point on the floor")
	var drifting := ArenaParticleEmitter.new()
	drifting.emitter_name = "into the floor"
	drifting.points_uv = PackedVector2Array([Vector2(0.5, 0.2)])
	drifting.direction = Vector2.DOWN
	drifting.speed_px = Vector2(40.0, 60.0)
	drifting.lifetime = 5.0
	var probe := ArenaSceneryData.new()
	probe.emitters.append(drifting)
	if CATALOG.validate_scenery(probe, false).is_empty():
		_fail("validate_scenery accepts particles that drift onto the floor")

	# Runtime layer: material on the background, particles, Reduced Motion, cleanup, Shop material.
	var mythic: ArenaSkinData = CATALOG.get_skin(&"aurora_throne")
	var background := TextureRect.new()
	root.add_child(background)
	var ambience := ArenaAmbience.new()
	root.add_child(ambience)
	ambience.size = Vector2(1080.0, 2400.0)
	ambience.configure(mythic.scenery, background)
	var material := background.material as ShaderMaterial
	if material == null or material != ambience.get_scenery_material():
		_fail("scenery material is not on the background")
	if ambience.get_particles().size() != mythic.scenery.emitters.size():
		_fail("expected %d particle streams, got %d" % [
			mythic.scenery.emitters.size(), ambience.get_particles().size(),
		])
	if not ambience.is_animating() or material == null or float(material.get_shader_parameter(&"motion")) != 1.0:
		_fail("Mythic scenery is not animating")
	ambience.set_active(false)
	var hidden: bool = true
	for particles: CPUParticles2D in ambience.get_particles():
		hidden = hidden and not particles.visible and not particles.emitting
	if ambience.is_animating() or not hidden or float(material.get_shader_parameter(&"motion")) != 0.0:
		_fail("Reduced Motion does not still the scenery (motion, particles)")
	ambience.configure(null, background)
	if background.material != null or not ambience.get_particles().is_empty():
		_fail("clearing the scenery leaves its material or particles behind")
	var thumbnail_material: ShaderMaterial = ArenaAmbience.create_material(mythic.scenery)
	if float(thumbnail_material.get_shader_parameter(&"motion")) != 0.0 \
			or thumbnail_material.get_shader_parameter(&"scenery_mask") != mythic.scenery.mask:
		_fail("Shop scenery material is not the static grade + glow")
	ambience.queue_free()
	background.queue_free()


## The generated mask PNG (before lossy import): exact zeros on the floor, full scenery weight in the
## far scenery, and alpha zone ids on the encoding grid.
func _check_source_mask(skin_id: StringName) -> void:
	var path: String = ProjectSettings.globalize_path(MASK_DIR + String(skin_id) + ".png")
	var image := Image.load_from_file(path)
	if image == null or image.get_size() != ArenaSceneryData.MASK_SIZE:
		_fail("%s mask PNG is missing or not %s" % [skin_id, ArenaSceneryData.MASK_SIZE])
		return
	var floor_px := PackedVector2Array()
	var mask_scale := Vector2(ArenaSceneryData.MASK_SIZE)
	for point: Vector2 in CATALOG.floor_polygon:
		floor_px.append(point * mask_scale)
	var inner: Array[PackedVector2Array] = Geometry2D.offset_polygon(floor_px, -2.0)
	for y: int in range(0, image.get_height(), 4):
		for x: int in range(0, image.get_width(), 4):
			var value: Color = image.get_pixel(x, y)
			if (int(round((1.0 - value.a) * 255.0)) % ArenaSceneryData.ZONE_ALPHA_STEP) != 0:
				_fail("%s mask alpha %s at (%d, %d) is not a zone id" % [skin_id, value.a, x, y])
				return
			if inner.is_empty() or not Geometry2D.is_point_in_polygon(Vector2(x, y) + Vector2(0.5, 0.5), inner[0]):
				continue
			if value.r > 0.0 or value.g > 0.0 or value.b > 0.0:
				_fail("%s mask is not zero on the floor at (%d, %d): %s" % [skin_id, x, y, value])
				return
	if image.get_pixel(image.get_width() / 2, 4).b < 0.99:
		_fail("%s mask has no full scenery weight in the top scenery" % skin_id)


func _check_rules() -> void:
	var skin: ArenaSkinData = CATALOG.get_skin(&"eclipse_sanctum")
	var no_rifts: Array[RiftData] = []
	var no_bosses: Array[StringName] = []
	var rules := EndlessArenaRules.new(CATALOG, skin, no_rifts, no_bosses)
	if rules.get_scenery() != skin.scenery:
		_fail("EndlessArenaRules does not pass the skin's scenery")
	if rules.get_floor_polygon() != CATALOG.floor_polygon:
		_fail("a skin changed the floor polygon")
	if rules.get_background() == null:
		_fail("EndlessArenaRules does not load the background")
	if ArenaRules.new().get_scenery() != null:
		_fail("story arenas must have no animated scenery")


func _check_saves() -> void:
	var test_root: String = "user://test_runs/endless_catalog_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(test_root)
	var save_path: String = test_root + "/save.json"
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"schema_version": SaveManagerService.SCHEMA_VERSION,
		"owned_arena_skins": ["placeholder_void_slate", "aurora_throne", "not_a_skin"],
		"equipped_arena_skin": "placeholder_void_slate",
	}))
	file.close()
	var manager := SaveManagerService.new()
	manager.configure_storage_paths(save_path, test_root + "/save.tmp.json", test_root + "/save.backup.json")
	root.add_child(manager)
	manager.reload()
	var snapshot: Dictionary = manager.get_snapshot()
	var owned: Array = snapshot[&"owned_arena_skins"] as Array
	if (
		String(DEFAULT_SKIN_ID) not in owned
		or "aurora_throne" not in owned
		or "not_a_skin" in owned
		or "placeholder_void_slate" in owned
		or snapshot[&"equipped_arena_skin"] != String(DEFAULT_SKIN_ID)
	):
		_fail("save sanitizing kept a retired or unknown skin: %s / %s" % [
			owned, snapshot[&"equipped_arena_skin"],
		])
	manager.add_rift_points(3500)
	var kind: StringName = SaveManagerService.KIND_ARENA_SKIN
	if not manager.purchase_cosmetic(kind, &"dragon_skull_throne", 3500, true):
		_fail("could not buy the last Mythic skin")
	if manager.get_snapshot()[&"equipped_arena_skin"] != "dragon_skull_throne":
		_fail("buying a skin did not equip it")
	if not manager.equip_cosmetic(kind, &"aurora_throne") or manager.equip_cosmetic(kind, &"titans_palm"):
		_fail("equip accepted an unowned skin or refused an owned one")
	manager.queue_free()


func _fail(message: String) -> void:
	_failures += 1
	push_error("endless_catalog: %s" % message)
