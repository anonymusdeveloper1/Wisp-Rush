class_name VoidVisual
extends WholeFrameCharacterVisual
## Void, the default Wisp: a whole-frame sprite character.
##
## Replaces the single-image form that used to idle on the shared base rig; the form id, price,
## tint and dash effect are unchanged, so every save keeps working.
##
## All the behaviour is [WholeFrameCharacterVisual]; this exists so the tests and QA
## fixtures have a type to name. The two frame-set paths are set in the scene.
