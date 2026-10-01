class_name PatchvileVisual
extends WholeFrameCharacterVisual
## Patchvile: a stitched doll with one ember eye, as a whole-frame sprite character.
##
## Owner-approved, and the worked example of `docs/guides/character_creation.md`: every frame is
## AutoSprite's (storefront, floor, right wall and a one-shot dash attack). The packer flips the
## floor for the ceiling and mirrors the right wall for the left, which this visual mirrors back on
## the right wall, so the right wall shows the art as generated.
##
## All the behaviour is [WholeFrameCharacterVisual]; this exists so the tests and QA
## fixtures have a type to name. The two frame-set paths are set in the scene.
