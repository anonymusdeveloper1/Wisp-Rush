extends SceneTree
## Monetisation gating, rewarded flow, interstitial cadence, store purchases (Remove Ads, Rift Points
## packs, pending, cancelled, crash recovery), restore and consent — driven through fake providers
## (ADR-0009, ADR-0029, ADR-0030).

const SAVE_SCRIPT: Script = preload("res://scripts/autoload/save_manager.gd")
const SERVICE_SCRIPT: Script = preload("res://scripts/autoload/monetisation_service.gd")
const PACKS: RiftPointsPackCatalog = preload("res://data/shop/rift_points_packs.tres")

var _failures: int = 0
## SaveManager belonging to the most recently built service, so Rift Points balances can be read back.
var _last_save: SaveManagerService


## Provider that answers yes to everything, so the whole flow can be exercised headlessly.
class FakeProvider extends MonetisationService.AdProvider:
	var rewarded_earns: bool = true
	var shown: Array[StringName] = []
	var interstitials: int = 0

	func is_available() -> bool:
		return true

	func is_rewarded_ready(_placement: StringName) -> bool:
		return true

	func show_rewarded(placement: StringName) -> bool:
		shown.append(placement)
		return rewarded_earns

	func is_interstitial_ready() -> bool:
		return true

	func show_interstitial() -> bool:
		interstitials += 1
		return true



## Store that sells everything; `next_status` decides how the next purchase ends, `owned` is what the
## account holds, `finished` records consume (true) / acknowledge (false) calls.
class FakeStore extends MonetisationService.StoreProvider:
	var next_status: StringName = MonetisationService.PURCHASE_DONE
	var owned: Array[Dictionary] = []
	var finished: Array[Array] = []
	var bought: Array[StringName] = []

	func start(_product_ids: Array[StringName]) -> bool:
		return true

	func is_available() -> bool:
		return true

	func get_price(_product_id: StringName) -> String:
		return "1,99 €"

	func purchase(product_id: StringName) -> Dictionary:
		bought.append(product_id)
		return {&"status": next_status, &"token": "token_%s" % product_id}

	func finish(token: String, consumable: bool) -> bool:
		finished.append([token, consumable])
		return true

	func query_purchases() -> Array[Dictionary]:
		return owned


func _init() -> void:
	call_deferred(&"_run")


func _fail(message: String) -> void:
	_failures += 1
	push_error("monetisation: %s" % message)


func _make_service() -> MonetisationService:
	var root_dir: String = "user://codex_monet_%d" % Time.get_ticks_usec()
	var save := SAVE_SCRIPT.new() as SaveManagerService
	save.configure_storage_paths(
		root_dir + "/save.json", root_dir + "/tmp.json", root_dir + "/backup.json"
	)
	root.add_child(save)
	var service := SERVICE_SCRIPT.new() as MonetisationService
	root.add_child(service)
	service.set_save_manager(save)
	_last_save = save
	return service


func _run() -> void:
	# --- Shipped default: nothing is available, so no surface may be offered.
	var shipped: MonetisationService = _make_service()
	if shipped.is_available():
		_fail("the default build reports monetisation as available")
	for placement: StringName in MonetisationService.PLACEMENTS:
		if shipped.can_offer(placement):
			_fail("%s was offered with no provider" % placement)
		if await shipped.show_rewarded(placement):
			_fail("%s paid a reward with no provider" % placement)
	for _run_index: int in 3:
		shipped.record_finished_run()
	if shipped.can_show_interstitial() or await shipped.show_interstitial():
		_fail("an interstitial showed with no provider")
	if shipped.is_store_available():
		_fail("the store reported available with no provider, so the Shop would enable its buttons")
	if shipped.can_purchase_remove_ads():
		_fail("Remove Ads was offered with no store")
	if await shipped.purchase_remove_ads() != MonetisationService.PURCHASE_FAILED:
		_fail("Remove Ads completed with no store")
	if shipped.needs_consent_prompt():
		_fail("a consent prompt was demanded with no provider")

	# --- With a provider, consent gates everything.
	var service: MonetisationService = _make_service()
	var provider := FakeProvider.new()
	service.set_provider(provider)
	if not service.is_available():
		_fail("an injected provider was not picked up")
	if not service.needs_consent_prompt():
		_fail("consent was not requested before the first ad")
	if service.can_offer(MonetisationService.PLACEMENT_REVIVE):
		_fail("an offer was made before consent was decided")
	service.set_consent(true)
	if service.get_consent_state() != MonetisationService.CONSENT_GRANTED:
		_fail("consent did not persist")
	if service.needs_consent_prompt():
		_fail("consent was still requested after a decision")

	# --- Rewarded flow: granted once, then locked for the rest of the run.
	if not service.can_offer(MonetisationService.PLACEMENT_REVIVE):
		_fail("revive was not offered once everything was ready")
	if not await service.show_rewarded(MonetisationService.PLACEMENT_REVIVE):
		_fail("a completed rewarded ad did not grant")
	if service.can_offer(MonetisationService.PLACEMENT_REVIVE):
		_fail("revive was offered twice in one run")
	if await service.show_rewarded(MonetisationService.PLACEMENT_REVIVE):
		_fail("revive granted twice in one run")
	# A dismissed ad still consumes the placement, so it cannot be retried immediately.
	provider.rewarded_earns = false
	if await service.show_rewarded(MonetisationService.PLACEMENT_DOUBLE_RIFT_POINTS):
		_fail("a dismissed ad granted a reward")
	if service.can_offer(MonetisationService.PLACEMENT_DOUBLE_RIFT_POINTS):
		_fail("a dismissed placement was immediately re-offered")
	provider.rewarded_earns = true
	service.begin_run()
	if not service.can_offer(MonetisationService.PLACEMENT_REVIVE):
		_fail("a new run did not reset the placement locks")
	if service.can_offer(&"not_a_placement"):
		_fail("an unknown placement was offered")

	# --- Interstitials (owner 2026-10-05, ADR-0029): one after every second finished run.
	service.record_finished_run()
	if service.can_show_interstitial():
		_fail("an interstitial was due after the first finished run")
	service.record_finished_run()
	if not service.can_show_interstitial():
		_fail("no interstitial was due after the second finished run")
	if not await service.show_interstitial() or provider.interstitials != 1:
		_fail("the due interstitial did not show")
	if service.can_show_interstitial():
		_fail("an interstitial was due again right after one showed")
	service.record_finished_run()
	if service.can_show_interstitial():
		_fail("an interstitial was due one run after the last")
	service.record_finished_run()
	if not service.can_show_interstitial():
		_fail("no interstitial was due two runs after the last")

	# --- Product id (ADR-0013): Remove Ads only, with no currency inside.
	if MonetisationService.PRODUCT_REMOVE_ADS != &"remove_ads":
		_fail("the Remove Ads product id is %s" % MonetisationService.PRODUCT_REMOVE_ADS)
	if &"double_rift_points" not in MonetisationService.PLACEMENTS:
		_fail("the double Rift Points placement is missing")

	# --- Purchase, then ads must disappear entirely; the balance must not move.
	var store := FakeStore.new()
	service.set_rift_points_packs(PACKS)
	await service.set_store(store)
	_last_save.add_rift_points(300)
	var before_purchase: int = _rift_points()
	if not service.is_store_available():
		_fail("the store was not reported available with a live provider")
	if service.get_store_price(MonetisationService.PRODUCT_REMOVE_ADS) != "1,99 €":
		_fail("the store's price did not reach the service")
	if not service.can_purchase_remove_ads():
		_fail("Remove Ads was not offered with a live store")
	store.next_status = MonetisationService.PURCHASE_CANCELLED
	if await service.purchase_remove_ads() != MonetisationService.PURCHASE_CANCELLED or service.has_removed_ads():
		_fail("a cancelled Remove Ads purchase removed ads")
	store.next_status = MonetisationService.PURCHASE_DONE
	if await service.purchase_remove_ads() != MonetisationService.PURCHASE_DONE:
		_fail("the Remove Ads purchase failed")
	if store.finished.back() != ["token_remove_ads", false]:
		_fail("Remove Ads was not acknowledged as a non-consumable (%s)" % [store.finished])
	if _rift_points() != before_purchase:
		_fail("the Remove Ads purchase changed the Rift Points balance by %d"
			% (_rift_points() - before_purchase))
	if not service.has_removed_ads():
		_fail("ad removal did not persist")
	for placement: StringName in MonetisationService.PLACEMENTS:
		if service.can_offer(placement):
			_fail("%s was still offered after Remove Ads" % placement)
	# Remove Ads removes every ad (owner 2026-10-05), interstitials included.
	if service.can_show_interstitial() or await service.show_interstitial():
		_fail("an interstitial showed after Remove Ads")
	if service.can_purchase_remove_ads():
		_fail("Remove Ads was offered again after purchase")
	if not service.is_store_available():
		_fail("owning Remove Ads hid the store, so Restore Purchases would be disabled")

	# --- Rift Points packs (ADR-0028/0030): saved first, then consumed; pending and cancelled add nothing.
	var pack: RiftPointsPack = PACKS.get_pack(&"rp_pack_1200")
	var before_pack: int = _rift_points()
	store.next_status = MonetisationService.PURCHASE_PENDING
	if await service.purchase_rift_points(pack) != MonetisationService.PURCHASE_PENDING or _rift_points() != before_pack:
		_fail("a pending pack purchase added Rift Points")
	store.next_status = MonetisationService.PURCHASE_DONE
	if await service.purchase_rift_points(pack) != MonetisationService.PURCHASE_DONE:
		_fail("the pack purchase failed")
	if _rift_points() != before_pack + 1200:
		_fail("the pack added %d RP, expected 1200" % (_rift_points() - before_pack))
	if store.finished.back() != ["token_rp_pack_1200", true]:
		_fail("the pack was not consumed after delivery (%s)" % [store.finished])
	# The pending payment completes later: the store hands it over and it is delivered once.
	var delivered: Array = []
	service.purchase_delivered.connect(func(id: StringName, rp: int) -> void: delivered.append([id, rp]))
	store.purchase_ready.emit(&"rp_pack_500", "token_late")
	for _frame: int in 3:
		await process_frame
	if _rift_points() != before_pack + 1200 + 500 or delivered != [[&"rp_pack_500", 500]]:
		_fail("a completed pending payment was not delivered once (%s)" % [delivered])

	# --- Restoring grants ad removal only: on a fresh install and after a purchase alike.
	var restored: MonetisationService = _make_service()
	restored.set_provider(FakeProvider.new())
	restored.set_consent(true)
	restored.set_rift_points_packs(PACKS)
	var restore_store := FakeStore.new()
	restore_store.owned = [{&"product_id": &"remove_ads", &"token": "t_ads", &"acknowledged": true}]
	_last_save.add_rift_points(300)
	var fresh_balance: int = _rift_points()
	# Starting the store already restores what the account owns (a reinstall gets Remove Ads back).
	await restored.set_store(restore_store)
	if not restored.has_removed_ads():
		_fail("starting the store did not restore Remove Ads")
	if not await restored.restore_purchases():
		_fail("restore purchases failed")
	if _rift_points() != fresh_balance:
		_fail("restoring changed the Rift Points balance")
	if not restore_store.finished.is_empty():
		_fail("an acknowledged Remove Ads was acknowledged again (%s)" % [restore_store.finished])

	# --- A pack paid but never delivered (a crash before the save) is delivered at the next start.
	var crashed: MonetisationService = _make_service()
	crashed.set_rift_points_packs(PACKS)
	var crash_store := FakeStore.new()
	crash_store.owned = [{&"product_id": &"rp_pack_2500", &"token": "t_lost", &"acknowledged": false}]
	var before_crash: int = _rift_points()
	await crashed.set_store(crash_store)
	if _rift_points() != before_crash + 2500 or crash_store.finished != [["t_lost", true]]:
		_fail("an undelivered pack was not delivered and consumed at start (%d RP, %s)" % [
			_rift_points() - before_crash, crash_store.finished,
		])

	if _failures == 0:
		print("monetisation: null default, consent gating, rewarded locks, interstitial cadence, store purchases, recovery and restore OK")
	quit(_failures)


## Rift Points balance of the SaveManager backing the most recently built service.
func _rift_points() -> int:
	return int(_last_save.get_snapshot()[&"rift_points"])
