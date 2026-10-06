extends MonetisationService.StoreProvider
## Google Play Billing through the godot-sdk-integrations plugin (owner 2026-10-05, ADR-0030).
##
## [MonetisationService] creates it only on Android when the plugin's singleton exists. It connects,
## asks Play for the products (Remove Ads and the Rift Points packs, all one-time "inapp" products)
## and their localized prices, runs purchases, and consumes or acknowledges them once Monetisation
## has delivered them. Until Play Console has the app and those products, Play knows none of them,
## so [method is_available] stays false and the Shop keeps its buttons disabled.

## Seconds to wait for Play before giving up on one request.
const TIMEOUT_SECONDS: float = 20.0

signal _connection_finished(connected: bool)
signal _products_received(response: Dictionary)
signal _purchases_received(response: Dictionary)
signal _purchase_finished(response: Dictionary)
signal _finish_received(response: Dictionary)

var _billing: BillingClient
var _connected: bool = false
## Product id → product details from Play.
var _products: Dictionary[StringName, Dictionary] = {}
## The product being bought right now, so its update is told apart from a late pending one.
var _buying: StringName = &""


func start(product_ids: Array[StringName]) -> bool:
	_billing = BillingClient.new()
	_billing.connected.connect(func() -> void: _connection_finished.emit(true))
	_billing.connect_error.connect(func(code: int, message: String) -> void:
		print("[Store] billing connect error %d: %s" % [code, message])
		_connection_finished.emit(false))
	_billing.disconnected.connect(func() -> void: _connected = false)
	_billing.query_product_details_response.connect(_products_received.emit)
	_billing.query_purchases_response.connect(_purchases_received.emit)
	_billing.on_purchase_updated.connect(_on_purchase_updated)
	_billing.consume_purchase_response.connect(_finish_received.emit)
	_billing.acknowledge_purchase_response.connect(_finish_received.emit)
	_billing.start_connection()
	_connected = await _wait(_connection_finished, false)
	if not _connected:
		return false
	var ids := PackedStringArray()
	for id: StringName in product_ids:
		ids.append(String(id))
	_billing.query_product_details(ids, BillingClient.ProductType.INAPP)
	var response: Dictionary = await _wait(_products_received, {})
	if int(response.get("response_code", -1)) == BillingClient.BillingResponseCode.OK:
		for details: Dictionary in response.get("product_details", []):
			var id: StringName = StringName(str(details.get("product_id", "")))
			if not id.is_empty():
				_products[id] = details
	print("[Store] Google Play Billing connected | %d of %d products known" % [_products.size(), ids.size()])
	return is_available()


func is_available() -> bool:
	return _connected and not _products.is_empty()


func get_price(product_id: StringName) -> String:
	# Billing Library 8+ lists one-time offers (keys read from the plugin's own classes, 2026-10-05).
	var details: Dictionary = _products.get(product_id, {})
	var offers: Variant = details.get("one_time_purchase_offer_details_list", [])
	if offers is Array and not (offers as Array).is_empty() and (offers as Array)[0] is Dictionary:
		return str(((offers as Array)[0] as Dictionary).get("formatted_price", ""))
	return ""


func purchase(product_id: StringName) -> Dictionary:
	if not is_available() or not _products.has(product_id):
		return {&"status": MonetisationService.PURCHASE_FAILED}
	_buying = product_id
	var launched: Dictionary = _billing.purchase(String(product_id))
	if int(launched.get("response_code", BillingClient.BillingResponseCode.OK)) != BillingClient.BillingResponseCode.OK:
		_buying = &""
		return {&"status": MonetisationService.PURCHASE_FAILED}
	var response: Dictionary = await _purchase_finished
	_buying = &""
	var code: int = int(response.get("response_code", -1))
	if code == BillingClient.BillingResponseCode.USER_CANCELED:
		return {&"status": MonetisationService.PURCHASE_CANCELLED}
	if code != BillingClient.BillingResponseCode.OK:
		print("[Store] purchase %s failed %d: %s" % [product_id, code, response.get("debug_message", "")])
		return {&"status": MonetisationService.PURCHASE_FAILED}
	for entry: Dictionary in response.get("purchases", []):
		if String(product_id) not in Array(entry.get("product_ids", [])):
			continue
		if int(entry.get("purchase_state", 0)) == BillingClient.PurchaseState.PENDING:
			return {&"status": MonetisationService.PURCHASE_PENDING}
		if int(entry.get("purchase_state", 0)) == BillingClient.PurchaseState.PURCHASED:
			return {&"status": MonetisationService.PURCHASE_DONE, &"token": str(entry.get("purchase_token", ""))}
	return {&"status": MonetisationService.PURCHASE_FAILED}


func finish(token: String, consumable: bool) -> bool:
	if token.is_empty() or not _connected:
		return false
	if consumable:
		_billing.consume_purchase(token)
	else:
		_billing.acknowledge_purchase(token)
	var response: Dictionary = await _wait(_finish_received, {})
	return int(response.get("response_code", -1)) == BillingClient.BillingResponseCode.OK


func query_purchases() -> Array[Dictionary]:
	var owned: Array[Dictionary] = []
	if not _connected:
		return owned
	_billing.query_purchases(BillingClient.ProductType.INAPP)
	var response: Dictionary = await _wait(_purchases_received, {})
	if int(response.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		return owned
	for entry: Dictionary in response.get("purchases", []):
		if int(entry.get("purchase_state", 0)) != BillingClient.PurchaseState.PURCHASED:
			continue
		for id: Variant in entry.get("product_ids", []):
			owned.append({
				&"product_id": StringName(str(id)),
				&"token": str(entry.get("purchase_token", "")),
				&"acknowledged": bool(entry.get("is_acknowledged", false)),
			})
	return owned


## The purchase the player is waiting on goes to [method purchase]; any other completed purchase
## (a pending payment that went through) is handed to Monetisation through `purchase_ready`.
func _on_purchase_updated(response: Dictionary) -> void:
	if not _buying.is_empty():
		_purchase_finished.emit(response)
		return
	if int(response.get("response_code", -1)) != BillingClient.BillingResponseCode.OK:
		return
	for entry: Dictionary in response.get("purchases", []):
		if int(entry.get("purchase_state", 0)) != BillingClient.PurchaseState.PURCHASED:
			continue
		for id: Variant in entry.get("product_ids", []):
			purchase_ready.emit(StringName(str(id)), str(entry.get("purchase_token", "")))


## Waits for [param done] or [constant TIMEOUT_SECONDS], whichever comes first; returns the signal's
## value, or [param fallback] on time-out.
func _wait(done: Signal, fallback: Variant) -> Variant:
	var tree := Engine.get_main_loop() as SceneTree
	var state := {&"value": fallback, &"finished": false}
	var finish := func(value: Variant = null) -> void:
		if state[&"finished"]:
			return
		state[&"finished"] = true
		state[&"value"] = value if value != null else fallback
	done.connect(finish, CONNECT_ONE_SHOT)
	var timer := tree.create_timer(TIMEOUT_SECONDS, true)
	while not state[&"finished"] and timer.time_left > 0.0:
		await tree.process_frame
	if done.is_connected(finish):
		done.disconnect(finish)
	return state[&"value"]
