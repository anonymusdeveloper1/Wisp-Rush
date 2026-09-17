extends SceneTree
## Performance benchmark (not a pass/fail test): a crowded run — enemies, formations, kills,
## pickups, pooled VFX and shake — reporting whole-frame times after a warm-up.
##
## Usage (optional user arg = enemy count kept alive, default 45):
##   WISP_ISOLATED_SAVE=1 Godot --path . --resolution 390x844 --disable-vsync \
##     --script res://tools/godot/bench_stress.gd -- 45
## Run it windowed with vsync off: headless runs are frame-capped (~7 ms) and only prove the
## scenario runs without errors. The device budget is 16.6 ms per frame (60 FPS); expect phones
## to be several times slower than a desktop.

const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const FRAMES: int = 900
const WARMUP_FRAMES: int = 60
const BUDGET_MS: float = 16.6
const DEFAULT_ENEMY_TARGET: int = 45
const KINDS: Array[StringName] = [&"soul_wisp", &"shard_wraith", &"bone_mote"]


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	var enemy_target: int = int(user_args[0]) if not user_args.is_empty() else DEFAULT_ENEMY_TARGET
	var game := GAME_WORLD_SCENE.instantiate() as GameWorld
	game.run_seed = 99
	game.auto_pause_on_focus_loss = false
	root.add_child(game)
	await process_frame
	game._player.increase_maximum_health(60, 60)
	var random := RandomNumberGenerator.new()
	random.seed = 7
	var frame_ms := PackedFloat32Array()
	var warmup_max_ms: float = 0.0
	var over_budget: int = 0
	var peak_enemies: int = 0
	var last_usec: int = Time.get_ticks_usec()
	for frame: int in FRAMES:
		if game._run_over:
			break
		var enemies: Array[Node] = game._enemy_layer.get_children()
		peak_enemies = maxi(peak_enemies, enemies.size())
		if enemies.size() < enemy_target:
			var spot := Vector2(random.randf_range(0.15, 0.85), random.randf_range(0.15, 0.85))
			game._spawn_enemy(
				KINDS[frame % KINDS.size()],
				game._arena_rect.position + game._arena_rect.size * spot,
				true,
			)
		if frame % 12 == 0 and not enemies.is_empty():
			var target := enemies[random.randi() % enemies.size()] as EnemyActor
			if target != null and target.is_contact_active():
				target.try_direct_hit(5, 5000 + frame)
		if frame % 45 == 0:
			game.add_trauma(0.4)
		await process_frame
		var now_usec: int = Time.get_ticks_usec()
		var elapsed_ms: float = float(now_usec - last_usec) / 1000.0
		last_usec = now_usec
		if frame < WARMUP_FRAMES:
			warmup_max_ms = maxf(warmup_max_ms, elapsed_ms)
			continue
		frame_ms.append(elapsed_ms)
		if elapsed_ms > BUDGET_MS:
			over_budget += 1
	var sorted := frame_ms.duplicate()
	sorted.sort()
	var total: float = 0.0
	for value: float in sorted:
		total += value
	var count: int = maxi(1, sorted.size())
	print(
		"bench_stress: %d enemies | %d frames after %d warm-up | avg %.2f / p95 %.2f / max %.2f ms | over %.1f ms: %d | warm-up max %.2f ms | peak enemies %d | kills %d | orphans %d"
		% [
			enemy_target,
			sorted.size(),
			WARMUP_FRAMES,
			total / float(count),
			sorted[mini(sorted.size() - 1, int(float(sorted.size()) * 0.95))] if not sorted.is_empty() else 0.0,
			sorted[-1] if not sorted.is_empty() else 0.0,
			BUDGET_MS,
			over_budget,
			warmup_max_ms,
			peak_enemies,
			game.get_total_kills(),
			int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		]
	)
	game.queue_free()
	await process_frame
	quit(0)
