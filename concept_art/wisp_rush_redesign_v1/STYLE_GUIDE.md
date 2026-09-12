# Wisp Rush redesign v1 — style and UX guide

## Visual thesis

**A living soul-flame cuts through an obsidian garden suspended over the void.**

The world should feel ancient, mysterious and dangerous, but the playfield must remain instantly
readable on a phone. Painterly depth belongs at the perimeter. Crisp, pixel-inspired silhouettes
belong in combat. The Wisp is always the brightest small object on screen.

## Core palette

| Role | Color | Use |
|---|---|---|
| Void charcoal | `#111521` | Deepest background, panel interiors, threat bodies |
| Slate teal | `#263D42` | Floor tiles, metal and secondary surfaces |
| Soul cyan | `#62E8F2` | Wisp, navigation, friendly VFX, focus state |
| Soul white | `#EAFDFF` | Hot cores, primary readable highlights |
| Warning amber | `#F3A847` | Telegraphs, rewards and important landmarks |
| Rift magenta | `#B14CD9` | Enemy cores, boss actions and selected states |
| Moss green | `#5E7D4C` | Low-saturation organic contrast only |

Keep the arena mostly charcoal/slate. Cyan, amber and magenta are information colors, not general
decoration. Avoid making every object luminous.

## Rendering language

- Hand-painted 2D surfaces with crisp pixel-inspired outer contours and selective hard edges.
- Small sprites prioritize silhouette over texture. Fine painterly texture is for 180 px and above.
- Obsidian uses cool charcoal planes, chipped slate edges and sparse cyan rune inlays.
- Vegetation is irregular, desaturated and confined to edges so it never looks interactable.
- Glow has a white-hot core, a saturated narrow band and a short soft falloff.
- No generic neon-cyberpunk materials, glossy sci-fi chrome or noisy full-screen bloom.

## Camera and playfield

- Portrait target: `1080 × 1920`, safe-area aware.
- Gameplay camera: high top-down with only a slight three-quarter tilt.
- Keep at least 75% of the arena as uninterrupted navigable floor.
- Tall scenery, strong shadows and high-frequency decoration stay in the outer 12%.
- The center rune may establish orientation but must remain lower contrast than characters.
- Threat telegraphs use solid, readable shapes before decorative particles.

## Character hierarchy

1. **Wisp:** smallest but brightest; cyan-white core and round eye lights.
2. **Soul Wisp enemy:** compact charcoal mass with one magenta core.
3. **Shard Wraith:** angular crystal silhouette with wider attacking limbs.
4. **Bone Mote:** ivory skull/rib silhouette held by cyan fire.
5. **Reaper:** tallest and darkest silhouette; antler crown, crescent mask and magenta scythe.

Cosmetic forms keep identical base scale, anchor and collision silhouette. Their colors change
identity and feedback only.

## UI language

- Panel interiors: near-black blue, approximately 88–94% opaque over artwork.
- Borders: thin blue-steel edge, one cyan inlay; magenta only for selection/boss states.
- Primary controls: wide, bottom-reachable and visually dominant.
- Secondary controls: darker and one visual tier quieter.
- Touch target minimum: 48 logical pixels; preferred primary height: 88–112 px at 1080 width.
- Corner radii feel cut from stone: stepped or chamfered, not soft consumer-app pills.
- Text remains code-rendered. Generated frames and boards must not become baked copy.
- Use tabular numerals for score, wave, shards and challenge progress.

## Screen hierarchy

### Home

Title-safe area at top, Wisp hero in the upper-middle, one dominant Play button, then Forms and
Daily actions. Best score and Soul Shards form a compact profile strip, not competing hero cards.

### Gameplay

Health and shards top-left; score/wave centered; Pause top-right; slim XP beneath. Boss health
sits below the safe header. The lower playfield remains clear for aiming—no permanent joystick is
required for Wisp Rush's swipe-and-release movement.

### Upgrade selection

Dim but preserve the frozen arena. Show three large cards with icon, title, one-line effect and
level. Keep the choice region centered and the current run status quiet.

### Forms

Large selected-form preview first, six-item collection grid second, one persistent bottom action.
Locked forms remain previewable. Price and boss requirement must never rely on color alone.

### Daily Rift

Portal/seed hero card, today's best, three scan-friendly goal rows, then one primary Play action.
Completed and claimed are separate visible states.

### Results

Score first, personal best second, run metrics third, rewards fourth. Restart dominates; Home is
available but visually quieter. No shop or ad interruption belongs in the MVP result hierarchy.

## Motion principles

- Wisp idle: slow 2–3% breathing scale and subtle flame curl.
- Dash: 2-frame compression, bright core streak, 80–120 ms wall impact, short focus pause.
- Enemy defeat: silhouette breaks inward toward the core, then dissolves outward.
- Reaper telegraphs: amber for where/when danger occurs, magenta for supernatural execution.
- UI transition: 140–220 ms; selected cards may use a single cyan-to-magenta edge sweep.
- Respect reduced-motion by removing camera shake, repeated pulse and large parallax.

## Accessibility and mobile QA

- Validate every interactive icon at 64 px and every combat silhouette at intended device scale.
- Never encode friendly/threat/warning meaning through hue alone: shape and timing must differ.
- Maintain 4.5:1 contrast for body text and 3:1 for large labels where practical.
- Preserve system safe areas and test tall, short and notched phones.
- Keep all generated typography out of production except the separately reviewed wordmark.
