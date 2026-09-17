extends SceneTree
## Devlog footage: Endless arena skins shown back to back with their live scenery, no enemies, no HUD.
##
## Usage (repo root; a real window, not headless):
##   WISP_ISOLATED_SAVE=1 "$GODOT" --path . --resolution 540x960 \
##     --write-movie "$PWD/video/footage/arena_showcase.avi" \
##     --script res://tools/godot/render_arena_showcase.gd -- skins=eclipse_sanctum,dragon_skull_throne seconds=5
## Each skin gets a real GameWorld (Endless profile) whose run start is held (`hold_start`), so no waves
## spawn while the arena's scenery shader and particles animate. Options: `skins=` (default every
## Legendary and Mythic skin, catalog order), `seconds=` per skin (default 5), `hud=1` keeps the HUD,
## `wisp=0` hides the Wisp, `settle=` frames skipped after each build (default 20), `quality=` MJPEG
## quality (default 0.85), `events=` log path. The JSON-lines event log next to the movie marks
## `segment_start` / `segment_end` (movie seconds) per skin: cut on those. Movie audio is silent.

const DevlogBot = preload("res://tools/godot/devlog_bot.gd")
const Clip = preload("res://tools/godot/render_gameplay_clip.gd")
const GAME_WORLD_SCENE: PackedScene = preload("res://scenes/gameplay/game_world.tscn")
const ENDLESS_CATALOG: EndlessCatalog = preload("res://data/endless/default_endless_catalog.tres")
const RIFT_CATALOG: RiftCatalog = preload("res://data/rifts/default_catalog.tres")
const FORM_CATALOG: FormCatalog = preload("res://data/forms/default_catalog.tres")
const FPS: float = 60.0

var _options: Dictionary = {}
var _events: FileAccess


func _init() -> void:
	_options = DevlogBot.parse_options(OS.get_cmdline_user_args())
	ProjectSettings.set_setting(
		"editor/movie_writer/mjpeg_quality",
		clampf(DevlogBot.option_float(_options, "quality", 0.85), 0.1, 1.0),
	)
	call_deferred(&"_run")


func _run() -> void:
	_events = Clip.open_event_log(str(_options.get("events", "")))
	var seconds: float = DevlogBot.option_float(_options, "seconds", 5.0)
	var settle: int = DevlogBot.option_int(_options, "settle", 20)
	var show_hud: bool = DevlogBot.option_bool(_options, "hud", false)
	var show_wisp: bool = DevlogBot.option_bool(_options, "wisp", true)
	var rifts: Array[RiftData] = []
	for rift_id: StringName in ContentUnlocks.get_endless_roster_rift_ids(RIFT_CATALOG):
		rifts.append(RIFT_CATALOG.get_rift(rift_id))
	for skin: ArenaSkinData in _wanted_skins():
		var game := GAME_WORLD_SCENE.instantiate() as GameWorld
		game.auto_pause_on_focus_loss = false
		game.configure_run(RunProfile.endless(
			ENDLESS_CATALOG, skin, rifts, ContentUnlocks.get_endless_boss_ids(RIFT_CATALOG),
			FORM_CATALOG.get_form(&"void"),
		))
		# A held start never begins waves, so the arena stays empty while the scenery animates.
		game.hold_start()
		root.add_child(game)
		(game.get_node("HUD") as CanvasLayer).visible = show_hud
		game._player.visible = show_wisp
		for _frame: int in settle:
			await process_frame
		_log(&"segment_start", {"skin": skin.skin_id, "tier": skin.get_tier_name()})
		print("[showcase] %.2f %s" % [_now(), skin.skin_id])
		var until: float = _now() + seconds
		while _now() < until:
			await process_frame
		_log(&"segment_end", {"skin": skin.skin_id})
		root.remove_child(game)
		game.free()
		await process_frame
	if _events != null:
		_events.close()
	quit(0)


func _wanted_skins() -> Array[ArenaSkinData]:
	var ids: PackedStringArray = str(_options.get("skins", "")).split(",", false)
	var skins: Array[ArenaSkinData] = []
	if ids.is_empty():
		for skin: ArenaSkinData in ENDLESS_CATALOG.skins:
			if skin.tier >= ArenaSkinData.Tier.LEGENDARY:
				skins.append(skin)
		return skins
	for id: String in ids:
		var skin: ArenaSkinData = ENDLESS_CATALOG.get_skin(StringName(id.strip_edges()))
		if skin != null and String(skin.skin_id) == id.strip_edges():
			skins.append(skin)
		else:
			push_warning("render_arena_showcase: unknown skin %s" % id)
	return skins


func _log(event: StringName, fields: Dictionary = {}) -> void:
	Clip.write_event(_events, event, fields, _now(), 0.0)


func _now() -> float:
	return Clip.movie_seconds(FPS)
