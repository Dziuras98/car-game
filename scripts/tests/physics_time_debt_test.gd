extends SceneTree

const TEST_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var car: PlayerCarController = PlayerCarController.new()
	car.car_specs = TEST_SPECS
	root.add_child(car)
	car.set_physics_process(false)
	car.set_external_input_enabled(true)
	car.set_external_drive_inputs(0.5, 0.0, 0.0)

	car._physics_process(0.25)
	_expect(absf(car.get_physics_time_debt() - 0.15) < 0.002, "a 250 ms hitch retains the unsimulated 150 ms")

	car._physics_process(0.01)
	_expect(absf(car.get_physics_time_debt() - 0.06) < 0.002, "subsequent updates consume retained time within the frame budget")

	car._physics_process(0.01)
	_expect(is_zero_approx(car.get_physics_time_debt()), "retained time drains instead of being permanently discarded")

	car._physics_process(2.0)
	_expect(car.get_physics_time_debt() <= PlayerCarController.MAX_PHYSICS_TIME_DEBT, "time debt remains bounded after an extreme stall")
	car._reset_to_start()
	_expect(is_zero_approx(car.get_physics_time_debt()), "vehicle reset clears stale time debt")

	car.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[PHYSICS_TIME_DEBT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[PHYSICS_TIME_DEBT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PHYSICS_TIME_DEBT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[PHYSICS_TIME_DEBT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[PHYSICS_TIME_DEBT_TEST] - %s" % failure_message)
	quit(1)
