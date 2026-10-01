class_name ArenaSkinData
extends Resource
## One purchasable Endless background.
##
## Arenas painted to the contract share one floor (`EndlessCatalog.floor_rect` / `floor_polygon`,
## docs/guides/arena_art.md, ADR-0017), so they change only what a run looks like. An arena whose
## painting has its floor elsewhere carries its own [member floor_rect] (ADR-0020, owner 2026-09-30:
## the Stitched Doll Jungle is kept as painted); while it is equipped the walls follow its frame.
## The art comes from `tools/art/make_arena.py`. A layered or 3D arena (ADR-0021, ADR-0023) also
## names the scene a run shows instead of the painting ([member visual_scene_path]); its background
## is then the Shop's still of it.

## Shop rarity. Sets the price band, the card label and the animated scenery level
## (Legendary: calm living touches, Mythic: rich set pieces, Simple and Rare: none).
enum Tier { SIMPLE, RARE, LEGENDARY, MYTHIC }

## Player-facing tier names, indexed by `Tier`.
const TIER_NAMES: PackedStringArray = ["SIMPLE", "RARE", "LEGENDARY", "MYTHIC"]

## Stable identifier stored in the save (`owned_arena_skins`, `equipped_arena_skin`).
@export var skin_id: StringName
## Player-facing arena name.
@export var display_name: String
## Short flavour text for the Shop.
@export_multiline var description: String
## Shop rarity (price band, card label, scenery level).
@export var tier: Tier = Tier.SIMPLE
## Full-bleed background at `EndlessCatalog.BACKGROUND_SIZE`, painted to the arena contract. A path,
## loaded only when a run or a Shop card needs it (`load_background()`), never with the catalog.
@export_file("*.png") var background_path: String
## Small copy of the background for Shop cards (tools/art/extract_endless.py).
@export var thumbnail: Texture2D
## Rift Points price; zero for the default skin.
@export_range(0, 100000, 1) var price: int = 0
## Card accent colour; use a Palette constant, never a raw literal.
@export var accent: Color = Color.WHITE
## Animated scenery over the painted art (`ArenaAmbience`); null below Legendary, required from it.
@export var scenery: ArenaSceneryData
## Stand-in art that must never ship; `EndlessCatalog.validate()` rejects it.
@export var placeholder: bool = false
## This arena's own floor in UV of its background, as `tools/art/make_arena.py` prints it, when it is
## not painted on the shared floor. No area (the default) means the shared floor.
@export var floor_rect: Rect2 = Rect2()
## A layered or 3D arena's scene (an `ArenaVisual`, ADR-0021, ADR-0023), which a run shows instead of
## the background and takes its floor from. A path, loaded only when a run starts
## ([method load_visual_scene]); empty for a painted arena.
@export_file("*.tscn") var visual_scene_path: String = ""


## Whether this arena brings its own floor instead of the shared one.
func has_own_floor() -> bool:
	return floor_rect.has_area()


## Loads the full-size background (cached by the ResourceLoader while something holds it).
func load_background() -> Texture2D:
	if background_path.is_empty() or not ResourceLoader.exists(background_path):
		return null
	return load(background_path) as Texture2D


## Whether a run shows a layered scene for this arena rather than its background.
func has_visual_scene() -> bool:
	return not visual_scene_path.is_empty()


## Loads the layered scene, or null for a painted arena.
func load_visual_scene() -> PackedScene:
	if not has_visual_scene() or not ResourceLoader.exists(visual_scene_path):
		return null
	return load(visual_scene_path) as PackedScene


## The player-facing tier name, e.g. "MYTHIC".
func get_tier_name() -> String:
	return TIER_NAMES[clampi(tier, 0, TIER_NAMES.size() - 1)]


## Returns authoring failures for this skin. `check_background` loads the full-size texture
## to check its size; pass false where that memory matters.
func validate(check_background: bool = true) -> PackedStringArray:
	var failures := PackedStringArray()
	if skin_id.is_empty():
		failures.append("skin id is empty")
	if display_name.is_empty():
		failures.append("display name is empty")
	if background_path.is_empty() or not ResourceLoader.exists(background_path):
		failures.append("background %s is missing" % background_path)
	elif check_background:
		var background: Texture2D = load_background()
		if background == null or Vector2i(background.get_size()) != EndlessCatalog.BACKGROUND_SIZE:
			failures.append("background is %s, expected %s" % [
				Vector2i(background.get_size()) if background != null else Vector2i.ZERO,
				EndlessCatalog.BACKGROUND_SIZE,
			])
	if thumbnail == null:
		failures.append("thumbnail is missing")
	if price < 0:
		failures.append("price is negative")
	if has_own_floor() and not Rect2(0.0, 0.0, 1.0, 1.0).encloses(floor_rect):
		failures.append("own floor %s is not inside UV space" % floor_rect)
	if has_visual_scene() and not ResourceLoader.exists(visual_scene_path):
		failures.append("layered scene %s is missing" % visual_scene_path)
	if placeholder:
		failures.append("placeholder art must not ship")
	if scenery != null and tier < Tier.LEGENDARY:
		failures.append("animated scenery is reserved for Legendary and Mythic skins")
	elif scenery == null and tier >= Tier.LEGENDARY:
		failures.append("Legendary and Mythic skins need animated scenery")
	if scenery != null:
		for failure: String in scenery.validate():
			failures.append("scenery: %s" % failure)
	return failures
