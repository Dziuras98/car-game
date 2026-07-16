extends Node

const EPSILON: float = 0.001
const STEP: float = 1.0 / 120.0

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_vehicle_motion_projection()
	_test_chassis_projection_helpers()
	_test_steering_only_rotates_front_wheels()
	_test_tire_forces_generate_chassis_yaw()
	_test_airborne_steering_does_not_create_yaw()
	_test_lateral_tire_forces_recover_sideways_motion()
	_test_near_sideways_slide_recovers_quickly()
	_test_handbrake_reduces_rear_lateral_force()
	_finish()


func _test_vehicle_motion_projection() -> void:
	var motion := VehicleMotionModel.new()
	var identity_velocity: Vector3 = motion.get_horizontal_velocity_vector(
		Transform3D.IDENTITY,
		10.0,
		2.0
	)
	_expect(
		identity_velocity.is_equal_approx(Vector3(2.0, 0.0, -10.0)),
		"vehicle motion projects forward and lateral speeds into world velocity"
	)
	var rotated_transform := Transform3D(
		Basis(Vector3.UP, deg_to_rad(37.0)),
		Vector3.ZERO
	)
	var rotated_velocity: Vector3 = motion.get_horizontal_velocity_vector(
		rotated_transform,
		8.0,
		-1.5
	)
	var restored: Vector2 = motion.get_local_speeds_from_horizontal_velocity(
		rotated_transform,
		rotated_velocity
	)
	_expect(
		restored.is_equal_approx(Vector2(8.0, -1.5)),
		"vehicle motion round-trips local speeds through a rotated transform"
	)


func _test_chassis_projection_helpers() -> void:
	var chassis := _configured_chassis()
	var state := CarRuntimeState.new()
	state.forward_speed = 7.25
	state.lateral_speed = -2.5
	var car := CharacterBody3D.new()
	car.transform = Transform3D(
		Basis(Vector3.UP, deg_to_rad(-23.0)),
		Vector3.ZERO
	)
	var horizontal_velocity: Vector3 = chassis.get_horizontal_velocity_vector(
		state,
		car.transform
	)
	state.forward_speed = 0.0
	state.lateral_speed = 0.0
	chassis.set_local_speeds_from_horizontal_velocity(
		state,
		car.transform,
		horizontal_velocity
	)
	_expect(absf(state.forward_speed - 7.25) <= EPSILON, "chassis helper restores forward speed")
	_expect(absf(state.lateral_speed + 2.5) <= EPSILON, "chassis helper restores lateral speed")
	car.free()


func _test_steering_only_rotates_front_wheels() -> void:
	var chassis := _configured_chassis()
	var state := _contact_state(15.0)
	var car := CharacterBody3D.new()
	var initial_basis: Basis = car.transform.basis
	chassis.update_tire_dynamics(state, 1.0, false, 0.0)
	chassis.update_steering(state, 1.0, car, 0.10)

	var front_left: WheelTireState = state.get_wheel_state(WheelTireState.Position.FRONT_LEFT)
	var front_right: WheelTireState = state.get_wheel_state(WheelTireState.Position.FRONT_RIGHT)
	_expect(front_left.steering_angle_rad > 0.0, "steering input rotates the front-left wheel")
	_expect(front_right.steering_angle_rad > front_left.steering_angle_rad, "Ackermann geometry rotates the inner front wheel farther")
	_expect(is_zero_approx(state.get_wheel_state(WheelTireState.Position.REAR_LEFT).steering_angle_rad), "rear wheels do not steer")
	_expect(car.transform.basis.is_equal_approx(initial_basis), "steering angle alone does not rotate the chassis")
	_expect(is_zero_approx(state.yaw_rate_rad_s), "steering angle alone does not inject yaw rate")
	car.free()


func _test_tire_forces_generate_chassis_yaw() -> void:
	var chassis := _configured_chassis()
	var state := _contact_state(15.0)
	var car := CharacterBody3D.new()
	for _step_index: int in range(240):
		chassis.update_tire_dynamics(state, 0.35, false, STEP)
		chassis.update_steering(state, 0.35, car, STEP)

	_expect(state.yaw_rate_rad_s > 0.01, "front tire forces generate positive yaw rate for right steering")
	_expect(absf(car.rotation.y) > 0.01, "integrated tire-force yaw rotates the chassis")
	_expect(absf(state.yaw_moment_nm) > 1.0, "wheel lateral forces create a measurable yaw moment")
	_expect(absf(state.lateral_acceleration_mps2) > 0.05, "wheel lateral forces accelerate the chassis laterally")
	car.free()


func _test_airborne_steering_does_not_create_yaw() -> void:
	var chassis := _configured_chassis()
	var state := CarRuntimeState.new()
	state.forward_speed = 15.0
	var car := CharacterBody3D.new()
	for _step_index: int in range(120):
		chassis.update_tire_dynamics(state, 1.0, false, STEP)
		chassis.update_steering(state, 1.0, car, STEP)
	_expect(is_zero_approx(state.yaw_rate_rad_s), "airborne steering cannot create yaw rate")
	_expect(absf(car.rotation.y) <= EPSILON, "airborne steering cannot rotate the chassis")
	_expect(state.get_wheel_state(WheelTireState.Position.FRONT_LEFT).steering_angle_rad > 0.0, "airborne front wheels can still be visually steered")
	car.free()


func _test_lateral_tire_forces_recover_sideways_motion() -> void:
	var chassis := _configured_chassis()
	var state := _contact_state(15.0)
	state.lateral_speed = 2.5
	var initial_lateral_speed: float = absf(state.lateral_speed)
	for _step_index: int in range(240):
		chassis.update_tire_dynamics(state, 0.0, false, STEP)
	_expect(absf(state.lateral_speed) < initial_lateral_speed, "tire forces reduce an existing lateral velocity")
	_expect(state.lateral_slip_intensity > 0.0, "sideways motion creates physical tire slip angles")


func _test_near_sideways_slide_recovers_quickly() -> void:
	var chassis := _configured_chassis()
	var state := _contact_state(0.0)
	state.lateral_speed = 8.0
	for _step_index: int in range(30):
		chassis.update_tire_dynamics(state, 0.0, false, STEP)
	_expect(
		absf(state.lateral_speed) < 7.0,
		"near-sideways motion retains enough tire force for rapid lateral recovery"
	)


func _test_handbrake_reduces_rear_lateral_force() -> void:
	var chassis := _configured_chassis()
	var normal_state := _contact_state(12.0)
	normal_state.lateral_speed = 2.0
	chassis.update_tire_dynamics(normal_state, 0.0, false, 0.0)
	var handbrake_state := _contact_state(12.0)
	handbrake_state.lateral_speed = 2.0
	chassis.update_tire_dynamics(handbrake_state, 0.0, true, 0.0)
	var normal_rear_force: float = absf(
		normal_state.get_wheel_state(WheelTireState.Position.REAR_LEFT).lateral_force_n
	)
	var handbrake_rear_force: float = absf(
		handbrake_state.get_wheel_state(WheelTireState.Position.REAR_LEFT).lateral_force_n
	)
	_expect(handbrake_rear_force < normal_rear_force, "handbrake reduces rear lateral tire force")


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
		print("[CAR_CHASSIS_MOTION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CAR_CHASSIS_MOTION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CAR_CHASSIS_MOTION_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[CAR_CHASSIS_MOTION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CAR_CHASSIS_MOTION_TEST] - %s" % failure_message)
	get_tree().quit(1)
