extends SceneTree
## Checks arrival safety and one-, two- and three-hit durability across regular enemy families.

const SOUL: PackedScene = preload("res://scenes/enemies/soul_wisp.tscn")
const WRAITH: PackedScene = preload("res://scenes/enemies/shard_wraith.tscn")
const MOTE: PackedScene = preload("res://scenes/enemies/bone_mote.tscn")


func _init() -> void:
	call_deferred(&"_run_checks")


func _run_checks() -> void:
	var failures: int = 0
	var kills: Array[String] = []
	var soul := SOUL.instantiate() as EnemyActor
	var wraith := WRAITH.instantiate() as EnemyActor
	var mote := MOTE.instantiate() as EnemyActor
	for enemy: EnemyActor in [soul, wraith, mote]:
		enemy.movement_enabled = false
		root.add_child(enemy)
		enemy.set_arena_rect(Rect2(Vector2.ZERO, Vector2(1080.0, 1920.0)))
		enemy.killed.connect(
			func(killed_enemy: EnemyActor, _position: Vector2, _score: int, _xp: int, _event: int) -> void:
				kills.append(killed_enemy.name)
		)
	await create_timer(0.72).timeout
	if not soul.is_contact_active() or not wraith.is_contact_active() or not mote.is_contact_active():
		failures += 1
		push_error("enemy_families: an arrival telegraph did not become active")
	soul.try_direct_hit(1, 1)
	if not wraith.try_direct_hit(1, 2) or wraith.get_current_health() != 1:
		failures += 1
	if wraith.try_direct_hit(1, 2) or not wraith.try_direct_hit(1, 3):
		failures += 1
	for event_id: int in [4, 5, 6]:
		mote.try_direct_hit(1, event_id)
	if kills.size() != 3:
		failures += 1
		push_error("enemy_families: expected one lethal signal per family")
	if failures == 0:
		print("enemy_families: telegraphs and 1/2/3-hit durability passed")
	quit(failures)
