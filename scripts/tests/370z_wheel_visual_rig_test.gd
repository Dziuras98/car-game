extends SceneTree

const VISUAL_SCENE: PackedScene = preload("res://scenes/cars/370z_z34_visuals.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var visual := VISUAL_SCENE.instantiate() as Standard370ZVisualController
	_expect(visual != null, "the standard visual scene uses the model-specific wheel controller")
	if visual == null:
		_finish()
		return

	var front_left_brake := visual.get_node_or_null(Standard370ZVisualController.FRONT_LEFT_BRAKE) as Node3D
	var front_left_disk := visual.get_node_or_null(Standard370ZVisualController.FRONT_LEFT_DISK) as Node3D
	var front_left_tyre := visual.get_node_or_null(Standard370ZVisualController.FRONT_LEFT_TYRE) as Node3D
	var rear_left_brake := visual.get_node_or_null(Standard370ZVisualController.REAR_LEFT_BRAKE) as Node3D
	var rear_left_disk := visual.get_node_or_null(Standard370ZVisualController.REAR_LEFT_DISK) as Node3D
	var imported_root := visual.get_node_or_null(Standard370ZVisualController.IMPORTED_ROOT_PATH) as Node3D
	_expect(front_left_brake != null, "the front-left brake caliper exists before rigging")
	_expect(front_left_disk != null, "the front-left brake disc exists before rigging")
	_expect(front_left_tyre != null, "the front-left tyre exists before rigging")
	_expect(rear_left_brake != null, "the rear-left brake caliper exists before rigging")
	_expect(rear_left_disk != null, "the rear-left brake disc exists before rigging")
	_expect(imported_root != null, "the imported model root exists")

	root.add_child(visual)
	await process_frame

	_expect(visual.get_detailed_wheel_binding_count() == 4, "the detailed model exposes exactly four logical wheel bindings")
	_expect(visual.get_low_detail_wheel_binding_count() == 4, "the low-detail model retains exactly four wheel nodes")
	_expect(visual.get_registered_wheel_count() == 4, "the standard controller reports four wheels")

	var front_left_steering: Node3D = visual.get_detailed_wheel_steering_pivot(&"front_left")
	var front_left_spin: Node3D = visual.get_detailed_wheel_spin_pivot(&"front_left")
	var front_right_steering: Node3D = visual.get_detailed_wheel_steering_pivot(&"front_right")
	var front_right_spin: Node3D = visual.get_detailed_wheel_spin_pivot(&"front_right")
	var rear_left_steering: Node3D = visual.get_detailed_wheel_steering_pivot(&"rear_left")
	var rear_left_spin: Node3D = visual.get_detailed_wheel_spin_pivot(&"rear_left")
	var rear_right_steering: Node3D = visual.get_detailed_wheel_steering_pivot(&"rear_right")
	var rear_right_spin: Node3D = visual.get_detailed_wheel_spin_pivot(&"rear_right")
	_expect(front_left_steering != null and front_left_spin != null, "the front-left wheel has separate steering and spin pivots")
	_expect(front_right_steering != null and front_right_spin != null, "the front-right wheel has separate steering and spin pivots")
	_expect(rear_left_steering != null and rear_left_spin != null, "the rear-left wheel has a dedicated spin assembly")
	_expect(rear_right_steering != null and rear_right_spin != null, "the rear-right wheel has a dedicated spin assembly")

	if front_left_steering != null and front_left_spin != null:
		_expect(front_left_brake != null and front_left_brake.get_parent() == front_left_steering, "the front brake caliper steers but is outside the spin pivot")
		_expect(front_left_disk != null and front_left_disk.get_parent() == front_left_spin, "the front brake disc rotates with the wheel")
		_expect(front_left_tyre != null and front_left_tyre.get_parent() == front_left_spin, "the front tyre rotates with the wheel")
	if rear_left_spin != null:
		_expect(rear_left_disk != null and rear_left_disk.get_parent() == rear_left_spin, "the rear brake disc rotates with the wheel")
	_expect(rear_left_brake != null and rear_left_brake.get_parent() == imported_root, "the rear brake caliper remains fixed to the suspension")

	var notifier: VisibleOnScreenNotifier3D = visual.get_visibility_notifier()
	_expect(notifier != null, "the wheel test can activate on-screen animation")
	if notifier != null:
		notifier.emit_signal(&"screen_entered")

	var front_brake_local_before: Transform3D = front_left_brake.transform if front_left_brake != null else Transform3D.IDENTITY
	visual.update_vehicle_visuals(0.1, 10.0, 0.5, 0.339)
	_expect(front_left_spin != null and absf(front_left_spin.rotation.x) > 0.1, "the front wheel spins around its dedicated local X axis")
	_expect(rear_left_spin != null and absf(rear_left_spin.rotation.x) > 0.1, "the rear wheel spins around its dedicated local X axis")
	_expect(front_left_steering != null and front_left_steering.rotation.y < -0.01, "positive steering input turns the front wheel in the chassis yaw direction")
	_expect(front_right_steering != null and front_right_steering.rotation.y < -0.01, "both front wheels receive the same steering angle")
	_expect(rear_left_steering != null and absf(rear_left_steering.rotation.y) < 0.001, "the rear-left wheel does not steer")
	_expect(rear_right_steering != null and absf(rear_right_steering.rotation.y) < 0.001, "the rear-right wheel does not steer")

	var front_disk_origin_after_first_update: Vector3 = front_left_disk.global_position if front_left_disk != null else Vector3.ZERO
	visual.update_vehicle_visuals(0.1, 10.0, 0.5, 0.339)
	_expect(
		front_left_brake == null or front_left_brake.transform.is_equal_approx(front_brake_local_before),
		"wheel spin does not rotate the front brake caliper"
	)
	_expect(
		front_left_disk == null or front_left_disk.global_position.distance_to(front_disk_origin_after_first_update) < 0.001,
		"wheel spin does not move the brake disc away from its axle"
	)

	visual.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[370Z_WHEEL_VISUAL_RIG_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[370Z_WHEEL_VISUAL_RIG_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[370Z_WHEEL_VISUAL_RIG_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[370Z_WHEEL_VISUAL_RIG_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[370Z_WHEEL_VISUAL_RIG_TEST] - %s" % failure_message)
	quit(1)
