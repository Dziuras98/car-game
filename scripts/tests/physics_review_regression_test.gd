extends SceneTree

const STEP: float = 1.0 / 120.0

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_effective_drivetrain_inertia_is_applied()
	_test_per_wheel_contact_patch_speed()
	_test_vector_suspension_support()
	_test_suspension_load_affects_tire_capacity()
	_test_steered_longitudinal_force_creates_yaw()
	_test_post_peak_slip_signals_are_separate()
	_test_cvt_minimum_ratio_semantics()
	_test_differential_lock_couples_wheels()
	_test_vector_aerodynamic_drag()
	_test_banked_motion_projection()
	_test_soft_speed_limiter_does_not_hard_clamp()
	_finish()


func _test_effective_drivetrain_inertia_is_applied() -> void:
	var model := WheelRotationalDynamicsModel.new()
	var light := WheelTireState.new(WheelTireState.Position.REAR_LEFT)
	var reflected := WheelTireState.new(WheelTireState.Position.REAR_RIGHT)
	light.configure_rotation(0.30, 1.0)
	reflected.configure_rotation(0.30, 1.0)
	model.integrate_wheel(light, 100.0, 0.0, 0.0, 1000.0, 0.0, 0.0, 0.10, 1.0)
	model.integrate_wheel(reflected, 100.0, 0.0, 0.0, 1000.0, 0.0, 0.0, 0.10, 5.0)
	_expect(
		light.angular_velocity_rad_s > reflected.angular_velocity_rad_s * 4.9,
		"reflected drivetrain inertia slows wheel angular response"
	)


func _test_per_wheel_contact_patch_speed() -> void:
	var config := _config()
	var state := CarRuntimeState.new()
	state.forward_speed = 10.0
	state.lateral_speed = 1.5
	state.yaw_rate_rad_s = 0.8
	state.get_wheel_state(WheelTireState.Position.FRONT_LEFT).steering_angle_rad = 0.25
	state.get_wheel_state(WheelTireState.Position.FRONT_RIGHT).steering_angle_rad = 0.18
	var left_speed: float = state.get_wheel_longitudinal_road_speed(
		state.get_wheel_state(WheelTireState.Position.FRONT_LEFT), config
	)
	var right_speed: float = state.get_wheel_longitudinal_road_speed(
		state.get_wheel_state(WheelTireState.Position.FRONT_RIGHT), config
	)
	_expect(
		not is_equal_approx(left_speed, right_speed),
		"turning wheels use distinct contact-patch road speeds"
	)


func _test_vector_suspension_support() -> void:
	var state := CarRuntimeState.new()
	state.get_wheel_state(WheelTireState.Position.FRONT_LEFT).set_contact(
		1.0, Vector3.UP, 8.0
	)
	state.get_wheel_state(WheelTireState.Position.FRONT_RIGHT).set_contact(
		1.0, Vector3(0.6, 0.8, 0.0).normalized(), 2.0
	)
	state.update_contact_aggregates()
	var expected: Vector3 = Vector3.UP * 8.0 + Vector3(0.6, 0.8, 0.0).normalized() * 2.0
	_expect(
		state.suspension_acceleration_vector.is_equal_approx(expected),
		"suspension support is the vector sum of individual contacts"
	)


func _test_suspension_load_affects_tire_capacity() -> void:
	var config := _config()
	config.suspension_load_blend = 1.0
	var state := _contact_state(config)
	state.get_wheel_state(WheelTireState.Position.FRONT_LEFT).suspension_acceleration = 1.0
	state.get_wheel_state(WheelTireState.Position.FRONT_RIGHT).suspension_acceleration = 3.0
	state.get_wheel_state(WheelTireState.Position.REAR_LEFT).suspension_acceleration = 8.0
	state.get_wheel_state(WheelTireState.Position.REAR_RIGHT).suspension_acceleration = 8.0
	state.update_wheel_load_shares(config, 0.0, 0.0)
	_expect(
		state.get_wheel_state(WheelTireState.Position.FRONT_LEFT).normal_load_share
		< state.get_wheel_state(WheelTireState.Position.REAR_LEFT).normal_load_share,
		"a lightly supported wheel receives less tire-force capacity"
	)


func _test_steered_longitudinal_force_creates_yaw() -> void:
	var config := _config()
	config.transmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE
	config.drive_layout = CarSpecs.DriveLayout.FRONT_WHEEL_DRIVE
	config.engine_force = 24.0
	config.suspension_load_blend = 0.0
	config.sanitize()
	var state := _contact_state(config)
	state.get_wheel_state(WheelTireState.Position.FRONT_LEFT).steering_angle_rad = 0.30
	state.get_wheel_state(WheelTireState.Position.FRONT_RIGHT).steering_angle_rad = 0.22
	for wheel: WheelTireState in state.wheel_states:
		wheel.road_longitudinal_speed_mps = state.get_wheel_longitudinal_road_speed(wheel, config)
	var powertrain := CarPowertrainController.new()
	powertrain.configure(config)
	powertrain.reset(state)
	state.ground_contact_count = WheelTireState.WHEEL_COUNT
	state.synchronize_wheel_contacts_from_aggregate()
	state.get_wheel_state(WheelTireState.Position.FRONT_LEFT).steering_angle_rad = 0.30
	state.get_wheel_state(WheelTireState.Position.FRONT_RIGHT).steering_angle_rad = 0.22
	powertrain.update(state, 1.0, 0.0, false, false, false, 0.10)
	_expect(
		absf(state.yaw_moment_nm) > 0.1 and absf(state.lateral_acceleration_mps2) > 0.001,
		"steered drive force contributes lateral force and yaw moment"
	)


func _test_post_peak_slip_signals_are_separate() -> void:
	var lateral := LateralTireDynamicsModel.new()
	var peak: float = deg_to_rad(6.0)
	var peak_usage: float = lateral.calculate_lateral_grip_usage(peak, peak, 0.75)
	var slide_usage: float = lateral.calculate_lateral_grip_usage(peak * 3.0, peak, 0.75)
	var slide_severity: float = lateral.calculate_lateral_slip_intensity(peak * 3.0, peak)
	_expect(
		slide_usage < peak_usage and is_equal_approx(slide_severity, 1.0),
		"post-peak force falls while slip-effect severity remains saturated"
	)


func _test_cvt_minimum_ratio_semantics() -> void:
	var unbounded := CvtTransmissionModel.new()
	unbounded.configure(900.0, 2.5, 2.8, 4.0, 0.30, 100.0, 0.85, 900.0, 1800.0, 5000.0, 1000.0, 1200.0, 2000.0)
	unbounded.update_ratio(1000.0, 1.0, 1.0)
	var bounded := CvtTransmissionModel.new()
	bounded.configure(900.0, 2.5, 2.8, 4.0, 0.30, 100.0, 0.85, 900.0, 1800.0, 5000.0, 1000.0, 1200.0, 2000.0, 0.55)
	bounded.update_ratio(1000.0, 1.0, 1.0)
	_expect(
		unbounded.get_current_ratio() < 0.55 and bounded.get_current_ratio() >= 0.55,
		"zero CVT minimum remains unbounded while a configured minimum is enforced"
	)


func _test_differential_lock_couples_wheels() -> void:
	var config := _config()
	config.drive_layout = CarSpecs.DriveLayout.REAR_WHEEL_DRIVE
	config.rear_differential_lock = 1.0
	var state := CarRuntimeState.new()
	state.configure_wheel_rotation(config, false)
	state.get_wheel_state(WheelTireState.Position.REAR_LEFT).angular_velocity_rad_s = 10.0
	state.get_wheel_state(WheelTireState.Position.REAR_RIGHT).angular_velocity_rad_s = 50.0
	var torques: PackedFloat32Array = DifferentialModel.new().distribute_drive_torque(
		state, config, 400.0, STEP
	)
	_expect(
		torques[WheelTireState.Position.REAR_LEFT] > torques[WheelTireState.Position.REAR_RIGHT],
		"locked differential transfers coupling torque toward the slower wheel"
	)


func _test_vector_aerodynamic_drag() -> void:
	var model := ResistanceModel.new()
	model.configure(1200.0, 0.32, 2.1, 1.225, 0.0)
	var result: Vector2 = model.apply_local_velocity(Vector2(10.0, 10.0), 1.0, false, 1.5)
	_expect(
		result.x < 10.0 and result.y < 10.0,
		"aerodynamic drag reduces both forward and lateral motion"
	)


func _test_banked_motion_projection() -> void:
	var motion := VehicleMotionModel.new()
	var normal := Vector3(0.0, 0.8660254, 0.5).normalized()
	var velocity: Vector3 = motion.get_velocity_vector(Transform3D.IDENTITY, 12.0, 2.0, normal)
	_expect(
		absf(velocity.dot(normal)) <= 0.0001,
		"grounded motion is tangent to the sampled road plane"
	)


func _test_soft_speed_limiter_does_not_hard_clamp() -> void:
	var config := _config()
	config.max_forward_speed = 20.0
	config.speed_limiter_strength = 2.0
	config.coast_deceleration = 0.0
	config.rolling_resistance_coefficient = 0.0
	config.drag_coefficient = 0.0
	config.sanitize()
	var state := _contact_state(config)
	state.forward_speed = 25.0
	for wheel: WheelTireState in state.wheel_states:
		wheel.set_rolling_speed(state.forward_speed)
		wheel.road_longitudinal_speed_mps = state.forward_speed
	var powertrain := CarPowertrainController.new()
	powertrain.configure(config)
	powertrain.reset(state)
	state.forward_speed = 25.0
	state.ground_contact_count = WheelTireState.WHEEL_COUNT
	state.synchronize_wheel_contacts_from_aggregate()
	for wheel: WheelTireState in state.wheel_states:
		wheel.set_rolling_speed(state.forward_speed)
		wheel.road_longitudinal_speed_mps = state.forward_speed
	powertrain.update(state, 0.0, 0.0, false, false, false, STEP)
	_expect(
		state.forward_speed < 25.0 and state.forward_speed > config.max_forward_speed,
		"overspeed is reduced progressively instead of hard-clamped"
	)


func _config() -> CarDriveConfig:
	var config := CarDriveConfig.new()
	config.vehicle_mass = 1200.0
	config.wheel_base = 2.65
	config.front_axle_track_width = 1.55
	config.rear_axle_track_width = 1.55
	config.front_static_load_fraction = 0.53
	config.center_of_mass_height_m = 0.52
	config.front_lateral_grip = 10.0
	config.rear_lateral_grip = 10.0
	config.front_tire_width_m = 0.225
	config.rear_tire_width_m = 0.245
	config.longitudinal_grip_coefficient = 1.0
	config.coast_deceleration = 0.0
	config.engine_brake_force = 0.0
	config.drag_coefficient = 0.0
	config.rolling_resistance_coefficient = 0.0
	config.max_forward_speed = 80.0
	config.sanitize()
	return config


func _contact_state(config: CarDriveConfig) -> CarRuntimeState:
	var state := CarRuntimeState.new()
	state.forward_speed = 5.0
	state.ground_contact_count = WheelTireState.WHEEL_COUNT
	state.surface_grip_multiplier = 1.0
	state.suspension_acceleration = 40.0
	state.suspension_acceleration_vector = Vector3.UP * 40.0
	state.synchronize_wheel_contacts_from_aggregate()
	state.configure_wheel_rotation(config, false)
	return state


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[PHYSICS_REVIEW_REGRESSION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[PHYSICS_REVIEW_REGRESSION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PHYSICS_REVIEW_REGRESSION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[PHYSICS_REVIEW_REGRESSION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure: String in _failures:
		push_error("[PHYSICS_REVIEW_REGRESSION_TEST] - %s" % failure)
	quit(1)
