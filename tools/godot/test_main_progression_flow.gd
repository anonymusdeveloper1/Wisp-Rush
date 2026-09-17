extends SceneTree
## End-to-end profile check across Home, Forms, Daily, gameplay identity and Results.
##
## Results must show the run's Rift Points (collected, performance, rewards) and a total equal to the
## balance change. The change is compared with 3 + 1 RP plus rewards computed independently from the
## pre-run save (ChallengeTracker, TrialTracker, depth milestones), so a source paid twice fails.

const MAIN_SCENE: PackedScene = preload("res://scenes/main/main.tscn")
const CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")


func _init() -> void:
	call_deferred(&"_run_check")


func _run_check() -> void:
	var failures: int = 0
	# Main resolves /root/SaveManager, so drive the real autoload with isolated test paths.
	var save_manager := root.get_node_or_null(^"SaveManager") as SaveManagerService
	if save_manager == null:
		push_error("main_progression_flow: SaveManager autoload is missing")
		quit(1)
		return
	var test_save := "user://wisp_rush_main_progression_test.json"
	var test_temp := "user://wisp_rush_main_progression_test.tmp.json"
	var test_backup := "user://wisp_rush_main_progression_test.backup.json"
	save_manager.configure_storage_paths(test_save, test_temp, test_backup)
	save_manager.reload()
	save_manager.reset_save()
	# First launch opens the Tutorial screen; this check starts from Home.
	save_manager.mark_tutorial_completed()
	save_manager.add_rift_points(500)

	var main: Node = MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame
	# Main boots through the Loading screen; wait until Home is shown.
	for _frame: int in 600:
		if main.get_child_count() > 0 and main.get_child(0) is HomeScreen:
			break
		await process_frame
	var home := main.get_child(0) as HomeScreen
	if home == null:
		failures += 1
		push_error("main_progression_flow: Home did not open")
	else:
		home.forms_requested.emit()
	await process_frame
	var forms := main.get_child(0) as FormsScreen
	if forms == null:
		failures += 1
		push_error("main_progression_flow: Forms did not open")
	else:
		forms.select_form(&"ash")
		forms.purchase_requested.emit(&"ash")
		await process_frame
		forms.equip_requested.emit(&"ash")
		await process_frame
		var snapshot: Dictionary = save_manager.get_snapshot()
		if "ash" not in snapshot[&"owned_forms"] or snapshot[&"equipped_form"] != "ash":
			failures += 1
			push_error("main_progression_flow: Ash did not purchase and equip persistently")
		forms.back_requested.emit()
	await process_frame
	# Shop and Remove Ads both open the Shop; with no store connected nothing can be bought.
	for entry: StringName in [&"shop_requested", &"remove_ads_requested"]:
		home = main.get_child(0) as HomeScreen
		if home == null:
			failures += 1
			push_error("main_progression_flow: Home did not return before %s" % entry)
			break
		home.emit_signal(entry)
		await process_frame
		var shop := main.get_child(0) as ShopScreen
		if shop == null:
			failures += 1
			push_error("main_progression_flow: %s did not open the Shop" % entry)
			continue
		if shop.can_buy():
			failures += 1
			push_error("main_progression_flow: the Shop offered a purchase with no store")
		shop.purchase_requested.emit(MonetisationService.PRODUCT_REMOVE_ADS)
		await process_frame
		if bool(save_manager.get_snapshot().get(&"ads_removed", false)):
			failures += 1
			push_error("main_progression_flow: a purchase completed with no store")
		var still_shop := main.get_child(0) as ShopScreen
		if still_shop == null:
			failures += 1
			push_error("main_progression_flow: a failed purchase left the Shop")
			break
		still_shop.back_requested.emit()
		await process_frame
	home = main.get_child(0) as HomeScreen
	if home != null:
		home.daily_requested.emit()
	await process_frame
	var daily := main.get_child(0) as DailyScreen
	var date_key: String = ChallengeTracker.get_date_key()
	if daily == null:
		failures += 1
		push_error("main_progression_flow: Daily did not open")
	else:
		var daily_play := daily.get_node("Margin/Content/PlayButton") as Button
		daily_play.pressed.emit()
	await process_frame
	var game := main.get_child(0) as GameWorld
	if game == null or game.run_seed != ChallengeTracker.get_daily_seed(date_key):
		failures += 1
		push_error("main_progression_flow: Daily run did not preserve today's seed")
	var balance_before_run: int = save_manager.get_rift_points()
	var pre_run: Dictionary = save_manager.get_snapshot()
	var expected_rewards: int = -1
	var rp_summary: Dictionary = {}
	if game != null and game.run_seed == ChallengeTracker.get_daily_seed(date_key):
		var form_sprite := game.get_node_or_null(
			"WorldContent/PlayerLayer/WispPlayer/FormSprite"
		) as Sprite2D
		if form_sprite == null or form_sprite.texture != CATALOG.get_form(&"ash").texture:
			failures += 1
			push_error("main_progression_flow: equipped Ash form was not applied in gameplay")
		rp_summary = {
			&"score": 700,
			&"kills": 2,
			&"highest_combo": 2,
			&"wave": 1,
			&"multi_kill_dashes": 0,
			&"rapid_ricochets": 0,
			&"bosses": 0,
			&"rp_collected": 3,
			&"rp_performance": 1,
			&"daily_date": date_key,
			&"is_daily": true,
		}
		expected_rewards = _expected_rewards(rp_summary, pre_run, date_key)
		game.run_ended.emit(rp_summary)
	await process_frame
	var final_snapshot: Dictionary = save_manager.get_snapshot()
	if date_key not in (final_snapshot[&"daily_state"] as Dictionary)[&"completed_dates"]:
		failures += 1
		push_error("main_progression_flow: daily completion was not persisted")
	if int(final_snapshot[&"best_score"]) != 700:
		failures += 1
		push_error("main_progression_flow: best score was not persisted")
	var results := main.get_child(0) as ResultsScreen
	if results == null:
		failures += 1
		push_error("main_progression_flow: completed run did not open Results")
	else:
		var gained: int = int(final_snapshot[&"rift_points"]) - balance_before_run
		var collected_label := results.get_node("%CollectedValue") as Label
		var performance_label := results.get_node("%PerformanceValue") as Label
		var rewards_label := results.get_node("%RewardsValue") as Label
		var total_label := results.get_node("%TotalValue") as Label
		var balance_label := results.get_node("%BalanceValue") as Label
		# Exactly once: the balance change must equal the run's own 3 + 1 RP plus the rewards worked
		# out independently from the pre-run save. Main's total is itself a balance change, so
		# comparing it with `gained` alone could not catch a source paid twice.
		var expected_gain: int = 3 + 1 + expected_rewards
		if (
			expected_rewards < ChallengeTracker.DAILY_COMPLETION_REWARD
			or gained != expected_gain
			or results.get_displayed_rp_total() != expected_gain
			or collected_label.text != RiftPoints.format_gain(3)
			or performance_label.text != RiftPoints.format_gain(1)
			or rewards_label.text != RiftPoints.format_gain(expected_rewards)
			or total_label.text != RiftPoints.format_gain(expected_gain)
			or balance_label.text != RiftPoints.format(balance_before_run + expected_gain)
		):
			failures += 1
			push_error(
				"main_progression_flow: Results RP total %d (%s / %s / %s = %s, %s) vs a %d balance "
				% [
					results.get_displayed_rp_total(), collected_label.text, performance_label.text,
					rewards_label.text, total_label.text, balance_label.text, gained,
				]
				+ "change; expected 3 + 1 + %d rewards = %d" % [expected_rewards, expected_gain]
			)
	if failures == 0:
		print("main_progression_flow: forms, shop, daily run, persistent Results and RP totals passed")

	main.queue_free()
	await process_frame
	# Detach first so the autoload's exit-save lands in the test file, then delete the test files.
	root.remove_child(save_manager)
	for path: String in [test_save, test_temp, test_backup]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	save_manager.free()
	quit(failures)


## Rewards the run should pay (challenges + daily bonus, Trials, depth milestones), worked out
## from the save as it was before the run and never from the balance, so a double payment shows up.
func _expected_rewards(summary: Dictionary, pre_run: Dictionary, date_key: String) -> int:
	var challenges: Dictionary = ChallengeTracker.apply_run(
		summary,
		pre_run[&"challenge_state"] as Dictionary,
		pre_run[&"daily_state"] as Dictionary,
		date_key,
		true,
	)
	var trials: Dictionary = TrialTracker.apply_run(
		maxi(1, int(pre_run.get(&"trial_rank", 1))),
		pre_run.get(&"trial_progress", {}) as Dictionary,
		summary,
	)
	var reached: int = maxi(int(pre_run.get(&"highest_wave", 1)), int(summary[&"wave"]))
	var claimed: int = int(pre_run.get(&"claimed_depth", 0))
	var depth: int = 0
	for index: int in SaveManagerService.DEPTH_MILESTONES.size():
		var wave: int = SaveManagerService.DEPTH_MILESTONES[index]
		if wave > claimed and wave <= reached:
			depth += SaveManagerService.DEPTH_REWARDS[index]
	return int(challenges[&"reward_points"]) + int(trials[&"reward_points"]) + depth
