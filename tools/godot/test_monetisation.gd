extends SceneTree
## Monetisation gating, rewarded flow, purchase/restore and consent — driven through a fake provider.

const SAVE_SCRIPT: Script = preload("res://scripts/autoload/save_manager.gd")
const SERVICE_SCRIPT: Script = preload("res://scripts/autoload/monetisation_service.gd")

var _failures: int = 0
## SaveManager belonging to the most recently built service, so shard balances can be read back.
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
	if service.show_rewarded(MonetisationService.PLACEMENT_DOUBLE_SHARDS):
		_fail("a dismissed ad granted a reward")
	if service.can_offer(MonetisationService.PLACEMENT_DOUBLE_SHARDS):
		_fail("a dismissed placement was immediately re-offered")
	provider.rewarded_earns = true
	service.begin_run()
	if not service.can_offer(MonetisationService.PLACEMENT_REVIVE):
		_fail("a new run did not reset the placement locks")
	if service.can_offer(&"not_a_placement"):
		_fail("an unknown placement was offered")

	# --- Purchase, then ads must disappear entirely.
	if not service.can_purchase_remove_ads():
		_fail("Remove Ads was not offered with a live store")
	if not service.purchase_remove_ads():
		_fail("the Remove Ads purchase failed")
	if not service.has_removed_ads():
		_fail("ad removal did not persist")
	for placement: StringName in MonetisationService.PLACEMENTS:
		if service.can_offer(placement):
			_fail("%s was still offered after Remove Ads" % placement)
	if service.can_purchase_remove_ads():
		_fail("Remove Ads was offered again after purchase")

	# --- Restoring must never mint the bundled shards a second time.
	var restored: MonetisationService = _make_service()
	restored.set_provider(FakeProvider.new())
	restored.set_consent(true)
	restored.purchase_remove_ads()
	var after_purchase: int = _shards()
	if not restored.restore_purchases():
		_fail("restore purchases failed")
	if _shards() != after_purchase:
		_fail("restoring re-granted the bundled shards")

	if _failures == 0:
		print("monetisation: null default, consent gating, rewarded locks, purchase and restore OK")
	quit(_failures)


## Shard balance of the SaveManager backing the most recently built service.
func _shards() -> int:
	return int(_last_save.get_snapshot()[&"soul_shards"])
