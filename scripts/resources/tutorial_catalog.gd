class_name TutorialCatalog
extends Resource
## The Tutorial screen's ordered lessons (easiest first), its arena skin and every timing.

## Ordered lessons, easiest to most skilful.
@export var lessons: Array[TutorialLessonData] = []
## Endless skin the tutorial arena shows (the default, Astral Observatory).
@export var arena_skin_id: StringName = &"astral_observatory"
## Boss health in the boss lesson (rounded to three phase bands).
@export_range(3, 30, 3) var boss_health: int = 3
## Caption while a missed attempt rebuilds.
@export var retry_caption: String = "Try again."
## Caption after a hit in a lesson that must be passed untouched.
@export var hit_caption: String = "Hit! Watch the danger and try again."
## Callout and caption of the final beat.
@export var complete_callout: String = "TUTORIAL COMPLETE"
@export var complete_caption: String = "The Rift is yours."
@export_group("Demo")
## Seconds after a lesson is set up before the hand moves (spawn telegraphs finish first).
@export_range(0.0, 3.0, 0.05) var demo_start_delay: float = 1.0
## Fingertip press before dragging, seconds.
@export_range(0.0, 1.0, 0.05) var press_seconds: float = 0.3
## Drag duration, seconds.
@export_range(0.05, 2.0, 0.05) var drag_seconds: float = 0.55
## Hold at the end of the drag before release, seconds.
@export_range(0.0, 1.0, 0.05) var hold_seconds: float = 0.2
## Release ring fade, seconds.
@export_range(0.05, 1.5, 0.05) var release_seconds: float = 0.45
## Quick drag of a mid-dash redirect swipe (press + drag), seconds.
@export_range(0.02, 0.5, 0.01) var redirect_drag_seconds: float = 0.1
## Drag length in design px.
@export_range(60.0, 600.0, 10.0) var drag_length: float = 260.0
## Distance in design px from the Wisp at which a drag starts, along the drag.
@export_range(0.0, 300.0, 10.0) var drag_start_offset: float = 90.0
## Pause between demonstrated swipes once the Wisp rests, seconds.
@export_range(0.0, 2.0, 0.05) var swipe_gap_seconds: float = 0.45
## Distance in design px from the hazard at which the demonstrated hit lands.
@export_range(20.0, 400.0, 10.0) var demo_hit_distance: float = 150.0
## Rest after the demo's last landing before the try, seconds.
@export_range(0.0, 3.0, 0.05) var demo_settle_seconds: float = 0.9
## Real seconds the demo lets the upgrade cards rest before the hand taps one.
@export_range(0.0, 3.0, 0.05) var demo_card_look_seconds: float = 0.7
## Zero-based card the demo hand taps (clamped to the cards shown).
@export_range(0, 2, 1) var demo_card_index: int = 1
## Real seconds the demo waits for the upgrade tray to open before it moves on without the tap.
@export_range(1.0, 20.0, 0.5) var demo_tray_wait_limit: float = 8.0
@export_group("Try")
## Idle seconds before the hand repeats its hint during a try.
@export_range(0.5, 10.0, 0.1) var hint_interval: float = 2.6
## Opacity of the hint hand during a try (the demo hand is fully opaque).
@export_range(0.1, 1.0, 0.05) var hint_alpha: float = 0.6
## Delay before a missed attempt rebuilds, seconds.
@export_range(0.0, 3.0, 0.05) var retry_seconds: float = 0.8
## Delay before a hit Wisp's Soul Fragments refill, seconds (under the hit's invulnerability).
@export_range(0.0, 0.85, 0.05) var refill_delay: float = 0.6
## Success beat before the next lesson, seconds.
@export_range(0.2, 4.0, 0.1) var success_seconds: float = 1.3
## TUTORIAL COMPLETE beat before leaving, seconds.
@export_range(0.2, 6.0, 0.1) var complete_seconds: float = 2.0
## Callout emphasis of the success beat.
@export_range(0.8, 2.0, 0.05) var success_emphasis: float = 1.25


## Returns authoring failures for the whole catalog.
func validate() -> PackedStringArray:
	var failures := PackedStringArray()
	if lessons.is_empty():
		failures.append("no lessons")
	for lesson: TutorialLessonData in lessons:
		if lesson == null:
			failures.append("null lesson")
			continue
		failures.append_array(lesson.validate())
	return failures
