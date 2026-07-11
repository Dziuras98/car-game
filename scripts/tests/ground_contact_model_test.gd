extends Node

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_ground_contact_math()
	await _test_runtime_ground_probe()
	await _test_partial_contact_support_scaling()
	_finish()


func _test_ground_contact_math() -> void:
	var model: GroundContactModel = GroundContactModel.new()
	var probes: Array[Vector3] = model.get_probe_local_positions(2.6, 1.6, 0.4)
	_expect(probes.size() == 4, "ground-contact model produces four suspension probes")
	_expect(probes[0].x < 0.0 and probes[1].x > 0.0, "front probes span the configured axle width")
	_expect(probes[0].z < 0.0 and probes[2].z > 0.0, "probe rows span the configured wheelbase")
	_expect(probes.all(func(point: Vector3) -> bool: return is_equal_approx(point.y, 0.4)), "all probes use the configured local height")

	var unloaded: float = model.calculate_spring_acceleration(0.6, 0.3, 0.2, 0.0, 30.0, 5.0)
	var compressed: float = model.calculate_spring_acceleration(0.32, 0.3, 0.2, 0.0, 30.0, 5.0)
	var damped: float = model.calculate_spring_acceleration(0.32, 0.3, 0.2, 2.0, 30.0, 5.0)
	_expect(is_zero_approx(unloaded), "probe outside suspension travel produces no spring acceleration")
	_expect(compressed > 0.0, "compressed suspension produces upward acceleration")
	_expect(damped < compressed, "positive normal velocity is damped")

	var slope_normal: Vector3 = Vector3(0.0, 0.9659258, 0.258819).normalized()
	var averaged: Vector3 = model.calculate_average_normal([slope_normal, slope_normal, Vector3.UP, Vector3.UP])
	_expect(averaged.y > 0.95 and averaged.z > 0.0, "average normal preserves a stable sloped contact direction")
	_expect(is_equal_approx(model.calculate_average_grip([1.0, 1.0, 0.5, 0.5]), 0.75), "mixed wheel surfaces average their grip coefficients")


func _test_runtime_ground_probe() -> void:
	var floor_body: TrackSurfaceBody = _create_surface("TestSurface", Vector3(0.0, -0.1, 0.0), Vector3(20.0, 0.2, 20.0), 0.62)
	var car: CharacterBody3D = _create_probe_car("ProbeCar")
	await get_tree().physics_frame

	var config: CarDriveConfig = _build_contact_config()
	var chassis: CarChassisController = CarChassisController.new()
	chassis.configure(config)
	var state: CarRuntimeState = CarRuntimeState.new()
	state.reset_drive_state(config.idle_rpm)
	chassis.update_tires(state, 0.0, false, car, null, 1.0 / 60.0)

	_expect(state.ground_contact_count == 4, "four runtime probes detect a flat surface within suspension travel")
	_expect(state.ground_normal.distance_to(Vector3.UP) < 0.001, "flat surface produces an upward averaged normal")
	_expect(is_equal_approx(state.surface_grip_multiplier, 0.62), "runtime probes read the contacted typed surface grip")
	_expect(state.suspension_acceleration > 0.0, "runtime probes calculate suspension support acceleration")

	car.global_position.y = 0.10
	await get_tree().physics_frame
	chassis.update_tires(state, 0.0, false, car, null, 1.0 / 60.0)
	_expect(state.ground_contact_count == 0, "surface beyond suspension travel does not produce tire contact")
	_expect(is_zero_approx(state.suspension_acceleration), "surface beyond suspension travel produces no spring support")

	car.global_position.y = 3.0
	await get_tree().physics_frame
	chassis.update_tires(state, 0.0, false, car, null, 1.0 / 60.0)
	_expect(state.ground_contact_count == 0, "suspension probes report no contact when the car is airborne")
	_expect(is_equal_approx(state.surface_grip_multiplier, 1.0), "airborne state resets transient surface grip")

	car.queue_free()
	floor_body.queue_free()
	await get_tree().process_frame


func _test_partial_contact_support_scaling() -> void:
	var config: CarDriveConfig = _build_contact_config()
	var chassis: CarChassisController = CarChassisController.new()
	chassis.configure(config)
	var car: CharacterBody3D = _create_probe_car("PartialContactCar")
	var state: CarRuntimeState = CarRuntimeState.new()
	var probe_positions: Array[Vector3] = GroundContactModel.new().get_probe_local_positions(
		config.wheel_base,
		config.axle_track_width,
		config.suspension_probe_height
	)
	var single_probe_support: float = 0.0
	await get_tree().physics_frame

	for expected_contact_count: int in range(1, 5):
		var surfaces: Array[TrackSurfaceBody] = []
		for probe_index: int in range(expected_contact_count):
			var probe_position: Vector3 = probe_positions[probe_index]
			surfaces.append(_create_surface(
				"ProbeSurface%d_%d" % [expected_contact_count, probe_index],
				Vector3(probe_position.x, -0.1, probe_position.z),
				Vector3(0.5, 0.2, 0.5),
				1.0
			))
		await get_tree().physics_frame

		state.reset_drive_state(config.idle_rpm)
		car.velocity = Vector3.ZERO
		chassis.update_tires(state, 0.0, false, car, null, 1.0 / 60.0)
		_expect(
			state.ground_contact_count == expected_contact_count,
			"runtime suspension reports exactly %d active probe contact(s)" % expected_contact_count
		)
		_expect(
			state.ground_normal.distance_to(Vector3.UP) < 0.001,
			"%d-contact support preserves the flat averaged normal" % expected_contact_count
		)
		if expected_contact_count == 1:
			single_probe_support = state.suspension_acceleration
			_expect(single_probe_support > 0.0, "one active probe contributes positive spring support")
		else:
			_expect(
				absf(state.suspension_acceleration - single_probe_support * expected_contact_count) < 0.02,
				"spring support is the explicit sum of %d active probe forces" % expected_contact_count
			)

		for surface: TrackSurfaceBody in surfaces:
			remove_child(surface)
			surface.free()
		await get_tree().physics_frame

	car.queue_free()
	await get_tree().process_frame


func _build_contact_config() -> CarDriveConfig:
	var config: CarDriveConfig = CarDriveConfig.new()
	config.wheel_base = 2.6
	config.axle_track_width = 1.6
	config.suspension_probe_height = 0.42
	config.suspension_rest_length = 0.28
	config.suspension_travel = 0.18
	config.suspension_stiffness = 32.0
	config.suspension_damping = 5.0
	config.sanitize()
	return config


func _create_probe_car(car_name: String) -> CharacterBody3D:
	var car: CharacterBody3D = CharacterBody3D.new()
	car.name = car_name
	car.collision_layer = 1
	car.collision_mask = 1
	add_child(car)
	return car


func _create_surface(
	surface_name: String,
	position: Vector3,
	size: Vector3,
	grip_multiplier: float
) -> TrackSurfaceBody:
	var surface: TrackSurfaceBody = TrackSurfaceBody.new()
	surface.name = surface_name
	surface.position = position
	surface.collision_layer = 1
	surface.collision_mask = 1
	surface.grip_multiplier = grip_multiplier
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	surface.add_child(collision)
	add_child(surface)
	return surface


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[GROUND_CONTACT_MODEL_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[GROUND_CONTACT_MODEL_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[GROUND_CONTACT_MODEL_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[GROUND_CONTACT_MODEL_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[GROUND_CONTACT_MODEL_TEST] - %s" % failure_message)
	get_tree().quit(1)
