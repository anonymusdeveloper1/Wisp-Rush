class_name TutorialDirector
extends Node
## Runs the Tutorial screen's lessons in order: set up, ghost-hand demo, player try, success beat.
##
## Every lesson "shows, then you try": the ghost hand demonstrates the swipe while the director
## releases the same swipe through the real Wisp (`GameWorld.demo_aim` / `demo_swipe`), the arena is
## rebuilt, then the player repeats it and the lesson passes only on its goal. Lessons, captions,
## placements and timings are data (`TutorialCatalog`, `data/tutorial/default_tutorial.tres`).
## The director only talks to GameWorld through its scripted-run hooks and run event signals, and
## keeps the Wisp alive by refilling Soul Fragments after every hit, so the tutorial never ends in
## death.

## A lesson began (its demo starts); [param index] is zero-based.
signal lesson_started(index: int, count: int, lesson: TutorialLessonData)
## The one-line caption changed.
signal caption_changed(text: String)
## The lesson at [param index] reached its goal.
signal lesson_passed(index: int)
## Every lesson passed; the TUTORIAL COMPLETE beat started.
signal completion_started
## The TUTORIAL COMPLETE beat ended; the host leaves the screen.
signal completed

enum Phase { IDLE, DEMO, TRY, SUCCESS, COMPLETE }
## The upgrade lesson's demo after its swipes: wait for the card tray, let it rest, tap, see it close.
enum DemoTap { NONE, WAIT_TRAY, LOOK, TAPPING, WAIT_CLOSE, DONE }

var _catalog: TutorialCatalog
var _game: GameWorld
var _hand: TutorialGhostHand
var _lesson: TutorialLessonData
var _index: int = -1
var _phase: Phase = Phase.IDLE
## Countdown of the current step (demo delay/gap/settle, success or completion beat), seconds.
var _timer: float = 0.0
var _settling: bool = false
var _demo_swipe: int = 0
var _demo_hit_pending: bool = false
var _hint_timer: float = 0.0
var _retry_timer: float = -1.0
var _refill_timer: float = -1.0
var _needs_place: bool = false
## The dash leg now in flight was started by a mid-dash redirect.
var _leg_redirect: bool = false
var _attempt_hit: bool = false
var _rush_seen: bool = false
## The swipe the hand is playing aims at the nearest target, re-aimed at release.
var _swipe_aims_at_target: bool = false
var _demo_tap: DemoTap = DemoTap.NONE
## Real seconds left in the current `DemoTap` wait.
var _demo_tap_timer: float = 0.0
## The try already showed its dimmed card-tap hint for the tray now up.
var _tray_hint_shown: bool = false


func _process(delta: float) -> void:
	if _phase == Phase.IDLE or _game == null:
		return
	_update_refill(delta)
	if _needs_place and _game.place_player(_lesson.player_start):
		_needs_place = false
	if not _lesson.hud_focus.is_empty() and _phase != Phase.COMPLETE:
		_hand.set_focus_rect(_game.get_hud_rect(_lesson.hud_focus))
	match _phase:
		Phase.DEMO:
			_update_demo(delta)
		Phase.TRY:
			_update_try(delta)
		Phase.SUCCESS:
			_timer -= delta
			if _timer <= 0.0:
				if _index + 1 < _catalog.lessons.size():
					_begin_lesson(_index + 1)
				else:
					_begin_completion()
		Phase.COMPLETE:
			_timer -= delta
			if _timer <= 0.0:
				_phase = Phase.IDLE
				print("[Tutorial] complete")
				completed.emit()


## Starts the first lesson in [param game] (a `MODE_TUTORIAL` arena) with [param hand] and
## [param catalog]; [param reduced_motion] stills the hand's decoration.
func start(
	game: GameWorld,
	hand: TutorialGhostHand,
	catalog: TutorialCatalog,
	reduced_motion: bool,
) -> void:
	_game = game
	_hand = hand
	_catalog = catalog
	_hand.reduced_motion = reduced_motion
	_hand.aim_changed.connect(_on_hand_aim_changed)
	_hand.released.connect(_on_hand_released)
	_hand.tapped.connect(_on_hand_tapped)
	_game.dash_launched.connect(_on_dash_launched)
	_game.dash_resolved.connect(_on_dash_resolved)
	_game.enemy_defeated.connect(_on_enemy_defeated)
	_game.player_damaged.connect(_on_player_damaged)
	_game.upgrade_chosen.connect(_on_upgrade_chosen)
	_game.rush_started.connect(_on_rush_started)
	_game.boss_defeated.connect(_on_boss_defeated)
	var failures: PackedStringArray = catalog.validate()
	if not failures.is_empty():
		push_error("Invalid tutorial catalog: %s" % "; ".join(failures))
	_begin_lesson(0)


## Stops everything (the player skipped); no further signals are emitted.
func stop() -> void:
	_phase = Phase.IDLE
	if is_instance_valid(_hand):
		_hand.stop()


## Zero-based index of the current lesson.
func get_lesson_index() -> int:
	return _index


## Number of lessons.
func get_lesson_count() -> int:
	return _catalog.lessons.size() if _catalog != null else 0


## Current phase (`Phase`).
func get_phase() -> Phase:
	return _phase


func _begin_lesson(index: int) -> void:
	_index = index
	_lesson = _catalog.lessons[index]
	_hand.stop()
	_hand.set_focus_rect(Rect2())
	_game.set_player_input_enabled(false)
	_game.set_experience_enabled(false)
	_game.set_rush_enabled(_lesson.rush_enabled)
	_build_arena()
	_phase = Phase.DEMO
	_timer = _catalog.demo_start_delay
	_settling = false
	_demo_swipe = 0
	_demo_hit_pending = false
	_demo_tap = DemoTap.NONE
	lesson_started.emit(index, _catalog.lessons.size(), _lesson)
	caption_changed.emit(_lesson.demo_caption)
	print("[Tutorial] lesson %d/%d %s | demo" % [
		index + 1, _catalog.lessons.size(), _lesson.lesson_id,
	])


## Clears the arena and spawns the lesson: Wisp start, enemies, hazard, boss, RUSH meter.
func _build_arena() -> void:
	_game.clear_scripted_arena()
	_needs_place = not _game.place_player(_lesson.player_start)
	if _lesson.rush_enabled:
		_game.set_rush_meter(_lesson.rush_start_share * _game.feel_tuning.meter_max)
	for position: Vector2 in _lesson.enemy_positions:
		_game.spawn_scripted_enemy(_lesson.enemy_kind, position)
	if not _lesson.hazard_kind.is_empty():
		_game.spawn_scripted_hazard(_lesson.hazard_kind, _lesson.hazard_position)
	if _lesson.spawns_boss:
		_game.start_scripted_boss(_catalog.boss_health)
	_leg_redirect = false
	_attempt_hit = false
	_rush_seen = false


func _update_demo(delta: float) -> void:
	if _demo_hit_pending:
		_update_demo_hit()
	if _hand.is_gesturing() or _needs_place:
		return
	if _timer > 0.0:
		_timer -= delta
		return
	if _demo_swipe >= _lesson.demo_swipes.size():
		if _lesson.demo_drives_wisp and not _game.is_player_ready():
			return
		if not _settling:
			_settling = true
			_timer = _catalog.demo_settle_seconds
			if _lesson.demo_experience_share > 0.0:
				_game.set_experience_share(_lesson.demo_experience_share)
			if _lesson.demo_upgrade_tap:
				# A full bar banks the level; the cards wait for this calm moment.
				_game.set_experience_share(1.0)
				_game.request_upgrade_calm_moment()
				_demo_tap = DemoTap.WAIT_TRAY
				_demo_tap_timer = _catalog.demo_tray_wait_limit
			return
		if _demo_tap != DemoTap.NONE and _demo_tap != DemoTap.DONE:
			_update_demo_tap()
			return
		_begin_try()
		return
	var mid_dash: bool = _demo_swipe == _lesson.redirect_swipe_index
	if _lesson.demo_drives_wisp and not mid_dash and not _game.is_player_ready():
		return
	_play_swipe(_lesson.demo_swipes[_demo_swipe], mid_dash, 1.0)
	_demo_swipe += 1
	var next_is_redirect: bool = _demo_swipe == _lesson.redirect_swipe_index
	_timer = 0.0 if next_is_redirect else _catalog.swipe_gap_seconds


## Drives the upgrade demo in real time (the world is slow while the tray is up): wait for the tray to
## settle, rest `demo_card_look_seconds`, tap a card with the hand, then wait for the tray to close.
func _update_demo_tap() -> void:
	var real_delta: float = get_process_delta_time() / maxf(Engine.time_scale, 0.01)
	match _demo_tap:
		DemoTap.WAIT_TRAY:
			_demo_tap_timer -= real_delta
			if _game.is_upgrade_tray_settled():
				_demo_tap = DemoTap.LOOK
				_demo_tap_timer = _catalog.demo_card_look_seconds
			elif _demo_tap_timer <= 0.0:
				# The tray never came up (should not happen): move on, caption only.
				push_warning("[Tutorial] upgrade demo: the card tray did not open")
				_demo_tap = DemoTap.DONE
		DemoTap.LOOK:
			_demo_tap_timer -= real_delta
			if _demo_tap_timer > 0.0:
				return
			var card: Rect2 = _game.get_upgrade_card_rect(_catalog.demo_card_index)
			if not card.has_area():
				card = _game.get_upgrade_card_rect(0)
			if not card.has_area() or not _game.is_upgrade_tray_settled():
				_demo_tap = DemoTap.WAIT_CLOSE
				return
			_demo_tap = DemoTap.TAPPING
			_hand.play_tap(card.get_center(), _catalog.press_seconds, _catalog.hold_seconds,
				_catalog.release_seconds)
		DemoTap.TAPPING:
			if not _hand.is_gesturing():
				_demo_tap = DemoTap.WAIT_CLOSE
		DemoTap.WAIT_CLOSE:
			if not _game.is_upgrade_tray_open():
				_demo_tap = DemoTap.DONE
				_timer = _catalog.demo_settle_seconds


## The demo's own dash takes its hit once it nears the hazard, reforming where the lesson says.
func _update_demo_hit() -> void:
	if not _game.is_player_dashing():
		# That dash already ended (or a real hit landed first): nothing left to demonstrate.
		_demo_hit_pending = false
		return
	var hazard: Vector2 = _game.arena_to_world(_lesson.hazard_position)
	if _game.get_player_position().distance_to(hazard) <= _catalog.demo_hit_distance:
		_demo_hit_pending = false
		_game.hit_player_at(_lesson.demo_hit_reform)


func _begin_try() -> void:
	_settling = false
	if _lesson.reset_after_demo:
		_build_arena()
	_game.set_experience_enabled(_lesson.experience_enabled)
	_game.set_player_input_enabled(true)
	_phase = Phase.TRY
	_retry_timer = -1.0
	_hint_timer = _catalog.hint_interval * 0.5
	caption_changed.emit(_lesson.try_caption)
	print("[Tutorial] lesson %d %s | try" % [_index + 1, _lesson.lesson_id])


func _update_try(delta: float) -> void:
	if _retry_timer >= 0.0:
		_retry_timer -= delta
		if _retry_timer <= 0.0 and _game.is_player_ready():
			_retry_timer = -1.0
			_build_arena()
			caption_changed.emit(_lesson.try_caption)
			print("[Tutorial] lesson %d %s | retry" % [_index + 1, _lesson.lesson_id])
		return
	if _lesson.goal == TutorialLessonData.GOAL_RUSH_KILL:
		if _game.is_rush_active():
			_rush_seen = true
		elif _rush_seen:
			_schedule_retry(_catalog.retry_caption)
			return
	if _lesson.goal == TutorialLessonData.GOAL_UPGRADE and _update_upgrade_try():
		return
	if _hand.is_gesturing() or not _can_hint():
		_hint_timer = _catalog.hint_interval
		return
	_hint_timer -= delta
	if _hint_timer <= 0.0:
		_hint_timer = _catalog.hint_interval
		var authored: Vector2 = _lesson.demo_swipes[0]
		var start_point: Vector2 = _game.arena_to_world(_lesson.player_start)
		if _game.get_player_position().distance_to(start_point) > _catalog.drag_start_offset:
			authored = Vector2.ZERO
		_play_swipe(authored, false, _catalog.hint_alpha)


## The upgrade try: a banked level whose cards were sent away (swipe or timeout) asks for another calm
## moment once the field is empty; the first time the tray rests, a dimmed hand taps a card as a hint.
## Returns true while the tray is up (no swipe hints then).
func _update_upgrade_try() -> bool:
	if _game.is_upgrade_tray_open():
		if not _tray_hint_shown and _game.is_upgrade_tray_settled() and not _hand.is_gesturing():
			var card: Rect2 = _game.get_upgrade_card_rect(_catalog.demo_card_index)
			if card.has_area():
				_tray_hint_shown = true
				_hand.play_tap(card.get_center(), _catalog.press_seconds, _catalog.hold_seconds,
					_catalog.release_seconds, _catalog.hint_alpha)
		return true
	_tray_hint_shown = false
	if (
		_game.get_banked_upgrades() > 0
		and not _game.has_upgrade_calm_request()
		and _game.debug_live_enemy_count() == 0
		and _game.is_player_ready()
	):
		_game.request_upgrade_calm_moment()
	return false


func _can_hint() -> bool:
	if not _game.is_player_ready():
		return false
	if _lesson.goal == TutorialLessonData.GOAL_BOSS:
		return _game.is_boss_core_exposed()
	return _lesson.enemy_positions.is_empty() or _game.debug_live_enemy_count() > 0


## Plays one hand swipe from beside the Wisp; `Vector2.ZERO` aims at the nearest live target.
func _play_swipe(authored: Vector2, mid_dash: bool, alpha: float) -> void:
	var origin: Vector2 = _game.get_player_position()
	var direction: Vector2 = authored
	if direction.is_zero_approx():
		direction = _game.find_nearest_target(origin) - origin
	if direction.is_zero_approx():
		direction = Vector2.UP
	_swipe_aims_at_target = authored.is_zero_approx()
	var drag: Vector2 = direction.normalized() * _catalog.drag_length
	var from: Vector2 = origin + direction.normalized() * _catalog.drag_start_offset
	if mid_dash:
		_hand.play_swipe(from, drag, 0.0, _catalog.redirect_drag_seconds, 0.0,
			_catalog.release_seconds, alpha)
	else:
		_hand.play_swipe(from, drag, _catalog.press_seconds, _catalog.drag_seconds,
			_catalog.hold_seconds, _catalog.release_seconds, alpha)


func _schedule_retry(caption: String) -> void:
	_retry_timer = _catalog.retry_seconds
	_hand.stop()
	caption_changed.emit(caption)


func _succeed() -> void:
	if _phase != Phase.TRY:
		return
	_phase = Phase.SUCCESS
	_timer = _catalog.success_seconds
	_retry_timer = -1.0
	_hand.stop()
	_game.show_callout(_lesson.success_callout, _catalog.success_emphasis)
	SoundFx.play(&"upgrade_choice")
	caption_changed.emit(_lesson.success_callout)
	lesson_passed.emit(_index)
	print("[Tutorial] lesson %d %s | passed" % [_index + 1, _lesson.lesson_id])


func _begin_completion() -> void:
	_phase = Phase.COMPLETE
	_timer = _catalog.complete_seconds
	_hand.stop()
	_hand.set_focus_rect(Rect2())
	_game.set_rush_enabled(false)
	_game.clear_scripted_arena()
	_game.show_callout(_catalog.complete_callout, _catalog.success_emphasis)
	SoundFx.play(&"level_up")
	caption_changed.emit(_catalog.complete_caption)
	completion_started.emit()


func _update_refill(delta: float) -> void:
	if _refill_timer < 0.0:
		return
	_refill_timer -= delta
	if _refill_timer <= 0.0:
		_refill_timer = -1.0
		_game.refill_health()


func _on_hand_aim_changed(drag_vector: Vector2) -> void:
	if _phase == Phase.DEMO and _lesson.demo_drives_wisp:
		_game.demo_aim(drag_vector)


func _on_hand_released(drag_vector: Vector2) -> void:
	if _phase != Phase.DEMO or not _lesson.demo_drives_wisp:
		return
	var swipe: Vector2 = drag_vector
	if _swipe_aims_at_target:
		# Re-aim from where the Wisp is now: a redirect releases mid-flight, past the press point.
		var origin: Vector2 = _game.get_player_position()
		var to_target: Vector2 = _game.find_nearest_target(origin) - origin
		if not to_target.is_zero_approx():
			swipe = to_target.normalized() * drag_vector.length()
	_game.demo_swipe(swipe)
	# The first demonstrated dash is the one that runs into the hazard.
	if _lesson.demo_shows_hit and _demo_swipe == 1:
		_demo_hit_pending = true


## The demo hand lifted from an upgrade card: pick it through the real tray (hint taps never pick).
func _on_hand_tapped(_point: Vector2) -> void:
	if _phase != Phase.DEMO or _demo_tap != DemoTap.TAPPING:
		return
	if not _game.choose_upgrade_card(_catalog.demo_card_index):
		_game.choose_upgrade_card(0)


func _on_dash_launched(from_redirect: bool) -> void:
	_leg_redirect = from_redirect
	if _phase == Phase.TRY:
		_hand.stop()
		_hint_timer = _catalog.hint_interval


func _on_enemy_defeated(world_position: Vector2, _dash_kill_index: int) -> void:
	if _phase != Phase.DEMO and _phase != Phase.TRY:
		return
	if _lesson.drops_shards:
		_game.spawn_scripted_shard(world_position)
	if _phase != Phase.TRY or _retry_timer >= 0.0:
		return
	match _lesson.goal:
		TutorialLessonData.GOAL_KILL:
			_succeed()
		TutorialLessonData.GOAL_REDIRECT_KILL:
			if _leg_redirect:
				_succeed()
		TutorialLessonData.GOAL_SAFE_KILL:
			if not _attempt_hit:
				_succeed()
		TutorialLessonData.GOAL_RUSH_KILL:
			if _game.is_rush_active():
				_succeed()


func _on_dash_resolved(kills: int, ended_by: StringName) -> void:
	if _phase != Phase.DEMO and _phase != Phase.TRY:
		return
	if ended_by == &"wall" and _lesson.drops_shards:
		_game.sweep_shards()
	if _phase != Phase.TRY or _retry_timer >= 0.0:
		return
	match _lesson.goal:
		TutorialLessonData.GOAL_WALL_DASH:
			if ended_by == &"wall":
				_succeed()
			return
		TutorialLessonData.GOAL_CHAIN:
			if kills >= _lesson.goal_count:
				_succeed()
				return
		TutorialLessonData.GOAL_BOSS:
			return
	if ended_by != &"wall":
		return
	var live: int = _game.debug_live_enemy_count()
	match _lesson.goal:
		TutorialLessonData.GOAL_UPGRADE:
			if live == 0:
				# Every soul reaped: top the bar up; the lesson's calm moment
				# slides the cards up once the Wisp rests with its combo run out.
				_game.set_experience_share(1.0)
				_game.request_upgrade_calm_moment()
				return
		TutorialLessonData.GOAL_RUSH_KILL:
			if _game.is_rush_active():
				if live == 0:
					_spawn_rush_targets()
				return
	if _lesson.retry_on_miss or live == 0:
		_schedule_retry(_catalog.retry_caption)


func _on_player_damaged(current_health: int) -> void:
	# The tutorial never ends in death: refill after the hit reads, at once if one more would kill.
	if current_health <= 1:
		_game.refill_health()
	else:
		_refill_timer = _catalog.refill_delay
	if _phase == Phase.TRY and _lesson.goal == TutorialLessonData.GOAL_SAFE_KILL:
		_attempt_hit = true
		_schedule_retry(_catalog.hit_caption)


func _on_upgrade_chosen(_mutation_id: StringName) -> void:
	if _lesson != null and _lesson.goal == TutorialLessonData.GOAL_UPGRADE:
		_succeed()


func _on_rush_started() -> void:
	if _phase == Phase.TRY and _lesson.goal == TutorialLessonData.GOAL_RUSH_KILL:
		_spawn_rush_targets()


func _on_boss_defeated() -> void:
	if _lesson != null and _lesson.goal == TutorialLessonData.GOAL_BOSS:
		_succeed()


func _spawn_rush_targets() -> void:
	for position: Vector2 in _lesson.rush_positions:
		_game.spawn_scripted_enemy(_lesson.enemy_kind, position)
