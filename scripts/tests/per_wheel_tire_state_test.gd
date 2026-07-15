extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_runtime_initializes_four_wheels()
	_test_contact_aggregates_are_derived_from_wheels()
	_test_legacy_contact_bridge()
	_test_mixed_surface_longitudinal_distribution()
	_test_front_and_rear_lateral_states()
	_finish()


func _test_runtime_initializes_four_wheels() -> void:
	var state: CarRuntimeState = CarRuntimeState.new()
	_expect(
		state.wheel_states.size() == WheelTireState.WHEEL_COUNT,
		"runtime creates exactly four wheel tire states"
	)
	for wheel_index: int in range(WheelTireState.WHEEL_COUNT):
		var wheel: WheelTireState = state.get_wheel_state(wheel_index)
		_expect(wheel != null, "wheel state %d exists" % wheel_index)
		if wheel != null:
			_expect(wheel.wheel_index == wheel_index, "wheel state %d keeps its stable position index" % wheel_index)


func _test_contact_aggregates_are_derived_from_wheels() -> void:
	var state: CarRuntimeState = CarRuntimeState.new()
	state.wheel_states[WheelTireState.Position.FRONT_LEFT].set_contact(1.0, Vector3.UP, 4.0)
	state.wheel_states[WheelTireState.Position.REAR_RIGHT].set_contact(0.5, Vector3.UP, 6.0)
	state.update_contact_aggregates()

	_expect(state.ground_contact_count == 2, "aggregate contact count is derived from contacted wheels")
	_expect(is_equal_approx(state.surface_grip_multiplier, 0.75), "aggregate surface grip is the contacted-wheel average")
	_expect(is_equal_approx(state.suspension_acceleration, 10.0), "aggregate suspension support is the wheel sum")
	_expect(state.ground_normal.is_equal_approx(Vector3.UP), "aggregate ground normal is derived from wheel normals")


func _test_legacy_contact_bridge() -> void:
	var state: CarRuntimeState = CarRuntimeState.new()
	state.ground_contact_count = 2
	state.surface_grip_multiplier = 0.6
	state.lateral_slip_intensity = 0.4
	state.synchronize_wheel_contacts_from_aggregate()

	_expect(state.wheel_states[0].has_contact and state.wheel_states[1].has_contact, "legacy aggregate contact seeds the first two wheel states")
	_expect(not state.wheel_states[2].has_contact and not state.wheel_states[3].has_contact, "legacy aggregate contact leaves remaining wheels airborne")
	_expect(is_equal_approx(state.wheel_states[0].surface_grip_multiplier, 0.6), "legacy aggregate surface grip is copied into seeded wheels")
	_expect(is_equal_approx(state.wheel_states[1].lateral_slip_intensity, 0.4), "legacy aggregate lateral slip is copied into seeded wheels")


func _test_mixed_surface_longitudinal_distribution() -> void:
	var config: CarDriveConfig = _build_config()
	config.drive_layout = CarSpecs.DriveLayout.ALL_WHEEL_DRIVE
	config.awd_front_torque_fraction = 0.5
	config.sanitize()
	var state: CarRuntimeState = _build_contact_state(config)
	state.wheel_states[WheelTireState.Position.FRONT_LEFT].surface_grip_multiplier = 1.0
	state.wheel_states[WheelTireState.Position.FRONT_RIGHT].surface_grip_multiplier = 0.5
	state.wheel_states[WheelTireState.Position.REAR_LEFT].surface_grip_multiplier = 1.0
	state.wheel_states[WheelTireState.Position.REAR_RIGHT].surface_grip_multiplier = 0.5
	state.update_contact_aggregates()

	var powertrain: CarPowertrainController = CarPowertrainController.new()
	powertrain.configure(config)
	powertrain.reset(state)
	powertrain.update(state, 1.0, 0.0, false, false, false, 0.1)

	var front_left: WheelTireState = state.wheel_states[WheelTireState.Position.FRONT_LEFT]
	var front_right: WheelTireState = state.wheel_states[WheelTireState.Position.FRONT_RIGHT]
	var rear_left: WheelTireState = state.wheel_states[WheelTireState.Position.REAR_LEFT]
	var rear_right: WheelTireState = state.wheel_states[WheelTireState.Position.REAR_RIGHT]
	_expect(front_left.applied_longitudinal_acceleration > front_right.applied_longitudinal_acceleration, "higher grip produces more actual longitudinal force between equally loaded wheels on one axle")
	_expect(is_equal_approx(front_left.requested_longitudinal_acceleration, front_right.requested_longitudinal_acceleration), "equal left-right torque split gives equal demand before tire response")
	_expect(front_left.longitudinal_slip_ratio > 0.0, "high-grip front wheel records positive drive slip")
	_expect(front_right.longitudinal_slip_ratio > 0.0, "low-grip front wheel records positive drive slip")
	_expect(is_equal_approx(state.surface_grip_multiplier, 0.75), "legacy surface telemetry remains the average of wheel states")
	var strongest_slip: float = maxf(
		maxf(front_left.longitudinal_slip_ratio, front_right.longitudinal_slip_ratio),
		maxf(rear_left.longitudinal_slip_ratio, rear_right.longitudinal_slip_ratio)
	)
	_expect(
		is_equal_approx(state.longitudinal_slip_ratio, strongest_slip),
		"aggregate longitudinal slip remains available for existing telemetry"
	)

	state.wheel_states[WheelTireState.Position.REAR_RIGHT].reset_contact()
	state.update_contact_aggregates()
	powertrain.update(state, 1.0, 0.0, false, false, false, 0.1)
	_expect(state.ground_contact_count == 3, "losing one wheel contact updates aggregate contact count")
	_expect(
		is_zero_approx(state.wheel_states[WheelTireState.Position.REAR_RIGHT].applied_longitudinal_acceleration),
		"airborne wheel contributes no longitudinal acceleration"
	)


func _test_front_and_rear_lateral_states() -> void:
	var config: CarDriveConfig = _build_config()
	var state: CarRuntimeState = _build_contact_state(config)
	state.forward_speed = 20.0
	state.lateral_speed = 2.0
	var chassis: CarChassisController = CarChassisController.new()
	chassis.configure(config)
	chassis.update_tire_dynamics(state, 1.0, false, 0.0)

	var front_left: WheelTireState = state.wheel_states[WheelTireState.Position.FRONT_LEFT]
	var front_right: WheelTireState = state.wheel_states[WheelTireState.Position.FRONT_RIGHT]
	var rear_left: WheelTireState = state.wheel_states[WheelTireState.Position.REAR_LEFT]
	_expect(front_left.steering_angle_rad > 0.0, "steering rotates the front-left wheel state")
	_expect(front_right.steering_angle_rad > front_left.steering_angle_rad, "Ackermann geometry gives the inner right wheel a larger angle")
	_expect(is_zero_approx(rear_left.steering_angle_rad), "rear wheel states remain unsteered")
	_expect(front_left.lateral_slip_intensity > rear_left.lateral_slip_intensity, "front steering produces a distinct front-wheel slip angle")
	_expect(absf(front_left.lateral_force_n) > 0.0, "front wheel slip produces a physical lateral tire force")
	_expect(is_equal_approx(state.lateral_slip_intensity, maxf(front_left.lateral_slip_intensity, front_right.lateral_slip_intensity)), "aggregate lateral slip exposes the strongest wheel state")

	var normal_state: CarRuntimeState = _build_contact_state(config)
	normal_state.forward_speed = 15.0
	normal_state.lateral_speed = 2.0
	chassis.update_tire_dynamics(normal_state, 0.0, false, 0.0)
	var handbrake_state: CarRuntimeState = _build_contact_state(config)
	handbrake_state.forward_speed = 15.0
	handbrake_state.lateral_speed = 2.0
	chassis.update_tire_dynamics(handbrake_state, 0.0, true, 0.0)
	_expect(
		absf(handbrake_state.wheel_states[WheelTireState.Position.REAR_LEFT].lateral_force_n)
		< absf(normal_state.wheel_states[WheelTireState.Position.REAR_LEFT].lateral_force_n),
		"handbrake reduces rear-wheel lateral force rather than adding artificial yaw"
	)


func _build_contact_state(config: CarDriveConfig) -> CarRuntimeState:
	var state: CarRuntimeState = CarRuntimeState.new()
	state.reset_drive_state(config.idle_rpm)
	for wheel: WheelTireState in state.wheel_states:
		wheel.set_contact(1.0, Vector3.UP, 4.0)
	state.update_contact_aggregates()
	return state


func _build_config() -> CarDriveConfig:
	var config: CarDriveConfig = CarDriveConfig.new()
	config.transmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE
	config.engine_force = 40.0
	config.brake_deceleration = 20.0
	config.reverse_acceleration = 10.0
	config.coast_deceleration = 0.0
	config.engine_brake_force = 0.0
	config.handbrake_deceleration = 18.0
	config.max_forward_speed = 50.0
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
	config.low_rpm_torque_multiplier = 1.0
	config.mid_rpm_torque_multiplier = 1.0
	config.redline_torque_multiplier = 1.0
	config.front_lateral_grip = 10.0
	config.rear_lateral_grip = 10.0
	config.front_tire_width_m = 0.225
	config.rear_tire_width_m = 0.245
	config.longitudinal_grip_coefficient = 1.0
	config.longitudinal_peak_slip_ratio = 0.12
	config.longitudinal_slide_grip_multiplier = 0.78
	config.slip_speed_threshold = 2.2
	config.steering_slip_gain = 1.0
	config.handbrake_lateral_grip_multiplier = 0.3
	config.sanitize()
	return config


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[PER_WHEEL_TIRE_STATE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[PER_WHEEL_TIRE_STATE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PER_WHEEL_TIRE_STATE_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[PER_WHEEL_TIRE_STATE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[PER_WHEEL_TIRE_STATE_TEST] - %s" % failure_message)
	quit(1)
