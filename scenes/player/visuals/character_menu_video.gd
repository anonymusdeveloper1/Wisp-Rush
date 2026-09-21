class_name CharacterMenuVideo
extends VideoStreamPlayer
## A character's menu video (ADR-0016), drawn in the square its [MenuVideoData] placed it in.
##
## Shared by every visual that can perform a menu video — [WholeFrameCharacterVisual] and
## [IlyraVisual] today. It owns the three things a [VideoStreamPlayer] does not do on its own for
## this job:
##
## - it draws through the packed-alpha shader, since Theora carries no alpha;
## - it pauses while hidden: a Shop card on another tab keeps its character in the tree, and a
##   player keeps decoding on its own;
## - it restarts when it re-enters the tree. A [VideoStreamPlayer] stops itself on leaving it, and
##   Main detaches the kept Home instead of freeing it, so without this the Home hero's video stood
##   still after every trip to another screen (owner bug report, 2026-09-21).
##
## Playback starts on the first entry too, so a caller only builds it with [method create] and adds
## it under the node the character is drawn in.

const PACKED_ALPHA_SHADER: Shader = preload("res://assets/shaders/packed_alpha_video.gdshader")


## A player for [param data]: a looping square of [member MenuVideoData.side] rig px centred on its
## offset, drawn through the packed-alpha shader, never taking a tap from the card under it.
static func create(data: MenuVideoData) -> CharacterMenuVideo:
	var video := CharacterMenuVideo.new()
	video.name = "MenuVideo"
	video.stream = data.stream
	video.loop = true
	video.expand = true
	video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video.size = Vector2.ONE * data.side
	video.position = data.offset - video.size * 0.5
	var material := ShaderMaterial.new()
	material.shader = PACKED_ALPHA_SHADER
	material.set_shader_parameter(&"alpha_floor", data.alpha_floor)
	material.set_shader_parameter(&"alpha_ceiling", data.alpha_ceiling)
	video.material = material
	return video


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			# Deferred so the player has finished entering the tree before it is asked to play.
			_resume.call_deferred()
		NOTIFICATION_VISIBILITY_CHANGED:
			if is_inside_tree():
				paused = not is_visible_in_tree()


## Stops playback and frees the player; the character is leaving the menu.
func dispose() -> void:
	stop()
	var parent: Node = get_parent()
	if parent != null:
		parent.remove_child(self)
	queue_free()


func _resume() -> void:
	if not is_inside_tree():
		return
	if not is_playing():
		play()
	paused = not is_visible_in_tree()
