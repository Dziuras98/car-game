extends Node

const EPSILON: float = 0.001

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_vehicle_motion_projection()
	_test_chassis_projection_helpers()
	_test_steering_contracts()
	_test_slip_limited_steering()
	await _test_apply_velocity_synchronizes_collision_response()
	_test_airborne_tire_state()
	await _test_grounded_lateral_recovery()
	await _test_current_frame_slip_reduces_steering()
	await _test_handbrake_reduces_lateral_recovery()
	_finish()


func _test_vehicle_motion_projection() -> void:
	var motion := VehicleMotionModel.new()
	var identity_velocity: Vector3 = motion.get_horizontal_velocity_vector(
		Transform3D.IDENTITY,
		10.0,
		2.0
	)
	_expect(
		_vector3_equal_approx(identity_velocity, Vector3(2.0, 0.0, -10.0)),
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
		_vector2_equal_approx(restored, Vector2(8.0, -1.5)),
		"vehicle motion round-trips local speeds through a rotated transform"
	)


func _test_chassis_projection_helpers() -> void:
	var chassis := _configured_chassis()
	var state := CarRuntimeState.new()
	state.forward_speed = 7.25
	state.lateral_speed = -2.5
	var car := _create_test_car(
		Transform3D(Basis(Vector3.UP, deg_to_rad(-23.0)), Vector3.ZERO)
	)
	var horizontal_velocity: Vector3 = chassis.get_horizontal_velocity_vector(
		state,
		car.global_transform
	)
	state.forward_speed = 0.0
	state.lateral_speed = 0.0
	chassis.set_local_speeds_from_horizontal_velocity(
		state,
		car.global_transform,
		horizontal_velocity
	)
	_expect(
		_float_equal_approx(state.forward_speed, 7.25),
		"chassis helper restores forward speed from horizontal velocity"
	)
	_expect(
		_float_equal_approx(state.lateral_speed, -2.5),
		"chassis helper restores lateral speed from horizontal velocity"
	)
	car.queue_free()


func _test_steering_contracts() -> void:
	var chassis := _configured_chassis()
	var moving_state := CarRuntimeState.new()
	moving_state.forward_speed = 10.0
	moving_state.ground_contact_count = 4
	var moving_car := _create_test_car()
	var before_velocity: Vector3 = chassis.get_horizontal_velocity_vector(
		moving_state,
		moving_car.global_transform
	)
	var before_basis: Basis = moving_car.global_transform.basis
	chassis.update_steering(moving_state, 1.0, moving_car, 0.10)
	var after_velocity: Vector3 = chassis.get_horizontal_velocity_vector(
		moving_state,
		moving_car.global_transform
	)
	_expect(
		not _basis_equal_approx(moving_car.global_transform.basis, before_basis),
		"grounded steering rotates a moving chassis"
	)
	_expect(
		_vector3_equal_approx(after_velocity, before_velocity),
		"steering preserves horizontal velocity while changing heading"
	)
	moving_car.queue_free()

	var slow_state := CarRuntimeState.new()
	slow_state.forward_speed = 0.20
	slow_state.ground_contact_count = 4
	var slow_car := _create_test_car()
	before_basis = slow_car.global_transform.basis
	chassis.update_steering(slow_state, 1.0, slow_car, 0.10)
	_expect(
		_basis_equal_approx(slow_car.global_transform.basis, before_basis),
		"steering ignores very low forward speed"
	)
	slow_car.queue_free()

	var airborne_state := CarRuntimeState.new()
	airborne_state.forward_speed = 10.0
	airborne_state.ground_contact_count = 0
	var airborne_car := _create_test_car()
	before_basis = airborne_car.global_transform.basis
	chassis.update_steering(airborne_state, 1.0, airborne_car, 0.10)
	_expect(
		_basis_equal_approx(airborne_car.global_transform.basis, before_basis),
		"airborne steering cannot yaw the chassis"
	)
	airborne_car.queue_free()


func _test_slip_limited_steering() -> void:
	var chassis := _configured_chassis()
	var same_direction_state := CarRuntimeState.new()
	same_direction_state.forward_speed = 10.0
	same_direction_state.lateral_speed = 3.0
	same_direction_state.ground_contact_count = 4
	var same_direction_car := _create_test_car()
	chassis.update_steering(
		same_direction_state,
		1.0,
		same_direction_car,
		0.10
	)
	var same_direction_yaw: float = absf(same_direction_car.rotation.y)

	var opposite_direction_state := CarRuntimeState.new()
	opposite_direction_state.forward_speed = 10.0
	opposite_direction_state.lateral_speed = 3.0
	opposite_direction_state.ground_contact_count = 4
	var opposite_direction_car := _create_test_car()
	chassis.update_steering(
		opposite_direction_state,
		-1.0,
		opposite_direction_car,
		0.10
	)
	var opposite_direction_yaw: float = absf(opposite_direction_car.rotation.y)
	_expect(
		same_direction_yaw < opposite_direction_yaw,
		"same-direction steering is limited under lateral slip"
	)
	same_direction_car.queue_free()
	opposite_direction_car.queue_free()


func _test_apply_velocity_synchronizes_collision_response() -> void:
	var config := _build_chassis_config()
	config.gravity = 0.0
	config.floor_stick_force = 0.0
	var chassis := CarChassisController.new()
	chassis.configure(config)
	var state := CarRuntimeState.new()
	state.forward_speed = 30.0
	state.lateral_speed = 3.0
	var car := _create_test_car(
		Transform3D(Basis.IDENTITY, Vector3(0.0, 1.0, 0.0))
	)
	_add_box_collision(car, Vector3(1.0, 1.0, 1.0))
	var wall := StaticBody3D.new()
	add_child(wall)
	wall.global_position = Vector3(0.0, 1.0, -0.8)
	_add_box_collision(wall, Vector3(10.0, 4.0, 0.2))
	await get_tree().physics_frame
	chassis.apply_velocity(state, car, 1.0 / 60.0)
	var resolved_velocity := Vector3(car.velocity.x, 0.0, car.velocity.z)
	var expected_local := VehicleMotionModel.new().get_local_speeds_from_horizontal_velocity(
		car.global_transform,
		resolved_velocity
	)
	_expect(car.get_slide_collision_count() > 0, "chassis reaches the static wall")
	_expect(
		_vector2_equal_approx(
			Vector2(state.forward_speed, state.lateral_speed),
			expected_local
		),
		"collision-resolved velocity is written back to runtime state"
	)
	_expect(
		absf(state.forward_speed) < 1.0,
		"collision removes velocity directed into the wall"
	)
	_expect(
		absf(state.lateral_speed - 3.0) < 0.1,
		"collision preserves tangential slide velocity"
	)
	car.queue_free()
	wall.queue_free()


func _test_airborne_tire_state() -> void:
	var chassis := _configured_chassis()
	var state := CarRuntimeState.new()
	state.forward_speed = 12.0
	state.lateral_speed = 4.0
	state.tire_slip_intensity = 0.75
	var car := _create_test_car()
	chassis.update_tires(state, 1.0, false, car, null, 0.10)
	_expect(
		_float_equal_approx(state.lateral_speed, 4.0),
		"airborne chassis does not recover lateral speed"
	)
	_expect(
		_float_equal_approx(state.tire_slip_intensity, 0.0),
		"airborne chassis clears ground tire-slip intensity"
	)
	car.queue_free()


func _test_grounded_lateral_recovery() -> void:
	var chassis := _configured_chassis()
	var floor := _create_test_floor()
	var car := _create_grounded_test_car()
	await get_tree().physics_frame
	_ground_test_car(car)
	var state := CarRuntimeState.new()
	state.forward_speed = 12.0
	state.lateral_speed = 4.0
	chassis.update_tires(state, 0.0, false, car, null, 0.10)
	_expect(car.is_on_floor(), "grounded tire test establishes floor contact")
	_expect(
		state.ground_contact_count == 4,
		"all four per-axle suspension probes contact the floor"
	)
	_expect(
		_float_equal_approx(state.lateral_speed, 3.0),
		"balanced front and rear tire data recover lateral speed"
	)
	_expect(state.tire_slip_intensity > 0.0, "grounded chassis calculates tire slip")
	car.queue_free()
	floor.queue_free()


func _test_current_frame_slip_reduces_steering() -> void:
	var chassis := _configured_chassis()
	var floor := _create_test_floor()
	var stale_car := _create_grounded_test_car(-2.0)
	var current_car := _create_grounded_test_car(2.0)
	await get_tree().physics_frame
	_ground_test_car(stale_car)
	_ground_test_car(current_car)

	var stale_state := CarRuntimeState.new()
	stale_state.forward_speed = 20.0
	stale_state.ground_contact_count = 4
	chassis.update_steering(stale_state, 1.0, stale_car, 0.10)
	var stale_yaw: float = absf(stale_car.rotation.y)

	var current_state := CarRuntimeState.new()
	current_state.forward_speed = 20.0
	chassis.update_tires(current_state, 1.0, false, current_car, null, 0.10)
	chassis.update_steering(current_state, 1.0, current_car, 0.10)
	var current_yaw: float = absf(current_car.rotation.y)
	_expect(
		current_state.tire_slip_intensity > 0.5,
		"tire update calculates significant current-frame steering slip"
	)
	_expect(
		current_yaw < stale_yaw,
		"current-frame tire slip reduces steering immediately"
	)
	stale_car.queue_free()
	current_car.queue_free()
	floor.queue_free()


func _test_handbrake_reduces_lateral_recovery() -> void:
	var chassis := _configured_chassis()
	var floor := _create_test_floor()
	var normal_car := _create_grounded_test_car(-2.0)
	var handbrake_car := _create_grounded_test_car(2.0)
	await get_tree().physics_frame
	_ground_test_car(normal_car)
	_ground_test_car(handbrake_car)
	var normal_state := CarRuntimeState.new()
	normal_state.forward_speed = 12.0
	normal_state.lateral_speed = 4.0
	chassis.update_tires(normal_state, 0.0, false, normal_car, null, 0.10)
	var handbrake_state := CarRuntimeState.new()
	handbrake_state.forward_speed = 12.0
	handbrake_state.lateral_speed = 4.0
	chassis.update_tires(handbrake_state, 0.0, true, handbrake_car, null, 0.10)
	_expect(
		normal_car.is_on_floor() and handbrake_car.is_on_floor(),
		"handbrake comparison establishes floor contact"
	)
	_expect(
		handbrake_state.lateral_speed > normal_state.lateral_speed,
		"handbrake reduces lateral recovery"
	)
	_expect(
		_float_equal_approx(normal_state.lateral_speed, 3.0),
		"normal tire recovery uses both axle grip values"
	)
	_expect(
		_float_equal_approx(handbrake_state.lateral_speed, 3.75),
		"handbrake applies the configured lateral-grip multiplier"
	)
	normal_car.queue_free()
	handbrake_car.queue_free()
	floor.queue_free()


func _configured_chassis() -> CarChassisController:
	var chassis := CarChassisController.new()
	chassis.configure(_build_chassis_config())
	return chassis


func _build_chassis_config() -> CarDriveConfig:
	var config := CarDriveConfig.new()
	config.max_forward_speed = 30.0
	config.steering_speed = 2.7
	config.wheel_base = 2.65
	config.front_axle_track_width = 1.55
	config.rear_axle_track_width = 1.55
	config.max_steering_angle_degrees = 32.0
	config.front_lateral_grip = 10.0
	config.rear_lateral_grip = 10.0
	config.front_tire_width_m = 0.225
	config.rear_tire_width_m = 0.245
	config.handbrake_lateral_grip_multiplier = 0.25
	config.steering_slip_gain = 0.85
	config.slip_speed_threshold = 2.0
	config.slip_steering_lock_threshold = 0.55
	config.slip_steering_same_direction_multiplier = 0.12
	config.sanitize()
	return config


func _create_test_car(
	target_transform: Transform3D = Transform3D.IDENTITY
) -> CharacterBody3D:
	var car := CharacterBody3D.new()
	add_child(car)
	car.global_transform = target_transform
	return car


func _create_grounded_test_car(x_position: float = 0.0) -> CharacterBody3D:
	var car := _create_test_car(
		Transform3D(Basis.IDENTITY, Vector3(x_position, 0.0, 0.0))
	)
	_add_box_collision(
		car,
		Vector3(1.0, 1.0, 1.0),
		Vector3(0.0, 0.5, 0.0)
	)
	return car


func _create_test_floor() -> TrackSurfaceBody:
	var floor := TrackSurfaceBody.new()
	floor.collision_layer = 1
	floor.collision_mask = 1
	floor.grip_multiplier = 1.0
	add_child(floor)
	floor.global_position = Vector3(0.0, -0.1, 0.0)
	_add_box_collision(floor, Vector3(20.0, 0.2, 20.0))
	return floor


func _ground_test_car(car: CharacterBody3D) -> void:
	car.velocity = Vector3(0.0, -1.0, 0.0)
	car.move_and_slide()


func _add_box_collision(
	collision_object: CollisionObject3D,
	size: Vector3,
	local_position: Vector3 = Vector3.ZERO
) -> void:
	var collision_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	collision_shape.shape = box_shape
	collision_shape.position = local_position
	collision_object.add_child(collision_shape)


func _float_equal_approx(a: float, b: float) -> bool:
	return absf(a - b) <= EPSILON


func _vector2_equal_approx(a: Vector2, b: Vector2) -> bool:
	return _float_equal_approx(a.x, b.x) and _float_equal_approx(a.y, b.y)


func _vector3_equal_approx(a: Vector3, b: Vector3) -> bool:
	return (
		_float_equal_approx(a.x, b.x)
		and _float_equal_approx(a.y, b.y)
		and _float_equal_approx(a.z, b.z)
	)


func _basis_equal_approx(a: Basis, b: Basis) -> bool:
	return (
		_vector3_equal_approx(a.x, b.x)
		and _vector3_equal_approx(a.y, b.y)
		and _vector3_equal_approx(a.z, b.z)
	)


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
	push_error(
		"[CAR_CHASSIS_MOTION_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[CAR_CHASSIS_MOTION_TEST] - %s" % failure_message)
	get_tree().quit(1)
