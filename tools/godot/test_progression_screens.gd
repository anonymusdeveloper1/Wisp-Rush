extends SceneTree
## Live scene checks for locked-form preview and deterministic Daily presentation.

const FORMS_SCENE: PackedScene = preload("res://scenes/screens/forms_screen.tscn")
const DAILY_SCENE: PackedScene = preload("res://scenes/screens/daily_screen.tscn")


func _init() -> void:
	call_deferred(&"_run_check")


func _run_check() -> void:
	var failures: int = 0
	var forms := FORMS_SCENE.instantiate() as FormsScreen
	forms.setup(500, ["void", "ash"], &"ash", 0)
	root.add_child(forms)
	await process_frame
	forms.select_form(&"eclipse")
	if forms.get_selected_form_id() != &"eclipse":
		failures += 1
		push_error("progression_screens: locked Eclipse could not be previewed")
	var eclipse_action := forms.get_node("SafeMargin/Content/ActionButton") as Button
	if not eclipse_action.disabled or eclipse_action.text != "REAPER REQUIRED":
		failures += 1
		push_error("progression_screens: Eclipse boss gate was not presented")
	forms.select_form(&"venom")
	var venom_action := forms.get_node("SafeMargin/Content/ActionButton") as Button
	if venom_action.disabled or "500" not in venom_action.text:
		failures += 1
		push_error("progression_screens: eligible purchase state was incorrect")
	forms.queue_free()
	await process_frame

	var date_key := "2026-09-11"
	var daily := DAILY_SCENE.instantiate() as DailyScreen
	daily.setup(date_key, ChallengeTracker.get_daily_seed(date_key), {})
	root.add_child(daily)
	await process_frame
	var seed_label := daily.get_node("Margin/Content/PortalCard/PortalContent/SeedLabel") as Label
	if str(ChallengeTracker.get_daily_seed(date_key)) not in seed_label.text:
		failures += 1
		push_error("progression_screens: Daily seed was not displayed")
	for index: int in 3:
		var label := daily.get_node(
			"Margin/Content/Challenges/ChallengeLabel%d" % index
		) as Label
		if label.text.is_empty():
			failures += 1
			push_error("progression_screens: challenge row %d was empty" % index)
	if failures == 0:
		print("progression_screens: form preview and daily presentation passed")
	daily.queue_free()
	quit(failures)
