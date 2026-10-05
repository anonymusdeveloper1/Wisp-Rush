# Ranged boss — the green lantern boss

> **Status:** design recorded and six pose images prepared, 2026-10-05; not implemented.
> **Owner decisions:** GDD §14 #75. No character name has been chosen in this session.
> **Art and animation prompts:** [green_lantern_boss_v1/PROMPTS.md](../../../concept_art/green_lantern_boss_v1/PROMPTS.md).

## Owner-approved direction

The hooded skeleton from the supplied image stays in the **middle of the arena**, fights from
range and **summons his own green wisps**. The owner likes the proposed attacks and requests their
starting poses. Soul Recall returns surviving summoned wisps to **heal him**, with its own first
frame. Idle and a slumped death pose with the lantern extinguished are included.
A separate recovery pose is declined.

The 2026-10-05 own-wisp decision replaces the earlier `Summons? no` draft for the ranged boss
in [README.md §6](README.md#6-the-three-bosses); the separate spawner boss's design is unchanged.

## Appearance

Use the [owner's supplied reference](../../../concept_art/green_lantern_boss_v1/references/boss.jpg):
a hooded skull with emerald eyes, charcoal/dark teal tattered robes, bone shoulder ornaments and
rib armour with green gems, and green fire beneath the robe. His right hand holds a tall wooden
staff with a caged green-fire lantern, on the viewer's left; his free skeletal hand is on the right.

The boss and his green spell effects are 2D pixel art: visible square pixel clusters, limited
palette and crisp edges, with no added enclosing outline, anti-aliasing, gradients, blur,
painterly rendering or 3D rendering. The supplied image determines his costume and equipment.

The SIMULATION illustrations made in this conversation show how his green attacks read against
the existing dark/cyan portrait board. This is visual exploration, not an arena restriction or
a runtime implementation.

## Abilities

| Ability | Discussed behaviour | Cast-start visual |
|---|---|---|
| Summon green wisps | Calls his own green wisps into the fight. | Lantern lifted inward above the hood; free palm opens upward in a broad calling gesture. |
| Green Flame Volley | Casts a spread of green ghost flames toward the player's position at release; they continue along their launched paths. | Free hand gathers a compact flame close to the chest; staff remains upright. |
| Lantern Sweep | Swings the staff to cast a broad curved green-fire wave across part of the arena, with visible staff preparation and room to escape. | Staff drawn back diagonally to the side before the sweep. |
| Soul Recall — heal | Pulls surviving summoned wisps back to the lantern to heal him. The player can slice the returning wisps before they reach him. | Lantern raised inward; free fingers curl toward it in a pulling gesture. |

The names above label the attacks discussed with the owner; they do not assign a character name.
Summoned wisps, travelling flames, the sweep wave and returning souls are separate from the
body animation. The first-frame body artwork contains the boss and his attached fire.

## Pose and sheet list

| Animation | Starting pose | Ending pose | Loop |
|---|---|---|---|
| Idle | `01_idle.png` | Same idle pose | Yes |
| Summon | `02_summon_start.png` | Idle | No |
| Green Flame Volley | `03_flame_volley_start.png` | Idle | No |
| Lantern Sweep | `04_lantern_sweep_start.png` | Idle | No |
| Soul Recall — heal | `05_soul_recall_heal_start.png` | Idle | No |
| Death | Idle | `06_death_end.png`: slumped, lantern extinguished | No |

The six individual images are in
[poses/](../../../concept_art/green_lantern_boss_v1/poses/).
The [prompt pack](../../../concept_art/green_lantern_boss_v1/PROMPTS.md) contains the exact
first-frame generation prompts, six copy-ready AutoSprite motion prompts and upload/export
instructions. The images are unchanged 1254 × 1254 generations on a magenta backing;
AutoSprite's background removal and pixel filter produce the later sheets.

No additional boss body pose is necessary for these animations. The stationary fight needs
no locomotion pose, and idle supplies each cast's ending. Separate wisps and spell-effect assets
will be needed when their artwork is requested.

## Not decided in this session

Character name, health, damage, cooldowns, attack order/phases, number and behaviour of wisps,
healing amount, vulnerability/damage windows and final
on-screen size remain undecided. In particular, the earlier suggestion of extra damage after
large casts is not an owner-approved rule.

The earlier ranged-boss draft excludes ordinary enemy spawning. This session adds his own
summoned green wisps; it does not make another decision about ordinary enemy spawns.

These omissions are not filled with defaults. The boss has no new scene, script, tuning resource,
runtime atlas or AutoSprite-generated animation sheet in this task. No tests or game runs are
performed, as instructed by the owner.

## Change history

| Date | Change |
|---|---|
| 2026-10-05 | Owner confirms own green wisps, a central ranged boss, the discussed attacks, healing Soul Recall, death, and no extra recovery pose; six body poses and animation prompts prepared. |
