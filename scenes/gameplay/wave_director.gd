class_name WaveDirector
extends Node
## Deterministic endless-wave state machine that spends budget on authored formations.

## Requests one formation and its procedural variant from GameWorld.
signal formation_requested(formation: FormationData, mirrored: bool, quarter_turns: int)
## Emitted when a new one-based wave and threat budget begin.
signal wave_started(wave: int, threat_budget: int)

## Pacing and budget values for this run.
@export var tuning: WaveTuning
## Ordered formation catalog used for validated selection.
@export var catalog: FormationCatalog

var _formations: Array[FormationData] = []
var _random := RandomNumberGenerator.new()
var _running: bool = false
var _suspended: bool = false
var _current_wave: int = 0
var _difficulty_tier: int = 0
var _wave_remaining: float = 0.0
var _wave_budget: int = 0
var _spent_budget: int = 0
var _formation_gap_remaining: float = 0.0
var _current_health: int = 3
var _maximum_health: int = 3
var _total_upgrade_levels: int = 0
## Threat-budget multiplier for the active Rift and level (RiftData.get_threat_multiplier).
var _rift_threat_multiplier: float = 1.0


func _ready() -> void:
	assert(tuning != null, "WaveDirector requires WaveTuning")
	assert(catalog != null, "WaveDirector requires FormationCatalog")
	_formations = catalog.load_formations()
	var failures: PackedStringArray = catalog.validate()
	assert(failures.is_empty(), "Invalid formation catalog: %s" % "; ".join(failures))


## Resets deterministic selection and begins wave one.
func start(seed: int) -> void:
	_random.seed = seed
	_running = true
	_suspended = false
	_current_wave = 0
	_difficulty_tier = 0
	_begin_next_wave()


## Advances timers and requests an affordable formation only when live threat is zero.
func advance(delta: float, live_threat: int) -> void:
	if not _running or _suspended:
		return
	_wave_remaining = maxf(0.0, _wave_remaining - delta)
	_formation_gap_remaining = maxf(0.0, _formation_gap_remaining - delta)
	if _wave_remaining <= 0.0 and live_threat <= 0:
		_begin_next_wave()
		return
	if live_threat > 0 or _formation_gap_remaining > 0.0 or _spent_budget >= _wave_budget:
		return
	_request_affordable_formation()


## Scales every wave budget for the active Rift and level; call before start() and on level up.
func set_rift_threat_multiplier(multiplier: float) -> void:
	_rift_threat_multiplier = clampf(multiplier, 0.25, 4.0)


## Supplies health and upgrade context used to soften unsafe low-health requests.
func set_run_context(current_health: int, maximum_health: int, total_upgrade_levels: int) -> void:
	_current_health = maxi(0, current_health)
	_maximum_health = maxi(1, maximum_health)
	_total_upgrade_levels = maxi(0, total_upgrade_levels)


## Suspends wave timers and formation requests for a boss encounter.
func suspend_for_boss() -> void:
	_suspended = true


## Raises post-boss difficulty and begins the wave after the suspended boss marker.
func resume_after_boss() -> void:
	if not _running or not _suspended:
		return
	_difficulty_tier += 1
	_suspended = false
	_begin_next_wave()


## Returns the active one-based wave number.
func get_current_wave() -> int:
	return _current_wave


## Returns normalized elapsed progress through the current timed wave.
func get_wave_progress() -> float:
	return 1.0 - (_wave_remaining / maxf(tuning.wave_duration, 0.001))


## Returns budget not yet assigned to a formation in the current wave.
func get_remaining_budget() -> int:
	return maxi(0, _wave_budget - _spent_budget)


## Returns the number of completed Reaper encounters affecting wave tuning.
func get_difficulty_tier() -> int:
	return _difficulty_tier


## Returns whether a boss currently owns the encounter flow.
func is_suspended() -> bool:
	return _suspended


func _begin_next_wave() -> void:
	_current_wave += 1
	_wave_remaining = tuning.wave_duration
	var base_budget: int = tuning.base_threat_budget + roundi(
		float(_current_wave - 1) * tuning.threat_growth_per_wave
	) + _difficulty_tier * tuning.post_boss_budget_bonus
	_wave_budget = maxi(1, roundi(float(base_budget) * _rift_threat_multiplier))
	_spent_budget = 0
	_formation_gap_remaining = 0.0
	wave_started.emit(_current_wave, _wave_budget)
	print("[WaveDirector] wave=%d budget=%d" % [_current_wave, _wave_budget])


func _request_affordable_formation() -> void:
	var remaining_budget: int = _wave_budget - _spent_budget
	var eligible: Array[FormationData] = []
	for formation: FormationData in _formations:
		var low_health: bool = _current_health * 3 <= _maximum_health
		if low_health and not formation.hazard_kind.is_empty():
			continue
		var upgrade_allowance: int = mini(2, floori(float(_total_upgrade_levels) / 3.0))
		if (
			formation.minimum_wave <= _current_wave + upgrade_allowance
			and formation.threat_cost <= remaining_budget
		):
			eligible.append(formation)
	if eligible.is_empty():
		_spent_budget = _wave_budget
		return
	var formation: FormationData = eligible[_random.randi_range(0, eligible.size() - 1)]
	var mirrored: bool = formation.allow_mirror and _random.randf() >= 0.5
	var quarter_turns: int = _random.randi_range(0, 3) if formation.allow_rotation else 0
	_spent_budget += formation.threat_cost
	_formation_gap_remaining = tuning.formation_gap * pow(
		tuning.post_boss_gap_multiplier,
		float(_difficulty_tier),
	)
	formation_requested.emit(formation, mirrored, quarter_turns)
	print(
		"[WaveDirector] formation=%s variant=%d/%s remaining=%d"
		% [formation.formation_id, quarter_turns, mirrored, get_remaining_budget()]
	)
