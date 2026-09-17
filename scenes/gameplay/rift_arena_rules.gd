class_name RiftArenaRules
extends ArenaRules
## Arena rules for one story level of a Rift: its art floor, rule twist, roster and boss.

## Boss cadence divisor under Reaper's Court's `boss_rush` twist (a boss every half level).
const BOSS_RUSH_CADENCE_DIVISOR: int = 2

var _rift: RiftData
var _level: int = 1


func _init(rift: RiftData, level: int) -> void:
	_rift = rift
	_level = maxi(1, level)


func get_background() -> Texture2D:
	return _rift.background


func get_floor_polygon() -> PackedVector2Array:
	return _rift.floor_polygon if _rift.has_floor_polygon() else PackedVector2Array()


func get_rule_key() -> StringName:
	return _rift.rule_key


func get_boss_wave_interval() -> int:
	var waves: int = get_level_waves()
	if _rift.rule_key == &"boss_rush":
		return maxi(1, waves / BOSS_RUSH_CADENCE_DIVISOR)
	return waves


func get_level_waves() -> int:
	return maxi(1, _rift.waves_per_level)


func is_final_boss_wave(wave: int) -> bool:
	return wave >= get_level_waves()


func get_threat_multiplier(_cycle: int) -> float:
	return _rift.get_threat_multiplier(_level)


func get_enemy_speed_scale(_cycle: int) -> float:
	return _rift.enemy_speed_scale


func substitute_enemy(base_kind: StringName, _wave: int, _run_seed: int) -> StringName:
	return _rift.substitute_enemy(base_kind)


func get_boss_id(_boss_index: int, _run_seed: int) -> StringName:
	return _rift.boss_id


func get_rift_id() -> StringName:
	return _rift.rift_id
