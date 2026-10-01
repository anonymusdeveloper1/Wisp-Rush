class_name MothmereVisual
extends WholeFrameCharacterVisual
## Mothmere: a hooded wanderer with a flame-topped staff, as a whole-frame sprite character.
##
## Built on the AutoSprite recipe on 2026-09-25 (`docs/guides/character_creation.md`): every frame is
## AutoSprite's (storefront, floor, right wall and a one-shot dash attack whose staff swing draws a
## red reap), packed at Patchvile's pixel scale. The packer flips the floor for the ceiling and
## mirrors the right wall for the left, which this visual mirrors back on the right wall, so the right
## wall shows the art as generated. He keeps the outline his source images carry (GDD §14 #49).
##
## All the behaviour is [WholeFrameCharacterVisual]; this exists so the tests and QA
## fixtures have a type to name. The two frame-set paths are set in the scene.
