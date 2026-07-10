extends Node

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_manual_shift_requests_and_timer()
	_test_manual_drive_blocking_and_gears()
	_test_automatic_reverse_and_drive_selection()
	_test_automatic_direction_interlock()
	_test_automatic_upshift_request_and_torque_cut()
	_test_airborne_traction_is_disabled()
	_test_fallback_drive_brake_and_reverse()
	_finish()


func _test_manual_shift_requests_and_timer() -> void:
	var config: CarDriveConfig = _build_manual_config()
	var state: CarRuntimeState = _build_state(config)
	var powertrain: CarPowertrainController = _build_powertrain(config, state)

	powertrain.update(state, 0.0, 0.0, false, true, false, 0.0)
	_expect(state.current_gear == 2, "manual gear-up moves from first to second gear")
	_expect(is_equal_approx(state.shift_timer, config.shift_delay), "manual gear-up applies manual shift delay")
	_expect(powertrain.get_gear_text(state) == "2", "manual gear text reports second gear")

	powertrain.update(state, 0.0, 0.0, false, false, false, 0.10)
	_expect(is_equal_approx(state.shift_timer, config.shift_delay - 0.10), "manual shift timer decays with delta")

	powertrain.update(state, 0.0, 0.0, false, false, true, 0.0)
	_expect(state.current_gear == 1, "manual gear-down moves from second to first gear")


func _test_manual_drive_blocking_and_gears() -> void:
	var config: CarDriveConfig = _build_manual_config()
	var state: CarRuntimeState = _build_state(config)
	var powertrain: CarPowertrainController = _build_powertrain(config, state)

	state.current_gear = 0
	powertrain.update(state, 1.0, 0.0, false, false, false, 0.20)
	_expect(is_equal_approx(state.forward_speed, 0.0), "manual neutral does not drive the car")
	_expect(powertrain.get_gear_text(state) == "N", "manual gear text reports neutral")

	state.current_gear = 1
	state.shift_timer = config.shift_delay
	powertrain.update(state, 1.0, 0.0, false, false, false, 0.05)
	_expect(is_equal_approx(state.forward_speed, 0.0), "manual drive is blocked while shift timer is active")

	state.current_gear = -1
	state.shift_timer = 0.0
	powertrain.update(state, 1.0, 0.0, false, false, false, 0.20)
	_expect(state.forward_speed < 0.0, "manual reverse gear drives the car backwards with throttle")
	_expect(powertrain.get_gear_text(state) == "R", "manual gear text reports reverse")


func _test_automatic_reverse_and_drive_selection() -> void:
	var config: CarDriveConfig = _build_automatic_config()
	var state: CarRuntimeState = _build_state(config)
	var powertrain: CarPowertrainController = _build_powertrain(config, state)

	powertrain.update(state, 0.0, 1.0, false, false, false, 0.0)
	_expect(state.current_gear == -1, "automatic brake from near stop selects reverse")
	_expect(is_equal_approx(state.forward_speed, 0.0), "automatic direction change does not apply drive before shift delay")
	_expect(is_equal_approx(state.shift_timer, config.automatic_shift_delay), "automatic reverse selection starts shift delay")
	_advance_shift(powertrain, state, 0.0, 1.0)
	_expect(state.forward_speed < 0.0, "automatic reverse applies backwards drive after shift delay")
	_expect(powertrain.get_gear_text(state) == "R", "automatic gear text reports reverse")

	state.forward_speed = 0.0
	state.shift_timer = 0.0
	powertrain.update(state, 1.0, 0.0, false, false, false, 0.0)
	_expect(state.current_gear == 1, "automatic throttle from reverse selects first drive gear")
	_expect(is_equal_approx(state.forward_speed, 0.0), "automatic drive selection waits for shift delay")
	_advance_shift(powertrain, state, 1.0, 0.0)
	_expect(state.forward_speed > 0.0, "automatic first drive gear applies forward drive after shift delay")
	_expect(powertrain.get_gear_text(state) == "D1", "automatic gear text reports first drive gear")


func _test_automatic_direction_interlock() -> void:
	var config: CarDriveConfig = _build_automatic_config()
	var state: CarRuntimeState = _build_state(config)
	var powertrain: CarPowertrainController = _build_powertrain(config, state)

	state.current_gear = 2
	state.forward_speed = 8.0
	state.shift_timer = 0.0
	powertrain.update(state, 0.0, 1.0, false, false, false, 0.10)
	_expect(state.current_gear == 1, "automatic braking performs a safe forward-gear downshift")
	_expect(state.forward_speed > 0.0 and state.forward_speed < 8.0, "automatic reverse request brakes forward motion before selecting reverse")

	state.forward_speed = 0.20
	state.shift_timer = 0.0
	powertrain.update(state, 0.0, 1.0, false, false, false, 0.0)
	_expect(state.current_gear == -1, "automatic selects reverse only near zero forward speed")
	_advance_shift(powertrain, state, 0.0, 1.0)
	_expect(state.forward_speed < 0.0, "automatic begins reverse drive only after stopping and completing the shift")

	state.current_gear = -1
	state.forward_speed = -6.0
	state.shift_timer = 0.0
	powertrain.update(state, 1.0, 0.0, false, false, false, 0.10)
	_expect(state.current_gear == -1, "automatic keeps reverse gear while braking from reverse motion toward drive")
	_expect(state.forward_speed > -6.0 and state.forward_speed <= 0.0, "automatic drive request brakes reverse motion before selecting drive")

	state.forward_speed = -0.20
	state.shift_timer = 0.0
	powertrain.update(state, 1.0, 0.0, false, false, false, 0.0)
	_expect(state.current_gear == 1, "automatic selects first drive gear only near zero reverse speed")
	_advance_shift(powertrain, state, 1.0, 0.0)
	_expect(state.forward_speed > 0.0, "automatic begins forward drive only after stopping and completing the shift")


func _test_automatic_upshift_request_and_torque_cut() -> void:
	var config: CarDriveConfig = _build_automatic_config()
	var state: CarRuntimeState = _build_state(config)
	var powertrain: CarPowertrainController = _build_powertrain(config, state)

	state.current_gear = 1
	state.engine_rpm = config.redline_rpm
	state.forward_speed = 20.0
	powertrain.update(state, 0.0, 0.0, false, false, false, 0.0)
	_expect(state.current_gear == 2, "automatic high RPM requests upshift")
	_expect(is_equal_approx(state.shift_timer, config.automatic_shift_delay), "automatic upshift applies automatic shift delay")
	_expect(powertrain.get_gear_text(state) == "D2", "automatic gear text reports second drive gear")

	var speed_before_shift: float = state.forward_speed
	powertrain.update(state, 0.5, 0.0, false, false, false, 0.10)
	_expect(is_equal_approx(state.forward_speed, speed_before_shift), "automatic shift delay cuts wheel torque")
	_advance_shift(powertrain, state, 0.5, 0.0)
	_expect(state.forward_speed > speed_before_shift, "automatic drive torque resumes after shift delay")


func _test_airborne_traction_is_disabled() -> void:
	var config: CarDriveConfig = _build_fallback_config()
	var state: CarRuntimeState = _build_state(config)
	state.ground_contact_count = 0
	state.forward_speed = 5.0
	var powertrain: CarPowertrainController = _build_powertrain(config, state)

	powertrain.update(state, 1.0, 0.0, false, false, false, 0.10)
	_expect(is_equal_approx(state.forward_speed, 5.0), "airborne throttle cannot accelerate vehicle translation")
	_expect(state.engine_rpm > config.idle_rpm, "airborne engine can still free-rev")

	powertrain.update(state, 0.0, 1.0, false, false, false, 0.10)
	_expect(is_equal_approx(state.forward_speed, 5.0), "airborne service brake cannot change vehicle translation")
	powertrain.update(state, 0.0, 0.0, true, false, false, 0.10)
	_expect(is_equal_approx(state.forward_speed, 5.0), "airborne handbrake cannot change vehicle translation")


func _test_fallback_drive_brake_and_reverse() -> void:
	var config: CarDriveConfig = _build_fallback_config()
	var state: CarRuntimeState = _build_state(config)
	var powertrain: CarPowertrainController = _build_powertrain(config, state)

	powertrain.update(state, 1.0, 0.0, false, false, false, 0.20)
	_expect(state.forward_speed > 0.0, "fallback non-geared drive accelerates forward with throttle")
	_expect(powertrain.get_gear_text(state) == "D", "fallback gear text reports drive while moving forward")

	var forward_speed: float = state.forward_speed
	powertrain.update(state, 0.0, 1.0, false, false, false, 0.10)
	_expect(state.forward_speed < forward_speed, "fallback brake reduces forward speed")

	state.forward_speed = 0.0
	powertrain.update(state, 0.0, 1.0, false, false, false, 0.20)
	_expect(state.forward_speed < 0.0, "fallback brake from stop applies reverse acceleration")
	_expect(powertrain.get_gear_text(state) == "R", "fallback gear text reports reverse while moving backwards")


func _advance_shift(
	powertrain: CarPowertrainController,
	state: CarRuntimeState,
	throttle: float,
	brake: float
) -> void:
	for step: int in range(4):
		powertrain.update(state, throttle, brake, false, false, false, 0.10)


func _build_state(config: CarDriveConfig) -> CarRuntimeState:
	var state: CarRuntimeState = CarRuntimeState.new()
	state.reset_drive_state(config.idle_rpm)
	state.ground_contact_count = 4
	return state


func _build_powertrain(config: CarDriveConfig, state: CarRuntimeState) -> CarPowertrainController:
	var powertrain: CarPowertrainController = CarPowertrainController.new()
	powertrain.configure(config)
	powertrain.reset(state)
	return powertrain


func _build_manual_config() -> CarDriveConfig:
	var config: CarDriveConfig = _build_base_config()
	config.transmission_type = CarSpecs.TransmissionType.MANUAL
	return config


func _build_automatic_config() -> CarDriveConfig:
	var config: CarDriveConfig = _build_base_config()
	config.transmission_type = CarSpecs.TransmissionType.AUTOMATIC
	return config


func _build_fallback_config() -> CarDriveConfig:
	var config: CarDriveConfig = _build_base_config()
	config.transmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE
	return config


func _build_base_config() -> CarDriveConfig:
	var config: CarDriveConfig = CarDriveConfig.new()
	config.gear_ratios = [3.0, 2.0, 1.4]
	config.reverse_gear_ratio = 3.2
	config.final_drive_ratio = 3.5
	config.peak_engine_torque = 420.0
	config.wheel_radius = 0.34
	config.drivetrain_efficiency = 0.85
	config.vehicle_mass = 1200.0
	config.idle_rpm = 900.0
	config.peak_torque_rpm = 4200.0
	config.redline_rpm = 6500.0
	config.rev_limiter_rpm = 6800.0
	config.low_rpm_torque_multiplier = 0.42
	config.mid_rpm_torque_multiplier = 0.82
	config.redline_torque_multiplier = 0.72
	config.engine_force = 30.0
	config.engine_brake_force = 0.0
	config.rpm_response = 8.0
	config.shift_delay = 0.28
	config.automatic_upshift_rpm = 6200.0
	config.automatic_downshift_rpm = 2100.0
	config.automatic_kickdown_throttle = 0.82
	config.automatic_kickdown_rpm = 5200.0
	config.automatic_shift_delay = 0.22
	config.torque_converter_stall_rpm = 2600.0
	config.torque_converter_coupling_rpm = 4200.0
	config.torque_converter_stall_torque_multiplier = 1.65
	config.brake_deceleration = 34.0
	config.reverse_acceleration = 12.0
	config.coast_deceleration = 0.0
	config.handbrake_deceleration = 18.0
	config.max_forward_speed = 30.0
	config.max_reverse_speed = 10.0
	config.drag_coefficient = 0.0
	config.frontal_area = 2.05
	config.air_density = 1.225
	config.rolling_resistance_coefficient = 0.0
	config.sanitize()
	return config


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CAR_POWERTRAIN_TEST][PASS] %s" % message)
		return

	_failures.append(message)
	push_error("[CAR_POWERTRAIN_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CAR_POWERTRAIN_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return

	push_error("[CAR_POWERTRAIN_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CAR_POWERTRAIN_TEST] - %s" % failure_message)
	get_tree().quit(1)
