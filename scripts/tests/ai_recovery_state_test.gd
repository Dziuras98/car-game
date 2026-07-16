extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


class RecoveryCar:
	extends PlayerCarController

	var simulated_speed_kmh: float = 0.0
	var simulated_gear: int = 1
	var last_throttle: float = 0.0
	var last_brake: float = 0.0
	var last_steering: float = 0.0

	func get_speed_kmh() -> float:
		return absf(simulated_speed_kmh)

	func get_forward_speed() -> float:
		return simulated_speed_kmh / 3.6

	func get_current_gear() -> int:
		return simulated_gear

	func set_external_drive_inputs(
		throttle: float,
		brake: float,
		steering: float,
		_handbrake_active: bool = false
	) -> void:
		last_throttle = throttle
		last_brake = brake
		last_steering = steering


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_recovery_requires_stop_reverse_distance_and_forward_return()
	_test_reverse_motion_is_stopped_without_requesting_more_reverse()
	_finish()


func _create_driver(car: RecoveryCar) -> AiRaceDriver:
	var profile: AiDriverProfile = AiDriverProfile.new()
	profile.recovery_stop_speed_kmh = 1.0
	profile.reverse_engage_timeout_seconds = 2.0
	profile.reverse_recovery_distance = 3.0
	profile.reverse_recovery_seconds = 3.0
	var driver: AiRaceDriver = AiRaceDriver.new()
	driver._car = car
	driver._profile = profile
	driver._last_steering = 0.4
	return driver


func _test_recovery_requires_stop_reverse_distance_and_forward_return() -> void:
	var car: RecoveryCar = RecoveryCar.new()
	car.car_specs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")
	root.add_child(car)
	car.set_physics_process(false)
	var driver: AiRaceDriver = _create_driver(car)

	car.simulated_speed_kmh = 8.0
	driver._begin_recovery()
	_expect(
		driver.get_driver_state() == AiRaceDriver.DriverState.RECOVERY_BRAKE_TO_STOP,
		"recovery starts by braking to a stop"
	)
	driver._update_recovery(0.1)
	_expect(
		driver.get_driver_state() == AiRaceDriver.DriverState.RECOVERY_BRAKE_TO_STOP,
		"recovery does not request reverse while the car is still moving forward"
	)
	_expect(is_zero_approx(car.last_throttle) and car.last_brake > 0.0, "forward motion uses the service-brake input")

	car.simulated_speed_kmh = 0.5
	driver._update_recovery(0.1)
	_expect(
		driver.get_driver_state() == AiRaceDriver.DriverState.RECOVERY_ENGAGE_REVERSE,
		"near-zero speed advances recovery to reverse engagement"
	)

	car.simulated_speed_kmh = 0.0
	car.simulated_gear = 1
	driver._update_recovery(0.2)
	_expect(
		driver.get_driver_state() == AiRaceDriver.DriverState.RECOVERY_ENGAGE_REVERSE,
		"recovery waits for the gearbox to confirm reverse"
	)

	car.simulated_speed_kmh = -1.0
	car.simulated_gear = -1
	driver._update_recovery(0.1)
	_expect(
		driver.get_driver_state() == AiRaceDriver.DriverState.RECOVERY_REVERSE_UNTIL_CLEAR,
		"confirmed reverse motion starts displacement tracking"
	)
	var recovery_origin: Vector3 = car.global_position
	car.global_position = recovery_origin + Vector3(0.0, 0.0, 2.0)
	driver._update_recovery(0.1)
	_expect(
		driver.get_driver_state() == AiRaceDriver.DriverState.RECOVERY_REVERSE_UNTIL_CLEAR,
		"recovery does not leave reverse before the required displacement"
	)

	car.global_position = recovery_origin + Vector3(0.0, 0.0, 3.5)
	driver._update_recovery(0.1)
	_expect(
		driver.get_driver_state() == AiRaceDriver.DriverState.RECOVERY_RETURN_TO_FORWARD,
		"required reverse displacement starts an explicit return-to-forward phase"
	)

	car.simulated_speed_kmh = -0.8
	car.simulated_gear = -1
	driver._update_recovery(0.1)
	_expect(car.last_throttle > 0.0 and is_zero_approx(car.last_brake), "return-to-forward uses throttle to stop reverse motion")
	_expect(
		driver.get_driver_state() == AiRaceDriver.DriverState.RECOVERY_RETURN_TO_FORWARD,
		"recovery waits until the gearbox confirms a forward gear"
	)

	car.simulated_speed_kmh = 0.0
	car.simulated_gear = 1
	driver._update_recovery(0.1)
	_expect(
		driver.get_driver_state() == AiRaceDriver.DriverState.FOLLOW_LINE,
		"recovery finishes only after forward gear is restored"
	)

	driver.free()
	root.remove_child(car)
	car.free()


func _test_reverse_motion_is_stopped_without_requesting_more_reverse() -> void:
	var car: RecoveryCar = RecoveryCar.new()
	car.car_specs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")
	root.add_child(car)
	car.set_physics_process(false)
	var driver: AiRaceDriver = _create_driver(car)
	car.simulated_speed_kmh = -6.0
	car.simulated_gear = -1
	driver._begin_recovery()
	driver._update_recovery(0.1)
	_expect(
		car.last_throttle > 0.0 and is_zero_approx(car.last_brake),
		"brake-to-stop phase does not map the brake input to additional reverse acceleration"
	)
	_expect(
		driver.get_driver_state() == AiRaceDriver.DriverState.RECOVERY_BRAKE_TO_STOP,
		"reverse motion remains in the bounded stop phase until speed is safe"
	)
	driver.free()
	root.remove_child(car)
	car.free()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[AI_RECOVERY_STATE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[AI_RECOVERY_STATE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[AI_RECOVERY_STATE_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[AI_RECOVERY_STATE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[AI_RECOVERY_STATE_TEST] - %s" % failure_message)
	quit(1)
