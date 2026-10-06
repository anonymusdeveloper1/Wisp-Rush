extends MonetisationService.AdProvider
## Google AdMob through the Poing Studios AdMob plugin (owner 2026-10-05, ADR-0029): Google's
## consent form (UMP), then interstitial and rewarded ads.
##
## [MonetisationService] creates it only on Android when the plugin's singleton exists, so desktop
## runs and the headless tests never load the plugin's classes (in the editor they would return the
## plugin's mock ads). It keeps one interstitial and one rewarded ad loaded and replaces each after it
## shows. The ad units are Google's test units, which always serve test ads; the owner's real units
## replace them before release. The store is not connected: [method is_store_available] stays false.

## Google's test ad units for Android (ADR-0029).
const INTERSTITIAL_UNIT_ID: String = "ca-app-pub-3940256099942544/1033173712"
const REWARDED_UNIT_ID: String = "ca-app-pub-3940256099942544/5224354917"
## Seconds before a failed load is tried again.
const RETRY_SECONDS: float = 30.0

signal _consent_finished(allowed: bool)
signal _initialised
signal _interstitial_closed(shown: bool)
signal _rewarded_closed

var _ready_for_ads: bool = false
var _interstitial: InterstitialAd
var _rewarded: RewardedAd
var _loading_interstitial: bool = false
var _loading_rewarded: bool = false
var _earned: bool = false


## Asks for consent with Google's form when it is required, then initialises the SDK and loads the
## first ads. Returns whether ads may be requested (consent obtained or not required).
func start() -> bool:
	UserMessagingPlatform.consent_information.update(
		ConsentRequestParameters.new(), _on_consent_updated, _on_consent_update_failed
	)
	var allowed: bool = await _consent_finished
	print("[Ads] consent: %s" % ("ads allowed" if allowed else "ads not allowed"))
	if not allowed:
		return false
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_initialised.emit()
	MobileAds.initialize(listener)
	await _initialised
	_ready_for_ads = true
	print("[Ads] AdMob initialised (test ad units)")
	_load_interstitial()
	_load_rewarded()
	return true


func is_available() -> bool:
	return _ready_for_ads


func is_rewarded_ready(_placement: StringName) -> bool:
	return _ready_for_ads and _rewarded != null


func is_interstitial_ready() -> bool:
	return _ready_for_ads and _interstitial != null


## Shows the loaded rewarded ad and returns, once it is closed, whether the reward was earned.
func show_rewarded(placement: StringName) -> bool:
	if not is_rewarded_ready(placement):
		return false
	var ad: RewardedAd = _rewarded
	_rewarded = null
	_earned = false
	var callback := FullScreenContentCallback.new()
	callback.on_ad_dismissed_full_screen_content = _close_rewarded_next_frame
	callback.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		print("[Ads] rewarded failed to show: %s" % error.message)
		_rewarded_closed.emit()
	ad.full_screen_content_callback = callback
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
		_earned = true
	ad.show(listener)
	await _rewarded_closed
	ad.destroy()
	_load_rewarded()
	print("[Ads] rewarded %s closed | earned=%s" % [placement, _earned])
	return _earned


## Shows the loaded interstitial and returns true once it is closed; false when it could not show.
func show_interstitial() -> bool:
	if not is_interstitial_ready():
		return false
	var ad: InterstitialAd = _interstitial
	_interstitial = null
	var callback := FullScreenContentCallback.new()
	callback.on_ad_dismissed_full_screen_content = func() -> void:
		_interstitial_closed.emit(true)
	callback.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		print("[Ads] interstitial failed to show: %s" % error.message)
		_interstitial_closed.emit(false)
	ad.full_screen_content_callback = callback
	ad.show()
	var shown: bool = await _interstitial_closed
	ad.destroy()
	_load_interstitial()
	print("[Ads] interstitial closed | shown=%s" % shown)
	return shown


## The reward and the dismissal arrive as separate deferred calls; one frame later both have.
func _close_rewarded_next_frame() -> void:
	(Engine.get_main_loop() as SceneTree).process_frame.connect(
		func() -> void: _rewarded_closed.emit(), CONNECT_ONE_SHOT
	)


func _on_consent_updated() -> void:
	var info: ConsentInformation = UserMessagingPlatform.consent_information
	if (
		info.get_is_consent_form_available()
		and info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED
	):
		UserMessagingPlatform.load_consent_form(_on_consent_form_loaded, _on_consent_form_failed)
	else:
		_finish_consent()


func _on_consent_update_failed(error: FormError) -> void:
	print("[Ads] consent update failed: %s" % error.message)
	_finish_consent()


func _on_consent_form_loaded(form: ConsentForm) -> void:
	var info: ConsentInformation = UserMessagingPlatform.consent_information
	if info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED:
		form.show(func(_error: FormError) -> void: _finish_consent())
	else:
		_finish_consent()


func _on_consent_form_failed(error: FormError) -> void:
	print("[Ads] consent form failed: %s" % error.message)
	_finish_consent()


func _finish_consent() -> void:
	var status: ConsentInformation.ConsentStatus = (
		UserMessagingPlatform.consent_information.get_consent_status()
	)
	_consent_finished.emit(
		status == ConsentInformation.ConsentStatus.OBTAINED
		or status == ConsentInformation.ConsentStatus.NOT_REQUIRED
	)


func _load_interstitial() -> void:
	if _loading_interstitial or _interstitial != null:
		return
	_loading_interstitial = true
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_loading_interstitial = false
		_interstitial = ad
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_loading_interstitial = false
		print("[Ads] interstitial failed to load: %s" % error.message)
		_retry_later(_load_interstitial)
	InterstitialAdLoader.new().load(INTERSTITIAL_UNIT_ID, AdRequest.new(), callback)


func _load_rewarded() -> void:
	if _loading_rewarded or _rewarded != null:
		return
	_loading_rewarded = true
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_loading_rewarded = false
		_rewarded = ad
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_loading_rewarded = false
		print("[Ads] rewarded failed to load: %s" % error.message)
		_retry_later(_load_rewarded)
	RewardedAdLoader.new().load(REWARDED_UNIT_ID, AdRequest.new(), callback)


func _retry_later(load_again: Callable) -> void:
	(Engine.get_main_loop() as SceneTree).create_timer(RETRY_SECONDS, true).timeout.connect(load_again)
