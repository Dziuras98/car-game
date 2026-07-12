extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var floor_body: StaticBody3D = StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 1
	floor_body.position = Vector3(0.0, -0.1, 0.0)
	var floor_collision: CollisionShape3D = CollisionShape3D.new()
	var floor_shape: BoxShape3D = BoxShape3D.new()
	floor_shape.size = Vector3(20.0, 0.2, 20.0)
	floor_collision.shape = floor_shape
	floor_body.add_child(floor_collision)
	root.add_child(floor_body)

	var car: CharacterBody3D = CharacterBody3D.new()
	car.collision_layer = 1
	car.collision_mask = 1
	root.add_child(car)
	await physics_frame

	var config: CarDriveConfig = CarDriveConfig.new()
	config.wheel_base = 2.6
	config.front_axle_track_width = 1.5
	config.rear_axle_track_width = 1.7
	config.suspension_probe_height = 0.42
	config.suspension_rest_length = 0.28
	config.suspension_travel = 0.18
	config.suspension_stiffness = 32.0
	config.suspension_damping = 5.0
	config.ground_probe_collision_mask = 1
	config.sanitize()

	var chassis: CarChassisController = CarChassisController.new()
	chassis.configure(config)
	var state: CarRuntimeState = CarRuntimeState.new()
	state.reset_drive_state(config.idle_rpm)
	chassis.sample_ground_contact(state, car)
	_expect(state.ground_contact_count == 4, "plain StaticBody3D surfaces provide suspension contact")
	_expect(is_equal_approx(state.surface_grip_multiplier, 1.0), "plain collision bodies use neutral default grip")

	floor_body.set_meta("surface_grip_multiplier", 0.42)
	chassis.sample_ground_contact(state, car)
	_expect(is_equal_approx(state.surface_grip_multiplier, 0.42), "generic collision bodies can override grip through metadata")
	_expect(state.suspension_acceleration > 0.0, "generic ground contact still provides spring support")

	car.queue_free()
	floor_body.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[GENERIC_GROUND_CONTACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[GENERIC_GROUND_CONTACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[GENERIC_GROUND_CONTACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[GENERIC_GROUND_CONTACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[GENERIC_GROUND_CONTACT_TEST] - %s" % failure_message)
	quit(1)
