extends SceneTree

const MIN_TURBO_LIMITER_RESIDUAL: float = 0.28
const VOLUME_EPSILON_DB: float = 0.001
const FIAT_GT: EngineAudioProfile = preload("res://resources/audio/fiat_punto_176a4_gt_audio_profile.tres")
const FIAT_NA_PETROL: EngineAudioProfile = preload("res://resources/audio/fiat_punto_176a9_1581_audio_profile.tres")
const FIAT_TD: EngineAudioProfile = preload("res://resources/audio/fiat_punto_176a5_td_audio_profile.tres")
const FIAT_NA_DIESEL: EngineAudioProfile = preload("res://resources/audio/fiat_punto_176b3_diesel_audio_profile.tres")
const BMW_MODEL: CarModelDefinition = preload("res://resources/cars/bmw/e46_sedan/model.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_fiat_turbo_profiles()
	_test_bmw_turbo_profiles()
	_finish()


func _test_fiat_turbo_profiles() -> void:
	_assert_turbo_not_louder_than_reference(FIAT_GT, FIAT_NA_PETROL, "Punto GT", "Punto 90")
	_assert_turbo_not_louder_than_reference(FIAT_TD, FIAT_NA_DIESEL, "Punto TD70", "Punto D")
	_expect(
		FIAT_GT.limiter_residual_combustion >= MIN_TURBO_LIMITER_RESIDUAL,
		"Punto GT keeps enough residual combustion to avoid an abrupt turbo-limiter cut"
	)
	_expect(
		FIAT_TD.limiter_residual_combustion >= MIN_TURBO_LIMITER_RESIDUAL,
		"Punto TD70 keeps enough residual combustion to avoid an abrupt turbo-limiter cut"
	)


func _test_bmw_turbo_profiles() -> void:
	_expect(BMW_MODEL != null, "BMW E46 model loads for turbo audio balance checks")
	if BMW_MODEL == null:
		return

	var naturally_aspirated_idle_ceiling_db: float = -INF
	var naturally_aspirated_load_ceiling_db: float = -INF
	var naturally_aspirated_effective_idle_ceiling_db: float = -INF
	var naturally_aspirated_effective_load_ceiling_db: float = -INF
	var turbo_profiles: Array[EngineAudioProfile] = []
	var seen_families: Dictionary = {}

	for variant: CarVariantDefinition in BMW_MODEL.get_variants():
		if variant == null or variant.specs == null:
			continue
		var profile := variant.specs.engine_audio_profile as EngineAudioProfile
		if profile == null or seen_families.has(profile.family_id):
			continue
		seen_families[profile.family_id] = true
		if _is_turbo_profile(profile):
			turbo_profiles.append(profile)
			continue
		naturally_aspirated_idle_ceiling_db = maxf(
			naturally_aspirated_idle_ceiling_db,
			_master_level_db(profile, false)
		)
		naturally_aspirated_load_ceiling_db = maxf(
			naturally_aspirated_load_ceiling_db,
			_master_level_db(profile, true)
		)
		naturally_aspirated_effective_idle_ceiling_db = maxf(
			naturally_aspirated_effective_idle_ceiling_db,
			_effective_level_db(profile, false)
		)
		naturally_aspirated_effective_load_ceiling_db = maxf(
			naturally_aspirated_effective_load_ceiling_db,
			_effective_level_db(profile, true)
		)

	_expect(not turbo_profiles.is_empty(), "BMW E46 model exposes turbocharged audio profiles")
	_expect(
		is_finite(naturally_aspirated_idle_ceiling_db)
		and is_finite(naturally_aspirated_load_ceiling_db),
		"BMW E46 model exposes naturally aspirated volume references"
	)
	for profile: EngineAudioProfile in turbo_profiles:
		var label: String = str(profile.family_id)
		_expect(
			_master_level_db(profile, false) <= naturally_aspirated_idle_ceiling_db + VOLUME_EPSILON_DB,
			"%s turbo idle master level stays below the naturally aspirated ceiling" % label
		)
		_expect(
			_master_level_db(profile, true) <= naturally_aspirated_load_ceiling_db + VOLUME_EPSILON_DB,
			"%s turbo load master level stays below the naturally aspirated ceiling" % label
		)
		_expect(
			_effective_level_db(profile, false) <= naturally_aspirated_effective_idle_ceiling_db + VOLUME_EPSILON_DB,
			"%s turbo effective idle level stays below the naturally aspirated ceiling" % label
		)
		_expect(
			_effective_level_db(profile, true) <= naturally_aspirated_effective_load_ceiling_db + VOLUME_EPSILON_DB,
			"%s turbo effective load level stays below the naturally aspirated ceiling" % label
		)
		_expect(
			profile.limiter_residual_combustion >= MIN_TURBO_LIMITER_RESIDUAL,
			"%s turbo limiter keeps a continuous combustion floor" % label
		)


func _assert_turbo_not_louder_than_reference(
	turbo_profile: EngineAudioProfile,
	reference_profile: EngineAudioProfile,
	turbo_label: String,
	reference_label: String
) -> void:
	_expect(
		_master_level_db(turbo_profile, false) <= _master_level_db(reference_profile, false) + VOLUME_EPSILON_DB,
		"%s idle master level does not exceed %s" % [turbo_label, reference_label]
	)
	_expect(
		_master_level_db(turbo_profile, true) <= _master_level_db(reference_profile, true) + VOLUME_EPSILON_DB,
		"%s load master level does not exceed %s" % [turbo_label, reference_label]
	)
	_expect(
		_effective_level_db(turbo_profile, false) <= _effective_level_db(reference_profile, false) + VOLUME_EPSILON_DB,
		"%s effective idle level does not exceed %s" % [turbo_label, reference_label]
	)
	_expect(
		_effective_level_db(turbo_profile, true) <= _effective_level_db(reference_profile, true) + VOLUME_EPSILON_DB,
		"%s effective load level does not exceed %s" % [turbo_label, reference_label]
	)


func _master_level_db(profile: EngineAudioProfile, loaded: bool) -> float:
	var operating_level_db: float = profile.load_volume_db if loaded else profile.idle_volume_db
	return operating_level_db + profile.output_volume_boost_db


func _effective_level_db(profile: EngineAudioProfile, loaded: bool) -> float:
	return _master_level_db(profile, loaded) + profile.synthesis_gain_db


func _is_turbo_profile(profile: EngineAudioProfile) -> bool:
	return maxf(profile.turbo_whistle, maxf(profile.turbo_flutter, profile.turbo_blowoff)) > 0.0001


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TURBO_AUDIO_BALANCE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TURBO_AUDIO_BALANCE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TURBO_AUDIO_BALANCE_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TURBO_AUDIO_BALANCE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TURBO_AUDIO_BALANCE_TEST] - %s" % failure_message)
	quit(1)
