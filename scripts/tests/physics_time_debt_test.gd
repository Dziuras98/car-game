extends SceneTree

const TEST_SCENE: PackedScene = preload("res://scenes/cars/370zat.tscn")
const TEST_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")
const TEST_FORWARD_SPEED: float = 12.0
const OVERSIZED_DELTA: float = 0.25

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var oversized_car: PlayerCarController = _create_test_car(Vector3.ZERO)
	var reference_car: PlayerCarController = _create_test_car(Vector3(10.0, 0.0, 0.0))
	_expect(oversized_car != null and reference_car != null, "physics-step fixtures instantiate")
	if oversized_car == null or reference_car == null:
		_finish()
		return

	root.add_child(oversized_car)
	root.add_child(reference_car)
	oversized_car.set_physics_process(false)
	reference_car.set_physics_process(false)
	await physics_frame

	var physics_step: float = maxf(oversized_car.get_physics_process_delta_time(), 1.0 / 240.0)
	var oversized_start: Vector3 = oversized_car.global_position
	var reference_start: Vector3 = reference_car.global_position
	oversized_car._runtime_state.forward_speed = TEST_FORWARD_SPEED
	reference_car._runtime_state.forward_speed = TEST_FORWARD_SPEED

	oversized_car._physics_process(OVERSIZED_DELTA)
	reference_car._physics_process(physics_step)

	var oversized_distance: float = _horizontal_distance(oversized_start, oversized_car.global_position)
	var reference_distance: float = _horizontal_distance(reference_start, reference_car.global_position)
	var expected_distance: float = TEST_FORWARD_SPEED * physics_step
	_expect(
		absf(oversized_distance - expected_distance) < 0.02,
		"an oversized callback delta performs exactly one CharacterBody3D motion step"
	)
	_expect(
		absf(reference_distance - expected_distance) < 0.02,
		"a normal callback delta performs exactly one CharacterBody3D motion step"
	)
	_expect(
		absf(oversized_distance - reference_distance) < 0.005,
		"oversized callback input cannot replay additional spatial motion"
	)
	_expect(
		absf(oversized_car.get_forward_speed() - reference_car.get_forward_speed()) < 0.005,
		"oversized callback input advances the vehicle model by only the active physics tick"
	)

	oversized_car._reset_to_start()
	_expect(
		oversized_car.global_position.distance_to(oversized_start) < 0.001,
		"vehicle reset restores the captured start transform without retained simulation time"
	)
	_expect(
		is_zero_approx(oversized_car.get_forward_speed()),
		"vehicle reset clears the active motion state"
	)

	oversized_car.queue_free()
	reference_car.queue_free()
	await process_frame
	_finish()


func _create_test_car(start_position: Vector3) -> PlayerCarController:
	var car: PlayerCarController = TEST_SCENE.instantiate() as PlayerCarController
	if car == null:
		return null
	var specs: CarSpecs = TEST_SPECS.duplicate(true) as CarSpecs
	specs.coast_deceleration = 0.0
	specs.engine_brake_force = 0.0
	specs.drag_coefficient = 0.0
	specs.rolling_resistance_coefficient = 0.0
	car.car_specs = specs
	car.position = start_position
	car.set_external_input_enabled(true)
	car.set_external_drive_inputs(0.0, 0.0, 0.0)
	return car


func _horizontal_distance(from_position: Vector3, to_position: Vector3) -> float:
	return Vector2(
		to_position.x - from_position.x,
		to_position.z - from_position.z
	).length()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[PHYSICS_STEP_INTEGRITY_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[PHYSICS_STEP_INTEGRITY_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PHYSICS_STEP_INTEGRITY_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[PHYSICS_STEP_INTEGRITY_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[PHYSICS_STEP_INTEGRITY_TEST] - %s" % failure_message)
	quit(1)
