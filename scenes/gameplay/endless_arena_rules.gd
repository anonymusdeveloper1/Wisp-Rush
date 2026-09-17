class_name EndlessArenaRules
extends ArenaRules
## Arena rules for Endless and the daily run: the shared floor template under a skin, no rule
## twist, seeded rosters and bosses from a pool, and difficulty that climbs every boss cycle
## (ADR-0013, ADR-0014).
##
## Picks are pure functions of the run seed and the wave or boss index, so the same seed always
## plays the same rosters and bosses, and two picks in a row never repeat while the pool has two or
## more.

## Salt that separates boss picks from roster picks for the same seed.
const BOSS_SALT: int = 7919

var _catalog: EndlessCatalog
var _skin: ArenaSkinData
var _roster_rifts: Array[RiftData] = []
var _boss_ids: Array[StringName] = []
## Memoised picks: wave -> roster index, and boss index -> boss pool index, for one seed.
var _roster_picks: Dictionary[int, int] = {}
var _boss_picks: Dictionary[int, int] = {}
var _picks_seed: int = 0


func _init(
	catalog: EndlessCatalog,
	skin: ArenaSkinData,
	roster_rifts: Array[RiftData],
	boss_ids: Array[StringName],
) -> void:
	_catalog = catalog
	_skin = skin
	for rift: RiftData in roster_rifts:
		if rift != null:
			_roster_rifts.append(rift)
	for boss_id: StringName in boss_ids:
		if not boss_id.is_empty() and boss_id not in _boss_ids:
			_boss_ids.append(boss_id)
	if _boss_ids.is_empty():
		_boss_ids.append(&"reaper")


func get_background() -> Texture2D:
	return _skin.load_background() if _skin != null else null


func get_scenery() -> ArenaSceneryData:
	return _skin.scenery if _skin != null else null


func get_floor_polygon() -> PackedVector2Array:
	return _catalog.floor_polygon if _catalog != null else PackedVector2Array()


func get_boss_wave_interval() -> int:
	if _tuning() == null:
		return DEFAULT_BOSS_WAVE_INTERVAL
	return maxi(1, _tuning().boss_wave_interval)


func get_threat_multiplier(cycle: int) -> float:
	return _tuning().get_threat_multiplier(cycle) if _tuning() != null else 1.0


func get_enemy_speed_scale(cycle: int) -> float:
	return _tuning().get_speed_scale(cycle) if _tuning() != null else 1.0


func substitute_enemy(base_kind: StringName, wave: int, run_seed: int) -> StringName:
	var rift: RiftData = get_roster_rift(wave, run_seed)
	return rift.substitute_enemy(base_kind) if rift != null else base_kind


func get_roster_name(wave: int, run_seed: int) -> String:
	var rift: RiftData = get_roster_rift(wave, run_seed)
	return rift.display_name if rift != null else ""


func get_boss_id(boss_index: int, run_seed: int) -> StringName:
	_sync_seed(run_seed)
	var index: int = _pick(_boss_picks, maxi(0, boss_index), _boss_ids.size(), run_seed + BOSS_SALT)
	return _boss_ids[index]


func get_skin_id() -> StringName:
	return _skin.skin_id if _skin != null else &""


## Rift whose roster `wave` uses; a boss wave keeps the roster of the wave before it.
func get_roster_rift(wave: int, run_seed: int) -> RiftData:
	if _roster_rifts.is_empty():
		return null
	_sync_seed(run_seed)
	var roster_wave: int = maxi(1, wave)
	var interval: int = get_boss_wave_interval()
	while roster_wave > 1 and roster_wave % interval == 0:
		roster_wave -= 1
	return _roster_rifts[_pick_roster(roster_wave, run_seed)]


## Arena skin the run shows.
func get_skin() -> ArenaSkinData:
	return _skin


## Endless tuning for this run (continuous spawning, cycles).
func get_tuning() -> EndlessTuning:
	return _tuning()


func _tuning() -> EndlessTuning:
	return _catalog.tuning if _catalog != null else null


func _sync_seed(run_seed: int) -> void:
	if run_seed != _picks_seed:
		_picks_seed = run_seed
		_roster_picks.clear()
		_boss_picks.clear()


## Roster index of non-boss `wave`, never equal to the previous non-boss wave's pick.
##
## Walks forward from wave 1 (memoised), so deep waves never recurse.
func _pick_roster(wave: int, run_seed: int) -> int:
	if _roster_picks.has(wave):
		return _roster_picks[wave]
	var interval: int = get_boss_wave_interval()
	var previous: int = -1
	for step_wave: int in range(1, wave + 1):
		if step_wave > 1 and step_wave % interval == 0 and step_wave != wave:
			continue
		if not _roster_picks.has(step_wave):
			_roster_picks[step_wave] = _seeded_index(
				run_seed, step_wave, _roster_rifts.size(), previous
			)
		previous = _roster_picks[step_wave]
	return _roster_picks[wave]


## Pool index of the `index`-th pick in `picks`, never equal to the pick before it.
func _pick(picks: Dictionary[int, int], index: int, count: int, run_seed: int) -> int:
	var previous: int = -1
	for step: int in range(0, index + 1):
		if not picks.has(step):
			picks[step] = _seeded_index(run_seed, step, count, previous)
		previous = picks[step]
	return picks[index]


static func _seeded_index(run_seed: int, salt: int, count: int, previous: int) -> int:
	if count <= 1:
		return 0
	var random := RandomNumberGenerator.new()
	random.seed = run_seed ^ (salt * 2654435761)
	var index: int = random.randi_range(0, count - 1)
	if index == previous:
		index = (index + 1 + random.randi_range(0, count - 2)) % count
	return index
