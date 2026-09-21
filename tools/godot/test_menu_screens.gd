extends SceneTree
## Home, Rift Map, Forms and Shop: on Home the side-column and PLAY/Rifts signals, tap-the-Wisp for
## Forms, animations kept clear of every button, PLAY and portal motion and Reduced Motion; lock
## gating, selection and ENTER on the Rift Map; carousel selection and tap-to-act on Forms; the
## Shop's disabled, available and owned states.

const HOME_SCENE: PackedScene = preload("res://scenes/screens/home_screen.tscn")
const RIFT_MAP_SCENE: PackedScene = preload("res://scenes/screens/rift_map_screen.tscn")
const FORMS_SCENE: PackedScene = preload("res://scenes/screens/forms_screen.tscn")
const SHOP_SCENE: PackedScene = preload("res://scenes/screens/shop_screen.tscn")
const FORM_CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
## Owner requirement: the PLAY row sits at least this far below the lowest animated hero pixel.
const MIN_HERO_GAP: float = 50.0
## ...and directly under the Wisp, not parked at the bottom of the screen.
const MAX_HERO_GAP: float = 160.0

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _fail(message: String) -> void:
	_failures += 1
	push_error("menu_screens: %s" % message)


func _run() -> void:
	await _check_home()
	await _check_home_reduced_motion()
	await _check_home_tall()
	await _check_hero_press_recovery()
	await _check_rift_map()
	await _check_forms()
	await _check_shop()
	if _failures == 0:
		print("menu_screens: home columns + wisp tap + clear motion, rift map, forms, shop OK")
	quit(_failures)


func _home_snapshot(reduced_motion: bool, ads_removed: bool = false) -> Dictionary:
	return {
		&"best_score": 12480,
		&"rift_points": 320,
		&"selected_rift": "ember_hollow",
		&"rift_levels": {"ember_hollow": 3},
		&"ads_removed": ads_removed,
		&"settings": {&"reduced_motion": reduced_motion},
	}


## Mounts Home inside a phone-sized frame: the headless root viewport is square, which would never
## squeeze the hero between the side columns the way a real phone does.
func _add_home(snapshot: Dictionary, form_id: StringName, phone_size: Vector2) -> HomeScreen:
	var phone := Control.new()
	phone.size = phone_size
	root.add_child(phone)
	var home := HOME_SCENE.instantiate() as HomeScreen
	home.setup(snapshot, FORM_CATALOG.get_form(form_id))
	phone.add_child(home)
	return home


func _check_home() -> void:
	# 390×844 phone aspect in the 1080-wide design space.
	var home := _add_home(_home_snapshot(false), &"ilyra", Vector2(1080.0, 2337.0))
	for frame: int in 3:
		await process_frame

	var caption: String = home.get_rift_caption()
	if "EMBER HOLLOW" not in caption or "LEVEL 4" not in caption:
		_fail("rift caption should name Ember Hollow at level 4, got '%s'" % caption)
	if home.find_child("NavBar", true, false) != null:
		_fail("the bottom navigation bar should be gone")

	var emitted: Array[StringName] = []
	var expectations: Dictionary = {
		"%PlayButton": &"play_requested",
		"%RiftsButton": &"rift_map_requested",
		"%TrialsButton": &"trials_requested",
		"%DailyButton": &"daily_requested",
		"%ShopButton": &"shop_requested",
		"%RemoveAdsButton": &"remove_ads_requested",
		"%StatsButton": &"statistics_requested",
		"%SettingsButton": &"settings_requested",
	}
	for signal_name: StringName in expectations.values() + [&"forms_requested"]:
		home.connect(signal_name, func() -> void: emitted.append(signal_name))
	for path: String in expectations:
		emitted.clear()
		(home.get_node(path) as Button).pressed.emit()
		if emitted != [expectations[path]]:
			_fail("%s emitted %s, expected [%s]" % [path, emitted, expectations[path]])

	# Tapping the Wisp opens Forms, through real GUI hit-testing; a drag does not.
	var preview := home.get_node("%WispPreview") as Control
	emitted.clear()
	var tap_point: Vector2 = preview.get_global_rect().get_center()
	_mouse_button(tap_point, true)
	await process_frame
	_mouse_button(tap_point, false)
	await process_frame
	if emitted != [&"forms_requested"]:
		_fail("tapping the hero Wisp emitted %s, expected [forms_requested]" % [emitted])
	emitted.clear()
	_mouse_button(tap_point, true)
	await process_frame
	_mouse_button(tap_point + Vector2(120.0, 0.0), false)
	await process_frame
	if not emitted.is_empty():
		_fail("dragging off the hero Wisp should not open Forms, got %s" % [emitted])

	await _check_home_clearance(home)

	var play := home.get_node("%PlayButton") as Control
	var portal := home.get_node("%RiftsIcon") as Control
	var play_scale: Vector2 = play.scale
	var portal_turn: float = portal.rotation
	for frame: int in 12:
		await process_frame
	if play.scale.is_equal_approx(play_scale):
		_fail("PLAY should animate while Reduced Motion is off")
	if is_equal_approx(portal.rotation, portal_turn):
		_fail("the Rifts portal icon should turn while Reduced Motion is off")

	if not home.is_animating():
		_fail("home should animate with Reduced Motion off")
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
	home.get_parent().queue_free()
	await process_frame


## Nothing animated may pass over a button: the hero's motion bounds stay out of both columns, and
## the caption and PLAY row sit under the Wisp with at least MIN_HERO_GAP to spare.
func _check_home_clearance(home: HomeScreen) -> void:
	await process_frame
	var motion: Rect2 = home.get_hero_motion_rect()
	if motion.size.x <= 0.0 or motion.size.y <= 0.0:
		_fail("hero motion bounds were never laid out: %s" % motion)
		return
	var action_rect: Rect2 = (home.get_node("%ActionBlock") as Control).get_global_rect()
	for path: String in ["%LeftColumn", "%RightColumn"]:
		var column: Rect2 = (home.get_node(path) as Control).get_global_rect()
		if column.intersects(motion):
			_fail("hero animation %s overlaps %s %s" % [motion, path, column])
		if column.end.y > action_rect.position.y:
			_fail("%s %s runs into the PLAY row %s" % [path, column, action_rect])
	var gap: float = action_rect.position.y - motion.end.y
	if gap < MIN_HERO_GAP or gap > MAX_HERO_GAP:
		_fail("PLAY row should sit %d-%d px under the Wisp's animation, got %.1f" % [
			MIN_HERO_GAP, MAX_HERO_GAP, gap,
		])


## 23:9-class screens (e.g. a foldable's cover display): the preview's own animated width once
## overlapped the right column here while 2337-tall phones were fine.
func _check_home_tall() -> void:
	var home := _add_home(_home_snapshot(false), &"void", Vector2(1080.0, 2800.0))
	for frame: int in 3:
		await process_frame
	await _check_home_clearance(home)
	home.get_parent().queue_free()
	await process_frame


## A press cancelled mid-dip, or a quick re-press during the spring-back, must not leave the Wisp at
## the wrong scale. Reduced Motion keeps the breathing out of the measurement.
func _check_hero_press_recovery() -> void:
	var home := _add_home(_home_snapshot(true), &"void", Vector2(1080.0, 1920.0))
	for frame: int in 3:
		await process_frame
	var forms_opened: Array[bool] = []
	home.forms_requested.connect(func() -> void: forms_opened.append(true))
	var preview := home.get_node("%WispPreview") as Control
	var point: Vector2 = preview.get_global_rect().get_center()

	_mouse_button(point, true)
	await process_frame
	home.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await create_timer(0.3).timeout
	if not preview.scale.is_equal_approx(Vector2.ONE):
		_fail("focus loss mid-press left the Wisp at scale %s" % preview.scale)
	_mouse_button(point, false)
	await process_frame
	if not forms_opened.is_empty():
		_fail("a press cancelled by focus loss still opened Forms on release")

	_mouse_button(point, true)
	await process_frame
	_mouse_button(point + Vector2(200.0, 0.0), false)
	await process_frame
	_mouse_button(point, true)
	await create_timer(0.3).timeout
	if not preview.scale.is_equal_approx(Vector2.ONE * HomeScreen.PRESSED_SCALE):
		_fail("a re-press during the spring-back should hold the dip, got %s" % preview.scale)
	_mouse_button(point + Vector2(200.0, 0.0), false)
	await create_timer(0.3).timeout
	if not preview.scale.is_equal_approx(Vector2.ONE):
		_fail("the Wisp should spring back after release, got %s" % preview.scale)
	home.get_parent().queue_free()
	await process_frame


func _check_home_reduced_motion() -> void:
	# 16:9 phone (320×568, 360×640): the shortest supported screen.
	var home := _add_home(_home_snapshot(true, true), &"void", Vector2(1080.0, 1920.0))
	for frame: int in 3:
		await process_frame
	if home.is_animating():
		_fail("Reduced Motion should stop the hero and background animation")
	if (home.get_node("%RemoveAdsButton") as Control).is_visible_in_tree():
		_fail("Remove Ads should be hidden once ads are removed")
	if not (home.get_node("%ShopButton") as Control).is_visible_in_tree():
		_fail("Shop should stay reachable after ads are removed")
	await _check_home_clearance(home)
	var play := home.get_node("%PlayButton") as Control
	var portal := home.get_node("%RiftsIcon") as Control
	if not play.scale.is_equal_approx(Vector2.ONE) or not is_zero_approx(portal.rotation):
		_fail("PLAY and the portal should rest under Reduced Motion")
	if (home.get_node("%PlaySheen") as CanvasItem).visible:
		_fail("PLAY's light sweep should be hidden under Reduced Motion")
	var preview := home.get_node("%WispPreview") as Control
	var start: Vector2 = preview.position
	for frame: int in 20:
		await process_frame
	if not preview.position.is_equal_approx(start):
		_fail("hero Wisp moved under Reduced Motion")
	for orbit: OrbitMotes in home.get_orbits():
		if orbit.visible:
			_fail("orbit %s should be hidden under Reduced Motion" % orbit.name)
	home.get_parent().queue_free()
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
	forms.setup(500, ["void", "eclipse"], &"eclipse", 0)
	root.add_child(forms)
	await process_frame
	var carousel := forms.get_node("%Carousel") as FocusCarousel
	var action := forms.get_node("%ActionButton") as Button
	var purchases: Array[StringName] = []
	var equips: Array[StringName] = []
	forms.purchase_requested.connect(func(form_id: StringName) -> void: purchases.append(form_id))
	forms.equip_requested.connect(func(form_id: StringName) -> void: equips.append(form_id))

	var forms_list: Array[FormData] = FORM_CATALOG.load_forms()
	var eclipse_index: int = forms_list.find(FORM_CATALOG.get_form(&"eclipse"))
	var veyra_index: int = forms_list.find(FORM_CATALOG.get_form(&"veyra"))
	if carousel.get_card_count() != forms_list.size():
		_fail("forms carousel has %d cards, expected %d" % [carousel.get_card_count(), forms_list.size()])
	if carousel.get_selected_index() != eclipse_index:
		_fail("forms carousel should open on the equipped form")

	forms.select_form(&"veyra")
	if carousel.get_selected_index() != veyra_index:
		_fail("select_form should move the carousel to Venom")
	carousel.select(forms_list.find(FORM_CATALOG.get_form(&"void")), false)
	if forms.get_selected_form_id() != &"void" or action.text != "EQUIP" or action.disabled:
		_fail("swiping to owned Void should offer EQUIP, got '%s'" % action.text)
	carousel.activated.emit(carousel.get_selected_index())
	if equips != [&"void"]:
		_fail("tapping the focused owned card should request equip, got %s" % equips)

	carousel.select(veyra_index, false)
	carousel.activated.emit(veyra_index)
	if purchases != [&"veyra"]:
		_fail("tapping the focused affordable card should request purchase, got %s" % purchases)
	carousel.select(eclipse_index, false)
	carousel.activated.emit(eclipse_index)
	if equips.size() != 1:
		_fail("tapping the already-equipped card must not request anything")
	forms.queue_free()
	await process_frame


func _check_shop() -> void:
	var shop := SHOP_SCENE.instantiate() as ShopScreen
	shop.setup(1320, false, false)
	root.add_child(shop)
	await process_frame
	var buy := shop.get_node("%BuyButton") as Button
	var restore := shop.get_node("%RestoreButton") as Button
	var purchases: Array[StringName] = []
	var restores: Array[bool] = []
	var backs: Array[bool] = []
	shop.purchase_requested.connect(func(product: StringName) -> void: purchases.append(product))
	shop.restore_requested.connect(func() -> void: restores.append(true))
	shop.back_requested.connect(func() -> void: backs.append(true))

	# No store: both store buttons are disabled and a stray press buys nothing.
	if shop.can_buy() or not buy.disabled or not restore.disabled or buy.text != "COMING SOON":
		_fail("with no store the Shop should show a disabled COMING SOON, got '%s'" % buy.text)
	buy.pressed.emit()
	if not purchases.is_empty():
		_fail("a disabled Shop requested a purchase")

	shop.setup(1320, false, true)
	if not shop.can_buy() or restore.disabled or buy.text != "BUY":
		_fail("with a store the Shop should offer BUY and Restore, got '%s'" % buy.text)
	buy.pressed.emit()
	restore.pressed.emit()
	if purchases != [MonetisationService.PRODUCT_REMOVE_ADS] or restores.size() != 1:
		_fail("BUY and Restore should request once each, got %s / %d" % [purchases, restores.size()])

	shop.setup(2820, true, true)
	if shop.can_buy() or buy.text != "OWNED" or restore.disabled:
		_fail("owned Remove Ads should read OWNED and keep Restore, got '%s'" % buy.text)
	(shop.get_node("%BackButton") as Button).pressed.emit()
	if backs.size() != 1:
		_fail("BACK should emit back_requested once")
	shop.queue_free()
	await process_frame


func _mouse_button(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	event.global_position = point
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(event, true)
