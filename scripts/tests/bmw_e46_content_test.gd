extends SceneTree

const MODEL: CarModelDefinition = preload("res://resources/cars/bmw/e46_sedan/model.tres")
const CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const VISUAL_SCENE: PackedScene = preload("res://scenes/cars/bmw_e46_sedan_visuals.tscn")

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
		_test_inline_six_audio_identity()
	_expect(CATALOG != null and CATALOG.get_model_by_id(&"bmw_e46_sedan") == MODEL, "main catalog registers BMW E46")
	_test_visual_scale()
	_test_torque_converter_automatic_player_model()
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


func _test_inline_six_audio_identity() -> void:
	var definition := MODEL as BmwE46ModelDefinition
	var petrol_four: BmwE46EngineAudioProfile = definition.get_audio_profile(&"n46_b20_105")
	var petrol_six: BmwE46EngineAudioProfile = definition.get_audio_profile(&"m54_b30_eu_170")
	var diesel_four: BmwE46EngineAudioProfile = definition.get_audio_profile(&"m47tu_d20_110_330")
	var diesel_six: BmwE46EngineAudioProfile = definition.get_audio_profile(&"m57tu_d30_150")
	_expect(is_equal_approx(BmwE46EngineAudioSynthesizer.inline_six_collector_frequency_hz(3600.0), 90.0), "inline-six collector cadence is 1.5 crank orders")
	_expect(petrol_six != null and petrol_four != null and petrol_six.cylinders == 6 and petrol_four.cylinders == 4, "petrol BMW profiles preserve cylinder architecture")
	if petrol_six != null and petrol_four != null:
		_expect(petrol_six.exhaust_resonance > petrol_four.exhaust_resonance + 0.15, "petrol inline six has a stronger exhaust body than the inline four")
		_expect(petrol_six.exhaust_roughness < petrol_four.exhaust_roughness * 0.55, "petrol inline six is materially smoother than the inline four")
		_expect(petrol_six.combustion_sharpness < petrol_four.combustion_sharpness, "petrol inline six avoids four-cylinder combustion harshness")
	_expect(diesel_six != null and diesel_four != null and diesel_six.cylinders == 6 and diesel_four.cylinders == 4, "diesel BMW profiles preserve cylinder architecture")
	if diesel_six != null and diesel_four != null:
		_expect(diesel_six.diesel_combustion < diesel_four.diesel_combustion, "M57 combustion is smoother than M47 combustion")
		_expect(diesel_six.diesel_mechanical_clatter < diesel_four.diesel_mechanical_clatter, "M57 mechanical clatter does not mask its six-cylinder cadence")


func _test_visual_scale() -> void:
	var visuals := VISUAL_SCENE.instantiate() as BmwE46VisualController
	_expect(visuals != null, "BMW E46 visual scene instantiates")
	if visuals == null:
		return
	root.add_child(visuals)
	var detailed_size: Vector3 = visuals.get_detailed_model_size_m()
	_expect(absf(detailed_size.z - BmwE46VisualController.TARGET_BODY_LENGTH_M) <= 0.01, "detailed BMW E46 model is normalized to the 4.47 m production length")
	_expect(visuals.get_detailed_scale_correction() < 1.0, "oversized source GLB is scaled down")
	visuals.free()


func _test_torque_converter_automatic_player_model() -> void:
	var variant: CarVariantDefinition = MODEL.get_variant_by_id(&"bmw_e46_sedan_330i_5at")
	_expect(
		variant != null and variant.specs != null and variant.specs.is_torque_converter_automatic(),
		"330i 5AT is configured as a torque-converter automatic"
	)
	if variant == null or variant.specs == null:
		return

	var player_car := variant.get_car_scene().instantiate() as BmwE46CarController
	_expect(player_car != null, "330i 5AT player scene instantiates the BMW controller")
	if player_car == null:
		return
	player_car.car_specs = variant.specs
	root.add_child(player_car)
	player_car.set_physics_process(false)
	_expect(not player_car.is_manual_transmission(), "330i 5AT player runtime does not expose a manual transmission")
	_expect(player_car.get_forward_gear_count() == 5, "330i 5AT player runtime keeps all five automatic gears")
	player_car.free()

	var config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(variant.specs)
	var state := CarRuntimeState.new()
	var controller := BmwE46PowertrainController.new()
	controller.configure(config)
	state.reset_drive_state(config.idle_rpm)
	controller.reset(state)
	state.ground_contact_count = GroundContactModel.PROBE_COUNT
	state.current_gear = 1
	state.forward_speed = 8.0
	state.engine_rpm = config.idle_rpm + 250.0
	controller.update(state, 0.45, 0.0, false, true, false, 0.0)
	_expect(state.current_gear == 1, "330i 5AT ignores a manual gear-up request at low RPM")
	state.engine_rpm = config.redline_rpm
	controller.update(state, 0.45, 0.0, false, false, false, 0.0)
	_expect(state.current_gear == 2 and state.shift_timer > 0.0, "330i 5AT upshifts automatically without player gear input")
	_expect(controller.get_gear_text(state) == "D2", "330i 5AT reports an automatic drive gear")
	_expect(is_equal_approx(state.clutch_engagement, 1.0), "330i 5AT keeps the torque converter path fully engaged")


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
