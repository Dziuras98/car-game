extends Node

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_engine_free_rev_range()
	_test_brake_priority_for_contradictory_input()
	_test_large_delta_clamp()
	_test_substep_consistency()
	_finish()


func _test_engine_free_rev_range() -> void:
	var engine: EngineModel = EngineModel.new()
	engine.configure(900.0, 4200.0, 6500.0, 6800.0, 0.4, 0.8, 0.7, 8.0)
	for step: int in range(240):
		engine.update(1.0, 900.0, 1.0 / 120.0)
	_expect(engine.get_rpm() > 6500.0, "full throttle free-rev reaches the configured redline range")
	_expect(engine.get_rpm() <= 6800.0, "free-rev remains bounded by the configured limiter")


func _test_brake_priority_for_contradictory_input() -> void:
	var config: CarDriveConfig = _build_fallback_config()
	var state: CarRuntimeState = _build_state(config)
	state.forward_speed = 8.0
	var powertrain: CarPowertrainController = _build_powertrain(config, state)
	powertrain.update(state, 1.0, 1.0, false, false, false, 0.1)
	_expect(state.forward_speed < 8.0, "service brake wins over simultaneous throttle input")
	_expect(state.forward_speed >= 0.0, "contradictory input cannot instantaneously reverse forward motion")


func _test_large_delta_clamp() -> void:
	var config: CarDriveConfig = _build_fallback_config()
	var clamped_state: CarRuntimeState = _build_state(config)
	var reference_state: CarRuntimeState = _build_state(config)
	var clamped_powertrain: CarPowertrainController = _build_powertrain(config, clamped_state)
	var reference_powertrain: CarPowertrainController = _build_powertrain(config, reference_state)
	clamped_powertrain.update(clamped_state, 1.0, 0.0, false, false, false, 5.0)
	reference_powertrain.update(reference_state, 1.0, 0.0, false, false, false, CarPowertrainController.MAX_FRAME_DELTA)
	_expect(
		is_equal_approx(clamped_state.forward_speed, reference_state.forward_speed),
		"large frame delta is clamped to the documented simulation budget"
	)


func _test_substep_consistency() -> void:
	var config: CarDriveConfig = _build_fallback_config()
	var coarse_state: CarRuntimeState = _build_state(config)
	var fine_state: CarRuntimeState = _build_state(config)
	var coarse_powertrain: CarPowertrainController = _build_powertrain(config, coarse_state)
	var fine_powertrain: CarPowertrainController = _build_powertrain(config, fine_state)
	coarse_powertrain.update(coarse_state, 0.7, 0.0, false, false, false, 0.1)
	for step: int in range(10):
		fine_powertrain.update(fine_state, 0.7, 0.0, false, false, false, 0.01)
	_expect(
		absf(coarse_state.forward_speed - fine_state.forward_speed) < 0.05,
		"internal substeps keep coarse and fine frame integration close"
	)
	_expect(
		absf(coarse_state.engine_rpm - fine_state.engine_rpm) < 20.0,
		"internal substeps keep coarse and fine RPM integration close"
	)


func _build_fallback_config() -> CarDriveConfig:
	var config: CarDriveConfig = CarDriveConfig.new()
	config.transmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE
	config.transmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE
	config.engine_force = 30.0
	config.brake_deceleration = 34.0
	config.reverse_acceleration = 12.0
	config.coast_deceleration = 0.0
	config.engine_brake_force = 0.0
	config.handbrake_deceleration = 18.0
	config.max_forward_speed = 30.0
	config.max_reverse_speed = 10.0
	config.vehicle_mass = 1200.0
	config.drag_coefficient = 0.0
	config.frontal_area = 2.0
	config.air_density = 1.225
	config.rolling_resistance_coefficient = 0.0
	config.idle_rpm = 900.0
	config.peak_torque_rpm = 4200.0
	config.redline_rpm = 6500.0
	config.rev_limiter_rpm = 6800.0
	config.rpm_response = 8.0
	config.sanitize()
	return config


func _build_state(config: CarDriveConfig) -> CarRuntimeState:
	var state: CarRuntimeState = CarRuntimeState.new()
	state.reset_drive_state(config.idle_rpm)
	return state


func _build_powertrain(config: CarDriveConfig, state: CarRuntimeState) -> CarPowertrainController:
	var controller: CarPowertrainController = CarPowertrainController.new()
	controller.configure(config)
	controller.reset(state)
	return controller


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[POWERTRAIN_STABILITY_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[POWERTRAIN_STABILITY_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[POWERTRAIN_STABILITY_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[POWERTRAIN_STABILITY_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[POWERTRAIN_STABILITY_TEST] - %s" % failure_message)
	get_tree().quit(1)
