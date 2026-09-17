extends SceneTree
## Monetisation gating, rewarded flow, purchase/restore and consent — driven through a fake provider.

const SAVE_SCRIPT: Script = preload("res://scripts/autoload/save_manager.gd")
const SERVICE_SCRIPT: Script = preload("res://scripts/autoload/monetisation_service.gd")

var _failures: int = 0
## SaveManager belonging to the most recently built service, so Rift Points balances can be read back.
var _last_save: SaveManagerService


## Provider that answers yes to everything, so the whole flow can be exercised headlessly.
class FakeProvider extends MonetisationService.AdProvider:
	var rewarded_earns: bool = true
	var store_up: bool = true
	var shown: Array[StringName] = []

	func is_available() -> bool:
		return true

	func is_rewarded_ready(_placement: StringName) -> bool:
		return true

	func show_rewarded(placement: StringName) -> bool:
		shown.append(placement)
		return rewarded_earns

	func is_store_available() -> bool:
		return store_up

	func purchase(_product_id: StringName) -> bool:
		return store_up

	func restore_purchases() -> bool:
		return store_up


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
		if shipped.show_rewarded(placement):
			_fail("%s paid a reward with no provider" % placement)
	if shipped.is_store_available():
		_fail("the store reported available with no provider, so the Shop would enable its buttons")
	if shipped.can_purchase_remove_ads():
		_fail("Remove Ads was offered with no store")
	if shipped.purchase_remove_ads():
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
	if not service.show_rewarded(MonetisationService.PLACEMENT_REVIVE):
		_fail("a completed rewarded ad did not grant")
	if service.can_offer(MonetisationService.PLACEMENT_REVIVE):
		_fail("revive was offered twice in one run")
	if service.show_rewarded(MonetisationService.PLACEMENT_REVIVE):
		_fail("revive granted twice in one run")
	# A dismissed ad still consumes the placement, so it cannot be retried immediately.
	provider.rewarded_earns = false
	if service.show_rewarded(MonetisationService.PLACEMENT_DOUBLE_RIFT_POINTS):
		_fail("a dismissed ad granted a reward")
	if service.can_offer(MonetisationService.PLACEMENT_DOUBLE_RIFT_POINTS):
		_fail("a dismissed placement was immediately re-offered")
	provider.rewarded_earns = true
	service.begin_run()
	if not service.can_offer(MonetisationService.PLACEMENT_REVIVE):
		_fail("a new run did not reset the placement locks")
	if service.can_offer(&"not_a_placement"):
		_fail("an unknown placement was offered")

	# --- Product id (ADR-0013): Remove Ads only, with no currency inside.
	if MonetisationService.PRODUCT_REMOVE_ADS != &"remove_ads":
		_fail("the Remove Ads product id is %s" % MonetisationService.PRODUCT_REMOVE_ADS)
	if &"double_rift_points" not in MonetisationService.PLACEMENTS:
		_fail("the double Rift Points placement is missing")

	# --- Purchase, then ads must disappear entirely; the balance must not move.
	_last_save.add_rift_points(300)
	var before_purchase: int = _rift_points()
	if not service.is_store_available():
		_fail("the store was not reported available with a live provider")
	if not service.can_purchase_remove_ads():
		_fail("Remove Ads was not offered with a live store")
	if not service.purchase_remove_ads():
		_fail("the Remove Ads purchase failed")
	if _rift_points() != before_purchase:
		_fail("the Remove Ads purchase changed the Rift Points balance by %d"
			% (_rift_points() - before_purchase))
	if not service.has_removed_ads():
		_fail("ad removal did not persist")
	for placement: StringName in MonetisationService.PLACEMENTS:
		if service.can_offer(placement):
			_fail("%s was still offered after Remove Ads" % placement)
	if service.can_purchase_remove_ads():
		_fail("Remove Ads was offered again after purchase")
	if not service.is_store_available():
		_fail("owning Remove Ads hid the store, so Restore Purchases would be disabled")

	# --- Restoring grants ad removal only: on a fresh install and after a purchase alike.
	var restored: MonetisationService = _make_service()
	restored.set_provider(FakeProvider.new())
	restored.set_consent(true)
	_last_save.add_rift_points(300)
	var fresh_balance: int = _rift_points()
	if not restored.restore_purchases():
		_fail("restore purchases failed")
	if not restored.has_removed_ads():
		_fail("restoring did not remove ads")
	if _rift_points() != fresh_balance:
		_fail("restoring on a fresh install changed the Rift Points balance")
	var after_restore: int = _rift_points()
	if not restored.restore_purchases():
		_fail("a second restore failed")
	if _rift_points() != after_restore:
		_fail("restoring again changed the Rift Points balance")

	if _failures == 0:
		print("monetisation: null default, consent gating, rewarded locks, purchase and restore OK")
	quit(_failures)


## Rift Points balance of the SaveManager backing the most recently built service.
func _rift_points() -> int:
	return int(_last_save.get_snapshot()[&"rift_points"])
