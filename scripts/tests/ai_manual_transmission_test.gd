extends SceneTree

const MANUAL_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_6mt_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []


class ManualCar:
	extends PlayerCarController

	var simulated_speed_kmh: float = 0.0
	var simulated_gear: int = 1
	var simulated_rpm: float = 900.0
	var simulated_shift_in_progress: bool = false
	var upshift_requests: int = 0
	var downshift_requests: int = 0
	var last_throttle: float = 0.0
	var last_brake: float = 0.0
	var last_steering: float = 0.0

	func get_speed_kmh() -> float:
		return simulated_speed_kmh

	func get_current_gear() -> int:
		return simulated_gear

	func get_engine_rpm() -> float:
		return simulated_rpm

	func is_manual_transmission() -> bool:
		return true

	func get_forward_gear_count() -> int:
		return 6

	func get_idle_rpm() -> float:
		return 800.0

	func get_redline_rpm() -> float:
		return 7500.0

	func is_shift_in_progress() -> bool:
		return simulated_shift_in_progress

	func request_external_gear_up() -> void:
		upshift_requests += 1

	func request_external_gear_down() -> void:
		downshift_requests += 1

	func clear_external_gear_requests() -> void:
		pass

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
	_test_external_shift_requests_are_one_shot()
	_test_manual_shift_thresholds()
	_test_manual_recovery_sequence()
	_finish()


func _test_external_shift_requests_are_one_shot() -> void:
	var car_input: CarInput = CarInput.new()
	car_input.set_external_input_enabled(true)
	car_input.request_external_gear_up()
	car_input.read_drive_input()
	_expect(car_input.gear_up_pressed and not car_input.gear_down_pressed, "external upshift request reaches the powertrain input snapshot")
	car_input.read_drive_input()
	_expect(not car_input.gear_up_pressed and not car_input.gear_down_pressed, "external upshift request is consumed exactly once")

	car_input.request_external_gear_down()
	car_input.read_drive_input()
	_expect(car_input.gear_down_pressed and not car_input.gear_up_pressed, "external downshift request reaches the powertrain input snapshot")
	car_input.request_external_gear_up()
	car_input.set_external_input_enabled(false)
	car_input.set_external_input_enabled(true)
	car_input.read_drive_input()
	_expect(not car_input.gear_up_pressed and not car_input.gear_down_pressed, "disabling external input clears pending shift requests")


func _test_manual_shift_thresholds() -> void:
	var car: ManualCar = ManualCar.new()
	var driver: AiRaceDriver = AiRaceDriver.new()
	driver._car = car

	car.simulated_gear = 2
	car.simulated_rpm = 7000.0
	driver._update_manual_transmission(0.9, 0.0)
	_expect(car.upshift_requests == 1, "AI upshifts a manual gearbox near redline under power")

	car.simulated_shift_in_progress = true
	driver._update_manual_transmission(0.9, 0.0)
	_expect(car.upshift_requests == 1, "AI does not stack shift requests while a manual shift is in progress")

	car.simulated_shift_in_progress = false
	car.simulated_gear = 3
	car.simulated_rpm = 2000.0
	driver._update_manual_transmission(0.4, 0.0)
	_expect(car.downshift_requests == 1, "AI downshifts a manual gearbox at low engine speed")

	car.simulated_rpm = 3400.0
	driver._update_manual_transmission(0.0, 0.6)
	_expect(car.downshift_requests == 2, "AI uses an earlier manual downshift threshold while braking")

	car.simulated_gear = 6
	car.simulated_rpm = 7400.0
	driver._update_manual_transmission(1.0, 0.0)
	_expect(car.upshift_requests == 1, "AI does not request a gear above the configured manual gearbox")

	car.simulated_gear = 1
	car.simulated_rpm = 900.0
	driver._update_manual_transmission(0.0, 0.5)
	_expect(car.downshift_requests == 2, "AI does not downshift below first gear during normal driving")

	driver.free()
	car.free()


func _test_manual_recovery_sequence() -> void:
	var car: ManualCar = ManualCar.new()
	car.car_specs = MANUAL_SPECS
	root.add_child(car)
	car.set_physics_process(false)
	var profile: AiDriverProfile = AiDriverProfile.new()
	profile.recovery_stop_speed_kmh = 1.0
	profile.reverse_engage_timeout_seconds = 2.0
	profile.reverse_recovery_distance = 3.0
	profile.reverse_recovery_seconds = 3.0
	var driver: AiRaceDriver = AiRaceDriver.new()
	driver._car = car
	driver._profile = profile
	driver._last_steering = 0.4

	car.simulated_speed_kmh = 0.5
	driver._begin_recovery()
	driver._update_recovery(0.1)
	_expect(driver.get_driver_state() == AiRaceDriver.DriverState.RECOVERY_ENGAGE_REVERSE, "manual recovery first brakes to a stop")

	car.simulated_gear = 1
	driver._update_recovery(0.1)
	_expect(car.downshift_requests == 1, "manual recovery requests the first step from first gear toward reverse")
	_expect(is_zero_approx(car.last_throttle) and car.last_brake > 0.0, "manual recovery holds the service brake while selecting reverse")

	car.simulated_gear = 0
	driver._update_recovery(0.1)
	_expect(car.downshift_requests == 2, "manual recovery explicitly shifts from neutral into reverse")

	car.simulated_gear = -1
	driver._update_recovery(0.1)
	_expect(driver.get_driver_state() == AiRaceDriver.DriverState.RECOVERY_REVERSE_UNTIL_CLEAR, "manual recovery accepts a stationary confirmed reverse gear")

	car.simulated_speed_kmh = -1.0
	driver._update_recovery(0.1)
	_expect(car.last_throttle > 0.0 and is_zero_approx(car.last_brake), "manual reverse recovery uses throttle instead of the automatic brake-pedal mapping")

	car.global_position = Vector3(0.0, 0.0, 3.5)
	driver._update_recovery(0.1)
	_expect(driver.get_driver_state() == AiRaceDriver.DriverState.RECOVERY_RETURN_TO_FORWARD, "manual recovery returns toward a forward gear after clearing the obstacle")

	car.simulated_speed_kmh = -2.0
	driver._update_recovery(0.1)
	_expect(is_zero_approx(car.last_throttle) and car.last_brake > 0.0, "manual recovery brakes reverse motion before selecting a forward gear")
	_expect(car.upshift_requests == 0, "manual recovery does not shift forward while reversing too quickly")

	car.simulated_speed_kmh = 0.0
	driver._update_recovery(0.1)
	_expect(car.upshift_requests == 1, "manual recovery starts shifting from reverse toward first gear at rest")

	car.simulated_gear = 0
	driver._update_recovery(0.1)
	_expect(car.upshift_requests == 2, "manual recovery explicitly shifts from neutral into first gear")

	car.simulated_gear = 1
	driver._update_recovery(0.1)
	_expect(driver.get_driver_state() == AiRaceDriver.DriverState.FOLLOW_LINE, "manual recovery resumes racing only after first gear is confirmed")

	driver.free()
	car.free()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[AI_MANUAL_TRANSMISSION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[AI_MANUAL_TRANSMISSION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[AI_MANUAL_TRANSMISSION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[AI_MANUAL_TRANSMISSION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[AI_MANUAL_TRANSMISSION_TEST] - %s" % failure_message)
	quit(1)
