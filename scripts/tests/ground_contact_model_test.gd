extends Node

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_ground_contact_math()
	await _test_runtime_ground_probe()
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
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.name = "TestSurface"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 1
	floor_body.set_meta("surface_grip_multiplier", 0.62)
	var floor_shape: CollisionShape3D = CollisionShape3D.new()
	var floor_box: BoxShape3D = BoxShape3D.new()
	floor_box.size = Vector3(20.0, 0.2, 20.0)
	floor_shape.shape = floor_box
	floor_shape.position.y = -0.1
	floor_body.add_child(floor_shape)
	add_child(floor_body)

	var car: CharacterBody3D = CharacterBody3D.new()
	car.name = "ProbeCar"
	car.collision_layer = 1
	car.collision_mask = 1
	add_child(car)
	await get_tree().physics_frame

	var config: CarDriveConfig = CarDriveConfig.new()
	config.wheel_base = 2.6
	config.axle_track_width = 1.6
	config.suspension_probe_height = 0.42
	config.suspension_rest_length = 0.28
	config.suspension_travel = 0.18
	config.suspension_stiffness = 32.0
	config.suspension_damping = 5.0
	config.sanitize()
	var chassis: CarChassisController = CarChassisController.new()
	chassis.configure(config)
	var state: CarRuntimeState = CarRuntimeState.new()
	state.reset_drive_state(config.idle_rpm)
	chassis.update_tires(state, 0.0, false, car, null, 1.0 / 60.0)

	_expect(state.ground_contact_count == 4, "four runtime probes detect a flat surface")
	_expect(state.ground_normal.distance_to(Vector3.UP) < 0.001, "flat surface produces an upward averaged normal")
	_expect(is_equal_approx(state.surface_grip_multiplier, 0.62), "runtime probes read the contacted surface grip metadata")
	_expect(state.suspension_acceleration > 0.0, "runtime probes calculate suspension support acceleration")

	car.global_position.y = 3.0
	await get_tree().physics_frame
	chassis.update_tires(state, 0.0, false, car, null, 1.0 / 60.0)
	_expect(state.ground_contact_count == 0, "suspension probes report no contact when the car is airborne")
	_expect(is_equal_approx(state.surface_grip_multiplier, 1.0), "airborne state resets transient surface grip")

	car.queue_free()
	floor_body.queue_free()
	await get_tree().process_frame


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
