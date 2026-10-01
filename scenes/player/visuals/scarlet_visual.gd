class_name ScarletVisual
extends WholeFrameCharacterVisual
## Scarlet: an elf dancer with a great blue folding fan, as a whole-frame sprite character.
##
## Built on the AutoSprite recipe on 2026-09-26 (`docs/guides/character_creation.md`): every frame is
## AutoSprite's (storefront, floor, right wall and a one-shot dash attack whose fan swing draws an
## airy blue reap), sliced and cleaned by her pack's slicer and packed at Patchvile's pixel scale, at
## her own height (166 px standing, GDD §14 #52). The packer flips the floor for the ceiling and
## mirrors the right wall for the left, which this visual mirrors back on the right wall, so the
## right wall shows the art as generated. Her dash throws her own reap crescents and trails her
## crown diamond (`%DashParticles`, `%TrailParticles`).
##
## All the behaviour is [WholeFrameCharacterVisual]; this exists so the tests and QA
## fixtures have a type to name. The two frame-set paths are set in the scene.
