extends SceneTree
## Checks crystal blocking, bloom safe/danger cycling and four-point blade geometry.

const CRYSTAL: PackedScene = preload("res://scenes/hazards/split_void_crystal.tscn")
const BLOOM: PackedScene = preload("res://scenes/hazards/spike_bloom.tscn")
const RING: PackedScene = preload("res://scenes/hazards/blade_ring.tscn")


func _init() -> void:
	call_deferred(&"_run_checks")


func _run_checks() -> void:
	var failures: int = 0
	var crystal := CRYSTAL.instantiate() as HazardActor
	var bloom := BLOOM.instantiate() as HazardActor
	var ring := RING.instantiate() as HazardActor
	for hazard: HazardActor in [crystal, bloom, ring]:
		root.add_child(hazard)
		hazard.set_viewport_width(1080.0)
	await create_timer(0.76).timeout
	if not crystal.blocks_dash() or crystal.get_blocking_radius() <= 0.0:
		failures += 1
		push_error("hazards: crystal did not become a solid dash blocker")
	if not bloom.get_dangerous_circles().is_empty():
		failures += 1
		push_error("hazards: bloom was dangerous during its safe state")
	if ring.get_dangerous_circles().size() != 4:
		failures += 1
		push_error("hazards: blade ring did not expose four blade-tip circles")
	await create_timer(1.7).timeout
	if bloom.get_dangerous_circles().size() != 1:
		failures += 1
		push_error("hazards: bloom did not enter its visibly dangerous state")
	if failures == 0:
		print("hazards: crystal, bloom and blade-ring states passed")
	quit(failures)
