# ADR-0026: Enemy pickups and consumable item packs

> **Status:** Accepted · **Date:** 2026-10-05 · **Decider:** owner

## Context
The owner accepted seven pickup concepts, chose immediate collection for six, and stored Soul
Wards activated by double tap. They requested implementation in place of run upgrades and an
Items shop page with packs of 1, 5, 10 and 25. The owner approved choosing provisional balance
values rather than requiring further price/duration/drop-rate decisions.

## Decision
Implement the accepted pickup effects, stored Ward copies and the three discussed shop items:
Soul Ward, Rift Magnet and Fortune Star. Pack costs scale by quantity. A bought Magnet or Star
can be selected before PLAY and activates at the next run's start. Keep RUSH as the existing
separate mechanic. Remove XP/card-upgrade behaviour from live gameplay and update its tutorial
and HUD connections.

## Consequences
The Shop now spends earned RP on consumables as well as cosmetics, superseding ADR-0013's
cosmetic-only purchase restriction. Items grant run-only effects; there is no permanent stat tree.
Local saves gain item counts and a selected next-run boost. The seven icon originals remain
preserved; a reproducible pixel-art packer creates source finals and runtime copies.
