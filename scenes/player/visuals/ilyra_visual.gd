class_name IlyraVisual
extends PlayableCharacterVisual
## Ilyra: whole painted poses on a single [AnimatedSprite2D], from loose PNGs rather than a sheet.
##
## She is the character the whole-frame direction came out of, and the only one still drawn from
## individual files: [WholeFrameCharacterVisual] is the path every other one takes, and re-cutting
## her onto its packer is outstanding work. Instead of layers on bone chains, each of the five
## surviving animations is a finished painting from the approved `ilyra` pose pack, with a
## [CharacterAura] of drifting star motes around her so a held painting still reads as a living
## character. The shared base owns the state machine, heading, alpha, squash and bounce; this script
## only decides which painting shows, where it is anchored and how big it is drawn. It holds no
## collision and never touches gameplay.
##
## **Her menus play a video** (ADR-0016): the ready-stance clip the owner approved on 2026-09-21,
## through the shared [CharacterMenuVideo]. While it plays, the pose sprite and her ornament ring are
## hidden — the clip carries its own crown sparkle, and the ring would add pieces the approved take
## does not have. Reduced Motion shows [constant MENU_REST] instead, as before.
##
## Two things are specific to painted poses. The pack does not frame the figure identically in every
## picture, so a [CharacterPoseSheet] generated with the art carries the per-pose drawing offset and
## scale that keep the collision-centre anchor and the apparent height fixed. And the four wall
## poses are painted in screen space rather than in the character's own space, so while one shows,
## the rotation the base applies to stand on that wall is cancelled again instead of turning the
## painting twice.

## Where each pose is drawn (generated: `tools/art/extract_playable_characters.py ilyra`).
const POSE_SHEET: CharacterPoseSheet = preload("res://data/characters/ilyra_poses.tres")

## The resting painting. Nothing reaches it as a *pose* any more — a live character rests against a
## wall and a menu character holds [constant MENU_REST] — but it is still the character's portrait
## ([code]FormData.texture[/code]), which is why it stays in the pack and the sheet. Its blink twin,
## `idle_blink.png`, is unused for the same reason: swapping whole paintings reads as a cut.
const IDLE_POSE: StringName = &"idle_hover"
## The dash *is* the attack, so the contact accent holds the pack's attack frame of the dash loop.
const ATTACK_POSE: StringName = &"dash_loop_01_attack"
const WALL_BOTTOM: StringName = &"wall_bottom"
const WALL_TOP: StringName = &"wall_top"
const WALL_LEFT: StringName = &"wall_left"
const WALL_RIGHT: StringName = &"wall_right"

## Gameplay states drawn with the dash paintings: the launch, the flight and the kill accent are one
## picture, because the dash *is* the attack. Every other state falls through to the wall she is
## resting against — see [WholeFrameCharacterVisual], which holds the same rule for the characters
## built on the packed sheets.
const DASH_STATES: Array[StringName] = [DASH_START, DASH_LOOP, ATTACK]
## The dash cycle. Its second painting is the contact frame the kill accent holds.
const DASH_POSES: Array[StringName] = [&"dash_loop_00", ATTACK_POSE]
## Frames per second the dash cycles at.
const DASH_FPS: float = 12.0
## Her menu frames: whole 600x724 paintings of her own, not the 627 gameplay canvas. She only ever
## shows these in a menu, where she is drawn large. `MENU_BLINK` and `MENU_SETTLE` are extracted but
## unreachable — see [constant MENU_REST] — and stay named here so [constant MENU_POSES] can tell
## every menu canvas from a gameplay one, and so a future registered loop has somewhere to land.
const MENU_WELCOME: StringName = &"storefront_welcome"
const MENU_BLINK: StringName = &"storefront_blink"
const MENU_SETTLE: StringName = &"storefront_settle"
## Her fan spin. It was her menu attack until the storefront reactions were cut on 2026-09-20;
## it stays named so [constant MENU_POSES] can still tell a menu canvas from a gameplay one.
const MENU_FLOURISH: StringName = &"storefront_flourish"
## The menu rest pose. It is deliberately ONE painting, not a loop: the four storefront frames are
## four different drawings, so cycling them swapped her whole silhouette and read as a flip-book
## next to the other characters, whose rigs move a few parts continuously. She breathes on the
## shared body animation and her ornament ring keeps turning, which is the same read Morrow has.
## The other three frames are reactions, not idle states.
const MENU_REST: StringName = MENU_WELCOME
## The menu performance as a pre-rendered video (`tools/art/extract_menu_video.py`); null holds
## [constant MENU_REST] instead.
@export var menu_video: MenuVideoData
## What [method get_current_pose] reports while the menu video is on screen.
const MENU_VIDEO: StringName = &"menu_video"
## Every menu frame, so the placement code can tell them from the gameplay poses.
const MENU_POSES: Array[StringName] = [MENU_WELCOME, MENU_BLINK, MENU_SETTLE, MENU_FLOURISH]
## The menu frames are 724 px tall where the gameplay canvas is 627, so they are drawn at 627/724
## to keep her the same apparent height on a Shop card as in a run.
const MENU_SCALE: float = 0.866

## Poses painted in screen space, for a character resting against that boundary.
const SURFACE_POSES: Array[StringName] = [WALL_BOTTOM, WALL_TOP, WALL_LEFT, WALL_RIGHT]
## Inward wall normal (see [member surface_normal]) to the pose painted for standing on that wall.
const SURFACE_NORMAL_POSES: Dictionary[Vector2, StringName] = {
	Vector2.UP: WALL_BOTTOM,
	Vector2.DOWN: WALL_TOP,
	Vector2.RIGHT: WALL_LEFT,
	Vector2.LEFT: WALL_RIGHT,
}

## Scale units per second the drawn size eases at. A pose painted smaller than the rest grows into
## place over about a twelfth of a second, which reads as a settle rather than a pop and keeps every
## frame well inside the rig smoothness contract.
const POSE_SCALE_RATE: float = 2.5
## Radians per second the painting rights itself when a screen-space wall pose takes over.
const BODY_TURN_RATE: float = 24.0

var _pose: StringName = &""
var _cycle_time: float = 0.0
var _pose_scale: float = 1.0
var _still: bool = false
var _menu: bool = false
## The menu video while one is on screen; freed as soon as she leaves the menu.
var _video: CharacterMenuVideo

@onready var _body: Node2D = %Body
@onready var _sprite: AnimatedSprite2D = %PoseSprite


func _ready() -> void:
	super()
	_report_pack_gaps()
	_apply_menu_video()
	_settle_pose()


## Menu previews show the hovering idle even when the rig reports a wall: only a live gameplay
## character rests against a boundary.
func set_preview_mode(enabled: bool) -> void:
	_menu = enabled
	super(enabled)
	_apply_menu_video()
	_settle_pose()


## Reduced Motion freezes the cycles and the menu loop but keeps the state's pose and its wall.
func set_reduced_motion(enabled: bool) -> void:
	_still = enabled
	super(enabled)
	_apply_menu_video()
	_settle_pose()


## The painting currently on screen, for tests and QA fixtures ([constant MENU_VIDEO] while the
## menu video plays).
func get_current_pose() -> StringName:
	return _pose


## True while the menu video is on screen and playing.
func is_menu_video_playing() -> bool:
	return _video != null and _video.is_playing() and not _video.paused


## The menu video player while one is on screen, for the tests and the QA fixtures.
func get_menu_video_player() -> VideoStreamPlayer:
	return _video


## Drawn offset and scale of the current painting, for the anchor checks.
func get_pose_transform() -> Transform2D:
	return Transform2D(0.0, Vector2.ONE * _pose_scale, 0.0, _sprite.offset * _pose_scale)


## Box around the painting in this rig's frame; the base walks sprite layers, and this rig has one
## [AnimatedSprite2D] instead.
func get_layer_bounds() -> Rect2:
	var rect := Rect2()
	var drawn_by: CanvasItem = _sprite
	if _video != null:
		rect = Rect2(_video.position, _video.size)
		drawn_by = _body
	else:
		var texture: Texture2D = _current_texture()
		if texture == null:
			return Rect2()
		var size: Vector2 = texture.get_size()
		rect = Rect2(_sprite.offset - size * 0.5, size)
	var to_rig: Transform2D = (
		get_global_transform().affine_inverse() * drawn_by.get_global_transform()
	)
	var bounds := Rect2(to_rig * rect.position, Vector2.ZERO)
	for corner: Vector2 in [
		Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y),
	]:
		bounds = bounds.expand(to_rig * corner)
	return bounds


func _update_secondary_motion(delta: float) -> void:
	_cycle_time += delta
	_refresh_pose(delta, false)


## A new state restarts its cycle and shows its first painting at once, but lets the drawn scale and
## the wall-pose counter-rotation ease in: landing under a ceiling must not spin the picture in one
## frame (the rig smoothness contract measures exactly that).
func _on_state_started(_state_name: StringName) -> void:
	if not is_node_ready():
		return
	_cycle_time = 0.0
	_refresh_pose(0.0, false)


func _apply_reduced_pose() -> void:
	_settle_pose()


## Shows the menu video in a menu (unless Reduced Motion is on) and the paintings everywhere else.
func _apply_menu_video() -> void:
	if not is_node_ready():
		return
	var wanted: bool = _menu and not _still and menu_video != null and menu_video.stream != null
	if wanted and _video == null:
		_video = CharacterMenuVideo.create(menu_video)
		_body.add_child(_video)
	elif not wanted and _video != null:
		_video.dispose()
		_video = null
		_pose = &""
	_sprite.visible = _video == null
	if _aura != null:
		_aura.visible = _video == null


## Re-picks the painting and snaps its placement, for the moments that are not a normal frame:
## becoming a preview, Reduced Motion turning on or off, and the first frame after loading.
func _settle_pose() -> void:
	if not is_node_ready():
		return
	_cycle_time = 0.0
	_refresh_pose(0.0, true)


## Shows [method _target_pose], then places it: the sheet's drawing offset at once, its scale and
## the wall-pose counter-rotation over a few frames unless [param snap] asks for them immediately.
func _refresh_pose(delta: float, snap: bool) -> void:
	if _video != null:
		_pose = MENU_VIDEO
		_body.rotation = 0.0
		return
	var pose: StringName = _target_pose()
	var menu_frame: bool = pose in MENU_POSES
	if pose != _pose:
		_pose = pose
		_sprite.animation = pose
		_sprite.frame = 0
		_sprite.offset = Vector2.ZERO if menu_frame else POSE_SHEET.get_offset(pose)
	var wanted_scale: float = MENU_SCALE if menu_frame else POSE_SHEET.get_scale(pose)
	if snap or _still:
		_pose_scale = wanted_scale
	else:
		_pose_scale = move_toward(_pose_scale, wanted_scale, delta * POSE_SCALE_RATE)
	_sprite.scale = Vector2.ONE * _pose_scale
	# The wall paintings are already oriented on screen, so undo the rotation the base applied to
	# stand the character on that wall rather than turning the picture a second time.
	var inherited: float = wrapf(_body.global_rotation - _body.rotation, -PI, PI)
	var upright: float = -inherited if pose in SURFACE_POSES else 0.0
	if snap or _still:
		_body.rotation = upright
	else:
		_body.rotation = rotate_toward(_body.rotation, upright, delta * BODY_TURN_RATE)


## The whole thirteen-state vocabulary, resolved onto the paintings she still shows.
##
## Five animations and no more (owner, 2026-09-20): a menu character holds her storefront rest, a
## live one is either dashing or against a wall. The windup shows only the aim arrow, the landing
## *is* the wall painting arriving, and a hit or a death plays out through the controller's blink,
## edge reset and alpha dissolve over whatever is already on screen. Her other paintings are still
## in the pack and in her [SpriteFrames]; nothing reaches them.
func _target_pose() -> StringName:
	if _menu:
		return MENU_REST
	var state: StringName = get_current_visual_state()
	# Holding the aim arrow must not change the character (owner, 2026-09-19).
	if state == AIM_CHARGE:
		return _pose if _pose != &"" else _surface_pose()
	if state not in DASH_STATES:
		return _surface_pose()
	var step: int = 0
	if not _still:
		step = int(_cycle_time * DASH_FPS) % DASH_POSES.size()
	return DASH_POSES[step]


## The wall the character rests against, as the pose painted for it. Arena edges can be diagonal
## (a Rift floor is a polygon), so the nearest of the four cardinal walls wins.
func _surface_pose() -> StringName:
	var pose: StringName = WALL_BOTTOM
	var closest: float = -INF
	for normal: Vector2 in SURFACE_NORMAL_POSES:
		var alignment: float = normal.dot(surface_normal)
		if alignment > closest:
			closest = alignment
			pose = SURFACE_NORMAL_POSES[normal]
	return pose


func _current_texture() -> Texture2D:
	var frames: SpriteFrames = _sprite.sprite_frames
	if frames == null or not frames.has_animation(_sprite.animation):
		return null
	return frames.get_frame_texture(_sprite.animation, _sprite.frame)


## Loudly reports a pose the generated sheet and the scene's [SpriteFrames] disagree about, so a
## re-run of the extractor that adds or renames a pose cannot fail silently at runtime.
func _report_pack_gaps() -> void:
	var frames: SpriteFrames = _sprite.sprite_frames
	if frames == null:
		push_error("IlyraVisual: the pose sprite has no SpriteFrames")
		return
	for pose: StringName in POSE_SHEET.get_pose_names():
		if not frames.has_animation(pose):
			push_error("IlyraVisual: the scene is missing the %s pose" % pose)
	for pose: StringName in frames.get_animation_names():
		if not POSE_SHEET.has_pose(pose) and pose not in MENU_POSES:
			push_error("IlyraVisual: %s is neither a sheet pose nor a menu frame" % pose)
