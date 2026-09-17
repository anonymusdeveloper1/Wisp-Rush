extends SceneTree
## Generates res://assets/ui/theme/wisp_theme.tres and the ornament scenes from textures/slices.json.
##
## Pipeline (repo root): python3 assets/ui/theme/tools/build_theme_textures.py, then
## Godot --headless --path . --import, then
## Godot --headless --path . --script res://assets/ui/theme/tools/build_wisp_theme.gd
## The theme is generated rather than hand-edited so nine-patch margins always match the derived
## textures. Colours come from Palette (scripts/utils/palette.gd). See docs/systems/ui_design_system.md.

const Pal := preload("res://scripts/utils/palette.gd")

const THEME_DIR := "res://assets/ui/theme/"
const TEX_DIR := THEME_DIR + "textures/"
const THEME_PATH := THEME_DIR + "wisp_theme.tres"
const ORNAMENT_DIR := THEME_DIR + "ornaments/"
const RING_TEXTURE := "res://assets/art/ui/frames/portrait_ring.png"

const FONT_BODY := 30
const FONT_CAPTION := 26
const FONT_TITLE := 48
const FONT_VALUE := 56
const FONT_AMBER := 64
const FONT_PRIMARY := 44
const FONT_SECONDARY := 34
const FONT_SLOT := 26
const FONT_CARD := 30
const FONT_BAR := 22
const FONT_NAV := 26
## The system glyphs fill only ~60 % of their texture canvas, so the icon box is larger than the
## glyph should appear.
const NAV_ICON := 96
const ICON_MAX := 64
const HOVER := Color(1.12, 1.12, 1.12)
const PRESS_BRIGHT := Color(1.35, 1.35, 1.35)
const DIM := Color(0.55, 0.57, 0.62, 0.85)

var _slices: Dictionary = {}
var _theme: Theme
## Content margins per panel variation, reused to position ornaments inside PanelContainers.
var _panel_margins: Dictionary = {}


func _initialize() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEX_DIR + "slices.json"))
	if not parsed is Dictionary:
		push_error("[ThemeBuilder] cannot read %sslices.json" % TEX_DIR)
		quit(1)
		return
	_slices = parsed
	_theme = Theme.new()
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
	print("[ThemeBuilder] saved %s" % THEME_PATH)
	quit(0)


# ------------------------------------------------------------------------ helpers

func _slice(name: String) -> Dictionary:
	assert(_slices.has(name), "missing slice " + name)
	return _slices[name]


## A nine-patch StyleBoxTexture from textures/<name>.png with margins from slices.json.
func _tex(name: String, content: Array, modulate: Color = Color.WHITE) -> StyleBoxTexture:
	var s: Dictionary = _slice(name)
	var sb := StyleBoxTexture.new()
	sb.texture = load(TEX_DIR + name + ".png")
	var m: Array = s.get("margins", [0, 0, 0, 0])
	var e: Array = s.get("expand", [0, 0, 0, 0])
	sb.texture_margin_left = m[0]
	sb.texture_margin_top = m[1]
	sb.texture_margin_right = m[2]
	sb.texture_margin_bottom = m[3]
	sb.expand_margin_left = e[0]
	sb.expand_margin_top = e[1]
	sb.expand_margin_right = e[2]
	sb.expand_margin_bottom = e[3]
	sb.content_margin_left = content[0]
	sb.content_margin_top = content[1]
	sb.content_margin_right = content[2]
	sb.content_margin_bottom = content[3]
	sb.modulate_color = modulate
	return sb


## Content margins = distance from the frame edge to the flat interior + padding.
func _inner(name: String, pad: Array) -> Array:
	var inner: Array = _slice(name).get("inner", [0, 0, 0, 0])
	return [inner[0] + pad[0], inner[1] + pad[1], inner[2] + pad[2], inner[3] + pad[3]]


## Button content margins: sides clear the frame tips, vertical keeps the native frame height.
func _button_content(name: String, font_size: int, side_pad: float) -> Array:
	var s: Dictionary = _slice(name)
	var frame_h: float = s.frame[1]
	var line_h: float = ThemeDB.fallback_font.get_height(font_size)
	var v := maxf(8.0, floorf((frame_h - line_h) * 0.5))
	var inner: Array = s.inner
	return [inner[0] + side_pad, v, inner[2] + side_pad, v]


## Chamfered cyan outline used as the keyboard/controller focus state.
func _focus_box(expand: float, color: Color = Pal.SOUL_CYAN) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_border_width_all(4)
	sb.border_color = color
	sb.set_corner_radius_all(16)
	sb.corner_detail = 1
	sb.set_expand_margin_all(expand)
	return sb


## Flat chamfered box for tracks and slim bars (no frame piece fits these).
func _flat(bg: Color, border: Color, border_w: int, radius: int, content_v: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_border_width_all(border_w)
	sb.border_color = border
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 1
	sb.content_margin_top = content_v
	sb.content_margin_bottom = content_v
	sb.content_margin_left = content_v
	sb.content_margin_right = content_v
	return sb


func _variation(type: StringName, base: StringName) -> void:
	_theme.set_type_variation(type, base)


func _font_tnum() -> FontVariation:
	var fv := FontVariation.new()
	var ts := TextServerManager.get_primary_interface()
	fv.opentype_features = {ts.name_to_tag("tnum"): 1}
	return fv


# ------------------------------------------------------------------------ labels

func _build_labels() -> void:
	var t := &"Label"
	_theme.set_color(&"font_color", t, Pal.SOUL_WHITE)
	_theme.set_color(&"font_outline_color", t, Pal.TEXT_OUTLINE)
	_theme.set_color(&"font_shadow_color", t, Color(0, 0, 0, 0))
	_theme.set_font_size(&"font_size", t, FONT_BODY)
	_theme.set_constant(&"outline_size", t, 0)
	_theme.set_constant(&"line_spacing", t, 2)

	var title_font := FontVariation.new()
	title_font.spacing_glyph = 3
	title_font.variation_embolden = 0.35
	_variation(&"TitleLabel", t)
	_theme.set_font(&"font", &"TitleLabel", title_font)
	_theme.set_font_size(&"font_size", &"TitleLabel", FONT_TITLE)
	_theme.set_color(&"font_color", &"TitleLabel", Pal.SOUL_WHITE)
	_theme.set_constant(&"outline_size", &"TitleLabel", 8)
	_theme.set_color(&"font_shadow_color", &"TitleLabel", Color(Pal.SOUL_CYAN, 0.30))
	_theme.set_constant(&"shadow_outline_size", &"TitleLabel", 14)
	_theme.set_constant(&"shadow_offset_x", &"TitleLabel", 0)
	_theme.set_constant(&"shadow_offset_y", &"TitleLabel", 0)

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
	_theme.set_color(&"font_shadow_color", &"AmberValueLabel", Pal.AMBER_GLOW)
	_theme.set_constant(&"shadow_outline_size", &"AmberValueLabel", 12)
	_theme.set_constant(&"shadow_offset_x", &"AmberValueLabel", 0)
	_theme.set_constant(&"shadow_offset_y", &"AmberValueLabel", 0)


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


func _build_buttons() -> void:
	# Default Button = the quieter secondary tier; opt into PrimaryButton for the one main action.
	var sec := _button_content("button_secondary", FONT_SECONDARY, 14.0)
	var secondary := {
		"normal": _tex("button_secondary", sec),
		"hover": _tex("button_secondary", sec, HOVER),
		"pressed": _tex("button_secondary_pressed", sec),
		"hover_pressed": _tex("button_secondary_pressed", sec),
		"disabled": _tex("button_disabled_small", sec),
		"focus": _tex("button_focus_small", [0, 0, 0, 0]),
	}
	_set_button(&"Button", secondary, FONT_SECONDARY, Pal.SOUL_WHITE)
	_variation(&"SecondaryButton", &"Button")
	_set_button(&"SecondaryButton", secondary, FONT_SECONDARY, Pal.SOUL_WHITE)

	var pri := _button_content("button_primary", FONT_PRIMARY, 16.0)
	_variation(&"PrimaryButton", &"Button")
	_set_button(&"PrimaryButton", {
		"normal": _tex("button_primary", pri),
		"hover": _tex("button_primary", pri, HOVER),
		"pressed": _tex("button_primary_pressed", pri),
		"hover_pressed": _tex("button_primary_pressed", pri),
		"disabled": _tex("button_disabled", pri),
		"focus": _tex("button_primary_focus", [0, 0, 0, 0]),
	}, FONT_PRIMARY, Pal.SOUL_WHITE)

	var dng := _button_content("button_danger", FONT_SECONDARY, 14.0)
	_variation(&"DangerButton", &"Button")
	_set_button(&"DangerButton", {
		"normal": _tex("button_danger", dng),
		"hover": _tex("button_danger", dng, HOVER),
		"pressed": _tex("button_danger_pressed", dng),
		"hover_pressed": _tex("button_danger_pressed", dng),
		"disabled": _tex("button_disabled_small", dng),
		"focus": _tex("button_focus_small", [0, 0, 0, 0]),
	}, FONT_SECONDARY, Color("#FFE2B8"))

	var icon_c := [24, 24, 24, 24]
	_variation(&"IconButton", &"Button")
	_set_button(&"IconButton", {
		"normal": _tex("slot_small", icon_c),
		"hover": _tex("slot_small", icon_c, HOVER),
		"pressed": _tex("slot_small", icon_c, PRESS_BRIGHT),
		"hover_pressed": _tex("slot_small", icon_c, PRESS_BRIGHT),
		"disabled": _tex("slot_small", icon_c, DIM),
		"focus": _focus_box(6.0),
	}, FONT_SLOT, Pal.SOUL_WHITE)

	var slot_c := _inner("slot", [8, 8, 8, 8])
	_variation(&"SlotButton", &"Button")
	_set_button(&"SlotButton", {
		"normal": _tex("slot", slot_c),
		"hover": _tex("slot", slot_c, HOVER),
		"pressed": _tex("slot_selected", slot_c),
		"hover_pressed": _tex("slot_selected", slot_c),
		"disabled": _tex("slot", slot_c, DIM),
		"focus": _focus_box(6.0),
	}, FONT_SLOT, Pal.SOUL_WHITE)
	_theme.set_constant(&"icon_max_width", &"SlotButton", 0)

	var card_c := _inner("panel_card", [16, 28, 16, 16])
	_variation(&"CardButton", &"Button")
	_set_button(&"CardButton", {
		"normal": _tex("panel_card", card_c),
		"hover": _tex("panel_card", card_c, HOVER),
		"pressed": _tex("panel_card_selected", card_c),
		"hover_pressed": _tex("panel_card_selected", card_c),
		"disabled": _tex("panel_card", card_c, DIM),
		"focus": _focus_box(8.0),
	}, FONT_CARD, Pal.SOUL_WHITE)
	_theme.set_constant(&"icon_max_width", &"CardButton", 0)

	# NavButton: one tab of the Home bottom navigation bar. Flat, icon above a short caption, so the
	# bar reads as a single calm dock rather than five framed buttons. The pressed and focused
	# states use a chamfered cyan lozenge behind the item - stone-cut corners, not a soft pill.
	var nav_pad := [8.0, 10.0, 8.0, 10.0]
	var nav_empty := StyleBoxEmpty.new()
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		nav_empty.set_content_margin(side, nav_pad[side])
	var nav_active := _flat(Color(Pal.SOUL_CYAN, 0.14), Color(Pal.SOUL_CYAN, 0.55), 2, 18, 10.0)
	nav_active.content_margin_left = nav_pad[0]
	nav_active.content_margin_right = nav_pad[2]
	_variation(&"NavButton", &"Button")
	_set_button(&"NavButton", {
		"normal": nav_empty,
		"hover": nav_empty,
		"pressed": nav_active,
		"hover_pressed": nav_active,
		"disabled": nav_empty,
		"focus": _focus_box(2.0),
	}, FONT_NAV, Pal.TEXT_MUTED)
	for c: StringName in [&"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color",
			&"font_focus_color"]:
		_theme.set_color(c, &"NavButton", Pal.SOUL_WHITE)
	_theme.set_color(&"icon_hover_color", &"NavButton", Color(1.15, 1.15, 1.15))
	_theme.set_constant(&"icon_max_width", &"NavButton", NAV_ICON)
	_theme.set_constant(&"h_separation", &"NavButton", 4)


# ------------------------------------------------------------------------ panels

func _panel(type: StringName, box: StyleBox) -> void:
	if type != &"PanelContainer":
		_variation(type, &"PanelContainer")
	_theme.set_stylebox(&"panel", type, box)
	_panel_margins[type] = [box.content_margin_left, box.content_margin_top,
			box.content_margin_right, box.content_margin_bottom]


func _build_panels() -> void:
	_panel(&"PanelContainer", _tex("panel_default", _inner("panel_default", [24, 24, 24, 24])))
	_panel(&"PanelCard", _tex("panel_card", _inner("panel_card", [16, 28, 16, 16])))
	_panel(&"PanelCrest", _tex("panel_crest", _inner("panel_crest", [20, 56, 20, 36])))
	_panel(&"PanelBanner", _tex("panel_banner", _inner("panel_banner", [28, 4, 28, 4])))
	_panel(&"PanelPlate", _tex("plate_small", _inner("plate_small", [10, 0, 10, 0])))
	# NavBar: the Home bottom navigation dock. The default stone panel, with tight vertical padding
	# so five NavButtons fit a thumb-height strip.
	_panel(&"NavBar", _tex("panel_default", _inner("panel_default", [6, 2, 6, 2])))
	var ring := StyleBoxTexture.new()
	ring.texture = load(RING_TEXTURE)
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		ring.set_content_margin(side, 56.0)
	_panel(&"PortraitRing", ring)


# ------------------------------------------------------------------------ bars

func _bar_bg() -> StyleBoxTexture:
	var s: Dictionary = _slice("bar_track")
	var half := floorf(float(s.frame[1]) * 0.5)
	var m: Array = s.margins
	var e: Array = s.expand
	return _tex("bar_track", [m[0] - e[0], half, m[2] - e[2], float(s.frame[1]) - half])


func _bar_fill(name: String) -> StyleBoxTexture:
	return _tex(name, _slice(name).content)


func _build_bars() -> void:
	var t := &"ProgressBar"
	_theme.set_stylebox(&"background", t, _bar_bg())
	_theme.set_stylebox(&"fill", t, _bar_fill("bar_fill"))
	_theme.set_color(&"font_color", t, Pal.SOUL_WHITE)
	_theme.set_color(&"font_outline_color", t, Pal.TEXT_OUTLINE)
	_theme.set_font_size(&"font_size", t, FONT_BAR)
	_theme.set_constant(&"outline_size", t, 4)

	_variation(&"BossProgressBar", t)
	_theme.set_stylebox(&"background", &"BossProgressBar", _bar_bg())
	_theme.set_stylebox(&"fill", &"BossProgressBar", _bar_fill("bar_fill_boss"))

	_variation(&"SlimProgressBar", t)
	_theme.set_stylebox(&"background", &"SlimProgressBar",
			_flat(Color(Pal.VOID_CHARCOAL, 0.92), Pal.STEEL_BORDER, 2, 6, 9.0))
	var fill := _flat(Pal.SOUL_CYAN, Color(Pal.VOID_CHARCOAL, 0.92), 3, 6, 0.0)
	fill.content_margin_left = 6.0
	fill.content_margin_right = 6.0
	_theme.set_stylebox(&"fill", &"SlimProgressBar", fill)

	# RUSH meter under the HUD XP strip: the same slim track, a Soul White fill with a cyan rim so it
	# never reads as a second XP bar (GDD §5.6).
	_variation(&"RushProgressBar", t)
	_theme.set_stylebox(&"background", &"RushProgressBar",
			_flat(Color(Pal.VOID_CHARCOAL, 0.92), Pal.STEEL_BORDER, 2, 6, 9.0))
	var rush_fill := _flat(Pal.SOUL_WHITE, Pal.SOUL_CYAN, 3, 6, 0.0)
	rush_fill.content_margin_left = 6.0
	rush_fill.content_margin_right = 6.0
	_theme.set_stylebox(&"fill", &"RushProgressBar", rush_fill)


func _build_slider() -> void:
	var t := &"HSlider"
	_theme.set_stylebox(&"slider", t,
			_flat(Color(Pal.VOID_CHARCOAL, 0.92), Pal.STEEL_BORDER, 2, 6, 8.0))
	_theme.set_stylebox(&"grabber_area", t, _flat(Pal.SOUL_CYAN, Pal.SOUL_CYAN, 0, 6, 8.0))
	_theme.set_stylebox(&"grabber_area_highlight", t,
			_flat(Pal.SOUL_CYAN.lerp(Pal.SOUL_WHITE, 0.4), Pal.SOUL_CYAN, 0, 6, 8.0))
	_theme.set_stylebox(&"focus", t, _focus_box(6.0))
	_theme.set_icon(&"grabber", t, load(TEX_DIR + "grabber.png"))
	_theme.set_icon(&"grabber_highlight", t, load(TEX_DIR + "grabber_highlight.png"))
	_theme.set_icon(&"grabber_disabled", t, load(TEX_DIR + "grabber_disabled.png"))
	_theme.set_icon(&"tick", t, ImageTexture.new())
	_theme.set_constant(&"center_grabber", t, 0)
	_theme.set_constant(&"grabber_offset", t, 0)


func _build_separator() -> void:
	var s: Dictionary = _slice("divider_line")
	var h: float = s.frame[1]
	var box := _tex("divider_line", [0, floorf(h * 0.5), 0, h - floorf(h * 0.5)])
	_theme.set_stylebox(&"separator", &"HSeparator", box)
	_theme.set_constant(&"separation", &"HSeparator", 24)


func _build_scrollbar() -> void:
	var t := &"VScrollBar"
	var track := _flat(Color(Pal.VOID_CHARCOAL, 0.5), Color(0, 0, 0, 0), 0, 4, 5.0)
	_theme.set_stylebox(&"scroll", t, track)
	_theme.set_stylebox(&"scroll_focus", t, track)
	_theme.set_stylebox(&"grabber", t, _flat(Color(Pal.SOUL_CYAN, 0.55), Color(0, 0, 0, 0), 0, 4, 5.0))
	_theme.set_stylebox(&"grabber_highlight", t, _flat(Pal.SOUL_CYAN, Color(0, 0, 0, 0), 0, 4, 5.0))
	_theme.set_stylebox(&"grabber_pressed", t, _flat(Pal.SOUL_WHITE, Color(0, 0, 0, 0), 0, 4, 5.0))


# ------------------------------------------------------------------------ ornaments

## Ornament scenes: instance one as a child of a PanelContainer with the matching variation.
## The root is a zero-size Control the container centres on its content edge; the art is
## offset back out onto the frame edge using that variation's content margin.
func _build_ornaments() -> void:
	_ornament("crest_top", "ornament_crest_top", &"PanelCrest")
	_ornament("crest_bottom", "ornament_crest_bottom", &"PanelCrest")
	_ornament("card_top", "ornament_card_top", &"PanelCard")
	_ornament("banner_top", "ornament_banner_top", &"PanelBanner")
	_ornament("amber_top", "ornament_amber_top", &"PanelContainer")


func _ornament(scene_name: String, tex_name: String, panel: StringName) -> void:
	var s: Dictionary = _slice(tex_name)
	var size := Vector2(s.size[0], s.size[1])
	var off := Vector2(s.offset[0], s.offset[1])
	var margins: Array = _panel_margins[panel]
	var root := Control.new()
	root.name = scene_name.to_pascal_case() + "Ornament"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var art := TextureRect.new()
	art.name = "Art"
	art.texture = load(TEX_DIR + tex_name + ".png")
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.size = size
	if s.edge == "top":
		root.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		art.position = Vector2(roundf(-size.x * 0.5 + off.x), roundf(off.y - float(margins[1])))
	else:
		root.size_flags_vertical = Control.SIZE_SHRINK_END
		art.position = Vector2(roundf(-size.x * 0.5 + off.x),
				roundf(float(margins[3]) + off.y - size.y))
	root.add_child(art)
	art.owner = root
	var packed := PackedScene.new()
	packed.pack(root)
	var path := ORNAMENT_DIR + scene_name + ".tscn"
	var err := ResourceSaver.save(packed, path)
	if err != OK:
		push_error("[ThemeBuilder] saving %s failed: %d" % [path, err])
	root.free()
