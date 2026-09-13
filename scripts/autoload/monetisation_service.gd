class_name MonetisationService
extends Node
## Provider-agnostic monetisation: opt-in rewarded video and a single Remove Ads purchase.
##
## The game never talks to an ad or store SDK directly. It talks to an injected `AdProvider`, and
## the shipped default is `NullAdProvider`, which reports nothing available. That is deliberate:
## GDD §13 forbids dead buttons and fake purchases, so with no real provider configured every
## monetisation surface stays hidden and the game is exactly the offline build it was before.
##
## Wiring a real SDK means implementing `AdProvider` and calling `set_provider()` at boot — no
## gameplay code changes. See [ADR-0009](../../docs/decisions/0009-monetisation-model.md).

## A rewarded placement finished successfully and its reward must be granted exactly once.
signal rewarded_granted(placement: StringName)
## A rewarded placement was dismissed, failed or was unavailable; no reward is owed.
signal rewarded_failed(placement: StringName)
## Ad removal was purchased or restored.
signal ads_removed_changed(removed: bool)
## Consent state changed; the host should re-evaluate whether personalised ads are allowed.
signal consent_changed(state: StringName)

## Rewarded placements the game offers. Never interstitials: GDD §2's momentum pillar forbids them.
const PLACEMENT_REVIVE: StringName = &"revive"
const PLACEMENT_DOUBLE_SHARDS: StringName = &"double_shards"
const PLACEMENT_UPGRADE_REROLL: StringName = &"upgrade_reroll"
const PLACEMENTS: Array[StringName] = [
	PLACEMENT_REVIVE,
	PLACEMENT_DOUBLE_SHARDS,
	PLACEMENT_UPGRADE_REROLL,
]

## Consent has not been asked for yet; no personalised ads may be requested.
const CONSENT_UNKNOWN: StringName = &"unknown"
const CONSENT_GRANTED: StringName = &"granted"
const CONSENT_DENIED: StringName = &"denied"

## Product identifier for the single in-app purchase.
const PRODUCT_REMOVE_ADS: StringName = &"remove_ads_shard_pack"
## Shards granted alongside ad removal.
const REMOVE_ADS_SHARD_GRANT: int = 1500


## Minimal contract a real SDK adapter must implement.
##
## Every method is synchronous and side-effect free in the null case, so the game degrades to
## "no monetisation" rather than hanging on a provider that never answers.
class AdProvider extends RefCounted:
	## Whether the provider is initialised and may be asked for anything at all.
	func is_available() -> bool:
		return false

	## Whether a rewarded ad is loaded and ready for this placement right now.
	func is_rewarded_ready(_placement: StringName) -> bool:
		return false

	## Shows a rewarded ad. Returns true only when the viewer earned the reward.
	func show_rewarded(_placement: StringName) -> bool:
		return false

	## Whether the store is reachable for purchases.
	func is_store_available() -> bool:
		return false

	## Runs the purchase flow for a product. Returns true only on a completed purchase.
	func purchase(_product_id: StringName) -> bool:
		return false

	## Restores previously owned non-consumable purchases.
	func restore_purchases() -> bool:
		return false


## The shipped default: no ads, no store, nothing to show.
class NullAdProvider extends AdProvider:
	pass


var _provider: AdProvider = NullAdProvider.new()
var _save: SaveManagerService
## Placements already consumed this run, so one rewarded revive cannot be farmed repeatedly.
var _consumed_this_run: Dictionary[StringName, bool] = {}


func _ready() -> void:
	_save = get_node_or_null(^"/root/SaveManager") as SaveManagerService


## Injects a real SDK adapter. Called once at boot by whoever owns the SDK lifecycle.
func set_provider(provider: AdProvider) -> void:
	_provider = provider if provider != null else NullAdProvider.new()


## Injects the save service directly. Used by headless tests that build their own SaveManager.
func set_save_manager(save: SaveManagerService) -> void:
	_save = save


## Whether any monetisation surface should be shown at all.
##
## False on the shipped build, so no ad or purchase button is ever rendered.
func is_available() -> bool:
	return _provider.is_available()


## Whether the player has bought or restored ad removal.
func has_removed_ads() -> bool:
	return _save != null and _save.has_removed_ads()


## Current consent state; personalised ads require CONSENT_GRANTED.
func get_consent_state() -> StringName:
	if _save == null:
		return CONSENT_UNKNOWN
	return StringName(_save.get_consent_state())


## Records the player's consent decision.
func set_consent(granted: bool) -> void:
	var state: StringName = CONSENT_GRANTED if granted else CONSENT_DENIED
	if _save != null:
		_save.set_consent_state(String(state))
	consent_changed.emit(state)


## Whether the consent prompt still needs to be shown before any ad request.
func needs_consent_prompt() -> bool:
	return is_available() and get_consent_state() == CONSENT_UNKNOWN


## Whether a rewarded offer for this placement should be shown to the player right now.
##
## Every gate lives here so no caller can accidentally show an offer it cannot honour: the provider
## must be up, consent decided, ads not removed, the placement known and unused this run.
func can_offer(placement: StringName) -> bool:
	if placement not in PLACEMENTS:
		return false
	if not is_available() or has_removed_ads():
		return false
	if get_consent_state() == CONSENT_UNKNOWN:
		return false
	if _consumed_this_run.get(placement, false):
		return false
	return _provider.is_rewarded_ready(placement)


## Shows a rewarded ad and reports whether the reward was earned.
##
## Marks the placement consumed for this run whether or not the viewer completed it, so a dismissed
## ad cannot be retried immediately — that is the pattern players read as nagging.
func show_rewarded(placement: StringName) -> bool:
	if not can_offer(placement):
		rewarded_failed.emit(placement)
		return false
	_consumed_this_run[placement] = true
	if _provider.show_rewarded(placement):
		rewarded_granted.emit(placement)
		return true
	rewarded_failed.emit(placement)
	return false


## Clears per-run placement locks. Called when a new run starts.
func begin_run() -> void:
	_consumed_this_run.clear()


## Whether the Remove Ads product can be offered.
func can_purchase_remove_ads() -> bool:
	return is_available() and _provider.is_store_available() and not has_removed_ads()


## Runs the Remove Ads purchase and grants its shards on success.
func purchase_remove_ads() -> bool:
	if not can_purchase_remove_ads():
		return false
	if not _provider.purchase(PRODUCT_REMOVE_ADS):
		return false
	if _save != null:
		_save.grant_remove_ads(REMOVE_ADS_SHARD_GRANT)
	ads_removed_changed.emit(true)
	return true


## Restores a previously owned Remove Ads purchase without re-granting its shards.
func restore_purchases() -> bool:
	if not is_available() or not _provider.is_store_available():
		return false
	if not _provider.restore_purchases():
		return false
	if _save != null:
		_save.grant_remove_ads(0)
	ads_removed_changed.emit(true)
	return true
