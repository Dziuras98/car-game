extends SceneTree

const STOCK_PROFILE: EngineAudioProfile = preload("res://resources/audio/370z_stock_audio_profile.tres")
const NISMO_PROFILE: EngineAudioProfile = preload("res://resources/audio/370z_nismo_audio_profile.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_expect(STOCK_PROFILE.validate().is_empty(), "stock audio profile satisfies its typed contract")
	_expect(NISMO_PROFILE.validate().is_empty(), "NISMO audio profile satisfies its typed contract")
	_expect(
		STOCK_PROFILE.output_volume_boost_db > 8.0
		and STOCK_PROFILE.output_volume_boost_db <= EngineAudioProfile.MAX_OUTPUT_VOLUME_BOOST_DB,
		"stock profile retains its approved output boost"
	)
	_expect(
		NISMO_PROFILE.output_volume_boost_db > 8.0
		and NISMO_PROFILE.output_volume_boost_db <= EngineAudioProfile.MAX_OUTPUT_VOLUME_BOOST_DB,
		"NISMO profile retains its approved output boost"
	)

	var stock_audio: EngineAudioSynthesizer = EngineAudioSynthesizer.new()
	var nismo_audio: EngineAudioSynthesizer = EngineAudioSynthesizer.new()
	_expect(STOCK_PROFILE.apply_to(stock_audio), "stock profile applies to the engine synthesizer")
	_expect(NISMO_PROFILE.apply_to(nismo_audio), "NISMO profile applies to the engine synthesizer")
	_expect(
		is_equal_approx(stock_audio.output_volume_boost_db, STOCK_PROFILE.output_volume_boost_db),
		"stock synthesizer receives the profile output boost"
	)
	_expect(
		is_equal_approx(nismo_audio.output_volume_boost_db, NISMO_PROFILE.output_volume_boost_db),
		"NISMO synthesizer receives the profile output boost"
	)

	var profiled_audio: ProfiledEngineAudioSynthesizer = ProfiledEngineAudioSynthesizer.new()
	var boost_property: Dictionary = _find_property(
		profiled_audio.get_property_list(),
		&"output_volume_boost_db"
	)
	_expect(not boost_property.is_empty(), "profiled synthesizer exposes output-volume metadata")
	_expect(
		str(boost_property.get("hint_string", "")).begins_with("0.0,16.0,"),
		"profiled synthesizer editor range accepts the approved profile loudness"
	)

	var invalid_profile: EngineAudioProfile = STOCK_PROFILE.duplicate(true) as EngineAudioProfile
	invalid_profile.output_volume_boost_db = EngineAudioProfile.MAX_OUTPUT_VOLUME_BOOST_DB + 0.5
	_expect(
		not invalid_profile.validate().is_empty(),
		"profile validation rejects output boost above the supported range"
	)

	stock_audio.free()
	nismo_audio.free()
	profiled_audio.free()
	invalid_profile = null
	_finish()


func _find_property(properties: Array[Dictionary], property_name: StringName) -> Dictionary:
	for property: Dictionary in properties:
		if StringName(property.get("name", &"")) == property_name:
			return property
	return {}


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[ENGINE_AUDIO_PROFILE_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[ENGINE_AUDIO_PROFILE_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ENGINE_AUDIO_PROFILE_CONTRACT_TEST] Passed: %d checks" % _checks)
		call_deferred("quit", 0)
		return
	push_error(
		"[ENGINE_AUDIO_PROFILE_CONTRACT_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[ENGINE_AUDIO_PROFILE_CONTRACT_TEST] - %s" % failure_message)
	call_deferred("quit", 1)
