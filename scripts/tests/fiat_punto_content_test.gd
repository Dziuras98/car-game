extends SceneTree

const MODEL: CarModelDefinition = preload("res://resources/cars/fiat/punto_176_1995/model.tres")
const CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const TARGETS: Dictionary = {
	&"fiat_punto_176_1995_55_5mt": {"zero_to_100": 17.0, "top_speed": 150.0},
	&"fiat_punto_176_1995_55_6mt": {"zero_to_100": 16.0, "top_speed": 150.0},
	&"fiat_punto_176_1995_60_a7_5mt": {"zero_to_100": 14.5, "top_speed": 160.0},
	&"fiat_punto_176_1995_60_a7_ecvt": {"zero_to_100": 17.0, "top_speed": 150.0},
	&"fiat_punto_176_1995_75_5mt": {"zero_to_100": 12.0, "top_speed": 170.0},
	&"fiat_punto_176_1995_90_5mt": {"zero_to_100": 11.0, "top_speed": 178.0},
	&"fiat_punto_176_1995_gt_5mt": {"zero_to_100": 8.0, "top_speed": 200.0},
	&"fiat_punto_176_1995_d_5mt": {"zero_to_100": 20.0, "top_speed": 150.0},
	&"fiat_punto_176_1995_td70_5mt": {"zero_to_100": 14.8, "top_speed": 163.0},
}

const PERFORMANCE_TOLERANCE_SECONDS: float = 1.5
const SIMULATION_STEP: float = 1.0 / 120.0
const MAX_ACCELERATION_TEST_SECONDS: float = 30.0
const MANUAL_UPSHIFT_RPM_RATIO: float = 0.86

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_model_and_catalog()
	if MODEL != null:
		for variant: CarVariantDefinition in MODEL.get_variants():
			_test_variant(variant)
	_finish()


func _test_model_and_catalog() -> void:
	_expect(MODEL != null, "Fiat Punto model resource loads")
	if MODEL == null:
		return
	_expect(MODEL.validate().is_empty(), "Fiat Punto model validates")
	_expect(MODEL.model_id == &"fiat_punto_176_1995", "Fiat Punto model has stable ID")
	_expect(MODEL.get_variant_count() == 9, "Fiat Punto exposes nine selected variants")
	_expect(MODEL.default_variant_id == &"fiat_punto_176_1995_gt_5mt", "Punto GT is the default variant")
	_expect(CATALOG != null and CATALOG.get_model_by_id(MODEL.model_id) == MODEL, "main catalog registers Fiat Punto")


func _test_variant(variant: CarVariantDefinition) -> void:
	_expect(variant != null, "Punto variant resource is not null")
	if variant == null:
		return
	var id: StringName = variant.variant_id
	_expect(TARGETS.has(id), "%s has a performance target" % str(id))
	_expect(variant.validate().is_empty(), "%s variant validates" % str(id))
	_expect(variant.is_ai_eligible_for_race(), "%s is available to AI" % str(id))
	_expect(variant.specs != null and variant.specs.torque_curve != null, "%s has a sampled engine curve" % str(id))
	if variant.specs == null or not TARGETS.has(id):
		return
	var target: Dictionary = TARGETS[id]
	var top_speed_kmh: float = variant.specs.max_forward_speed * 3.6
	_expect(absf(top_speed_kmh - float(target["top_speed"])) <= 0.05, "%s stores the catalog top speed" % str(id))
	_test_scene_and_audio(variant)
	var measured_zero_to_100: float = _simulate_zero_to_100(variant.specs)
	_expect(measured_zero_to_100 > 0.0, "%s reaches 100 km/h in deterministic simulation" % str(id))
	_expect(
		absf(measured_zero_to_100 - float(target["zero_to_100"])) <= PERFORMANCE_TOLERANCE_SECONDS,
		"%s matches its 0-100 km/h target: %.2f s versus %.2f s"
		% [str(id), measured_zero_to_100, float(target["zero_to_100"])]
	)


func _test_scene_and_audio(variant: CarVariantDefinition) -> void:
	var car := variant.car_scene.instantiate() as PlayerCarController
	_expect(car != null, "%s scene instantiates as PlayerCarController" % str(variant.variant_id))
	if car == null:
		return
	_expect(car.car_specs == variant.specs, "%s scene embeds authoritative specs" % str(variant.variant_id))
	var audio := car.get_node_or_null("EngineAudio") as FiatPuntoEngineAudioSynthesizer
	_expect(audio != null, "%s uses the dedicated Fiat four-cylinder synthesizer" % str(variant.variant_id))
	if audio != null:
		_expect(audio.profile != null and audio.profile.validate().is_empty(), "%s has a valid engine-specific audio profile" % str(variant.variant_id))
		if audio.profile != null:
			var id_text: String = str(variant.variant_id)
			if id_text.ends_with("_d_5mt"):
				_expect(audio.profile.diesel_combustion > 0.8, "naturally aspirated diesel uses compression-ignition synthesis")
				_expect(audio.profile.turbo_whistle == 0.0, "naturally aspirated diesel has no turbo layer")
			elif "td70" in id_text:
				_expect(audio.profile.diesel_combustion > 0.8, "TD uses compression-ignition synthesis")
				_expect(audio.profile.turbo_whistle > 0.2, "TD includes a diesel turbo whistle")
			elif "_gt_" in id_text:
				_expect(audio.profile.turbo_whistle > 0.4, "GT includes a prominent turbo whistle")
				_expect(audio.profile.turbo_blowoff > 0.2, "GT includes throttle-lift turbo release")
			else:
				_expect(audio.profile.diesel_combustion == 0.0, "%s remains spark-ignition audio" % id_text)
	car.free()


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
			var upshift_rpm: float = lerpf(config.idle_rpm, config.redline_rpm, MANUAL_UPSHIFT_RPM_RATIO)
			request_upshift = state.engine_rpm >= upshift_rpm
		controller.update(state, 1.0, 0.0, false, request_upshift, false, SIMULATION_STEP)
		elapsed += SIMULATION_STEP
		if state.forward_speed >= 100.0 / 3.6:
			return elapsed
	return -1.0


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[FIAT_PUNTO_CONTENT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[FIAT_PUNTO_CONTENT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[FIAT_PUNTO_CONTENT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[FIAT_PUNTO_CONTENT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[FIAT_PUNTO_CONTENT_TEST] - %s" % failure_message)
	quit(1)
