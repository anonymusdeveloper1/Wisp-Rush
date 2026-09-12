extends SceneTree
## Command-line checks for clamped health, healing and one-shot depletion behaviour.


func _init() -> void:
	call_deferred(&"_run_checks")


func _run_checks() -> void:
	var failures: int = 0
	var depletion_count: Array[int] = [0]
	var health := HealthComponent.new()
	root.add_child(health)
	health.depleted.connect(func() -> void: depletion_count[0] += 1)
	health.configure(3)
	if health.get_current_health() != 3:
		failures += 1
	if not health.apply_damage(1) or health.get_current_health() != 2:
		failures += 1
	if not health.apply_damage(99) or health.get_current_health() != 0:
		failures += 1
	health.apply_damage(1)
	if depletion_count[0] != 1:
		failures += 1
	if not health.heal(1) or health.get_current_health() != 1:
		failures += 1
	if not health.apply_damage(1) or depletion_count[0] != 2:
		failures += 1
	if failures == 0:
		print("health_component: 6 checks passed")
	else:
		push_error("health_component: %d checks failed" % failures)
	health.queue_free()
	quit(failures)
