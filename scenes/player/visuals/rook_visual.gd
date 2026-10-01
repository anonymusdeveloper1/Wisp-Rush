class_name RookVisual
extends WholeFrameCharacterVisual
## Rook, the Bonewing: a bone dragon with a tail blade, as a whole-frame sprite character.
##
## Rebuilt on the AutoSprite recipe on 2026-09-27 (`docs/guides/character_creation.md`), replacing his
## bone rig: every frame is AutoSprite's (storefront, floor, right wall, his own ceiling, and a
## one-shot dash attack in which he pushes, dives and swings his tail blade), sliced and cleaned by
## his pack's slicer and packed at Patchvile's pixel scale. At that scale his walls do not fit a
## 256 px cell, so his run sheet has 336 px cells: `design_size` is 336 and `art_scale` is 1.1875
## times 336/256, which draws him at everyone's size. The packer mirrors the right wall for the left,
## which this visual mirrors back on the right wall, so the right wall shows the art as generated.
##
## His dash look is the rig's, kept (owner, 2026-09-27): the streak his dash throws off
## (`%DashParticles`), his dust trail (`%TrailParticles`) and the ring of dust motes around him
## (`%Aura`), with their sizes carried over from the rig's 640 px design to this 336; no attack glow.
##
## All the behaviour is [WholeFrameCharacterVisual]; this exists so the tests and QA
## fixtures have a type to name. The two frame-set paths are set in the scene.
