class_name MonetisationService
extends Node
## Provider-agnostic monetisation: opt-in rewarded video, interstitials between runs, the Remove
## Ads purchase and Rift Points packs (owner 2026-10-05, ADR-0028, ADR-0029).
##
## The game never talks to an ad or store SDK directly. It talks to an injected `AdProvider` for ads
## and a `StoreProvider` for purchases. The defaults report nothing available, so on desktop and in
## tests no ad is offered and nothing can be bought. On Android `_ready` installs the `AdMobProvider`
## when the AdMob plugin's singleton exists (Google's test ad units until release, ADR-0029) and the
## Google Play Billing store when its plugin's singleton exists (ADR-0030); the store sells only once
## Play Console knows the products, until then the Shop's real-money buttons stay disabled.
##
## Showing an ad takes time, so [method show_rewarded] and [method show_interstitial] are coroutines:
## callers `await` them. See [ADR-0009](../../docs/decisions/0009-monetisation-model.md).

## A rewarded placement finished successfully and its reward must be granted exactly once.
signal rewarded_granted(placement: StringName)
## A rewarded placement was dismissed, failed or was unavailable; no reward is owed.
signal rewarded_failed(placement: StringName)
## Ad removal was purchased or restored.
signal ads_removed_changed(removed: bool)
## The store became available or unavailable, or learned its prices; the Shop refreshes.
signal store_changed
## A paid product reached the save outside a purchase the player is waiting on (a pending payment
## that completed, or one a crash left undelivered): Main tells the player. `rift_points` is 0 for
## Remove Ads.
signal purchase_delivered(product_id: StringName, rift_points: int)
## Consent state changed; the host should re-evaluate whether personalised ads are allowed.
signal consent_changed(state: StringName)

## Rewarded placements the game offers: the revive on death and doubling a run's Rift Points
## (owner 2026-10-05, ADR-0029).
const PLACEMENT_REVIVE: StringName = &"revive"
## Doubles the Rift Points a finished run earned (ADR-0013 renamed it from "double Soul Shards").
const PLACEMENT_DOUBLE_RIFT_POINTS: StringName = &"double_rift_points"
const PLACEMENT_UPGRADE_REROLL: StringName = &"upgrade_reroll"
const PLACEMENTS: Array[StringName] = [
	PLACEMENT_REVIVE,
	PLACEMENT_DOUBLE_RIFT_POINTS,
	PLACEMENT_UPGRADE_REROLL,
]

## Consent has not been asked for yet; no personalised ads may be requested.
const CONSENT_UNKNOWN: StringName = &"unknown"
const CONSENT_GRANTED: StringName = &"granted"
const CONSENT_DENIED: StringName = &"denied"

## Finished runs between interstitials: one shows, when ready, once this many runs have finished
## since the last (owner 2026-10-05: after every second run, before Results; ADR-0029).
const INTERSTITIAL_RUN_INTERVAL: int = 2
## Engine singleton the AdMob plugin registers on Android; its absence keeps the null provider.
const ADMOB_SINGLETON: String = "PoingGodotAdMob"
## Loaded only on Android, so desktop runs and tests never touch the plugin's classes.
const ADMOB_PROVIDER_PATH: String = "res://scripts/monetisation/admob_provider.gd"

## Product identifier for the Remove Ads purchase. Remove Ads carries no currency; Rift Points are
## sold as their own packs (ADR-0028).
const PRODUCT_REMOVE_ADS: StringName = &"remove_ads"
## Outcomes of a store purchase.
const PURCHASE_DONE: StringName = &"purchased"
## Paid by a slow method (cash at a shop, a bank transfer): delivered later through `purchase_ready`.
const PURCHASE_PENDING: StringName = &"pending"
const PURCHASE_CANCELLED: StringName = &"cancelled"
const PURCHASE_FAILED: StringName = &"failed"
## Engine singleton of the Google Play Billing plugin on Android (ADR-0030).
const BILLING_SINGLETON: String = "GodotGooglePlayBilling"
## Loaded only on Android, like the AdMob provider.
const PLAY_BILLING_STORE_PATH: String = "res://scripts/monetisation/play_billing_store.gd"


## Minimal contract a real SDK adapter must implement.
##
## Every method is side-effect free in the null case, so the game degrades to "no monetisation"
## rather than hanging on a provider that never answers. [method start], [method show_rewarded] and
## [method show_interstitial] may wait (a real ad takes time); callers `await` them.
class AdProvider extends RefCounted:
	## Asks for consent and initialises the SDK. Returns whether ads may be requested.
	func start() -> bool:
		return false

	## Whether the provider is initialised and may be asked for anything at all.
	func is_available() -> bool:
		return false

	## Whether a rewarded ad is loaded and ready for this placement right now.
	func is_rewarded_ready(_placement: StringName) -> bool:
		return false

	## Shows a rewarded ad. Returns true only when the viewer earned the reward.
	func show_rewarded(_placement: StringName) -> bool:
		return false

	## Whether an interstitial is loaded and ready right now.
	func is_interstitial_ready() -> bool:
		return false

	## Shows an interstitial and returns true once it is closed; false when none could show.
	func show_interstitial() -> bool:
		return false


## The shipped default: no ads, nothing to show.
class NullAdProvider extends AdProvider:
	pass


## Contract a store adapter implements (Google Play Billing on Android, ADR-0030). Every method that
## talks to the store may wait; callers `await` it. The null default reports no store.
class StoreProvider extends RefCounted:
	## A purchase completed outside [method purchase] (a pending payment went through).
	@warning_ignore("unused_signal")
	signal purchase_ready(product_id: StringName, token: String)

	## Connects and learns the products and prices. Returns whether the store can sell.
	func start(_product_ids: Array[StringName]) -> bool:
		return false

	## Whether the store is connected and knows at least one product.
	func is_available() -> bool:
		return false

	## The store's localized price for a product, or empty.
	func get_price(_product_id: StringName) -> String:
		return ""

	## Runs the purchase flow: {`status`: a `PURCHASE_*` value, `token`: the purchase token}.
	func purchase(_product_id: StringName) -> Dictionary:
		return {&"status": PURCHASE_FAILED}

	## Tells the store a purchase was delivered: consumed (bought again later) or acknowledged.
	func finish(_token: String, _consumable: bool) -> bool:
		return false

	## Completed purchases the account holds: [{`product_id`, `token`, `acknowledged`}]. Owned
	## non-consumables and consumables not consumed yet (paid but never delivered).
	func query_purchases() -> Array[Dictionary]:
		return []


## The default on desktop and in tests: no store.
class NullStoreProvider extends StoreProvider:
	pass


var _provider: AdProvider = NullAdProvider.new()
var _store: StoreProvider = NullStoreProvider.new()
## The Rift Points packs the store sells, set by Main from the Shop's catalog.
var _packs: RiftPointsPackCatalog
var _save: SaveManagerService
## Placements already consumed this run, so one rewarded revive cannot be farmed repeatedly.
var _consumed_this_run: Dictionary[StringName, bool] = {}
## Runs finished since the last interstitial, this session.
var _runs_since_interstitial: int = 0
## True while a full-screen ad is on screen, so the game does not pause itself behind it.
var _showing_ad: bool = false


func _ready() -> void:
	_save = get_node_or_null(^"/root/SaveManager") as SaveManagerService
	if OS.get_name() == "Android" and Engine.has_singleton(ADMOB_SINGLETON):
		_start_admob.call_deferred()
	if OS.get_name() == "Android" and Engine.has_singleton(BILLING_SINGLETON):
		_start_play_billing.call_deferred()


## Installs the Google Play Billing store (ADR-0030); deferred so Main can register the packs first.
func _start_play_billing() -> void:
	var store := load(PLAY_BILLING_STORE_PATH).new() as StoreProvider
	if store != null:
		set_store(store)


## Installs the AdMob provider and lets it ask for consent; the answer is stored like any consent.
func _start_admob() -> void:
	var provider := load(ADMOB_PROVIDER_PATH).new() as AdProvider
	if provider == null:
		return
	set_provider(provider)
	var allowed: bool = await provider.start()
	set_consent(allowed)


## Injects a real SDK adapter. Called once at boot by whoever owns the SDK lifecycle.
func set_provider(provider: AdProvider) -> void:
	_provider = provider if provider != null else NullAdProvider.new()


## Injects the save service directly. Used by headless tests that build their own SaveManager.
func set_save_manager(save: SaveManagerService) -> void:
	_save = save


## Whether the provider is up at all, so ads and purchases can even be attempted.
##
## False on the shipped build: no ad is offered and the Shop's buttons stay disabled.
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
## ad cannot be retried immediately — that is the pattern players read as nagging. A coroutine.
func show_rewarded(placement: StringName) -> bool:
	if not can_offer(placement):
		rewarded_failed.emit(placement)
		return false
	_consumed_this_run[placement] = true
	_showing_ad = true
	var earned: bool = await _provider.show_rewarded(placement)
	_showing_ad = false
	if earned:
		rewarded_granted.emit(placement)
		return true
	rewarded_failed.emit(placement)
	return false


## Counts a finished run toward the next interstitial. Main calls it once per run end.
func record_finished_run() -> void:
	_runs_since_interstitial += 1


## Whether an interstitial should show now: the provider up, consent decided, ads not removed,
## [constant INTERSTITIAL_RUN_INTERVAL] runs finished since the last one, and an ad loaded.
func can_show_interstitial() -> bool:
	if not is_available() or has_removed_ads():
		return false
	if get_consent_state() == CONSENT_UNKNOWN:
		return false
	if _runs_since_interstitial < INTERSTITIAL_RUN_INTERVAL:
		return false
	return _provider.is_interstitial_ready()


## Shows the interstitial when [method can_show_interstitial] allows it and returns once it is
## closed; true when one showed. A coroutine.
func show_interstitial() -> bool:
	if not can_show_interstitial():
		return false
	_showing_ad = true
	var shown: bool = await _provider.show_interstitial()
	_showing_ad = false
	if shown:
		_runs_since_interstitial = 0
	return shown


## Whether a full-screen ad is on screen right now (the game must not pause itself behind it).
func is_showing_ad() -> bool:
	return _showing_ad


## Clears per-run placement locks. Called when a new run starts.
func begin_run() -> void:
	_consumed_this_run.clear()


## Whether the store is up and knows the products, so the Shop can enable BUY. Gates Restore too.
func is_store_available() -> bool:
	return _store.is_available()


## The store's own localized price for a product ("0,99 €"), or empty before the store answers.
func get_store_price(product_id: StringName) -> String:
	return _store.get_price(product_id)


## Whether the Remove Ads product can be offered.
func can_purchase_remove_ads() -> bool:
	return is_store_available() and not has_removed_ads()


## Runs the Remove Ads purchase and returns a `PURCHASE_*` status; once bought, ads are removed and
## the purchase is acknowledged (a non-consumable the store keeps on the account). A coroutine.
func purchase_remove_ads() -> StringName:
	if not can_purchase_remove_ads():
		return PURCHASE_FAILED
	var result: Dictionary = await _store.purchase(PRODUCT_REMOVE_ADS)
	var status: StringName = StringName(str(result.get(&"status", PURCHASE_FAILED)))
	if status == PURCHASE_DONE:
		await _deliver(PRODUCT_REMOVE_ADS, str(result.get(&"token", "")))
	return status


## Runs the purchase of a Rift Points pack (owner 2026-10-05, ADR-0028) and returns a `PURCHASE_*`
## status; a completed one adds the pack's Rift Points to the save, then the purchase is consumed
## (ADR-0030: saved first, so a crash in between delivers it again at the next launch). A coroutine.
func purchase_rift_points(pack: RiftPointsPack) -> StringName:
	if pack == null or not is_store_available():
		return PURCHASE_FAILED
	var result: Dictionary = await _store.purchase(pack.product_id)
	var status: StringName = StringName(str(result.get(&"status", PURCHASE_FAILED)))
	if status == PURCHASE_DONE:
		await _deliver(pack.product_id, str(result.get(&"token", "")))
	return status


## Asks the store what this account owns and restores Remove Ads; returns whether ads are removed
## afterwards. Like the purchase, it grants no currency. A coroutine.
func restore_purchases() -> bool:
	if not is_store_available():
		return false
	await _deliver_owned_purchases()
	return has_removed_ads()


## Registers the Rift Points packs the store sells (Main passes the Shop's catalog at boot).
func set_rift_points_packs(catalog: RiftPointsPackCatalog) -> void:
	_packs = catalog


## Injects a store adapter and starts it: connect, learn the products and prices, then deliver
## anything the account owns that this save does not have yet. A coroutine.
func set_store(store: StoreProvider) -> void:
	if _store != null and _store.purchase_ready.is_connected(_on_store_purchase_ready):
		_store.purchase_ready.disconnect(_on_store_purchase_ready)
	_store = store if store != null else NullStoreProvider.new()
	_store.purchase_ready.connect(_on_store_purchase_ready)
	var started: bool = await _store.start(_product_ids())
	store_changed.emit()
	if started:
		await _deliver_owned_purchases()


func _product_ids() -> Array[StringName]:
	var ids: Array[StringName] = [PRODUCT_REMOVE_ADS]
	if _packs != null:
		for pack: RiftPointsPack in _packs.packs:
			if pack != null:
				ids.append(pack.product_id)
	return ids


## Delivers every purchase the store reports for this account: Remove Ads (owned, acknowledged if
## it was not yet) and any Rift Points pack still unconsumed (paid but never delivered).
func _deliver_owned_purchases() -> void:
	var owned: Array[Dictionary] = await _store.query_purchases()
	for entry: Dictionary in owned:
		await _deliver(StringName(str(entry.get(&"product_id", ""))), str(entry.get(&"token", "")),
			bool(entry.get(&"acknowledged", false)))


## Grants a paid product, saves, then tells the store it was delivered. A Rift Points pack is
## consumed (it can be bought again); Remove Ads is acknowledged (the account keeps it).
func _deliver(product_id: StringName, token: String, acknowledged: bool = false) -> void:
	if product_id == PRODUCT_REMOVE_ADS:
		var newly: bool = not has_removed_ads()
		if newly and _save != null:
			_save.grant_remove_ads()
			ads_removed_changed.emit(true)
		if not acknowledged:
			await _store.finish(token, false)
		if newly:
			purchase_delivered.emit(product_id, 0)
		return
	var pack: RiftPointsPack = _packs.get_pack(product_id) if _packs != null else null
	if pack == null:
		push_warning("[Monetisation] the store reported an unknown product %s" % product_id)
		return
	if _save == null or not _save.add_rift_points(pack.rift_points):
		return
	await _store.finish(token, true)
	purchase_delivered.emit(product_id, pack.rift_points)
	print("[Monetisation] delivered %s | +%d RP" % [product_id, pack.rift_points])


## A purchase that completed outside a purchase() call: a pending payment that went through later.
func _on_store_purchase_ready(product_id: StringName, token: String) -> void:
	_deliver(product_id, token)
