extends SceneTree

const STEP: float = 1.0 / 120.0

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_body_frame_yaw_rotation_preserves_horizontal_speed()
	_test_released_steering_damps_residual_yaw()
	_finish()


func _test_body_frame_yaw_rotation_preserves_horizontal_speed() -> void:
	var chassis := _configured_chassis()
	var state := _contact_state(10.0)
	state.yaw_rate_rad_s = 1.0
	_saturate_longitudinal_slip(state)
	var initial_speed: float = Vector2(state.forward_speed, state.lateral_speed).length()
	for _step_index: int in range(120):
		chassis.update_tire_dynamics(state, 0.0, false, STEP)
	var final_speed: float = Vector2(state.forward_speed, state.lateral_speed).length()
	_expect(
		absf(final_speed - initial_speed) <= 0.01,
		"body-frame yaw rotation preserves horizontal center speed when tire forces are unavailable"
	)


func _test_released_steering_damps_residual_yaw() -> void:
	var chassis := _configured_chassis()
	var state := _contact_state(0.2)
	state.yaw_rate_rad_s = 1.0
	_saturate_longitudinal_slip(state)
	for _step_index: int in range(240):
		chassis.update_tire_dynamics(state, 0.0, false, STEP)
	_expect(absf(state.yaw_rate_rad_s) < 0.01, "released steering damps residual low-speed chassis yaw")


func _saturate_longitudinal_slip(state: CarRuntimeState) -> void:
	for wheel: WheelTireState in state.wheel_states:
		wheel.longitudinal_slip_intensity = 1.0
		wheel.longitudinal_grip_usage = 1.0
		wheel.tire_slip_intensity = 1.0
	state.update_slip_aggregates()


func _configured_chassis() -> CarChassisController:
	var chassis := CarChassisController.new()
	chassis.configure(_build_chassis_config())
	return chassis


func _contact_state(forward_speed: float) -> CarRuntimeState:
	var state := CarRuntimeState.new()
	state.forward_speed = forward_speed
	state.ground_contact_count = WheelTireState.WHEEL_COUNT
	state.surface_grip_multiplier = 1.0
	state.synchronize_wheel_contacts_from_aggregate()
	return state


func _build_chassis_config() -> CarDriveConfig:
	var config := CarDriveConfig.new()
	config.vehicle_mass = 1300.0
	config.max_forward_speed = 60.0
	config.steering_speed = 2.5
	config.wheel_base = 2.65
	config.front_axle_track_width = 1.55
	config.rear_axle_track_width = 1.53
	config.max_steering_angle_degrees = 32.0
	config.front_static_load_fraction = 0.55
	config.center_of_mass_height_m = 0.52
	config.front_lateral_grip = 9.8
	config.rear_lateral_grip = 9.5
	config.front_tire_width_m = 0.225
	config.rear_tire_width_m = 0.225
	config.steering_slip_gain = 0.90
	config.handbrake_lateral_grip_multiplier = 0.28
	config.gravity = 0.0
	config.suspension_stiffness = 0.0
	config.suspension_damping = 0.0
	config.sanitize()
	return config


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CHASSIS_ENERGY_YAW_REGRESSION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CHASSIS_ENERGY_YAW_REGRESSION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CHASSIS_ENERGY_YAW_REGRESSION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[CHASSIS_ENERGY_YAW_REGRESSION_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[CHASSIS_ENERGY_YAW_REGRESSION_TEST] - %s" % failure_message)
	quit(1)
