extends SceneTree

const MODEL: CarModelDefinition = preload("res://resources/cars/bmw/e46_sedan/model.tres")
const CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")

var _checks: int = 0
var _failures: Array[String] = []

func _initialize() -> void:
	_expect(MODEL != null, "BMW E46 model resource loads")
	if MODEL != null:
		_expect(MODEL.model_id == &"bmw_e46_sedan", "BMW E46 model has stable ID")
		_expect(MODEL.get_variant_count() == 51, "BMW E46 exposes all 51 inventoried sedan powertrains")
		_expect(MODEL.default_variant_id == &"bmw_e46_sedan_330i_6mt", "330i 6MT is the default variant")
		var errors: PackedStringArray = MODEL.validate()
		_expect(errors.is_empty(), "BMW E46 model validates: %s" % "; ".join(errors))
		_test_variants()
		_test_all_engine_audio_profiles()
	_expect(CATALOG != null and CATALOG.get_model_by_id(&"bmw_e46_sedan") == MODEL, "main catalog registers BMW E46")
	_test_smg_model()
	_finish()

func _test_variants() -> void:
	var engine_profiles: Dictionary = {}
	var smg_count: int = 0
	var automatic_count: int = 0
	var manual_count: int = 0
	for variant: CarVariantDefinition in MODEL.get_variants():
		_expect(variant != null, "variant is not null")
		if variant == null: continue
		_expect(variant.validate().is_empty(), "%s validates" % str(variant.variant_id))
		_expect(variant.is_ai_eligible_for_race(), "%s is AI eligible" % str(variant.variant_id))
		_expect(variant.specs != null and variant.specs.torque_curve != null, "%s has a sampled torque curve" % str(variant.variant_id))
		_expect(variant.specs != null and variant.specs.engine_audio_profile is BmwE46EngineAudioProfile, "%s has a BMW engine audio profile" % str(variant.variant_id))
		if variant.specs == null: continue
		var audio := variant.specs.engine_audio_profile as BmwE46EngineAudioProfile
		if audio != null:
			engine_profiles[str(audio.family_id)] = true
			_expect(audio.validate().is_empty(), "%s audio profile validates" % str(audio.family_id))
		if variant.specs.is_smg_transmission(): smg_count += 1
		elif variant.specs.is_automatic_transmission(): automatic_count += 1
		else: manual_count += 1
		var theoretical_speed: float = variant.specs.rev_limiter_rpm / (variant.specs.gear_ratios[variant.specs.gear_ratios.size() - 1] * variant.specs.final_drive_ratio) * TAU * variant.specs.wheel_radius / 60.0
		_expect(variant.specs.max_forward_speed <= theoretical_speed * 1.05, "%s top speed is gear-valid" % str(variant.variant_id))
	_expect(engine_profiles.size() == 18, "all 18 European engine calibrations have distinct active profiles")
	_expect(smg_count == 4, "four SMG variants are imported")
	_expect(automatic_count == 22, "twenty-two torque-converter automatic variants are imported")
	_expect(manual_count == 25, "twenty-five manual variants are imported")


func _test_all_engine_audio_profiles() -> void:
	var expected_engine_keys: Array[StringName] = [
		&"m43tu_b19_77", &"m43tu_b19_87", &"n42_b18_85", &"n46_b18_85",
		&"n42_b20_105", &"n46_b20_105", &"m52tu_b20_110", &"m54_b22_125",
		&"m52tu_b25_125", &"m54_b25_eu_141", &"m52tu_b28_142", &"m54_b30_eu_170",
		&"m47_d20_85_265", &"m47tu_d20_85_280", &"m47_d20_100_280",
		&"m47tu_d20_110_330", &"m57_d30_135", &"m57tu_d30_150",
		&"n40_b16_85", &"n45_b16_85", &"m54_b25_us_137", &"m56_b25_sulev_135",
		&"m54_b30_us_168", &"m54_b30_zhp_175",
	]
	for engine_key: StringName in expected_engine_keys:
		var profile: BmwE46EngineAudioProfile = (MODEL as BmwE46ModelDefinition).get_audio_profile(engine_key)
		_expect(profile != null, "%s has a dedicated audio profile" % str(engine_key))
		if profile != null:
			_expect(profile.family_id == engine_key, "%s profile keeps its exact calibration identity" % str(engine_key))
			_expect(profile.validate().is_empty(), "%s profile validates" % str(engine_key))
			var synthesizer := BmwE46EngineAudioSynthesizer.new()
			profile.apply_to(synthesizer)
			var sample_rpm: float = 2500.0 if profile.diesel_combustion > 0.0 else 4200.0
			var frames: PackedFloat32Array = synthesizer.generate_test_frames(512, sample_rpm, 0.82, 0.78)
			var peak: float = 0.0
			var finite: bool = true
			for sample: float in frames:
				finite = finite and is_finite(sample)
				peak = maxf(peak, absf(sample))
			_expect(finite and peak > 0.0001, "%s synthesizer generates finite non-silent audio" % str(engine_key))
			synthesizer.free()

func _test_smg_model() -> void:
	var variant: CarVariantDefinition = MODEL.get_variant_by_id(&"bmw_e46_sedan_330i_smg6")
	_expect(variant != null and variant.specs.is_smg_transmission(), "330i 6SMG uses the SMG model")
	if variant == null: return
	var config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(variant.specs)
	var state := CarRuntimeState.new()
	var controller := BmwE46PowertrainController.new()
	controller.configure(config)
	state.reset_drive_state(config.idle_rpm)
	controller.reset(state)
	state.ground_contact_count = GroundContactModel.PROBE_COUNT
	state.set_drive_input_snapshot(1.0, 0.0)
	controller.update(state, 1.0, 0.0, false, false, false, 1.0 / 60.0)
	_expect(state.current_gear == 1, "SMG selects first gear automatically")
	_expect(state.clutch_engagement > 0.0 and state.clutch_engagement < 1.0, "SMG launch clutch slips progressively")
	state.engine_rpm = config.smg_upshift_rpm + 50.0
	controller.update(state, 1.0, 0.0, false, false, false, 1.0 / 60.0)
	_expect(state.current_gear == 2 and state.shift_timer > 0.0, "SMG performs an automatic upshift")
	_expect(state.clutch_engagement == 0.0, "SMG opens the clutch during a shift")

func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[BMW_E46_CONTENT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[BMW_E46_CONTENT_TEST][FAIL] %s" % message)

func _finish() -> void:
	if _failures.is_empty():
		print("[BMW_E46_CONTENT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[BMW_E46_CONTENT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures: push_error("[BMW_E46_CONTENT_TEST] - %s" % failure_message)
	quit(1)
