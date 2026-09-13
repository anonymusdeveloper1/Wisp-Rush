extends SceneTree
## Every Rift's boss resolves to a real variant, escalates in toughness, and swaps its atlas.

const REAPER_SCENE: PackedScene = preload("res://scenes/bosses/reaper_boss.tscn")
const RIFTS: RiftCatalog = preload("res://data/rifts/default_catalog.tres")
## Animations the phase machine plays; a variant missing any of these would freeze mid-encounter.
const REQUIRED_ANIMATIONS: Array[StringName] = [
	&"idle", &"arrival", &"appear", &"windup", &"strike",
	&"cast", &"vanish", &"exposed", &"hit", &"stagger", &"defeated",
]

var _failures: int = 0


func _init() -> void:
	call_deferred(&"_run")


func _fail(message: String) -> void:
	_failures += 1
	push_error("boss_variants: %s" % message)


func _run() -> void:
	var variants: Dictionary = GameWorld.BOSS_VARIANTS

	# Every Rift must name a boss that actually exists.
	for rift: RiftData in RIFTS.load_rifts():
		if not variants.has(rift.boss_id):
			_fail("%s names unknown boss %s" % [rift.rift_id, rift.boss_id])

	var seen_ids: Dictionary = {}
	for key: StringName in variants:
		var data := variants[key] as BossData
		if data == null:
			_fail("%s is not a BossData" % key)
			continue
		for failure: String in data.validate():
			_fail("%s: %s" % [key, failure])
		if data.boss_id != key:
			_fail("%s is registered under the wrong key" % data.boss_id)
		if seen_ids.has(data.display_name):
			_fail("duplicate boss name %s" % data.display_name)
		seen_ids[data.display_name] = true
		# A supplied atlas must cover every animation the phase machine plays.
		if data.frames != null:
			for anim: StringName in REQUIRED_ANIMATIONS:
				if not data.frames.has_animation(anim):
					_fail("%s atlas is missing the %s animation" % [key, anim])

	# Toughness must climb with the Rift ladder.
	var previous_health: int = 0
	for rift: RiftData in RIFTS.load_rifts():
		var data := variants.get(rift.boss_id) as BossData
		if data == null or data.tuning == null:
			continue
		if data.tuning.base_health < previous_health:
			_fail("%s boss is weaker than the Rift before it (%d < %d)" % [
				rift.rift_id, data.tuning.base_health, previous_health,
			])
		previous_health = data.tuning.base_health

	_check_live_swap(variants)

	if _failures == 0:
		print("boss_variants: %d variants, atlases, escalation and live swap validated"
			% variants.size())
	quit(_failures)


func _check_live_swap(variants: Dictionary) -> void:
	# Applying a variant must actually change the running boss, not just its data.
	var boss := REAPER_SCENE.instantiate() as ReaperBoss
	root.add_child(boss)
	var sprite := boss.get_node("Sprite") as AnimatedSprite2D
	var original: SpriteFrames = sprite.sprite_frames

	var choir := variants.get(&"hollow_choir") as BossData
	boss.configure_variant(choir)
	if sprite.sprite_frames == original:
		_fail("applying the Hollow Choir did not swap the atlas")
	if boss.tuning != choir.tuning:
		_fail("applying the Hollow Choir did not swap the tuning")

	# A variant with no atlas keeps whatever frames it already has, rather than clearing them.
	var ascended := variants.get(&"reaper_ascended") as BossData
	var before: SpriteFrames = sprite.sprite_frames
	boss.configure_variant(ascended)
	if sprite.sprite_frames != before:
		_fail("an atlas-less variant cleared the animation set")
	if sprite.modulate == Color.WHITE:
		_fail("the Ascended recolour did not tint the sprite")

	# A null variant must be ignored rather than crashing or wiping state.
	boss.configure_variant(null)
	if boss.tuning == null:
		_fail("a null variant wiped the tuning")
	boss.queue_free()
