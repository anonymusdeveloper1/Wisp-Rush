class_name WholeFrameCharacterVisual
extends PlayableCharacterVisual
## A whole-frame sprite character on one [AnimatedSprite2D].
##
## The shared behaviour for every character built to
## [url=res://docs/guides/character_creation.md]the AutoSprite recipe[/url] rather than as a
## bone rig. This script never steps frames by hand: it decides which animation should be playing,
## which way up the body is drawn, and which of the two frame sets is in memory.
## [PlayableCharacterVisual] still owns the state machine, heading, alpha and the squash on a state
## change.
##
## A character subclasses this only to carry a `class_name` the tests and fixtures can type against;
## everything that differs between characters is the two frame-set paths, set per scene.
##
## [b]Five animations, and no more[/b] (owner, 2026-09-20). The controller still speaks the full
## thirteen-state vocabulary in [PlayableCharacterVisual] — the bone rigs animate all of it for
## free — but a drawn character only has frames for what the player actually looks at:
##
## [codeblock]
## dash_loop                      the dash, which IS the attack
## wall_bottom / _top / _left     resting against a wall (_right is _left mirrored)
## storefront_idle                Home and the Shop card
## [/codeblock]
##
## Everything else resolves onto one of those in [method _target_animation]: a windup shows only the
## aim arrow, a landing is the wall animation arriving, a hit is the controller's blink and edge
## reset, and a death is the controller's alpha dissolve over whatever was showing. The frames that
## used to carry those beats (`dash_start`, `dash_end`, `attack`, `move_fly`, `hit_reaction`,
## `death`, `revive_spawn`, `victory`, the gameplay `idle_hover` and the two menu reactions) are
## still in `concept_art/`, so restoring any of them is a row in the packer and a re-pack.
##
## Three things are specific to a whole-frame character:
##
## 1. **Two frame sets, never both.** A Shop card holds a live character, and a texture costs its
##    full uncompressed size in VRAM whatever it cost on disk, so the menu animation and the
##    gameplay animations are separate resources, [method load]ed on demand. A run never holds the
##    storefront sheet and a menu never holds the run sheet.
## 2. **The wall frames are painted in screen space** — upright to the player on every surface — so
##    while one shows, the rotation the base applies to stand on that wall is cancelled again.
##    `wall_right` is `wall_left` mirrored, which is free and keeps eight frames off the sheet.
## 3. **The frames carry their own motion.** The pack already paints the breath, the flame drift and
##    the leaf overlap, so `bounce_amount` is 0: adding the shared bob on top would read as two
##    different rhythms fighting.
##
## **A menu may play a video instead** (ADR-0016). With [member menu_video] set, Home and the Shop
## card play a pre-rendered clip in place of `storefront_idle`, and a menu then loads no frame set
## at all. Under Reduced Motion the sprite loop's first frame is held instead, as for every other
## character, so a video is never the only way a character can appear.

## The two generated frame sets, set per character in its scene. Deliberately paths and not
## `preload`: see the class doc.
@export_file("*.tres") var gameplay_frames: String = ""
@export_file("*.tres") var menu_frames: String = ""
## Draws the frames this much larger than their cell, in a run and on the menus alike, for a
## character the owner wants bigger than the others. Cosmetic only: the collision radius never
## changes with it.
@export_range(0.5, 2.0, 0.01) var art_scale: float = 1.0
## The same on Home and the Shop card when it should differ from the run; 0 uses [member art_scale].
@export_range(0.0, 2.0, 0.0025) var menu_art_scale: float = 0.0
## Moves the storefront frame on Home and the Shop card, in design units, so the character stands
## centred on Home's platform: its feet on the platform's centre and its body centred over it
## (owner, 2026-09-27; character guide §7). Zero when the storefront frame already does. Never
## moves the character in a run.
@export var menu_offset: Vector2 = Vector2.ZERO

@export_group("Attack")
## The dash frame that lands the blow: Reduced Motion holds it, and the attack flash peaks on it.
@export_range(0, 64, 1) var attack_contact_frame: int = 2
## Glow of the dash attack - an outline while the character dashes, a flash on the contact frame
## and on a kill, and afterimages behind it. Alpha 0 (the default) turns all of it off.
@export var attack_glow: Color = Color(1.0, 1.0, 1.0, 0.0)
## Seconds between afterimages while dashing; 0 leaves none.
@export_range(0.0, 0.2, 0.005) var afterimage_interval: float = 0.03
## Seconds an afterimage takes to fade, and its opacity when it appears.
@export_range(0.05, 0.6, 0.01) var afterimage_life: float = 0.18
@export_range(0.0, 1.0, 0.01) var afterimage_alpha: float = 0.45
## For a dash drawn from the side (flying up the frame, head to its right): mirror it on a dash with
## a rightward component, so the turned drawing never flies upside down. Costs the drawing's
## left-right detail on those dashes, as the mirrored right wall already does.
@export var dash_head_up: bool = false
## A dagger slash drawn by `character_slash.gdshader` on the contact frame: a crescent sweeping
## across the front of the flight in [member attack_glow], edged in this colour. Alpha 0 (the
## default) draws none.
@export var slash_edge: Color = Color(1.0, 1.0, 1.0, 0.0)
## The slash's size as a share of [member design_size], and how far ahead of the body it sits.
@export_range(0.5, 3.0, 0.05) var slash_size: float = 1.3
@export_range(-1.0, 1.0, 0.01) var slash_forward: float = 0.18
@export_group("")

## The dash. The dash *is* the attack, so there is no separate contact animation: one of these
## frames is the contact frame and the accent holds the same picture.
const DASH: StringName = &"dash_loop"
const WALL_BOTTOM: StringName = &"wall_bottom"
const WALL_TOP: StringName = &"wall_top"
const WALL_LEFT: StringName = &"wall_left"
## Screen-space animations: while one plays, the body is turned back upright.
const SURFACE_ANIMATIONS: Array[StringName] = [WALL_BOTTOM, WALL_TOP, WALL_LEFT]
## Inward wall normal (see [member surface_normal]) to the animation painted for that wall, and
## whether it is drawn mirrored. The right wall is the left wall flipped.
const SURFACE_NORMAL_ANIMATIONS: Dictionary[Vector2, Array] = {
	Vector2.UP: [WALL_BOTTOM, false],
	Vector2.DOWN: [WALL_TOP, false],
	Vector2.RIGHT: [WALL_LEFT, false],
	Vector2.LEFT: [WALL_LEFT, true],
}

## Gameplay states drawn with the dash frames: the launch, the flight and the kill accent are one
## picture. Every other state falls through to the wall the character is resting against.
const DASH_STATES: Array[StringName] = [DASH_START, DASH_LOOP, ATTACK]

## The one menu animation. A card that is focused, equipped or bought keeps breathing — the
## storefront reactions were cut with the rest (owner, 2026-09-20).
@export var menu_idle_animation: StringName = &"storefront_idle"
const MENU_IDLE: StringName = &"storefront_idle"
## The menu performance as a pre-rendered video, generated by `tools/art/extract_menu_video.py`;
## null performs [member menu_idle_animation] from the menu frame set.
@export var menu_video: MenuVideoData
## What [method get_current_animation] reports while the menu video is on screen.
const MENU_VIDEO: StringName = &"menu_video"

## The menu frames are a 448 px cell. They are drawn at `design_size` / 448 - the run cell over the
## menu cell, 384/448 for most characters - so a character keeps the same apparent height on a Shop
## card as in a run whatever cell size its run sheet was packed at.
const MENU_CELL: float = 448.0
## Radians per second the body rights itself when a screen-space wall animation takes over. Fast
## enough to look immediate, slow enough that landing under a ceiling never spins in one frame
## (the rig smoothness contract measures exactly that).
const BODY_TURN_RATE: float = 24.0
## Outline and flash of the dash attack ([member attack_glow]).
const ATTACK_SHADER: Shader = preload("res://assets/shaders/character_attack.gdshader")
## Afterimages alive at once; the oldest is reused, so a long dash never grows the node count.
const AFTERIMAGE_POOL: int = 8
## How fast the outline comes up when a dash starts and fades when it lands, and how fast a flash
## fades, in units per second.
const OUTLINE_RISE: float = 14.0
const OUTLINE_FALL: float = 6.0
const FLASH_FADE: float = 6.0
## How far a flash pushes the frame toward the glow: short of 1, so the character stays readable.
const FLASH_PEAK: float = 0.75
const SLASH_SHADER: Shader = preload("res://assets/shaders/character_slash.gdshader")
## Seconds the slash takes to sweep across, and the moment it has faded out entirely.
const SLASH_SWEEP: float = 0.08
const SLASH_LIFE: float = 0.26

var _animation: StringName = &""
var _menu: bool = false
var _still: bool = false
## Which frame set is loaded, so switching costs nothing when nothing changed.
var _frames_path: String = ""
## The menu video while one is on screen; freed as soon as the character leaves the menu.
var _video: CharacterMenuVideo
## The attack look, when [member attack_glow] asks for one: the sprite's shader, its current
## outline and flash, the contact frame last flashed, and the afterimage pool with each one's life.
var _attack_material: ShaderMaterial
var _outline: float = 0.0
var _flash: float = 0.0
var _flashed_frame: int = -1
var _afterimages: Array[Sprite2D] = []
var _afterimage_lives: Array[float] = []
## Where each afterimage was dropped, in world space: re-applied every frame, because the pool
## moves with the character and a trail must stay where it was left.
var _afterimage_places: Array[Transform2D] = []
var _next_afterimage: int = 0
var _afterimage_wait: float = 0.0
## The slash drawn on the contact frame, and seconds since it started (negative: not showing).
var _slash: Sprite2D
var _slash_material: ShaderMaterial
var _slash_time: float = -1.0

@onready var _body: Node2D = %Body
@onready var _sprite: AnimatedSprite2D = %PoseSprite


func _ready() -> void:
	super()
	_build_attack_look()
	# A Shop card is configured before it is added to the tree, so `set_preview_mode` and
	# `set_reduced_motion` can both land ahead of `_ready`. Re-apply what they asked for now that
	# the sprite exists, or every card would show the gameplay frames.
	_apply_frame_set()
	_refresh(0.0, true)


## Menu previews perform the storefront loop: a menu character is not resting against anything, so
## the wall animations are never reachable there.
func set_preview_mode(enabled: bool) -> void:
	_menu = enabled
	super(enabled)
	_apply_frame_set()
	_refresh(0.0, true)


## Reduced Motion holds one readable frame per animation instead of playing it, and stops the walls
## turning; the state and the wall it picks are unchanged.
func set_reduced_motion(enabled: bool) -> void:
	_still = enabled
	super(enabled)
	_apply_frame_set()
	_refresh(0.0, true)


## The animation on screen, for the tests and the QA fixtures.
func get_current_animation() -> StringName:
	return _animation


## True while the menu frame set is the one in memory. The tests assert a run never holds it.
func is_menu_frame_set() -> bool:
	return _frames_path == menu_frames


## True while the menu video is on screen and playing.
func is_menu_video_playing() -> bool:
	return _video != null and _video.is_playing() and not _video.paused


## The menu video player while one is on screen, for the tests and the QA fixtures.
func get_menu_video_player() -> VideoStreamPlayer:
	return _video


## True while the character is drawn mirrored — the right wall, which reuses the left wall's frames.
func is_mirrored() -> bool:
	return _sprite.flip_h


## Box around the current frame in this rig's frame. The base walks sprite layers; this rig has one
## [AnimatedSprite2D] instead.
func get_layer_bounds() -> Rect2:
	var rect := Rect2()
	if _video != null:
		rect = Rect2(_video.position, _video.size)
	else:
		var texture: Texture2D = _current_texture()
		if texture == null:
			return Rect2()
		var size: Vector2 = texture.get_size() * _sprite.scale
		rect = Rect2(-size * 0.5, size)
	var to_rig: Transform2D = (
		get_global_transform().affine_inverse() * _body.get_global_transform()
	)
	var bounds := Rect2(to_rig * rect.position, Vector2.ZERO)
	for corner: Vector2 in [
		Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y),
	]:
		bounds = bounds.expand(to_rig * corner)
	return bounds


## A mid-dash redirect starts the attack again when the dash is a one-shot.
func restart_dash() -> void:
	_restart_attack()


## Current outline and flash of the attack look (0..1 each), for the tests.
func get_attack_look() -> Vector2:
	return Vector2(_outline, _flash)


## Afterimages on screen now, for the tests.
func get_visible_afterimages() -> int:
	var count: int = 0
	for ghost: Sprite2D in _afterimages:
		if ghost.visible:
			count += 1
	return count


func _update_secondary_motion(delta: float) -> void:
	_refresh(delta, false)
	_update_attack_look(delta)


## A new state starts its animation at once, but lets the wall counter-rotation ease in. A launch
## starts a one-shot dash from its first frame; a kill flashes the attack.
func _on_state_started(state_name: StringName) -> void:
	if not is_node_ready():
		return
	_refresh(0.0, false)
	if state_name == DASH_START:
		_restart_attack()
	elif state_name == ATTACK and _attack_material != null and not _still:
		_flash = FLASH_PEAK


func _apply_reduced_pose() -> void:
	_refresh(0.0, true)


## Picks the animation, points the body the right way up and keeps the drawn size honest.
func _refresh(delta: float, snap: bool) -> void:
	if not is_node_ready():
		return
	if _video != null:
		_animation = MENU_VIDEO
		_body.rotation = 0.0
		return
	var wanted: StringName = _target_animation()
	# Mirroring and the animation are separate: turning mid-attack must not restart it.
	_sprite.flip_h = _menu == false and _mirrors(wanted)
	if wanted != _animation:
		_animation = wanted
		_sprite.animation = wanted
		# Reduced Motion holds the first frame, or the dash's contact frame: the one a kill reads from.
		_sprite.frame = (attack_contact_frame if wanted == DASH else 0) if _still else 0
		if not _still:
			_sprite.play()
	_sprite.scale = Vector2.ONE * (
		(menu_art_scale if menu_art_scale > 0.0 else art_scale) * design_size / MENU_CELL
		if _menu else art_scale
	)
	_sprite.position = menu_offset if _menu else Vector2.ZERO
	if _still:
		_sprite.pause()
	elif not _sprite.is_playing() and _loops(_animation):
		# A one-shot (a dash drawn as a single attack) holds its last frame until the next state.
		_sprite.play()
	# A screen-space frame is already drawn the way the player must see it, so the rotation the base
	# applied to stand on this wall is taken off again instead of turning the picture twice.
	var inherited: float = wrapf(_body.global_rotation - _body.rotation, -PI, PI)
	var upright: float = -inherited if _animation in SURFACE_ANIMATIONS else 0.0
	if snap or _still:
		_body.rotation = upright
	else:
		_body.rotation = rotate_toward(_body.rotation, upright, delta * BODY_TURN_RATE)


## The whole thirteen-state vocabulary, resolved onto the five animations a drawn character has.
##
## A menu character always performs the storefront loop. In a run the character is either dashing or
## against a wall: there is nothing else it can be doing, because the windup shows only the aim
## arrow, the landing *is* the wall animation arriving, and a hit or a death plays out through the
## controller's blink, edge reset and alpha dissolve over whatever is already on screen.
func _target_animation() -> StringName:
	if _menu:
		return menu_idle_animation
	var state: StringName = get_current_visual_state()
	# Owner decision 2026-09-19: holding the aim arrow must not change the character at all. Nothing
	# in a run asks for it; if anything ever does, whatever is already playing keeps playing.
	if state == AIM_CHARGE:
		return _animation if _animation != &"" else _nearest_wall()[0]
	if state in DASH_STATES:
		return DASH
	return _nearest_wall()[0]


func _loops(animation: StringName) -> bool:
	var frames: SpriteFrames = _sprite.sprite_frames
	return frames == null or not frames.has_animation(animation) or frames.get_animation_loop(animation)


## Plays a one-shot dash from its first frame. A looping dash just keeps looping.
func _restart_attack() -> void:
	if not is_node_ready() or _still or _animation != DASH or _loops(DASH):
		return
	_sprite.frame = 0
	_sprite.play()
	_flashed_frame = -1


## The attack look exists only when [member attack_glow] is visible: the sprite gets the attack
## shader, and a pool of afterimages is laid out behind it - first child, so it draws before the
## body. Not `top_level`: that would draw the trail over the character.
func _build_attack_look() -> void:
	if attack_glow.a <= 0.0 or _attack_material != null:
		return
	_attack_material = ShaderMaterial.new()
	_attack_material.shader = ATTACK_SHADER
	_attack_material.set_shader_parameter(&"glow_color", attack_glow)
	_sprite.material = _attack_material
	var trail := Node2D.new()
	trail.name = "Afterimages"
	add_child(trail)
	move_child(trail, 0)
	if slash_edge.a > 0.0:
		_build_slash()
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for index: int in AFTERIMAGE_POOL:
		var ghost := Sprite2D.new()
		ghost.material = additive
		ghost.visible = false
		trail.add_child(ghost)
		_afterimages.append(ghost)
		_afterimage_lives.append(0.0)
		_afterimage_places.append(Transform2D.IDENTITY)


## Outline up while the character dashes and down after it lands, a flash on the contact frame,
## and afterimages dropped along the flight. Menus and Reduced Motion get none of the motion.
func _update_attack_look(delta: float) -> void:
	if _attack_material == null:
		return
	var dashing: bool = not _menu and _animation == DASH
	var target: float = 1.0 if dashing else 0.0
	_outline = move_toward(_outline, target, delta * (OUTLINE_RISE if dashing else OUTLINE_FALL))
	if dashing and not _still and _sprite.frame == attack_contact_frame \
			and _flashed_frame != attack_contact_frame:
		_flash = FLASH_PEAK
		_flashed_frame = attack_contact_frame
		_slash_time = 0.0
	_flash = move_toward(_flash, 0.0, delta * FLASH_FADE)
	_update_slash(delta)
	_attack_material.set_shader_parameter(&"outline", _outline)
	_attack_material.set_shader_parameter(&"flash", _flash)
	for index: int in _afterimages.size():
		if _afterimage_lives[index] <= 0.0:
			continue
		_afterimage_lives[index] -= delta
		var ghost: Sprite2D = _afterimages[index]
		ghost.global_transform = _afterimage_places[index]
		ghost.visible = _afterimage_lives[index] > 0.0
		ghost.modulate.a = afterimage_alpha * maxf(0.0, _afterimage_lives[index] / afterimage_life)
	if not dashing or _still or afterimage_interval <= 0.0:
		_afterimage_wait = 0.0
		return
	_afterimage_wait -= delta
	if _afterimage_wait <= 0.0:
		_afterimage_wait = afterimage_interval
		_drop_afterimage()


## The slash square sits in front of the pose, on the body, so it turns with the flight; it is a
## child of the body drawn after the sprite, so it covers the frame's own dagger arc.
func _build_slash() -> void:
	_slash_material = ShaderMaterial.new()
	_slash_material.shader = SLASH_SHADER
	_slash_material.set_shader_parameter(&"core_color", attack_glow)
	_slash_material.set_shader_parameter(&"edge_color", slash_edge)
	var white := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	white.fill(Color.WHITE)
	_slash = Sprite2D.new()
	_slash.name = "Slash"
	_slash.texture = ImageTexture.create_from_image(white)
	_slash.material = _slash_material
	_slash.visible = false
	# A fixed transform: the rig smoothness contract samples every node on the body, so the slash
	# never changes size or side itself - the shader does the sweep and the mirroring.
	var side: float = design_size * slash_size * art_scale / 8.0
	_slash.scale = Vector2(side, side)
	_slash.position = Vector2(0.0, -design_size * slash_forward * art_scale)
	_body.add_child(_slash)


## Sweeps the slash across, then fades it. The sweep turns with the drawing: mirrored with it.
func _update_slash(delta: float) -> void:
	if _slash == null:
		return
	if _slash_time < 0.0 or _menu or _still or _slash_time > SLASH_LIFE:
		_slash.visible = false
		_slash_time = -1.0
		return
	_slash_time += delta
	_slash.visible = true
	_slash_material.set_shader_parameter(&"mirror", _sprite.flip_h)
	_slash_material.set_shader_parameter(&"progress", clampf(_slash_time / SLASH_SWEEP, 0.0, 1.0))
	_slash_material.set_shader_parameter(
		&"strength", 1.0 - smoothstep(SLASH_SWEEP, SLASH_LIFE, _slash_time)
	)


## True while the contact slash is on screen, for the tests.
func is_slash_showing() -> bool:
	return _slash != null and _slash.visible


## Leaves a copy of the frame on screen where the character is now, in the glow colour.
func _drop_afterimage() -> void:
	var frames: SpriteFrames = _sprite.sprite_frames
	if frames == null or not frames.has_animation(_animation) or _afterimages.is_empty():
		return
	var index: int = _next_afterimage
	_next_afterimage = (index + 1) % _afterimages.size()
	var ghost: Sprite2D = _afterimages[index]
	_afterimage_lives[index] = afterimage_life
	_afterimage_places[index] = _sprite.global_transform
	ghost.texture = frames.get_frame_texture(_animation, _sprite.frame)
	ghost.global_transform = _sprite.global_transform
	ghost.flip_h = _sprite.flip_h
	ghost.offset = _sprite.offset
	ghost.modulate = Color(attack_glow, afterimage_alpha)
	ghost.visible = true


func _mirrors(animation: StringName) -> bool:
	if animation == DASH:
		# Turned by the flight angle + 90 degrees, the drawing's head (its +X) points down exactly
		# when the flight has a rightward component.
		return dash_head_up and movement_direction.x > 0.0
	return animation == WALL_LEFT and bool(_nearest_wall()[1])


## The arena is a rounded polygon, so a resting normal is rarely exactly cardinal: the nearest wall
## by alignment is the right answer, not the one that happens to round.
func _nearest_wall() -> Array:
	var best: Array = SURFACE_NORMAL_ANIMATIONS[Vector2.UP]
	var closest: float = -INF
	for normal: Vector2 in SURFACE_NORMAL_ANIMATIONS:
		var alignment: float = normal.dot(surface_normal)
		if alignment > closest:
			closest = alignment
			best = SURFACE_NORMAL_ANIMATIONS[normal]
	return best


## Swaps the loaded frame set. Only one is ever in memory: a Shop card must not pay for the run
## animations of every character on the carousel.
##
## A menu with a video holds no frame set at all, so a Shop card playing a clip pays for neither
## sheet. Reduced Motion falls back to the menu frame set, which holds one readable frame.
func _apply_frame_set() -> void:
	if not is_node_ready():
		return
	var video: bool = _plays_menu_video()
	var wanted: String = "" if video else (menu_frames if _menu else gameplay_frames)
	if _frames_path != wanted:
		_frames_path = wanted
		_sprite.sprite_frames = null if wanted.is_empty() else load(wanted) as SpriteFrames
		_animation = &""
	_sprite.visible = not video
	if video:
		_start_menu_video()
	else:
		_stop_menu_video()


func _plays_menu_video() -> bool:
	return _menu and not _still and menu_video != null and menu_video.stream != null


## Adds the shared [CharacterMenuVideo]; it plays, pauses while hidden and restarts after its screen
## is re-attached on its own.
func _start_menu_video() -> void:
	if _video != null:
		return
	_video = CharacterMenuVideo.create(menu_video)
	_body.add_child(_video)


func _stop_menu_video() -> void:
	if _video == null:
		return
	_video.dispose()
	_video = null


func _current_texture() -> Texture2D:
	var frames: SpriteFrames = _sprite.sprite_frames
	if frames == null or not frames.has_animation(_sprite.animation):
		return null
	return frames.get_frame_texture(_sprite.animation, _sprite.frame)
