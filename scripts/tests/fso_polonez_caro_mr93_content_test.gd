extends SceneTree

const MODEL: CarModelDefinition = preload("res://resources/cars/fso/polonez_caro_mr93/model.tres")
const CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const FORWARD_RATIOS: Array[float] = [3.753, 2.132, 1.378, 1.000, 0.860]
const FORD_RATIOS: Array[float] = [3.650, 1.970, 1.370, 1.000, 0.820]
const TOP_SPEEDS_KMH: Dictionary = {
	&"fso_polonez_caro_mr93_14_gli_16v_5mt": 176,
	&"fso_polonez_caro_mr93_15_gle_5mt": 155,
	&"fso_polonez_caro_mr93_15_gli_5mt": 158,
	&"fso_polonez_caro_mr93_16_gle_5mt": 160,
	&"fso_polonez_caro_mr93_16_gli_5mt": 163,
	&"fso_polonez_caro_mr93_20_gle_ford_5mt": 179,
	&"fso_polonez_caro_mr93_19_gld_5mt": 153,
}
const ZERO_TO_100_SECONDS: Dictionary = {
	&"fso_polonez_caro_mr93_14_gli_16v_5mt": 15.1,
	&"fso_polonez_caro_mr93_15_gle_5mt": 17.6,
	&"fso_polonez_caro_mr93_15_gli_5mt": 17.1,
	&"fso_polonez_caro_mr93_16_gle_5mt": 16.1,
	&"fso_polonez_caro_mr93_16_gli_5mt": 16.2,
	&"fso_polonez_caro_mr93_20_gle_ford_5mt": 13.4,
	&"fso_polonez_caro_mr93_19_gld_5mt": 19.6,
}
const PERFORMANCE_TOLERANCE_SECONDS: float = 0.5
const SIMULATION_STEP: float = 1.0 / 120.0
const MAX_ACCELERATION_TEST_SECONDS: float = 30.0
const POWER_PEAK_UPSHIFT_MULTIPLIER: float = 1.04
const REDLINE_UPSHIFT_MULTIPLIER: float = 0.98
const FINAL_DRIVES: Dictionary = {
	&"fso_polonez_caro_mr93_14_gli_16v_5mt": 4.3,
	&"fso_polonez_caro_mr93_15_gle_5mt": 4.1,
	&"fso_polonez_caro_mr93_15_gli_5mt": 4.1,
	&"fso_polonez_caro_mr93_16_gle_5mt": 3.9,
	&"fso_polonez_caro_mr93_16_gli_5mt": 3.9,
	&"fso_polonez_caro_mr93_20_gle_ford_5mt": 3.64,
	&"fso_polonez_caro_mr93_19_gld_5mt": 3.72,
}

var _checks: int = 0
var _failures: Array[String] = []
var _audio_frames: Dictionary = {}


func _initialize() -> void:
	_test_model_and_catalog()
	if MODEL != null:
		for variant: CarVariantDefinition in MODEL.get_variants():
			_test_variant(variant)
	_test_audio_signatures_are_distinct()
	_finish()


func _test_model_and_catalog() -> void:
	_expect(MODEL != null, "Polonez model resource loads")
	if MODEL == null:
		return
	_expect(MODEL.validate().is_empty(), "Polonez model validates")
	_expect(MODEL.model_id == &"fso_polonez_caro_mr93", "Polonez model has a stable ID")
	_expect(MODEL.get_variant_count() == 7, "Polonez exposes seven factory powertrain variants")
	_expect(
		MODEL.default_variant_id == &"fso_polonez_caro_mr93_14_gli_16v_5mt",
		"Rover K16 is the default Polonez variant"
	)
	var catalog_model: CarModelDefinition = (
		CATALOG.get_model_by_id(MODEL.model_id) if CATALOG != null else null
	)
	_expect(
		catalog_model != null and catalog_model.model_id == MODEL.model_id,
		"main catalog registers the Polonez"
	)


func _test_variant(variant: CarVariantDefinition) -> void:
	_expect(variant != null, "Polonez variant resource is not null")
	if variant == null:
		return
	var id: StringName = variant.variant_id
	_expect(TOP_SPEEDS_KMH.has(id), "%s has a top-speed target" % str(id))
	_expect(FINAL_DRIVES.has(id), "%s has a final-drive target" % str(id))
	_expect(ZERO_TO_100_SECONDS.has(id), "%s has an acceleration target" % str(id))
	_expect(variant.validate().is_empty(), "%s variant validates" % str(id))
	_expect(variant.is_ai_eligible_for_race(), "%s is available to AI" % str(id))
	_expect(variant.drivetrain_label == "RWD", "%s is labelled rear-wheel drive" % str(id))
	var specs: CarSpecs = variant.specs
	_expect(specs != null, "%s provides CarSpecs" % str(id))
	if specs == null:
		return
	_expect(specs.torque_curve != null and specs.torque_curve.validate().is_empty(), "%s has a sampled torque curve" % str(id))
	_expect(specs.engine_audio_profile != null and specs.engine_audio_profile.validate().is_empty(), "%s has a valid audio profile" % str(id))
	_expect(absf(specs.max_forward_speed * 3.6 - float(TOP_SPEEDS_KMH[id])) <= 0.01, "%s stores its catalog top speed" % str(id))
	_expect(absf(specs.final_drive_ratio - float(FINAL_DRIVES[id])) <= 0.0001, "%s stores its selected final drive" % str(id))
	_expect(absf(specs.reverse_gear_ratio - (3.660 if "20_gle_ford" in str(id) else 3.870)) <= 0.0001, "%s stores the selected reverse ratio" % str(id))
	var expected_ratios: Array[float] = FORD_RATIOS if "20_gle_ford" in str(id) else FORWARD_RATIOS
	_expect(_arrays_match(specs.gear_ratios, expected_ratios), "%s stores the selected five-speed ratios" % str(id))
	_test_scene_and_audio(variant)
	var measured_zero_to_100: float = _simulate_zero_to_100(specs)
	_expect(measured_zero_to_100 > 0.0, "%s reaches 100 km/h" % str(id))
	if measured_zero_to_100 > 0.0 and ZERO_TO_100_SECONDS.has(id):
		_expect(
			absf(measured_zero_to_100 - float(ZERO_TO_100_SECONDS[id])) <= PERFORMANCE_TOLERANCE_SECONDS,
			"%s keeps its calibrated 0-100 time: %.2f s" % [str(id), measured_zero_to_100]
		)


func _test_scene_and_audio(variant: CarVariantDefinition) -> void:
	var car := variant.car_scene.instantiate() as PlayerCarController
	_expect(car != null, "%s scene instantiates as PlayerCarController" % str(variant.variant_id))
	if car == null:
		return
	get_root().add_child(car)
	_expect(car.car_specs == variant.specs, "%s scene embeds authoritative specs" % str(variant.variant_id))
	var visual := car.get_node_or_null("VisualRoot") as PolonezCaroMr93VisualController
	_expect(visual != null, "%s uses the Polonez visual controller" % str(variant.variant_id))
	if visual != null:
		_expect(visual.get_registered_wheel_count() == 4, "%s registers four low-detail wheels" % str(variant.variant_id))
	var audio := car.get_node_or_null("EngineAudio") as PolonezEngineAudioSynthesizer
	_expect(audio != null, "%s uses a dedicated Polonez synthesizer" % str(variant.variant_id))
	if audio != null:
		_expect(audio.profile == variant.specs.engine_audio_profile, "%s scene and specs share one audio profile" % str(variant.variant_id))
		_expect(_has_expected_synthesizer_type(variant.variant_id, audio), "%s uses its engine-family synthesizer class" % str(variant.variant_id))
		var test_rpm: float = minf(variant.specs.peak_torque_rpm + 600.0, variant.specs.redline_rpm - 100.0)
		var frames: PackedFloat32Array = audio.generate_test_frames(4096, test_rpm, 0.72, 0.76)
		_expect(_frames_are_finite_and_audible(frames), "%s synthesizer produces finite audible samples" % str(variant.variant_id))
		_audio_frames[variant.variant_id] = frames
	car.free()


func _has_expected_synthesizer_type(id: StringName, audio: PolonezEngineAudioSynthesizer) -> bool:
	match id:
		&"fso_polonez_caro_mr93_14_gli_16v_5mt":
			return audio is PolonezRoverK16EngineAudioSynthesizer
		&"fso_polonez_caro_mr93_15_gle_5mt":
			return audio is PolonezAb15EngineAudioSynthesizer
		&"fso_polonez_caro_mr93_15_gli_5mt":
			return audio is PolonezAeAf15EngineAudioSynthesizer
		&"fso_polonez_caro_mr93_16_gle_5mt":
			return audio is PolonezCb16EngineAudioSynthesizer
		&"fso_polonez_caro_mr93_16_gli_5mt":
			return audio is PolonezCeCf16EngineAudioSynthesizer
		&"fso_polonez_caro_mr93_20_gle_ford_5mt":
			return audio is PolonezFordPintoEngineAudioSynthesizer
		&"fso_polonez_caro_mr93_19_gld_5mt":
			return audio is PolonezXud9EngineAudioSynthesizer
		_:
			return false


func _test_audio_signatures_are_distinct() -> void:
	var ids: Array = _audio_frames.keys()
	for left_index: int in range(ids.size()):
		for right_index: int in range(left_index + 1, ids.size()):
			var left_id: StringName = ids[left_index]
			var right_id: StringName = ids[right_index]
			var left_frames: PackedFloat32Array = _audio_frames[left_id]
			var right_frames: PackedFloat32Array = _audio_frames[right_id]
			var difference: float = _mean_absolute_difference(left_frames, right_frames)
			_expect(
				difference > 0.0005,
				"%s and %s retain distinct procedural signatures" % [str(left_id), str(right_id)]
			)


func _simulate_zero_to_100(specs: CarSpecs) -> float:
	var config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(specs)
	if config == null:
		return -1.0
	var state := CarRuntimeState.new()
	var controller := CarPowertrainController.new()
	controller.configure(config)
	state.reset_drive_state(config.idle_rpm)
	controller.reset(state)
	var elapsed: float = 0.0
	while elapsed < MAX_ACCELERATION_TEST_SECONDS:
		state.ground_contact_count = GroundContactModel.PROBE_COUNT
		state.surface_grip_multiplier = 1.0
		state.tire_slip_intensity = 0.0
		state.set_drive_input_snapshot(1.0, 0.0)
		var request_upshift: bool = false
		if (
			config.is_manual_transmission()
			and state.shift_timer <= 0.0
			and state.current_gear < config.gear_ratios.size()
		):
			var upshift_rpm: float = minf(
				config.redline_rpm * REDLINE_UPSHIFT_MULTIPLIER,
				config.power_peak_rpm * POWER_PEAK_UPSHIFT_MULTIPLIER
			)
			request_upshift = state.engine_rpm >= upshift_rpm
		controller.update(
			state,
			1.0,
			0.0,
			false,
			request_upshift,
			false,
			SIMULATION_STEP
		)
		elapsed += SIMULATION_STEP
		if state.forward_speed >= 100.0 / 3.6:
			return elapsed
	return -1.0


func _arrays_match(left: Array[float], right: Array[float]) -> bool:
	if left.size() != right.size():
		return false
	for index: int in left.size():
		if absf(left[index] - right[index]) > 0.0001:
			return false
	return true


func _frames_are_finite_and_audible(frames: PackedFloat32Array) -> bool:
	if frames.is_empty():
		return false
	var peak: float = 0.0
	for sample: float in frames:
		if not is_finite(sample):
			return false
		peak = maxf(peak, absf(sample))
	return peak > 0.02


func _mean_absolute_difference(
	left: PackedFloat32Array,
	right: PackedFloat32Array
) -> float:
	var count: int = mini(left.size(), right.size())
	if count <= 0:
		return 0.0
	var total: float = 0.0
	for index: int in count:
		total += absf(left[index] - right[index])
	return total / float(count)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[POLONEZ_MR93_CONTENT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[POLONEZ_MR93_CONTENT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[POLONEZ_MR93_CONTENT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[POLONEZ_MR93_CONTENT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[POLONEZ_MR93_CONTENT_TEST] - %s" % failure_message)
	quit(1)
