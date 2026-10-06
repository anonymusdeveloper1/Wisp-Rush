class_name RunItemData
extends Resource
## One enemy pickup: identity, icon, temporary effect and optional consumable shop price.

## Stable save and gameplay identifier.
@export var item_id: StringName
## Player-facing name and concise effect description.
@export var display_name: String
@export var description: String
## Lazy texture path so the inventory service does not load art at boot.
@export_file("*.png") var icon_path: String
## Seconds a timed effect lasts; zero for the instant bomb and stored Ward.
@export_range(0.0, 120.0, 0.1) var duration_seconds: float = 0.0
## Whether this item is sold, and its RP price per copy.
@export var shop_enabled: bool = false
@export_range(0, 100000, 1) var unit_price: int = 0
## A bought copy may be selected to activate at the next run's start.
@export var starting_boost: bool = false
## Effect values, used only by the corresponding item.
@export var score_multiplier: float = 1.0
@export var enemy_speed_multiplier: float = 1.0
@export var corridor_multiplier: float = 1.0
@export var burst_radius: float = 0.0

var _icon: Texture2D


## Loads and caches this item's small pixel-art texture on first use.
func get_icon() -> Texture2D:
	if _icon == null and not icon_path.is_empty():
		_icon = load(icon_path) as Texture2D
	return _icon
