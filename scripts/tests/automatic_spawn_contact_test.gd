extends SceneTree

const TRACK_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")
const CAR_SCENE: PackedScene = preload("res://scenes/cars/370z.tscn")
const AUTOMATIC_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var track: GeneratedTrack = TRACK_SCENE.instantiate() as GeneratedTrack
	root.add_child(track)
	await process_frame
	await physics_frame
	_expect(track.has_committed_generation(), "simple oval commits before the automatic spawn test")

	var car: PlayerCarController = CAR_SCENE.instantiate() as PlayerCarController
	car.car_specs = AUTOMATIC_SPECS
	car.global_transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 1.0, 0.0))
	root.add_child(car)
	car.capture_current_transform_as_start()
	car.set_player_input_enabled(false)
	car.set_external_input_enabled(true)
	car.set_external_drive_inputs(1.0, 0.0, 0.0)
	for _frame_index: int in range(90):
		await physics_frame

	var telemetry: CarTelemetrySnapshot = car.get_telemetry_snapshot()
	print(
		"[AUTOMATIC_SPAWN_CONTACT_TEST] speed=%.3f gear=%d throttle=%.2f brake=%.2f contacts=%d position=%s"
		% [
			telemetry.get_forward_speed(),
			telemetry.get_current_gear(),
			telemetry.get_throttle_input(),
			telemetry.get_brake_input(),
			telemetry.get_ground_contact_count(),
			str(car.global_position),
		]
	)
	_expect(telemetry.get_current_gear() >= 1, "automatic car remains in a forward gear after spawn")
	_expect(telemetry.get_throttle_input() > 0.9, "automatic car receives sustained external throttle")
	_expect(telemetry.get_ground_contact_count() > 0, "automatic car retains ground contact at the start seam")
	_expect(telemetry.get_forward_speed() > 0.5, "automatic car accelerates from the default track spawn")

	car.queue_free()
	track.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[AUTOMATIC_SPAWN_CONTACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[AUTOMATIC_SPAWN_CONTACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[AUTOMATIC_SPAWN_CONTACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[AUTOMATIC_SPAWN_CONTACT_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[AUTOMATIC_SPAWN_CONTACT_TEST] - %s" % failure_message)
	quit(1)
