extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var chassis := CarChassisController.new()
	chassis.configure(_build_config())
	var state := CarRuntimeState.new()
	state.forward_speed = 0.0
	state.lateral_speed = 0.15
	state.ground_contact_count = WheelTireState.WHEEL_COUNT
	state.surface_grip_multiplier = 1.0
	state.synchronize_wheel_contacts_from_aggregate()
	for _step_index: int in range(12):
		chassis.update_tire_dynamics(state, 0.0, false, 1.0 / 120.0)
	_expect(
		absf(state.lateral_speed) <= 0.001,
		"released steering and tire contact remove residual low-speed lateral creep"
	)
	_finish()


func _build_config() -> CarDriveConfig:
	var config := CarDriveConfig.new()
	config.vehicle_mass = 1400.0
	config.steering_speed = 2.5
	config.wheel_base = 2.70
	config.front_axle_track_width = 1.50
	config.rear_axle_track_width = 1.50
	config.front_static_load_fraction = 0.52
	config.center_of_mass_height_m = 0.50
	config.front_lateral_grip = 9.8
	config.rear_lateral_grip = 9.8
	config.front_tire_width_m = 0.225
	config.rear_tire_width_m = 0.225
	config.steering_slip_gain = 0.90
	config.handbrake_lateral_grip_multiplier = 0.30
	config.gravity = 0.0
	config.suspension_stiffness = 0.0
	config.suspension_damping = 0.0
	config.sanitize()
	return config


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[LOW_SPEED_LATERAL_FRICTION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[LOW_SPEED_LATERAL_FRICTION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[LOW_SPEED_LATERAL_FRICTION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[LOW_SPEED_LATERAL_FRICTION_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[LOW_SPEED_LATERAL_FRICTION_TEST] - %s" % failure_message)
	quit(1)
