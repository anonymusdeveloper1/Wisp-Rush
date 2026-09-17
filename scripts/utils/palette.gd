class_name Palette
extends RefCounted
## Redesign v1 colour palette as typed constants (source: concept_art/wisp_rush_redesign_v1/STYLE_GUIDE.md).
##
## Use these instead of hand-typed Color literals so every screen, HUD and effect shares one
## palette. The seven core roles come straight from the style guide; the derived colours below
## them are the theme's text, panel and glow tints. The Godot theme
## (res://assets/ui/theme/wisp_theme.tres) is generated from these values by
## res://assets/ui/theme/tools/build_wisp_theme.gd, so change a colour here, then rebuild the theme.
## Cyan, amber and magenta are information colours, not decoration: cyan = friendly / navigation /
## focus, amber = warnings, rewards and landmarks, magenta = enemy cores, boss actions and selection.

## Deepest background, panel interiors, threat bodies. #111521
const VOID_CHARCOAL: Color = Color("#111521")
## Floor tiles, metal and secondary surfaces. #263D42
const SLATE_TEAL: Color = Color("#263D42")
## The Wisp, navigation, friendly VFX and the keyboard/controller focus state. #62E8F2
const SOUL_CYAN: Color = Color("#62E8F2")
## Hot cores and primary readable text/highlights. #EAFDFF
const SOUL_WHITE: Color = Color("#EAFDFF")
## Telegraphs, rewards (score, Rift Points earned) and important landmarks. #F3A847
const WARNING_AMBER: Color = Color("#F3A847")
## Enemy cores, boss actions and selected states only. #B14CD9
const RIFT_MAGENTA: Color = Color("#B14CD9")
## Low-saturation organic contrast only (never an interactive colour). #5E7D4C
const MOSS_GREEN: Color = Color("#5E7D4C")

## Panel interior: near-black blue at 92 % alpha over artwork (guide: 88-94 %).
const PANEL_BG: Color = Color(0.078, 0.110, 0.161, 0.92)
## Muted slate-cyan for captions, units and secondary text (about 7:1 on PANEL_BG).
const TEXT_MUTED: Color = Color("#8FB3BA")
## Text on disabled controls.
const TEXT_DISABLED: Color = Color("#6B7A80")
## Thin blue-steel border colour for flat (non-texture) boxes such as tracks and outlines.
const STEEL_BORDER: Color = Color("#4C6670")
## Soft cyan glow for text shadows, focus halos and friendly highlights.
const CYAN_GLOW: Color = Color(0.384, 0.910, 0.949, 0.45)
## Soft amber glow behind reward numbers.
const AMBER_GLOW: Color = Color(0.953, 0.659, 0.278, 0.40)
## Full-screen dim behind modal overlays (pause, upgrade choice): void charcoal at 72 %.
const SCRIM: Color = Color(0.067, 0.082, 0.129, 0.72)
## Dark outline behind text drawn directly over artwork.
const TEXT_OUTLINE: Color = Color(0.067, 0.082, 0.129, 0.9)
