class_name SoulVesselPickup
extends SoulShardPickup
## A rare Soul Vessel on the floor: collecting it adds one Soul Fragment, with no cap.
##
## A run starts on a single fragment and there is no revive, so this is the only thing in the arena
## that buys the player another mistake (Reaper's Gift, which heals on a kill streak, is the other
## source and cannot raise the maximum). It drops from a kill at
## [member RunProgressionTuning.soul_vessel_drop_chance] and is otherwise exactly a
## [SoulShardPickup] — same attraction, dash sweep, lifetime and auto-collect — so a wave change
## never strands one on the floor. [GameWorld] decides what a collection is worth.
