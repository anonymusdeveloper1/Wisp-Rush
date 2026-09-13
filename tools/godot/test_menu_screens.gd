extends SceneTree
## Home, Rift Map and Forms after the carousel redesign: navigation signals, the Rift caption, hero
## motion and Reduced Motion on Home; lock gating, selection and ENTER on the Rift Map; carousel-driven
## selection and the tap-to-act shortcut on Forms.

const HOME_SCENE: PackedScene = preload("res://scenes/screens/home_screen.tscn")
const RIFT_MAP_SCENE: PackedScene = preload("res://scenes/screens/rift_map_screen.tscn")
const FORMS_SCENE: PackedScene = preload("res://scenes/screens/forms_screen.tscn")
const FORM_CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _fail(message: String) -> void:
	_failures += 1
	push_error("menu_screens: %s" % message)


func _run() -> void:
	await _check_home()
	await _check_home_reduced_motion()
	await _check_rift_map()
	await _check_forms()
	if _failures == 0:
		print("menu_screens: home nav + motion, rift map gating + enter, forms carousel OK")
	quit(_failures)


func _home_snapshot(reduced_motion: bool) -> Dictionary:
	return {
		&"best_score": 12480,
		&"soul_shards": 320,
		&"selected_rift": "ember_hollow",
		&"rift_levels": {"ember_hollow": 3},
		&"settings": {&"reduced_motion": reduced_motion},
	}


func _check_home() -> void:
	var home := HOME_SCENE.instantiate() as HomeScreen
	home.setup(_home_snapshot(false), FORM_CATALOG.get_form(&"frost"))
	root.add_child(home)
	for frame: int in 3:
		await process_frame

	var caption: String = home.get_rift_caption()
	if "EMBER HOLLOW" not in caption or "LEVEL 4" not in caption:
		_fail("rift caption should name Ember Hollow at level 4, got '%s'" % caption)

	var emitted: Array[StringName] = []
	var expectations: Dictionary = {
		"%RiftsNav": &"rift_map_requested",
		"%FormsNav": &"forms_requested",
		"%SanctumNav": &"sanctum_requested",
		"%TrialsNav": &"trials_requested",
		"%DailyNav": &"daily_requested",
		"%PlayButton": &"play_requested",
		"%StatsButton": &"statistics_requested",
		"%SettingsButton": &"settings_requested",
	}
	for signal_name: StringName in expectations.values():
		home.connect(signal_name, func() -> void: emitted.append(signal_name))
	for path: String in expectations:
		emitted.clear()
		(home.get_node(path) as Button).pressed.emit()
		if emitted != [expectations[path]]:
			_fail("%s emitted %s, expected [%s]" % [path, emitted, expectations[path]])

	if not home.is_animating():
		_fail("home should animate with Reduced Motion off")
	var preview := home.get_node("%WispPreview") as Control
	var hero_area := home.get_node("%HeroArea") as Control
	var start: Vector2 = preview.position
	var moved: bool = false
	for frame: int in 30:
		await process_frame
		if not preview.position.is_equal_approx(start):
			moved = true
		var centre: Vector2 = preview.get_global_rect().get_center()
		if not hero_area.get_global_rect().grow(2.0).has_point(centre):
			_fail("hero Wisp centre %s left the hero area %s" % [centre, hero_area.get_global_rect()])
			break
	if not moved:
		_fail("hero Wisp did not move while animating")
	for orbit: OrbitMotes in home.get_orbits():
		if not orbit.visible or orbit.get_spark_count() <= 0:
			_fail("orbit %s should be visible with sparks" % orbit.name)
	home.queue_free()
	await process_frame


func _check_home_reduced_motion() -> void:
	var home := HOME_SCENE.instantiate() as HomeScreen
	home.setup(_home_snapshot(true), FORM_CATALOG.get_form(&"void"))
	root.add_child(home)
	for frame: int in 3:
		await process_frame
	if home.is_animating():
		_fail("Reduced Motion should stop the hero and background animation")
	var preview := home.get_node("%WispPreview") as Control
	var start: Vector2 = preview.position
	for frame: int in 20:
		await process_frame
	if not preview.position.is_equal_approx(start):
		_fail("hero Wisp moved under Reduced Motion")
	for orbit: OrbitMotes in home.get_orbits():
		if orbit.visible:
			_fail("orbit %s should be hidden under Reduced Motion" % orbit.name)
	home.queue_free()
	await process_frame


func _check_rift_map() -> void:
	var rift_map := RIFT_MAP_SCENE.instantiate() as RiftMapScreen
	# Wave 9: Obsidian Garden (0) and Shattered Rift (5) are open; Ember Hollow (10) and up are not.
	rift_map.setup({
		&"highest_wave": 9,
		&"selected_rift": "ember_hollow",
		&"rift_bests": {"shattered_rift": 6120},
		&"rift_levels": {"shattered_rift": 3},
		&"settings": {&"reduced_motion": true},
	})
	root.add_child(rift_map)
	await process_frame
	var carousel := rift_map.get_node("%Carousel") as FocusCarousel
	var enter := rift_map.get_node("%EnterButton") as Button
	var status := rift_map.get_node("%StatusLabel") as Label
	var background := rift_map.get_node("%Background") as TextureRect
	var played: Array[StringName] = []
	var backs: Array[bool] = []
	rift_map.play_requested.connect(func(rift_id: StringName) -> void: played.append(rift_id))
	rift_map.back_requested.connect(func() -> void: backs.append(true))

	if carousel.get_card_count() != 5:
		_fail("rift map built %d cards, expected 5" % carousel.get_card_count())
	if rift_map.get_selected_rift_id() != &"obsidian_garden" or carousel.get_selected_index() != 0:
		_fail("a locked saved selection should fall back to Obsidian Garden")
	if enter.disabled:
		_fail("ENTER should be enabled on an unlocked Rift")
	var hollow: PackedInt32Array = (rift_map.get_node("%Dots") as PageDots).hollow
	if hollow != PackedInt32Array([2, 3, 4]):
		_fail("locked Rifts should be hollow page dots, got %s" % hollow)

	carousel.select(1, false)
	if rift_map.get_selected_rift_id() != &"shattered_rift":
		_fail("focusing card 1 should select Shattered Rift")
	if "BEST 6120" not in status.text or status.theme_type_variation != &"AmberValueLabel":
		_fail("Shattered Rift status should show its amber best, got '%s'" % status.text)
	var shattered: RiftData = rift_map.catalog.get_rift(&"shattered_rift")
	if background.texture != shattered.background:
		_fail("background should switch straight to the focused Rift's arena under Reduced Motion")
	var level := carousel.get_card(1).find_child("Level", true, false) as Label
	if level == null or level.text != "LEVEL 4 / 8":
		_fail("Shattered Rift card should read LEVEL 4 / 8")
	enter.pressed.emit()
	carousel.activated.emit(1)
	if played != [&"shattered_rift", &"shattered_rift"]:
		_fail("ENTER and tapping the focused card should both start Shattered Rift, got %s" % played)

	played.clear()
	carousel.select(2, false)
	if rift_map.get_selected_rift_id() != &"ember_hollow" or not enter.disabled:
		_fail("a locked Rift can be previewed but ENTER must be disabled")
	if carousel.get_card(2).find_child("Lock", true, false) == null:
		_fail("locked Ember Hollow card should show a lock")
	if "LOCKED" not in status.text:
		_fail("locked status should say LOCKED, got '%s'" % status.text)
	enter.pressed.emit()
	carousel.activated.emit(2)
	if not played.is_empty():
		_fail("a locked Rift must never emit play_requested, got %s" % played)

	(rift_map.get_node("%BackButton") as Button).pressed.emit()
	if backs.size() != 1:
		_fail("BACK should emit back_requested once")
	rift_map.queue_free()
	await process_frame


func _check_forms() -> void:
	var forms := FORMS_SCENE.instantiate() as FormsScreen
	forms.setup(500, ["void", "ash"], &"ash", 0)
	root.add_child(forms)
	await process_frame
	var carousel := forms.get_node("%Carousel") as FocusCarousel
	var action := forms.get_node("%ActionButton") as Button
	var purchases: Array[StringName] = []
	var equips: Array[StringName] = []
	forms.purchase_requested.connect(func(form_id: StringName) -> void: purchases.append(form_id))
	forms.equip_requested.connect(func(form_id: StringName) -> void: equips.append(form_id))

	var forms_list: Array[FormData] = FORM_CATALOG.load_forms()
	var ash_index: int = forms_list.find(FORM_CATALOG.get_form(&"ash"))
	var venom_index: int = forms_list.find(FORM_CATALOG.get_form(&"venom"))
	if carousel.get_card_count() != forms_list.size():
		_fail("forms carousel has %d cards, expected %d" % [carousel.get_card_count(), forms_list.size()])
	if carousel.get_selected_index() != ash_index:
		_fail("forms carousel should open on the equipped form")

	forms.select_form(&"venom")
	if carousel.get_selected_index() != venom_index:
		_fail("select_form should move the carousel to Venom")
	carousel.select(forms_list.find(FORM_CATALOG.get_form(&"void")), false)
	if forms.get_selected_form_id() != &"void" or action.text != "EQUIP" or action.disabled:
		_fail("swiping to owned Void should offer EQUIP, got '%s'" % action.text)
	carousel.activated.emit(carousel.get_selected_index())
	if equips != [&"void"]:
		_fail("tapping the focused owned card should request equip, got %s" % equips)

	carousel.select(venom_index, false)
	carousel.activated.emit(venom_index)
	if purchases != [&"venom"]:
		_fail("tapping the focused affordable card should request purchase, got %s" % purchases)
	carousel.select(ash_index, false)
	carousel.activated.emit(ash_index)
	if equips.size() != 1:
		_fail("tapping the already-equipped card must not request anything")
	forms.queue_free()
	await process_frame
