extends SceneTree

const EPSILON: float = 0.001

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_peak_lateral_slip_consumes_longitudinal_grip_budget()
	_test_peak_longitudinal_slip_consumes_lateral_grip_budget()
	_test_combined_forces_stay_inside_tire_budget()
	_test_pure_sideways_motion_generates_recovery_force()
	_test_ackermann_angles_remain_numerically_bounded()
	_test_wheel_steering_angle_is_not_limited_by_side_slip()
	_finish()


func _test_peak_lateral_slip_consumes_longitudinal_grip_budget() -> void:
	var lateral_model := LateralTireDynamicsModel.new()
	var tire_model := TireModel.new()
	var peak_slip_angle: float = deg_to_rad(7.0)
	var lateral_usage: float = lateral_model.calculate_lateral_slip_intensity(
		peak_slip_angle,
		peak_slip_angle
	)
	var longitudinal_capacity: float = tire_model.get_longitudinal_acceleration_capacity(
		lateral_usage,
		1.0,
		1.0,
		1.0
	)

	_expect(
		lateral_usage >= 0.999,
		"the lateral-force peak consumes the complete friction-circle budget"
	)
	_expect(
		longitudinal_capacity <= TireModel.MIN_ACCELERATION_CAPACITY,
		"peak lateral tire force does not leave artificial simultaneous drive capacity"
	)

	var half_peak_usage: float = lateral_model.calculate_lateral_slip_intensity(
		peak_slip_angle * 0.5,
		peak_slip_angle
	)
	_expect(
		absf(half_peak_usage - 0.5) <= EPSILON,
		"sub-peak lateral friction usage follows the linear lateral-force curve"
	)


func _test_peak_longitudinal_slip_consumes_lateral_grip_budget() -> void:
	var lateral_model := LateralTireDynamicsModel.new()
	var tire_model := TireModel.new()
	var peak_slip_ratio: float = 0.12
	var longitudinal_usage: float = tire_model.calculate_longitudinal_slip_intensity(
		peak_slip_ratio,
		peak_slip_ratio
	)
	var lateral_acceleration: float = lateral_model.resolve_lateral_acceleration(
		deg_to_rad(3.0),
		20.0,
		1.0,
		10.0,
		1.0,
		longitudinal_usage,
		deg_to_rad(7.0)
	)

	_expect(
		longitudinal_usage >= 0.999,
		"the longitudinal-force peak consumes the complete friction-circle budget"
	)
	_expect(
		absf(lateral_acceleration) <= EPSILON,
		"peak longitudinal tire force does not leave artificial simultaneous lateral capacity"
	)


func _test_combined_forces_stay_inside_tire_budget() -> void:
	var lateral_model := LateralTireDynamicsModel.new()
	var tire_model := TireModel.new()
	var peak_slip_angle: float = deg_to_rad(7.0)
	var peak_slip_ratio: float = 0.12
	var normalized_samples: Array[float] = [0.0, 0.25, 0.5, 0.75, 1.0, 2.0, 4.0]
	var longitudinal_coefficient_for_unit_capacity: float = 1.0 / TireModel.STANDARD_GRAVITY

	for lateral_sample: float in normalized_samples:
		for longitudinal_sample: float in normalized_samples:
			var lateral_usage: float = lateral_model.calculate_lateral_slip_intensity(
				peak_slip_angle * lateral_sample,
				peak_slip_angle
			)
			var longitudinal_usage: float = tire_model.calculate_longitudinal_slip_intensity(
				peak_slip_ratio * longitudinal_sample,
				peak_slip_ratio
			)
			var lateral_force_fraction: float = absf(
				lateral_model.resolve_lateral_acceleration(
					peak_slip_angle * lateral_sample,
					1000.0,
					1.0,
					1.0,
					1.0,
					longitudinal_usage,
					peak_slip_angle,
					1.0
				)
			)
			var longitudinal_force_fraction: float = absf(
				tire_model.resolve_longitudinal_acceleration_from_slip(
					peak_slip_ratio * longitudinal_sample,
					lateral_usage,
					1.0,
					1.0,
					longitudinal_coefficient_for_unit_capacity,
					peak_slip_ratio,
					0.78
				)
			)
			var combined_force_fraction: float = sqrt(
				lateral_force_fraction * lateral_force_fraction
				+ longitudinal_force_fraction * longitudinal_force_fraction
			)
			_expect(
				combined_force_fraction <= 1.001,
				"combined tire force remains inside the friction budget for lateral %.2f and longitudinal %.2f"
				% [lateral_sample, longitudinal_sample]
			)


func _test_pure_sideways_motion_generates_recovery_force() -> void:
	var config := _build_config()
	var chassis := CarChassisController.new()
	chassis.configure(config)
	var state := _build_contact_state(0.0, 8.0)
	chassis.update_tire_dynamics(state, 0.0, false, 0.0)

	var total_lateral_force: float = 0.0
	var minimum_lateral_grip_usage: float = 1.0
	for wheel: WheelTireState in state.wheel_states:
		total_lateral_force += wheel.lateral_force_n
		minimum_lateral_grip_usage = minf(minimum_lateral_grip_usage, wheel.lateral_grip_usage)
	_expect(
		total_lateral_force < -1.0,
		"pure sideways motion produces tire force opposing the slide"
	)
	_expect(
		state.lateral_slip_intensity >= 1.0 - EPSILON,
		"pure sideways motion reaches saturated slip severity"
	)
	_expect(
		absf(minimum_lateral_grip_usage - config.lateral_slide_grip_multiplier) <= EPSILON,
		"pure sideways motion reaches the configured post-peak physical grip usage"
	)


func _test_ackermann_angles_remain_numerically_bounded() -> void:
	var model := LateralTireDynamicsModel.new()
	var angles: Vector2 = model.get_ackermann_steering_angles(
		1.0,
		180.0,
		0.10,
		0.20
	)
	_expect(
		absf(angles.x) <= LateralTireDynamicsModel.MAX_STEERING_ANGLE_RAD + EPSILON
		and absf(angles.y) <= LateralTireDynamicsModel.MAX_STEERING_ANGLE_RAD + EPSILON,
		"pathological steering geometry cannot exceed the solver steering-angle bound"
	)


func _test_wheel_steering_angle_is_not_limited_by_side_slip() -> void:
	var config := _build_config()
	var chassis := CarChassisController.new()
	chassis.configure(config)

	var aligned_state := _build_contact_state(15.0, 0.0)
	var sliding_state := _build_contact_state(15.0, config.slip_speed_threshold * 3.0)
	chassis.update_tire_dynamics(aligned_state, 1.0, false, 0.0)
	chassis.update_tire_dynamics(sliding_state, 1.0, false, 0.0)

	var aligned_left_angle: float = aligned_state.get_wheel_state(
		WheelTireState.Position.FRONT_LEFT
	).steering_angle_rad
	var aligned_right_angle: float = aligned_state.get_wheel_state(
		WheelTireState.Position.FRONT_RIGHT
	).steering_angle_rad
	var sliding_left_angle: float = sliding_state.get_wheel_state(
		WheelTireState.Position.FRONT_LEFT
	).steering_angle_rad
	var sliding_right_angle: float = sliding_state.get_wheel_state(
		WheelTireState.Position.FRONT_RIGHT
	).steering_angle_rad

	_expect(
		is_equal_approx(sliding_left_angle, aligned_left_angle)
		and is_equal_approx(sliding_right_angle, aligned_right_angle),
		"side slip does not reduce either front-wheel steering angle"
	)
	_expect(
		sliding_left_angle > 0.0 and sliding_right_angle > sliding_left_angle,
		"full steering input retains the configured Ackermann wheel angles during a slide"
	)


func _build_contact_state(forward_speed: float, lateral_speed: float) -> CarRuntimeState:
	var state := CarRuntimeState.new()
	state.forward_speed = forward_speed
	state.lateral_speed = lateral_speed
	state.ground_contact_count = WheelTireState.WHEEL_COUNT
	state.surface_grip_multiplier = 1.0
	state.synchronize_wheel_contacts_from_aggregate()
	return state


func _build_config() -> CarDriveConfig:
	var config := CarDriveConfig.new()
	config.vehicle_mass = 1400.0
	config.max_forward_speed = 70.0
	config.steering_speed = 2.8
	config.wheel_base = 2.70
	config.front_axle_track_width = 1.56
	config.rear_axle_track_width = 1.55
	config.max_steering_angle_degrees = 34.0
	config.front_static_load_fraction = 0.54
	config.center_of_mass_height_m = 0.52
	config.front_lateral_grip = 10.0
	config.rear_lateral_grip = 9.8
	config.front_tire_width_m = 0.225
	config.rear_tire_width_m = 0.245
	config.steering_slip_gain = 0.90
	config.slip_speed_threshold = 2.2
	config.slip_steering_lock_threshold = 0.0
	config.slip_steering_same_direction_multiplier = 0.0
	config.handbrake_lateral_grip_multiplier = 0.28
	config.gravity = 0.0
	config.suspension_stiffness = 0.0
	config.suspension_damping = 0.0
	config.sanitize()
	return config


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[LATERAL_SLIP_TRACTION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[LATERAL_SLIP_TRACTION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[LATERAL_SLIP_TRACTION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[LATERAL_SLIP_TRACTION_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[LATERAL_SLIP_TRACTION_TEST] - %s" % failure_message)
	quit(1)
