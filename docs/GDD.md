# Wisp Rush — Game Design Document

> Source of truth for **what the game is**. Implementation lives in
> [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) and `docs/systems/`.
>
> **Status: 🔄 release MVP specified; implementation in progress.** Source: owner-supplied
> `WISP-RUSH-GODOT-RELEASE-MVP-PROMPT-v2.md` (SHA-256 `c174ff79…60b`).

## 1. Pitch

Wisp Rush is a fast, one-finger portrait survival game. Swipe and release to launch a small
purple Wisp in a straight line, slice every enemy along that line, stop at the physical screen
edge, then immediately redirect to build ricochet chains and survive escalating waves.

## 2. Pillars

1. **Precise supernatural motion** — every swipe produces a fast, predictable edge-to-edge dash.
2. **Readable skill expression** — planning multi-kill lines and safe edge positions beats clutter.
3. **Immediate momentum** — aim, rush, slice, impact and restart all happen with minimal delay.

## 3. Core loop

- **Seconds:** aim → release → slice along the dash segment → wall impact → short focus → redirect.
- **Minutes:** survive 18–25 second waves, build score/combo, gain XP, choose run mutations, then
  fight the Reaper around 55–75 seconds.
- **Sessions:** improve best score/wave, earn Soul Shards, unlock cosmetic forms, complete local
  challenges and the deterministic Rift of the Day.

This is explicitly **not** orbit, tap-to-reverse, ring-gap or slingshot movement.

## 4. Player & controls

| Action | Touch / mouse | Keyboard debug | Notes |
|---|---|---|---|
| Aim | Hold and drag / click-drag | WASD or arrows | A small direction arrow beside the Wisp (AIM ARROW, on by default) |
| Dash | Release after ≥ 28 dp | Space | Swipe direction is travel direction; length does not change power |
| Redirect | Swipe again while dashing | Direction + Space | Turns the live dash from wherever the Wisp is |
| Pause / back | HUD button | Escape | Closes the top overlay first |

Input actions must match [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) §5.4. Only the first active
pointer controls aiming; UI consumes its own input; interruptions cancel an active swipe.

## 5. Mechanics

### 5.1 Wisp state and dash

State machine: `SPAWNING → WAITING_AT_EDGE → AIMING → WINDUP → DASHING → WALL_IMPACT`, plus
`HURT`, `DEAD`, and `VICTORY`. Starting windup is 65 ms. A normalized direction produces constant
speed, initially tuned to cross 1080 px in about 180–260 ms. The first ray/arena intersection is
calculated before launch; movement stops exactly at it. Outward edge swipes reflect inward.

**Flow** (owner decision 2026-09-12):
- **Mid-dash redirect.** A swipe while dashing turns the dash from the Wisp's current position; a
  dash no longer has to run wall to wall. Each redirect is a new dash for hit purposes, so enemies
  passed on one leg can be hit on the next; the leg that ended is still scored.
- **No lost input.** A touch is tracked in every live state. A swipe released during the windup, a
  hurt reaction or a reform is buffered for 0.3 s and fires as soon as the Wisp can act; a swipe
  during the 140 ms landing reaction launches immediately instead of waiting it out, and a swipe
  during the 65 ms windup re-aims that dash.
- **Launch burst.** Each dash starts at 1.4× speed and eases to cruise over about 0.1 s.
- **Chain momentum.** A dash launched within 0.35 s of landing, or any redirect, adds +8 % speed up
  to +25 %. A slow restart or taking damage resets it.

Every dash has a unique `dash_id`. Collision uses the swept segment between physics positions,
not a point sample. Each enemy can be damaged once per dash.

### 5.2 Edge impact and focus

Gameplay reaches all four physical display edges; a small scale-dependent collision inset only
keeps the sprite visible and never forms a visible frame. Impact briefly compresses the Wisp,
flashes the wall, emits a ring, adds a subtle 2–4 px kick and starts 250–400 ms of Wisp Focus at
0.25–0.40× enemy/hazard speed. Player input remains responsive and the slowdown expires even if
the player waits.

### 5.3 Combat, health and failure

The dash corridor is the Wisp radius plus a configurable blade bonus. Normal enemies are sliced
without stopping the Wisp and cannot deal contact damage during a successful dash. Kills award
score, XP, combo and possible currency immediately. Multi-kill dashes escalate feedback. Normal
kills use at most 20–35 ms hit-stop; heavy/boss hits may use 50–80 ms.

The Wisp begins with three Soul Fragments. Contact damage removes one, resets combo and grants
750–1,000 ms invulnerability. At zero, play the death dissolve before results. Crowded hits reform
the player at a safe edge.

### 5.4 Enemies and hazards

| Content | Role |
|---|---|
| Soul Wisp | One-hit, slow steering enemy that creates early chain lines |
| Shard Wraith | Faster angular enemy with two-hit/shield behaviour and a telegraphed move |
| Bone Mote | Heavy enemy with a readable charge toward the last edge position |
| Split void crystal | Narrow indestructible route blocker |
| Spike bloom | Pulses before alternating safe/active states |
| Blade ring | Fixed rotating hazard with dangerous blades only |
| Void portal | Linked, visible entrances that preserve or predictably rotate dash direction |
| Obsidian pillar | Taught separately as a dash stop/bounce obstacle |

Enemy arrivals telegraph for at least 450–700 ms, never spawn on the Wisp and use collision circles
slightly smaller than the art. Obstacles remain sparse and formation validation preserves at least
one viable dash and safe edge.

### 5.5 Waves, upgrades and boss

An endless threat-budget director uses at least 20 handcrafted normalized formations with mirrored
and rotated variants. Waves introduce Soul Wisps, diagonal chains, Shard Wraiths, one obstacle at a
time, then Bone Motes and mixed formations. Difficulty rises through combinations and decision time,
not unrestricted random flooding.

XP pauses the run only after a dash resolves and offers three uncapped choices: Wide Reap, Soul
Hunger, Death Pulse, Soul Link, Cold Wake, Void Velocity, Soul Vessel and Reaper's Gift.

The Reaper stops normal spawning and uses three readable phases: scythe sweep, teleport hunt and
death corridors. Its core takes at most one hit per dash and is vulnerable only during exposed
windows. Victory awards 1,500 points plus Soul Shards, then endless play continues at a harder tier.

## 6. Progression & content

- Run-only power: eight mutations with levels/caps; permanent progress must not trivialise starts.
- Persistent currency: Soul Shards, separate from score.
- Cosmetic forms: Void (default), Ash (250), Venom (500), Bloodmoon (800), Frost (1,200), Eclipse
  (2,000 plus first boss victory). Cosmetics change visuals only.
- Local goals: personal bests, highest wave/combo, Reaper time, form collection, three rotating
  challenges and calendar-seeded Rift of the Day. Missing days have no penalty.

## 7. Win / lose conditions & scoring

The main mode is endless. Death at zero Soul Fragments ends the run; defeating the Reaper is a
victory beat, not the end. Track score, best, combo/highest combo, kills, multi-kill dashes, wave,
bosses and Soul Shards separately. Combo decay begins after 2.2 seconds without a kill; wall impact
does not reset it and damage does. Multi-kill bonuses are stepped or quadratic so alignment matters.

## 8. Game feel

- Emotional beat: focus → direction → 65 ms anticipation → explosive dash → slice → impact → breath.
- Idle animation is 3–4 FPS with gentle hover; impact is 100–180 ms; enemy dissolve 220–350 ms;
  Wisp death 450–650 ms; reform 350–500 ms.
- Aim previews and telegraphs always outrank particles. No floaty movement, muddy effects, constant
  shake, unavoidable damage or long input locks.
- Reduced motion lowers shake, flashes and heavy transitions without reducing gameplay clarity.

## 9. Art direction

Redesign v1 (owner-approved 2026-09-11, [ADR-0005](decisions/0005-visual-redesign-v1.md)); the full
authority is `concept_art/wisp_rush_redesign_v1/STYLE_GUIDE.md`.

- Thesis: a living soul-flame cuts through an obsidian garden suspended over the void. Painterly
  depth at the perimeter, crisp readable silhouettes in combat; the Wisp is always the brightest
  small object on screen.
- Palette: void charcoal `#111521`, slate teal `#263D42`, soul cyan `#62E8F2`, soul white `#EAFDFF`,
  warning amber `#F3A847`, rift magenta `#B14CD9`, moss green `#5E7D4C`. Cyan, amber and magenta are
  information colours (friendly/navigation, telegraphs/rewards, enemy cores/boss/selection).
- Top-down arena with ≥ 75 % uninterrupted floor; tall scenery only in the outer 12 %.
- UI: engraved stone frames with cyan inlays, stepped corners, near-black panel interiors,
  dominant bottom-reachable primary actions; all text code-rendered.
- Hierarchy: Wisp (cyan-white core) → Soul Wisp → Shard Wraith → Bone Mote → Reaper (tallest,
  darkest). Cosmetic forms keep scale, anchor and collision silhouette.
- Runtime art is generated from the concept sheets by `tools/art/extract_redesign.py`; the previous
  violet art is archived in `assets/legacy_v1/` and never ships.

## 10. Audio direction

Minimal dark electronic ambience grows with threat/combo; boss music deepens without medieval or
metal styling. Separate Master, Music, SFX and UI buses. Required cues cover aim, dash, slice and
multi-kill pitch steps, impact, pickup, damage/death, upgrades, Reaper actions and UI feedback. If
final files remain unavailable, use carefully tuned runtime synthesis rather than placeholder beeps.

## 11. UI & screen flow

`Loading → Home → Tutorial/Main Run → Upgrade/Pause overlays → Results → fast Restart/Home`.
Home also reaches Forms, Discovery/Upgrades, Statistics, Settings and Daily Challenge.

**Home** (owner decision 2026-09-13): minimal and Material-like in the stone-and-cyan style — a slim
top bar (shards, best, Statistics, Settings), the logo, the equipped Wisp alive in the middle, one
big PLAY with a caption naming the Rift it enters, and a bottom navigation bar (Rifts, Forms,
Sanctum, Trials, Daily). The Wisp floats, breathes and sways with a pulsing glow while soul motes
orbit it; the background comes alive (brazier flicker, rune pulse, drifting mist, rising motes)
while the art stays unchanged. No entrance animation, no PLAY pulse; Reduced Motion stills it all.

**Forms and Rift Map** are vertical card pickers: one big tall focused card in the centre, raised
and framed, neighbours peeking in dimmed; swipe sideways to browse; a description and one main
button below. Locked forms and Rifts stay previewable; a locked Rift can never be entered.

HUD places
score top-centre, health/currency top-left, pause top-right, contextual wave/combo information and a
slim XP bar. Only UI respects safe-area insets; the world continues behind cutouts. All controls are
large, focusable and have visible desktop/controller focus styling.

## 12. Platforms & technical targets

- Godot 4.7.2, typed GDScript, 2D Forward+ during development.
- Android and iOS portrait release; desktop debug controls.
- 1080×1920 design coordinates, `canvas_items` + `expand`, full physical display with no letterbox,
  card, border or fixed SubViewport. Edge-to-edge means the *presentation*: since redesign v1 the
  dashable playfield is inset to the painted stone floor ([ADR-0006](decisions/0006-inset-playfield-and-larger-sprites.md)).
- Stable 60 FPS on a mid-range Android phone and recent iPhone; interactive Home appears quickly.
- Offline base game, no account/backend/data collection; versioned local save under `user://`.
- QA sizes (phones only — owner decision 2026-09-11): 320×568, 360×800, 375×812, 390×844, 412×915.
  Tablets and desktop are not targets; desktop stays a debug convenience.

## 13. Scope

| Release MVP | Explicitly later / provider-dependent |
|---|---|
| Tutorial; endless mode; 20+ formations; 3 enemies; 3+ hazards; 8 mutations; 3-phase Reaper; 6 forms; daily/challenges; complete screen flow; local save/statistics/settings; final feedback; unsigned Android/iOS export configuration | Real ads, analytics, IAP/store verification, cloud saves, accounts, backend, signed store builds |

Release contains no dead buttons, placeholder/debug panels, fake purchases, required network calls
or legacy art. Monetisation integration stays hidden unless backed by a real platform provider.

## 14. Open questions & assumptions

| # | Question / ASSUMPTION | Status |
|---|---|---|
| 1 | Confirm the owner-supplied artwork's production/distribution license. | Open; not supplied in ZIP |
| 2 | `com.cognitix.wisprush` is configured in the Android debug export preset for on-device testing; iOS bundle id and store/release config stay deferred. | Partly settled |
| 3 | ASSUMPTION: no audio files were supplied, so the prompt's runtime-synthesis fallback ships (ADR-0004); supplied files can replace any sound id later. | Implemented in Milestone 4; owner may supply files |
| 4 | Confirm current store target SDK/deployment requirements at release time. | Open; verify during release milestone |
| 5 | Resolved: tutorial completion, best score, Soul Shards and all progression persist locally via SaveManager (ADR-0003). | Resolved in Milestone 3 |
| 6 | ASSUMPTION: taking damage resets the kill streak used by Reaper's Gift, matching combo risk/reward. | Implemented; owner may retune |
| 7 | ASSUMPTION: the Reaper recurs every four waves (first at wave 4, about 66 seconds); each victory resumes a harder cycle. | Milestone 3 default; owner may retune |
| 8 | ASSUMPTION: a completed daily run grants 10 Soul Shards once per local date; three date-seeded challenges grant 10–25 once each and accumulate across that date's runs. | Milestone 3 default; owner may retune |
| 9 | ASSUMPTION: five Rifts gated on lifetime best wave at 0/5/10/15/20, each with one rule twist (portals, shrinking floor, drift, boss rush). The GDD never specified arenas. | Ladder and map shipped ([ADR-0007](decisions/0007-rifts-as-rule-variant-arenas.md)); twists unimplemented; owner may retune |
| 11 | Monetisation model chosen: free with opt-in rewarded video (revive, double shards, upgrade reroll) plus one Remove Ads + shard pack IAP; never interstitials. Plumbing ships behind a null provider, so §12's offline/no-data-collection promise still holds today. §12 and §13 must be amended **before** a build with a real ad SDK ships. | Settled 2026-09-12 ([ADR-0009](decisions/0009-monetisation-model.md)); SDK, privacy policy and store config still owner-side |
| 10 | ASSUMPTION: three new enemies (Cinder Shade splits on death, Warden is shielded on one face, Rift Spawn is a tethered pair) and a second boss (The Hollow Choir, a static three-core structure) extend the roster. Invented to fill the M8 art pack; not in the owner prompt. | Art generated only — no tuning, behaviour or scene; owner may reject or redesign |

## Change history

| Date | Change | Source |
|---|---|---|
| 2026-09-13 | Home redesign (animated hero + living background, PLAY with Rift caption, bottom nav); Forms and Rift Map as portrait card carousels (§11) | Owner |
| 2026-09-12 | Movement flow: mid-dash redirect, input buffering, landing-lock cancel, launch burst, chain momentum; aim line replaced by a direction arrow (§4, §5.1) | Owner |
| 2026-09-12 | Monetisation model settled: opt-in rewarded video + one Remove Ads IAP, no interstitials (ADR-0009, §14 #11) | Owner |
| 2026-09-12 | Permanent progression added: Soul Sanctum, Trials ladder, depth milestones | Owner request |
| 2026-09-12 | Rifts: five rule-variant arenas, derived unlock ladder and map UI (ADR-0007); new enemy/boss art assumed (§14 #9–10) | Owner request |
| 2026-09-12 | Playfield inset to the painted floor; sprites and hitboxes ×1.3–1.45 (ADR-0006) | Owner |
| 2026-09-11 | Art direction replaced by redesign v1 (ADR-0005) | Owner |
| 2026-09-11 | Phones-only QA; planned id `com.cognitix.wisprush`; release deferred for polish | Owner |
| 2026-09-11 | Audio ships as runtime synthesis (assumption 3) | Milestone 4 |
| 2026-09-11 | Resolved assumption 5: progression now persists locally | Milestone 3 completion |
| 2026-09-11 | Defined recurring Reaper cadence and offline daily/challenge reward defaults | Milestone 3 implementation |
| 2026-09-11 | Expanded temporary session state and defined Reaper's Gift damage reset | Milestone 2 implementation |
| 2026-09-11 | Recorded temporary session-only tutorial completion assumption | Milestone 1 implementation |
| 2026-09-11 | Replaced template with complete release-MVP design and starting tuning | Owner prompt v2 |
| 2026-09-11 | Template created | Setup |
