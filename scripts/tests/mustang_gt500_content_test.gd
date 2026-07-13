extends SceneTree

const MODEL_PATH: String = "res://resources/cars/ford/mustang_shelby_gt500_1967/model.tres"
const CATALOG_PATH: String = "res://resources/cars/catalog.tres"
const MANUAL_SPECS_PATH: String = "res://resources/cars/ford/mustang_shelby_gt500_1967/specs/gt500_428_4mt_specs.tres"
const AUTOMATIC_SPECS_PATH: String = "res://resources/cars/ford/mustang_shelby_gt500_1967/specs/gt500_428_3at_specs.tres"
const MANUAL_SCENE_PATH: String = "res://scenes/cars/mustang_shelby_gt500_1967_4mt.tscn"
const AUTOMATIC_SCENE_PATH: String = "res://scenes/cars/mustang_shelby_gt500_1967_3at.tscn"

const SIMULATION_STEP: float = 1.0 / 120.0
const MAX_SIMULATION_SECONDS: float = 80.0
const SIXTY_MPH_MPS: float = 26.8224
const QUARTER_MILE_METERS: float = 402.336
const MPS_TO_MPH: float = 2.23693629

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_catalog_and_scenes()
	_test_powertrain_specs()
	_test_engine_curve()
	_test_performance_targets()
	_finish()


func _test_catalog_and_scenes() -> void:
	var model: CarModelDefinition = load(MODEL_PATH) as CarModelDefinition
	_expect(model != null, "the 1967 Shelby model resource loads")
	if model != null:
		_expect(model.model_id == &"ford_mustang_shelby_gt500_1967", "the model keeps its stable ID")
		_expect(model.default_variant_id == &"ford_mustang_shelby_gt500_1967_4mt", "the four-speed is the default variant")
		_expect(model.variants.size() == 2, "the model exposes exactly the two production transmissions")
		_expect(model.validate().is_empty(), "the Shelby model definition validates")

	var catalog: CarCatalog = load(CATALOG_PATH) as CarCatalog
	_expect(catalog != null, "the complete car catalog loads")
	if catalog != null:
		_expect(catalog.validate().is_empty(), "the complete catalog validates with the Shelby variants")
		var manual_variant: CarVariantDefinition = catalog.get_variant_by_id(&"ford_mustang_shelby_gt500_1967_4mt")
		var automatic_variant: CarVariantDefinition = catalog.get_variant_by_id(&"ford_mustang_shelby_gt500_1967_3at")
		_expect(manual_variant != null, "the catalog resolves the four-speed variant")
		_expect(automatic_variant != null, "the catalog resolves the C6 variant")
		_expect(manual_variant == null or not manual_variant.ai_eligible, "the four-speed is withheld from AI until a dedicated AI scene exists")
		_expect(automatic_variant == null or not automatic_variant.ai_eligible, "the C6 is withheld from AI until a dedicated AI scene exists")

	_test_player_scene(MANUAL_SCENE_PATH, "four-speed")
	_test_player_scene(AUTOMATIC_SCENE_PATH, "C6 automatic")


func _test_player_scene(scene_path: String, label: String) -> void:
	var packed: PackedScene = load(scene_path) as PackedScene
	_expect(packed != null, "%s player scene loads" % label)
	if packed == null:
		return
	var car: PlayerCarController = packed.instantiate() as PlayerCarController
	_expect(car != null, "%s scene instantiates as PlayerCarController" % label)
	if car == null:
		return
	_expect(car.car_specs != null and car.car_specs.validate().is_empty(), "%s scene owns valid specs" % label)
	_expect(car.get_node_or_null("VisualRoot") != null, "%s scene contains the imported visual wrapper" % label)
	var audio: ProfiledEngineAudioSynthesizer = car.get_node_or_null("EngineAudio") as ProfiledEngineAudioSynthesizer
	_expect(audio != null, "%s scene uses live profiled engine synthesis" % label)
	_expect(audio == null or audio.cylinders == 8, "%s scene synthesizes an eight-cylinder firing order" % label)
	car.free()


func _test_powertrain_specs() -> void:
	var manual: CarSpecs = load(MANUAL_SPECS_PATH) as CarSpecs
	var automatic: CarSpecs = load(AUTOMATIC_SPECS_PATH) as CarSpecs
	_expect(manual != null and manual.validate().is_empty(), "the four-speed specs validate")
	_expect(automatic != null and automatic.validate().is_empty(), "the C6 specs validate")
	if manual == null or automatic == null:
		return

	_expect(manual.is_manual_transmission(), "the four-speed variant uses the manual transmission model")
	_expect(manual.gear_ratios == [2.32, 1.69, 1.29, 1.0], "the manual uses the close-ratio Toploader set")
	_expect(is_equal_approx(manual.reverse_gear_ratio, 2.32), "the close-ratio Toploader reverse ratio is represented")
	_expect(automatic.is_automatic_transmission(), "the C6 variant uses the automatic transmission model")
	_expect(automatic.gear_ratios == [2.46, 1.46, 1.0], "the automatic uses the three C6 forward ratios")
	_expect(is_equal_approx(automatic.reverse_gear_ratio, 2.18), "the C6 reverse ratio is represented")
	_expect(is_equal_approx(manual.final_drive_ratio, 3.5), "the manual uses the documented representative 3.50 axle")
	_expect(is_equal_approx(automatic.final_drive_ratio, 3.5), "the automatic uses the documented 3.50 axle")
	_expect(manual.torque_curve == automatic.torque_curve, "both transmissions share one authoritative engine curve")
	_expect(is_equal_approx(manual.peak_engine_torque, 569.4435), "420 lb-ft is converted to SI without rounding drift")
	_expect(manual.max_drive_acceleration > automatic.max_drive_acceleration, "the C6 launch calibration preserves its slower period performance")
	_expect(CarDriveConfigBuilder.get_unmapped_specs_properties(manual).is_empty(), "all Shelby specs map into the runtime configuration")


func _test_engine_curve() -> void:
	var specs: CarSpecs = load(MANUAL_SPECS_PATH) as CarSpecs
	if specs == null or specs.torque_curve == null:
		_expect(false, "the sampled 428 FE torque curve is available")
		return
	_expect(specs.torque_curve.validate().is_empty(), "the sampled 428 FE torque curve validates")
	var engine: EngineModel = _build_engine_model(specs)

	engine.set_rpm(3200.0)
	var peak_torque_nm: float = specs.peak_engine_torque * engine.get_torque_multiplier()
	_expect(absf(peak_torque_nm - 569.4435) < 0.1, "the curve reaches exactly 420 lb-ft at 3200 RPM")

	engine.set_rpm(5400.0)
	var power_torque_nm: float = specs.peak_engine_torque * engine.get_torque_multiplier()
	var power_bhp: float = _power_bhp(power_torque_nm, 5400.0)
	_expect(absf(power_bhp - 355.0) < 0.25, "the curve produces the advertised 355 bhp at 5400 RPM")

	engine.set_rpm(2500.0)
	var low_speed_torque: float = specs.peak_engine_torque * engine.get_torque_multiplier()
	_expect(low_speed_torque > 550.0, "the reconstructed curve preserves the documented broad low-speed big-block torque")
	engine.set_rpm(5800.0)
	_expect(engine.get_torque_multiplier() < specs.torque_curve.sample(5400.0), "torque falls materially after the power peak")
	engine.set_rpm(6000.0)
	_expect(engine.get_torque_multiplier() < specs.torque_curve.sample(5800.0), "the curve continues falling toward the limiter")


func _test_performance_targets() -> void:
	var manual_specs: CarSpecs = load(MANUAL_SPECS_PATH) as CarSpecs
	var automatic_specs: CarSpecs = load(AUTOMATIC_SPECS_PATH) as CarSpecs
	if manual_specs == null or automatic_specs == null:
		_expect(false, "both powertrain configurations are available for performance simulation")
		return

	var manual_result: Dictionary = _simulate_straight_line(manual_specs, true)
	var automatic_result: Dictionary = _simulate_straight_line(automatic_specs, false)
	print("[MUSTANG_GT500_PERFORMANCE] manual=%s" % JSON.stringify(manual_result))
	print("[MUSTANG_GT500_PERFORMANCE] automatic=%s" % JSON.stringify(automatic_result))

	_expect(_in_range(float(manual_result["zero_to_sixty_s"]), 5.8, 7.8), "the four-speed 0-60 mph result remains inside the period-reference band")
	_expect(_in_range(float(manual_result["quarter_mile_s"]), 14.0, 16.5), "the four-speed quarter mile remains inside the period-reference band")
	_expect(_in_range(float(manual_result["quarter_trap_mph"]), 90.0, 108.0), "the four-speed quarter-mile trap speed remains plausible")
	_expect(_in_range(float(manual_result["top_speed_kmh"]), 190.0, 207.0), "the four-speed reaches the documented approximate top-speed region")

	_expect(_in_range(float(automatic_result["zero_to_sixty_s"]), 6.2, 8.5), "the C6 0-60 mph result remains inside the period-reference band")
	_expect(_in_range(float(automatic_result["quarter_mile_s"]), 14.4, 17.2), "the C6 quarter mile remains inside the period-reference band")
	_expect(_in_range(float(automatic_result["quarter_trap_mph"]), 87.0, 108.0), "the C6 quarter-mile trap speed remains plausible")
	_expect(_in_range(float(automatic_result["top_speed_kmh"]), 188.0, 207.0), "the C6 reaches the documented approximate top-speed region")
	_expect(float(manual_result["zero_to_sixty_s"]) <= float(automatic_result["zero_to_sixty_s"]) + 0.4, "the manual is not materially slower than the C6 in the calibrated period configuration")


func _simulate_straight_line(specs: CarSpecs, request_manual_shifts: bool) -> Dictionary:
	var config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(specs)
	var state: CarRuntimeState = CarRuntimeState.new()
	state.reset_drive_state(config.idle_rpm)
	state.ground_contact_count = GroundContactModel.PROBE_COUNT
	state.surface_grip_multiplier = 1.0
	var powertrain: CarPowertrainController = CarPowertrainController.new()
	powertrain.configure(config)
	powertrain.reset(state)

	var elapsed: float = 0.0
	var distance: float = 0.0
	var zero_to_sixty: float = -1.0
	var quarter_time: float = -1.0
	var quarter_trap_mph: float = -1.0
	var maximum_speed: float = 0.0

	while elapsed < MAX_SIMULATION_SECONDS:
		var previous_speed: float = state.forward_speed
		var shift_up: bool = false
		if request_manual_shifts:
			shift_up = (
				state.current_gear > 0
				and state.current_gear < config.gear_ratios.size()
				and state.shift_timer <= 0.0
				and state.engine_rpm >= 5700.0
			)
		state.brake_input = 0.0
		powertrain.update(state, 1.0, 0.0, false, shift_up, false, SIMULATION_STEP)
		elapsed += SIMULATION_STEP
		distance += maxf((previous_speed + state.forward_speed) * 0.5, 0.0) * SIMULATION_STEP
		maximum_speed = maxf(maximum_speed, state.forward_speed)
		if zero_to_sixty < 0.0 and state.forward_speed >= SIXTY_MPH_MPS:
			zero_to_sixty = elapsed
		if quarter_time < 0.0 and distance >= QUARTER_MILE_METERS:
			quarter_time = elapsed
			quarter_trap_mph = state.forward_speed * MPS_TO_MPH

	return {
		"zero_to_sixty_s": zero_to_sixty,
		"quarter_mile_s": quarter_time,
		"quarter_trap_mph": quarter_trap_mph,
		"top_speed_kmh": maximum_speed * 3.6,
		"distance_m": distance,
		"final_gear": state.current_gear,
		"final_rpm": state.engine_rpm,
	}


func _build_engine_model(specs: CarSpecs) -> EngineModel:
	var engine: EngineModel = EngineModel.new()
	engine.configure(
		specs.idle_rpm,
		specs.peak_torque_rpm,
		specs.redline_rpm,
		specs.rev_limiter_rpm,
		specs.low_rpm_torque_multiplier,
		specs.mid_rpm_torque_multiplier,
		specs.redline_torque_multiplier,
		specs.rpm_response,
		specs.torque_curve
	)
	return engine


func _power_bhp(torque_nm: float, rpm: float) -> float:
	return torque_nm * rpm / 7127.0


func _in_range(value: float, minimum: float, maximum: float) -> bool:
	return is_finite(value) and value >= minimum and value <= maximum


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[MUSTANG_GT500_CONTENT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[MUSTANG_GT500_CONTENT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[MUSTANG_GT500_CONTENT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[MUSTANG_GT500_CONTENT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[MUSTANG_GT500_CONTENT_TEST] - %s" % failure_message)
	quit(1)
