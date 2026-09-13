class_name RiftMapScreen
extends Control
## Rift map: a portrait card carousel of the arena ladder, each card showing the Rift's own arena.
##
## Owner reference (2026-09-13): the same vertical focus card picker as Forms - one big lifted card,
## neighbours peeking in dimmed, the rule twist and personal best underneath and ENTER at the bottom.
## Behind it the screen shows the focused Rift's arena, crossfading as the player browses.
## Cards are built from the RiftCatalog so adding a Rift is a data change. Unlocking is derived from
## the lifetime highest wave rather than a stored flag, so it can never desync from the save.
## Locked Rifts stay previewable, with the lock and the wave gate shown in text as well as dimming.

## The player backed out without entering a Rift.
signal back_requested
## The player chose an unlocked Rift and asked to start a run in it.
signal play_requested(rift_id: StringName)

const LOCK_ICON: Texture2D = preload("res://assets/art/ui/system/17_lock.png")
## Brightness of a locked Rift's arena art on its card.
const LOCKED_ART_BRIGHTNESS: float = 0.5
## Card text sizes in the 1080-wide design space.
const CARD_NAME_SIZE: int = 44
const CARD_CAPTION_SIZE: int = 34
const CARD_LOCK_SIZE: int = 40
const LOCK_ICON_SIZE := Vector2(128, 128)
## Inset of the arena art inside the card frame, so the frame's ornaments stay visible.
const ART_INSET: int = 16
const OVERLAY_PADDING: int = 22
## Seconds the screen background takes to crossfade to a newly focused Rift's arena.
const BACKGROUND_FADE: float = 0.3

## Ordered Rift registry backing the ladder.
@export var catalog: RiftCatalog

var _rifts: Array[RiftData] = []
var _selected_id: StringName = RiftCatalog.DEFAULT_RIFT_ID
var _highest_wave: int = 1
var _levels: Dictionary = {}
var _bests: Dictionary = {}
var _reduced_motion: bool = false
## Last snapshot handed to setup(), replayed on _ready() when setup ran before the node was ready.
var _snapshot: Dictionary = {}
var _fallback_background: Texture2D
var _fade_tween: Tween
var _shade_texture: GradientTexture2D

@onready var _background: TextureRect = %Background
@onready var _background_fade: TextureRect = %BackgroundFade
@onready var _carousel: FocusCarousel = %Carousel
@onready var _dots: PageDots = %Dots
@onready var _rule_label: Label = %RuleLabel
@onready var _best_icon: TextureRect = %BestIcon
@onready var _status_label: Label = %StatusLabel
@onready var _back_button: Button = %BackButton
@onready var _enter_button: Button = %EnterButton


func _ready() -> void:
	_fallback_background = _background.texture
	_back_button.pressed.connect(_on_back_pressed)
	_enter_button.pressed.connect(_on_enter_pressed)
	_carousel.selection_changed.connect(_on_carousel_selection_changed)
	_carousel.activated.connect(func(_index: int) -> void: _on_enter_pressed())
	_apply()
	_carousel.grab_focus.call_deferred()


func _process(_delta: float) -> void:
	_dots.position_value = _carousel.get_scroll()


## Rebuilds the ladder from a SaveManager snapshot.
##
## Safe before or after the screen enters the tree: callers commonly configure a screen straight
## after instancing them, when @onready references are still null, so the rebuild is deferred to
## _ready() in that case.
func setup(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	if is_node_ready():
		_apply()


## Rift in focus: the one ENTER starts when it is unlocked. Locked Rifts can be focused to preview.
func get_selected_rift_id() -> StringName:
	return _selected_id


## Whether a Rift is open to the current save, for tests and callers.
func is_rift_unlocked(rift_id: StringName) -> bool:
	return catalog != null and catalog.get_rift(rift_id).is_unlocked(_highest_wave)


func _apply() -> void:
	if catalog == null:
		push_error("RiftMapScreen has no RiftCatalog")
		return
	_highest_wave = maxi(1, int(_snapshot.get(&"highest_wave", 1)))
	_bests = _snapshot.get(&"rift_bests", {}) as Dictionary
	_levels = _snapshot.get(&"rift_levels", {}) as Dictionary
	var settings: Variant = _snapshot.get(&"settings", {})
	_reduced_motion = settings is Dictionary and bool((settings as Dictionary).get(&"reduced_motion", false))
	var stored: StringName = StringName(str(_snapshot.get(&"selected_rift", "")))
	_selected_id = stored if not stored.is_empty() else RiftCatalog.DEFAULT_RIFT_ID
	# A locked selection can survive in the save if the player reset progress; fall back cleanly.
	if not catalog.get_rift(_selected_id).is_unlocked(_highest_wave):
		_selected_id = RiftCatalog.DEFAULT_RIFT_ID
	_rifts = catalog.load_rifts()
	var cards: Array[Control] = []
	var hollow := PackedInt32Array()
	for index: int in _rifts.size():
		cards.append(_build_card(_rifts[index]))
		if not _rifts[index].is_unlocked(_highest_wave):
			hollow.append(index)
	_dots.count = _rifts.size()
	_dots.hollow = hollow
	_carousel.set_cards(cards, _index_of(_selected_id))
	_refresh(false)


func _on_carousel_selection_changed(index: int) -> void:
	if index < 0 or index >= _rifts.size():
		return
	_selected_id = _rifts[index].rift_id
	_refresh(true)


## Updates everything under the carousel and the backdrop for the focused Rift.
func _refresh(fade: bool) -> void:
	var rift: RiftData = catalog.get_rift(_selected_id)
	var unlocked: bool = rift.is_unlocked(_highest_wave)
	_rule_label.text = rift.rule_summary
	var best: int = int(_bests.get(String(rift.rift_id), 0))
	_best_icon.visible = unlocked and best > 0
	# Amber marks a reward or landmark value; plain caption marks "nothing yet" or a gate.
	if unlocked and best > 0:
		_status_label.theme_type_variation = &"AmberValueLabel"
		_status_label.text = "BEST %d" % best
	elif unlocked:
		_status_label.theme_type_variation = &"CaptionLabel"
		_status_label.text = "NO RUN YET"
	else:
		_status_label.theme_type_variation = &"CaptionLabel"
		_status_label.text = "LOCKED  ·  YOUR BEST WAVE %d OF %d" % [_highest_wave, rift.unlock_wave]
	_enter_button.disabled = not unlocked
	_enter_button.icon = null if unlocked else LOCK_ICON
	_enter_button.text = "ENTER" if unlocked else "LOCKED"
	_show_background(rift.background if rift.background != null else _fallback_background, fade)


func _show_background(texture: Texture2D, fade: bool) -> void:
	if _background.texture == texture:
		return
	if _fade_tween != null:
		_fade_tween.kill()
	if not fade or _reduced_motion:
		_background.texture = texture
		_background_fade.modulate.a = 0.0
		return
	# The old arena sits on top and fades out, so the new one is revealed rather than popped in.
	_background_fade.texture = _background.texture
	_background_fade.modulate.a = 1.0
	_background.texture = texture
	_fade_tween = create_tween()
	_fade_tween.tween_property(_background_fade, ^"modulate:a", 0.0, BACKGROUND_FADE)


## One portrait card: the Rift's arena art filling the frame, name and tier on top, level progress
## at the bottom, or a lock and the wave gate in the middle while it is locked.
func _build_card(rift: RiftData) -> Control:
	var unlocked: bool = rift.is_unlocked(_highest_wave)
	var card := Button.new()
	card.theme_type_variation = &"CardButton"
	card.name = "Card_%s" % rift.rift_id

	var inset := MarginContainer.new()
	inset.set_anchors_preset(Control.PRESET_FULL_RECT)
	_set_margins(inset, ART_INSET)
	card.add_child(inset)

	var art := TextureRect.new()
	art.name = "Art"
	art.texture = rift.background
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var brightness: float = 1.0 if unlocked else LOCKED_ART_BRIGHTNESS
	art.modulate = Color(brightness, brightness, brightness, 1.0)
	inset.add_child(art)

	var shade := TextureRect.new()
	shade.name = "ArtShade"
	if _shade_texture == null:
		_shade_texture = _card_shade_texture()
	shade.texture = _shade_texture
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	inset.add_child(shade)

	var overlay := MarginContainer.new()
	_set_margins(overlay, OVERLAY_PADDING)
	inset.add_child(overlay)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 6)
	overlay.add_child(column)

	var name_label := _card_label("Name", &"TitleLabel", CARD_NAME_SIZE, rift.display_name)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(name_label)
	column.add_child(_card_label("Tier", &"CaptionLabel", CARD_CAPTION_SIZE, "TIER %d" % rift.difficulty_tier))
	column.add_child(_expanding_spacer())

	if unlocked:
		var cleared: int = mini(int(_levels.get(String(rift.rift_id), 0)), rift.level_count)
		var level_text: String = "LEVEL %d / %d" % [cleared + 1, rift.level_count]
		if cleared >= rift.level_count:
			level_text = "ALL %d CLEARED  ·  ENDLESS" % rift.level_count
		column.add_child(_card_label("Level", &"CaptionLabel", CARD_CAPTION_SIZE, level_text))
		var progress := ProgressBar.new()
		progress.name = "Progress"
		progress.theme_type_variation = &"SlimProgressBar"
		progress.max_value = rift.level_count
		progress.value = cleared
		progress.show_percentage = false
		column.add_child(progress)
	else:
		var lock := TextureRect.new()
		lock.name = "Lock"
		lock.texture = LOCK_ICON
		lock.custom_minimum_size = LOCK_ICON_SIZE
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		column.add_child(lock)
		column.add_child(_card_label("Gate", &"ValueLabel", CARD_LOCK_SIZE, "REACH WAVE %d" % rift.unlock_wave))
		column.add_child(_expanding_spacer())
	return card


func _card_label(node_name: String, variation: StringName, font_size: int, text: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.theme_type_variation = variation
	label.add_theme_font_size_override(&"font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = text
	return label


func _expanding_spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return spacer


func _set_margins(container: MarginContainer, value: int) -> void:
	for side: String in ["left", "top", "right", "bottom"]:
		container.add_theme_constant_override("margin_%s" % side, value)


## Void-charcoal fade at the top and bottom of a card, so its text reads over any arena art.
func _card_shade_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.24, 0.62, 1.0])
	gradient.colors = PackedColorArray([
		Color(Palette.VOID_CHARCOAL, 0.82),
		Color(Palette.VOID_CHARCOAL, 0.0),
		Color(Palette.VOID_CHARCOAL, 0.0),
		Color(Palette.VOID_CHARCOAL, 0.86),
	])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	texture.width = 4
	texture.height = 128
	return texture


func _index_of(rift_id: StringName) -> int:
	for index: int in _rifts.size():
		if _rifts[index].rift_id == rift_id:
			return index
	return 0


func _on_enter_pressed() -> void:
	if _enter_button.disabled or not is_rift_unlocked(_selected_id):
		return
	play_requested.emit(_selected_id)


func _on_back_pressed() -> void:
	back_requested.emit()
