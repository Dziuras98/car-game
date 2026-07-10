extends Node

const EPSILON: float = 0.001

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_vehicle_motion_identity_projection()
	_test_vehicle_motion_round_trip_projection()
	_test_chassis_projection_helpers()
	_test_steering_preserves_horizontal_velocity()
	_test_steering_ignores_low_speed()
	_test_slip_limited_same_direction_steering()
	await _test_apply_velocity_synchronizes_collision_response()
	_test_tire_lateral_recovery_when_airborne()
	_test_handbrake_reduces_lateral_recovery()
	_finish()


func _test_vehicle_motion_identity_projection() -> void:
	var motion: VehicleMotionModel = VehicleMotionModel.new()
	var transform: Transform3D = Transform3D.IDENTITY
	var horizontal_velocity: Vector3 = motion.get_horizontal_velocity_vector(transform, 10.0, 2.0)

	_expect(_vector3_equal_approx(horizontal_velocity, Vector3(2.0, 0.0, -10.0)), "vehicle motion projects identity forward/lateral speeds to horizontal velocity")

	var local_speeds: Vector2 = motion.get_local_speeds_from_horizontal_velocity(transform, horizontal_velocity)
	_expect(_vector2_equal_approx(local_speeds, Vector2(10.0, 2.0)), "vehicle motion restores identity local speeds from horizontal velocity")


func _test_vehicle_motion_round_trip_projection() -> void:
	var motion: VehicleMotionModel = VehicleMotionModel.new()
	var transform: Transform3D = Transform3D(Basis(Vector3.UP, deg_to_rad(37.0)), Vector3.ZERO)
	var horizontal_velocity: Vector3 = motion.get_horizontal_velocity_vector(transform, 8.0, -1.5)
	var local_speeds: Vector2 = motion.get_local_speeds_from_horizontal_velocity(transform, horizontal_velocity)

	_expect(_vector2_equal_approx(local_speeds, Vector2(8.0, -1.5)), "vehicle motion round-trips local speeds through rotated transform")


func _test_chassis_projection_helpers() -> void:
	var config: CarDriveConfig = _build_chassis_config()
	var chassis: CarChassisController = CarChassisController.new()
	chassis.configure(config)

	var state: CarRuntimeState = CarRuntimeState.new()
	state.forward_speed = 7.25
	state.lateral_speed = -2.5

	var car: CharacterBody3D = _create_test_car(Transform3D(Basis(Vector3.UP, deg_to_rad(-23.0)), Vector3.ZERO))

	var horizontal_velocity: Vector3 = chassis.get_horizontal_velocity_vector(state, car.global_transform)
	state.forward_speed = 0.0
	state.lateral_speed = 0.0
	chassis.set_local_speeds_from_horizontal_velocity(state, car.global_transform, horizontal_velocity)

	_expect(_float_equal_approx(state.forward_speed, 7.25), "chassis helper restores forward speed from horizontal velocity")
	_expect(_float_equal_approx(state.lateral_speed, -2.5), "chassis helper restores lateral speed from horizontal velocity")

	car.queue_free()


func _test_steering_preserves_horizontal_velocity() -> void:
	var config: CarDriveConfig = _build_chassis_config()
	var chassis: CarChassisController = CarChassisController.new()
	chassis.configure(config)

	var state: CarRuntimeState = CarRuntimeState.new()
	state.forward_speed = 10.0
	state.lateral_speed = 0.0
	state.tire_slip_intensity = 0.0

	var car: CharacterBody3D = _create_test_car()

	var before_velocity: Vector3 = chassis.get_horizontal_velocity_vector(state, car.global_transform)
	var before_basis: Basis = car.global_transform.basis
	chassis.update_steering(state, 1.0, car, 0.10)
	var after_velocity: Vector3 = chassis.get_horizontal_velocity_vector(state, car.global_transform)

	_expect(not _basis_equal_approx(car.global_transform.basis, before_basis), "chassis steering rotates car when speed and steering are significant")
	_expect(_vector3_equal_approx(after_velocity, before_velocity), "chassis steering preserves horizontal velocity after yaw rotation")

	car.queue_free()


func _test_steering_ignores_low_speed() -> void:
	var config: CarDriveConfig = _build_chassis_config()
	var chassis: CarChassisController = CarChassisController.new()
	chassis.configure(config)

	var state: CarRuntimeState = CarRuntimeState.new()
	state.forward_speed = 0.20
	state.lateral_speed = 0.0
	state.tire_slip_intensity = 0.0

	var car: CharacterBody3D = _create_test_car()
	var before_basis: Basis = car.global_transform.basis
	chassis.update_steering(state, 1.0, car, 0.10)

	_expect(_basis_equal_approx(car.global_transform.basis, before_basis), "chassis steering ignores very low forward speed")

	car.queue_free()


func _test_slip_limited_same_direction_steering() -> void:
	var config: CarDriveConfig = _build_chassis_config()
	var chassis: CarChassisController = CarChassisController.new()
	chassis.configure(config)

	var same_direction_state: CarRuntimeState = CarRuntimeState.new()
	same_direction_state.forward_speed = 10.0
	same_direction_state.lateral_speed = 3.0
	same_direction_state.tire_slip_intensity = 0.0
	var same_direction_car: CharacterBody3D = _create_test_car()
	chassis.update_steering(same_direction_state, 1.0, same_direction_car, 0.10)
	var same_direction_yaw: float = absf(same_direction_car.rotation.y)

	var opposite_direction_state: CarRuntimeState = CarRuntimeState.new()
	opposite_direction_state.forward_speed = 10.0
	opposite_direction_state.lateral_speed = 3.0
	opposite_direction_state.tire_slip_intensity = 0.0
	var opposite_direction_car: CharacterBody3D = _create_test_car()
	chassis.update_steering(opposite_direction_state, -1.0, opposite_direction_car, 0.10)
	var opposite_direction_yaw: float = absf(opposite_direction_car.rotation.y)

	_expect(same_direction_yaw < opposite_direction_yaw, "chassis limits same-direction steering under lateral slip")

	same_direction_car.queue_free()
	opposite_direction_car.queue_free()


func _test_apply_velocity_synchronizes_collision_response() -> void:
	var config: CarDriveConfig = _build_chassis_config()
	config.gravity = 0.0
	config.floor_stick_force = 0.0
	var chassis: CarChassisController = CarChassisController.new()
	chassis.configure(config)

	var state: CarRuntimeState = CarRuntimeState.new()
	state.forward_speed = 30.0
	state.lateral_speed = 3.0

	var car_transform: Transform3D = Transform3D(Basis.IDENTITY, Vector3(0.0, 1.0, 0.0))
	var car: CharacterBody3D = _create_test_car(car_transform)
	_add_box_collision(car, Vector3(1.0, 1.0, 1.0))

	var wall: StaticBody3D = StaticBody3D.new()
	add_child(wall)
	wall.global_position = Vector3(0.0, 1.0, -0.8)
	_add_box_collision(wall, Vector3(10.0, 4.0, 0.2))

	await get_tree().physics_frame
	chassis.apply_velocity(state, car, 1.0 / 60.0)

	var resolved_horizontal_velocity: Vector3 = Vector3(car.velocity.x, 0.0, car.velocity.z)
	var expected_local_speeds: Vector2 = VehicleMotionModel.new().get_local_speeds_from_horizontal_velocity(
		car.global_transform,
		resolved_horizontal_velocity
	)

	_expect(car.get_slide_collision_count() > 0, "chassis collision test reaches the static wall")
	_expect(_vector2_equal_approx(Vector2(state.forward_speed, state.lateral_speed), expected_local_speeds), "chassis writes collision-resolved velocity back to runtime state")
	_expect(absf(state.forward_speed) < 1.0, "chassis collision removes velocity directed into the wall")
	_expect(absf(state.lateral_speed - 3.0) < 0.1, "chassis collision preserves tangential slide velocity")

	car.queue_free()
	wall.queue_free()


func _test_tire_lateral_recovery_when_airborne() -> void:
	var config: CarDriveConfig = _build_chassis_config()
	var chassis: CarChassisController = CarChassisController.new()
	chassis.configure(config)

	var state: CarRuntimeState = CarRuntimeState.new()
	state.forward_speed = 12.0
	state.lateral_speed = 4.0

	var car: CharacterBody3D = _create_test_car()
	chassis.update_tires(state, 1.0, false, car, null, 0.10)

	_expect(_float_equal_approx(state.lateral_speed, 3.0), "chassis tire update recovers lateral speed with normal grip")
	_expect(_float_equal_approx(state.tire_slip_intensity, 0.0), "chassis tire update clears slip intensity when car is airborne")

	car.queue_free()


func _test_handbrake_reduces_lateral_recovery() -> void:
	var config: CarDriveConfig = _build_chassis_config()
	var chassis: CarChassisController = CarChassisController.new()
	chassis.configure(config)

	var normal_state: CarRuntimeState = CarRuntimeState.new()
	normal_state.forward_speed = 12.0
	normal_state.lateral_speed = 4.0
	var normal_car: CharacterBody3D = _create_test_car()
	chassis.update_tires(normal_state, 0.0, false, normal_car, null, 0.10)

	var handbrake_state: CarRuntimeState = CarRuntimeState.new()
	handbrake_state.forward_speed = 12.0
	handbrake_state.lateral_speed = 4.0
	var handbrake_car: CharacterBody3D = _create_test_car()
	chassis.update_tires(handbrake_state, 0.0, true, handbrake_car, null, 0.10)

	_expect(handbrake_state.lateral_speed > normal_state.lateral_speed, "chassis handbrake reduces lateral grip recovery")
	_expect(_float_equal_approx(handbrake_state.lateral_speed, 3.75), "chassis handbrake applies configured lateral grip multiplier")

	normal_car.queue_free()
	handbrake_car.queue_free()


func _create_test_car(target_transform: Transform3D = Transform3D.IDENTITY) -> CharacterBody3D:
	var car: CharacterBody3D = CharacterBody3D.new()
	add_child(car)
	car.global_transform = target_transform
	return car


func _add_box_collision(collision_object: CollisionObject3D, size: Vector3) -> void:
	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	var box_shape: BoxShape3D = BoxShape3D.new()
	box_shape.size = size
	collision_shape.shape = box_shape
	collision_object.add_child(collision_shape)


func _build_chassis_config() -> CarDriveConfig:
	var config: CarDriveConfig = CarDriveConfig.new()
	config.max_forward_speed = 30.0
	config.steering_speed = 2.7
	config.wheel_base = 2.65
	config.max_steering_angle_degrees = 32.0
	config.lateral_grip = 10.0
	config.handbrake_lateral_grip_multiplier = 0.25
	config.steering_slip_gain = 0.85
	config.slip_speed_threshold = 2.0
	config.slip_steering_lock_threshold = 0.55
	config.slip_steering_same_direction_multiplier = 0.12
	config.sanitize()
	return config


func _float_equal_approx(a: float, b: float) -> bool:
	return absf(a - b) <= EPSILON


func _vector2_equal_approx(a: Vector2, b: Vector2) -> bool:
	return _float_equal_approx(a.x, b.x) and _float_equal_approx(a.y, b.y)


func _vector3_equal_approx(a: Vector3, b: Vector3) -> bool:
	return _float_equal_approx(a.x, b.x) and _float_equal_approx(a.y, b.y) and _float_equal_approx(a.z, b.z)


func _basis_equal_approx(a: Basis, b: Basis) -> bool:
	return _vector3_equal_approx(a.x, b.x) and _vector3_equal_approx(a.y, b.y) and _vector3_equal_approx(a.z, b.z)


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
