extends SceneTree
## Generates res://assets/ui/theme/wisp_theme.tres, the ornament scenes, the nearest-filtered texture wrappers and the pixel font from the pixel UI kit.
##
## Pipeline (repo root): python assets/ui/theme/tools/build_theme_textures.py, then
## Godot --headless --path . --import, then
## Godot --headless --path . --script res://assets/ui/theme/tools/build_wisp_theme.gd
## Every PNG in textures/ and icons/ gets a CanvasTexture .tres beside it with nearest filtering:
## the theme, scenes and scripts use the .tres, so the pixel art stays crisp while the project-wide
## default filter stays linear for everything else. The theme is generated, never hand-edited, so
## nine-patch margins always match textures/slices.json. Colours come from Palette
## (scripts/utils/palette.gd). See docs/systems/ui_design_system.md.
##
## The pixel font (owner, 2026-09-24) is Pixelify Sans, whose font pixel is 1/11 of the em. It is
## built here from the gdignored source TTF into a FontFile with no anti-aliasing, no hinting and
## whole-pixel glyph positions. It is saved beside the source and set as the theme's default font.
## Every font size is a multiple of 11, so one font pixel covers a whole number of design pixels
## (22 = 2 px … 66 = 6 px). The engine's default font is its fallback for the two symbols Pixelify
## lacks (→ and ✓).

const Pal := preload("res://scripts/utils/palette.gd")

const THEME_DIR := "res://assets/ui/theme/"
const TEX_DIR := THEME_DIR + "textures/"
const ICON_DIR := THEME_DIR + "icons/"
const THEME_PATH := THEME_DIR + "wisp_theme.tres"
const ORNAMENT_DIR := THEME_DIR + "ornaments/"
const FONT_SOURCE := "res://assets/fonts/pixelify_sans/source/PixelifySans.ttf"
const FONT_PATH := "res://assets/fonts/pixelify_sans/pixelify_sans.res"
## Pixelify Sans draws one font pixel per 11 units of size, so sizes are multiples of 11. Each was
## the old size × 1.06 (Pixelify is ~6 % narrower than the default font) snapped to that grid.
const FONT_GRID := 11
const FONT_BODY := 33
const FONT_CAPTION := 33
const FONT_TITLE := 55
const FONT_VALUE := 55
const FONT_AMBER := 66
const FONT_PRIMARY := 44
const FONT_SECONDARY := 33
const FONT_SLOT := 33
const FONT_CARD := 33
const FONT_BAR := 22
const FONT_NAV := 33
## Kit glyphs are 64 px: drawn at native size in buttons (whole art pixels).
const ICON_MAX := 64
## The Shop tab row is this tall for touch; NavButton draws the 64 px kit tab centred inside it.
const NAV_ROW := 88.0
const HOVER := Color(1.12, 1.12, 1.12)
const PRESS_BRIGHT := Color(1.3, 1.3, 1.3)
## Hard drop shadow under titles and reward numbers: one art pixel (4 px) down, no blur.
const SHADOW_DROP := 4

var _slices: Dictionary = {}
var _theme: Theme
## CanvasTexture wrappers by texture name (textures/ and icons/ share one namespace).
var _wrapped: Dictionary = {}
## Content margins per panel variation, reused to position ornaments inside PanelContainers.
var _panel_margins: Dictionary = {}
## The pixel font, as saved at [constant FONT_PATH]; every font resource in the theme builds on it.
var _font: FontFile


func _initialize() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEX_DIR + "slices.json"))
	if not parsed is Dictionary:
		push_error("[ThemeBuilder] cannot read %sslices.json" % TEX_DIR)
		quit(1)
		return
	_slices = parsed
	if not (_wrap_folder(TEX_DIR) and _wrap_folder(ICON_DIR)):
		quit(1)
		return
	_font = _build_font()
	if _font == null:
		quit(1)
		return
	_theme = Theme.new()
	_theme.default_font = _font
	_theme.default_font_size = FONT_BODY
	_build_labels()
	_build_buttons()
	_build_panels()
	_build_bars()
	_build_slider()
	_build_separator()
	_build_scrollbar()
	var err := ResourceSaver.save(_theme, THEME_PATH)
	if err != OK:
		push_error("[ThemeBuilder] saving %s failed: %d" % [THEME_PATH, err])
		quit(1)
		return
	_build_ornaments()
	print("[ThemeBuilder] saved %s (%d nearest-filtered textures)" % [THEME_PATH, _wrapped.size()])
	quit(0)


# ------------------------------------------------------------------------ texture wrappers

## Wraps every PNG in [param dir] in a CanvasTexture .tres with nearest filtering.
func _wrap_folder(dir: String) -> bool:
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() != "png":
			continue
		var tex_name := file.get_basename()
		var path := dir + tex_name + ".tres"
		var diffuse := load(dir + file) as Texture2D
		if diffuse == null:
			push_error("[ThemeBuilder] %s%s is not imported; run --import first" % [dir, file])
			return false
		var wrapper: CanvasTexture = null
		if ResourceLoader.exists(path):
			wrapper = load(path) as CanvasTexture
		var is_new := wrapper == null
		if is_new:
			wrapper = CanvasTexture.new()
		wrapper.diffuse_texture = diffuse
		wrapper.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var err := ResourceSaver.save(wrapper, path)
		if err != OK:
			push_error("[ThemeBuilder] saving %s failed: %d" % [path, err])
			return false
		if is_new:
			# Bind the object to its file, so the theme and scenes reference the .tres instead of
			# embedding a copy.
			wrapper.take_over_path(path)
		_wrapped[tex_name] = wrapper
	return true


# ------------------------------------------------------------------------ helpers

func _slice(tex_name: String) -> Dictionary:
	assert(_slices.has(tex_name), "missing slice " + tex_name)
	return _slices[tex_name]


func _native_height(tex_name: String) -> float:
	return float(_slice(tex_name).size[1])


## A nine-patch StyleBoxTexture over the wrapper of textures/<name>.png (margins from slices.json).
func _tex(tex_name: String, content: Array, modulate: Color = Color.WHITE) -> StyleBoxTexture:
	var m: Array = _slice(tex_name).margins
	var sb := StyleBoxTexture.new()
	sb.texture = _wrapped[tex_name]
	sb.texture_margin_left = m[0]
	sb.texture_margin_top = m[1]
	sb.texture_margin_right = m[2]
	sb.texture_margin_bottom = m[3]
	sb.content_margin_left = content[0]
	sb.content_margin_top = content[1]
	sb.content_margin_right = content[2]
	sb.content_margin_bottom = content[3]
	sb.modulate_color = modulate
	return sb


## Content margins that make one text line of [param font_size] fill the piece's native height
## exactly, so buttons and banners are drawn at their kit size.
func _fit_line(tex_name: String, side: float, font_size: int) -> Array:
	var line_h: float = _font.get_height(font_size)
	var spare: float = maxf(0.0, _native_height(tex_name) - line_h)
	var top := floorf(spare * 0.5)
	return [side, top, side, spare - top]


## Pressed kit art is drawn one art pixel (4 px) lower, so its label moves with it.
func _pressed(content: Array) -> Array:
	return [content[0], content[1] + 4.0, content[2], content[3] - 4.0]


## A focus ring overlay (kit focus art minus normal art); Godot draws it over the current state.
func _ring(tex_name: String) -> StyleBoxTexture:
	return _tex(tex_name, [0, 0, 0, 0])


## Crisp flat box for the scrollbar (no kit piece): square corners, no anti-aliasing.
func _flat(bg: Color, content: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.anti_aliasing = false
	sb.set_content_margin_all(content)
	return sb


func _variation(type: StringName, base: StringName) -> void:
	_theme.set_type_variation(type, base)


## The pixel font with crisp rendering, saved to [constant FONT_PATH] and loaded back, so the theme
## references the file rather than embedding a copy.
func _build_font() -> FontFile:
	var font := FontFile.new()
	var err := font.load_dynamic_font(FONT_SOURCE)
	if err != OK:
		push_error("[ThemeBuilder] cannot load %s: %d" % [FONT_SOURCE, err])
		return null
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.generate_mipmaps = false
	font.multichannel_signed_distance_field = false
	# Pixelify has no → or ✓; the engine's default font draws those two.
	font.fallbacks = [ThemeDB.fallback_font]
	err = ResourceSaver.save(font, FONT_PATH)
	if err != OK:
		push_error("[ThemeBuilder] saving %s failed: %d" % [FONT_PATH, err])
		return null
	return load(FONT_PATH) as FontFile


func _font_tnum() -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = _font
	var ts := TextServerManager.get_primary_interface()
	fv.opentype_features = {ts.name_to_tag("tnum"): 1}
	return fv


## Hard one-art-pixel drop shadow (no blur) under a label type.
func _drop_shadow(type: StringName, outline: int) -> void:
	_theme.set_color(&"font_shadow_color", type, Color(Pal.OBSIDIAN, 0.9))
	_theme.set_constant(&"shadow_outline_size", type, outline)
	_theme.set_constant(&"shadow_offset_x", type, 0)
	_theme.set_constant(&"shadow_offset_y", type, SHADOW_DROP)


# ------------------------------------------------------------------------ labels

func _build_labels() -> void:
	var t := &"Label"
	_theme.set_color(&"font_color", t, Pal.SOUL_WHITE)
	_theme.set_color(&"font_outline_color", t, Pal.TEXT_OUTLINE)
	_theme.set_color(&"font_shadow_color", t, Color(0, 0, 0, 0))
	_theme.set_font_size(&"font_size", t, FONT_BODY)
	_theme.set_constant(&"outline_size", t, 0)
	_theme.set_constant(&"line_spacing", t, 2)

	# No embolden: it thickens strokes by a fraction of a pixel and blurs the grid. The spacing is
	# one font pixel at title size.
	var title_font := FontVariation.new()
	title_font.base_font = _font
	title_font.spacing_glyph = FONT_TITLE / FONT_GRID
	_variation(&"TitleLabel", t)
	_theme.set_font(&"font", &"TitleLabel", title_font)
	_theme.set_font_size(&"font_size", &"TitleLabel", FONT_TITLE)
	_theme.set_color(&"font_color", &"TitleLabel", Pal.IVORY_LIGHT)
	_theme.set_constant(&"outline_size", &"TitleLabel", 8)
	_drop_shadow(&"TitleLabel", 8)

	_variation(&"CaptionLabel", t)
	_theme.set_font_size(&"font_size", &"CaptionLabel", FONT_CAPTION)
	_theme.set_color(&"font_color", &"CaptionLabel", Pal.TEXT_MUTED)

	var tnum := _font_tnum()
	_variation(&"ValueLabel", t)
	_theme.set_font(&"font", &"ValueLabel", tnum)
	_theme.set_font_size(&"font_size", &"ValueLabel", FONT_VALUE)
	_theme.set_color(&"font_color", &"ValueLabel", Pal.SOUL_WHITE)
	_theme.set_constant(&"outline_size", &"ValueLabel", 6)

	_variation(&"AmberValueLabel", t)
	_theme.set_font(&"font", &"AmberValueLabel", tnum)
	_theme.set_font_size(&"font_size", &"AmberValueLabel", FONT_AMBER)
	_theme.set_color(&"font_color", &"AmberValueLabel", Pal.WARNING_AMBER)
	_theme.set_constant(&"outline_size", &"AmberValueLabel", 6)
	_drop_shadow(&"AmberValueLabel", 6)


# ------------------------------------------------------------------------ buttons

func _set_button(type: StringName, boxes: Dictionary, font_size: int, text: Color) -> void:
	for state: String in boxes:
		_theme.set_stylebox(StringName(state), type, boxes[state])
	_theme.set_font_size(&"font_size", type, font_size)
	for c: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color",
			&"font_hover_pressed_color", &"font_focus_color"]:
		_theme.set_color(c, type, text)
	_theme.set_color(&"font_disabled_color", type, Pal.TEXT_DISABLED)
	_theme.set_color(&"font_outline_color", type, Pal.TEXT_OUTLINE)
	for c: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_pressed_color",
			&"icon_hover_pressed_color", &"icon_focus_color"]:
		_theme.set_color(c, type, Color.WHITE)
	_theme.set_color(&"icon_disabled_color", type, Color(1, 1, 1, 0.35))
	_theme.set_constant(&"h_separation", type, 16)
	_theme.set_constant(&"icon_max_width", type, ICON_MAX)
	_theme.set_constant(&"outline_size", type, 0)


## The five kit states of a text button: normal, hover, pressed (4 px lower), disabled, focus ring.
func _kit_button(prefix: String, font_size: int, hover_art: bool, disabled: String,
		ring: String) -> Dictionary:
	var c := _fit_line(prefix + "_normal", 40.0, font_size)
	var hover := _tex(prefix + "_hover", c) if hover_art else _tex(prefix + "_normal", c, HOVER)
	var pressed := _tex(prefix + "_pressed", _pressed(c))
	return {
		"normal": _tex(prefix + "_normal", c),
		"hover": hover,
		"pressed": pressed,
		"hover_pressed": _tex(prefix + "_pressed", _pressed(c)),
		"disabled": _tex(disabled, c),
		"focus": _ring(ring),
	}


func _build_buttons() -> void:
	# Default Button = the quieter secondary tier; opt into PrimaryButton for the one main action.
	var secondary := _kit_button("button_secondary", FONT_SECONDARY, true,
			"button_secondary_disabled", "button_secondary_focus_ring")
	_set_button(&"Button", secondary, FONT_SECONDARY, Pal.SOUL_WHITE)
	_variation(&"SecondaryButton", &"Button")
	_set_button(&"SecondaryButton", secondary, FONT_SECONDARY, Pal.SOUL_WHITE)

	_variation(&"PrimaryButton", &"Button")
	_set_button(&"PrimaryButton", _kit_button("button_primary", FONT_PRIMARY, true,
			"button_primary_disabled", "button_primary_focus_ring"), FONT_PRIMARY, Pal.IVORY_LIGHT)

	_variation(&"DangerButton", &"Button")
	_set_button(&"DangerButton", _kit_button("button_danger", FONT_SECONDARY, false,
			"button_secondary_disabled", "button_secondary_focus_ring"), FONT_SECONDARY,
			Pal.AMBER_LIGHT)

	# Square icon tile (Pause, Back, Settings, Stats, the HUD upgrade button). The kit has no
	# pressed tile, so pressed brightens the normal one.
	var icon_c := [24, 24, 24, 24]
	_variation(&"IconButton", &"Button")
	_set_button(&"IconButton", {
		"normal": _tex("icon_tile_normal", icon_c),
		"hover": _tex("icon_tile_normal", icon_c, HOVER),
		"pressed": _tex("icon_tile_normal", icon_c, PRESS_BRIGHT),
		"hover_pressed": _tex("icon_tile_normal", icon_c, PRESS_BRIGHT),
		"disabled": _tex("icon_tile_disabled", icon_c),
		"focus": _ring("icon_tile_focus_ring"),
	}, FONT_SLOT, Pal.SOUL_WHITE)

	# Captioned Home tile (140 x 164, native only): icon box above the seam, caption below it.
	var tile_c := [16, 16, 16, 16]
	_variation(&"CaptionTile", &"Button")
	_set_button(&"CaptionTile", {
		"normal": _tex("caption_tile_normal", tile_c),
		"hover": _tex("caption_tile_normal", tile_c, HOVER),
		"pressed": _tex("caption_tile_normal", tile_c, PRESS_BRIGHT),
		"hover_pressed": _tex("caption_tile_normal", tile_c, PRESS_BRIGHT),
		"disabled": _tex("caption_tile_disabled", tile_c),
		"focus": _ring("caption_tile_focus_ring"),
	}, FONT_SLOT, Pal.SOUL_WHITE)

	var slot_c := [28, 28, 28, 28]
	_variation(&"SlotButton", &"Button")
	_set_button(&"SlotButton", {
		"normal": _tex("slot_normal", slot_c),
		"hover": _tex("slot_normal", slot_c, HOVER),
		"pressed": _tex("slot_selected", slot_c),
		"hover_pressed": _tex("slot_selected", slot_c),
		"disabled": _tex("slot_disabled", slot_c),
		"focus": _ring("icon_tile_focus_ring"),
	}, FONT_SLOT, Pal.SOUL_WHITE)
	_theme.set_constant(&"icon_max_width", &"SlotButton", 0)

	var card_c := [36, 52, 36, 48]
	_variation(&"CardButton", &"Button")
	_set_button(&"CardButton", {
		"normal": _tex("panel_card", card_c),
		"hover": _tex("panel_card", card_c, HOVER),
		"pressed": _tex("panel_card_selected", card_c),
		"hover_pressed": _tex("panel_card_selected", card_c),
		"disabled": _tex("panel_card_locked", card_c),
		"focus": _ring("icon_tile_focus_ring"),
	}, FONT_CARD, Pal.SOUL_WHITE)
	_theme.set_constant(&"icon_max_width", &"CardButton", 0)

	# NavButton: one tab of the Shop's tab dock. The 64 px kit tab is drawn centred in the 88 px
	# touch row (negative expand margins), so the dock reads exactly like the kit's while the whole
	# row stays tappable. Pressed = the active tab (amber lines, cyan rune).
	var inset := -(NAV_ROW - _native_height("tab_normal")) * 0.5
	var nav_c := [32.0, 12.0, 32.0, 12.0]
	var nav := {}
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var tab := "tab_active" if state.contains("pressed") else "tab_normal"
		var box := _tex(tab, nav_c, HOVER if state == "hover" else Color.WHITE)
		box.expand_margin_top = inset
		box.expand_margin_bottom = inset
		nav[state] = box
	nav["focus"] = _ring("icon_tile_focus_ring")
	_variation(&"NavButton", &"Button")
	_set_button(&"NavButton", nav, FONT_NAV, Pal.TEXT_MUTED)
	for c: StringName in [&"font_pressed_color", &"font_hover_pressed_color"]:
		_theme.set_color(c, &"NavButton", Pal.IVORY_LIGHT)
	_theme.set_color(&"font_hover_color", &"NavButton", Pal.SOUL_WHITE)
	_theme.set_constant(&"h_separation", &"NavButton", 4)


# ------------------------------------------------------------------------ panels

func _panel(type: StringName, box: StyleBox) -> void:
	if type != &"PanelContainer":
		_variation(type, &"PanelContainer")
	_theme.set_stylebox(&"panel", type, box)
	_panel_margins[type] = [box.content_margin_left, box.content_margin_top,
			box.content_margin_right, box.content_margin_bottom]


func _build_panels() -> void:
	_panel(&"PanelContainer", _tex("panel_default", [36, 36, 36, 36]))
	_panel(&"PanelCard", _tex("panel_card", [36, 52, 36, 48]))
	_panel(&"PanelCrest", _tex("panel_crest", [64, 80, 64, 64]))
	_panel(&"PanelBanner", _tex("panel_banner", _fit_line("panel_banner", 48.0, FONT_TITLE)))
	# Plates: digits sit on the interior, which is one art pixel lower than the frame's middle.
	_panel(&"PanelPlate", _tex("plate_small", [28, 6, 28, 10]))
	_panel(&"RewardPlate", _tex("hud_alert_plate", [28, 6, 28, 10]))
	# The Shop tab dock: no vertical padding, so 88 px NavButtons fill it at its native height.
	_panel(&"NavBar", _tex("nav_dock", [20, 0, 20, 0]))
	_panel(&"PortraitRing", _tex("portrait_ring", [56, 56, 56, 56]))


# ------------------------------------------------------------------------ bars

## Track and fill share one outline in the kit: the fill covers the track where it reaches.
func _bar(type: StringName, track: String, fill: String) -> void:
	var half := _native_height(track) * 0.5
	var side: float = _slice(track).margins[0]
	_theme.set_stylebox(&"background", type, _tex(track, [side, half, side, half]))
	_theme.set_stylebox(&"fill", type, _tex(fill, [side, 0, side, 0]))


func _build_bars() -> void:
	var t := &"ProgressBar"
	_bar(t, "progress_track", "progress_fill_xp")
	_theme.set_color(&"font_color", t, Pal.SOUL_WHITE)
	_theme.set_color(&"font_outline_color", t, Pal.TEXT_OUTLINE)
	_theme.set_font_size(&"font_size", t, FONT_BAR)
	_theme.set_constant(&"outline_size", t, 4)

	_variation(&"BossProgressBar", t)
	_bar(&"BossProgressBar", "progress_track", "progress_fill_boss")
	_variation(&"SlimProgressBar", t)
	_bar(&"SlimProgressBar", "hud_slim_track", "hud_slim_fill_xp")
	# RUSH meter: the slim track with the kit's ivory fill, so it never reads as a second XP strip.
	_variation(&"RushProgressBar", t)
	_bar(&"RushProgressBar", "hud_slim_track", "hud_slim_fill_rush")


func _build_slider() -> void:
	var t := &"HSlider"
	var half := _native_height("hud_slim_track") * 0.5
	var c := [16, half, 16, half]
	_theme.set_stylebox(&"slider", t, _tex("hud_slim_track", c))
	_theme.set_stylebox(&"grabber_area", t, _tex("hud_slim_fill_xp", c))
	_theme.set_stylebox(&"grabber_area_highlight", t, _tex("hud_slim_fill_xp", c, HOVER))
	_theme.set_stylebox(&"focus", t, _ring("icon_tile_focus_ring"))
	_theme.set_icon(&"grabber", t, _wrapped["slider_grabber_idle"])
	_theme.set_icon(&"grabber_highlight", t, _wrapped["slider_grabber_active"])
	_theme.set_icon(&"grabber_disabled", t, _wrapped["slider_grabber_disabled"])
	_theme.set_icon(&"tick", t, ImageTexture.new())
	_theme.set_constant(&"center_grabber", t, 0)
	_theme.set_constant(&"grabber_offset", t, 0)


func _build_separator() -> void:
	var h := _native_height("divider")
	var box := _tex("divider", [0, floorf(h * 0.5), 0, h - floorf(h * 0.5)])
	_theme.set_stylebox(&"separator", &"HSeparator", box)
	_theme.set_constant(&"separation", &"HSeparator", 24)


func _build_scrollbar() -> void:
	var t := &"VScrollBar"
	var track := _flat(Color(Pal.OBSIDIAN, 0.6), 4.0)
	_theme.set_stylebox(&"scroll", t, track)
	_theme.set_stylebox(&"scroll_focus", t, track)
	_theme.set_stylebox(&"grabber", t, _flat(Pal.STONE_LIGHT, 4.0))
	_theme.set_stylebox(&"grabber_highlight", t, _flat(Pal.STITCH, 4.0))
	_theme.set_stylebox(&"grabber_pressed", t, _flat(Pal.IVORY_LIGHT, 4.0))


# ------------------------------------------------------------------------ ornaments

## Ornament scenes: instance one as a child of a PanelContainer with the matching variation.
## The root is a zero-size Control the container centres on its content edge; the art is
## offset back out so the kit's 48 px edge ornament sits centred on the frame's top/bottom band.
func _build_ornaments() -> void:
	_ornament("crest_top", "ornament_diamond_cyan", &"PanelCrest", "panel_crest", true)
	_ornament("crest_bottom", "ornament_diamond_cyan", &"PanelCrest", "panel_crest", false)
	_ornament("card_top", "ornament_diamond_cyan", &"PanelCard", "panel_card", true)
	_ornament("banner_top", "ornament_diamond_cyan", &"PanelBanner", "panel_banner", true)
	_ornament("amber_top", "ornament_diamond_warm", &"PanelContainer", "panel_default", true)


func _ornament(scene_name: String, tex_name: String, panel: StringName, piece: String,
		top: bool) -> void:
	var s: Dictionary = _slice(piece)
	var art_tex: Texture2D = _wrapped[tex_name]
	var art_size: Vector2 = art_tex.get_size()
	var margins: Array = _panel_margins[panel]
	var root := Control.new()
	root.name = scene_name.to_pascal_case() + "Ornament"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var art := TextureRect.new()
	art.name = "Art"
	art.texture = art_tex
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.size = art_size
	var x := -floorf(art_size.x * 0.5)
	if top:
		var band: Array = s.top_band
		var centre: float = (float(band[0]) + float(band[1])) * 0.5
		root.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		art.position = Vector2(x, roundf(centre - art_size.y * 0.5 - float(margins[1])))
	else:
		var band: Array = s.bottom_band
		var from_bottom: float = float(s.size[1]) - (float(band[0]) + float(band[1])) * 0.5
		root.size_flags_vertical = Control.SIZE_SHRINK_END
		art.position = Vector2(x, roundf(float(margins[3]) - from_bottom - art_size.y * 0.5))
	root.add_child(art)
	art.owner = root
	var packed := PackedScene.new()
	packed.pack(root)
	var path := ORNAMENT_DIR + scene_name + ".tscn"
	var err := ResourceSaver.save(packed, path)
	if err != OK:
		push_error("[ThemeBuilder] saving %s failed: %d" % [path, err])
	root.free()
