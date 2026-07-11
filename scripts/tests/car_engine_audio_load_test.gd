extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_manual_neutral_audio_load()
	_test_manual_shift_audio_load()
	_test_automatic_shift_audio_load()
	_test_automatic_reverse_audio_load()
	_finish()


func _test_manual_neutral_audio_load() -> void:
	var car: PlayerCarController = _build_car(CarSpecs.TransmissionType.MANUAL)
	car._runtime_state.current_gear = 0
	car._runtime_state.clutch_engagement = 0.0
	car._runtime_state.shift_timer = 0.0
	car._runtime_state.set_drive_input_snapshot(1.0, 0.0)

	_expect(is_equal_approx(car.get_engine_load(), 1.0), "full throttle produces full audio load in manual neutral")
	_expect(is_zero_approx(car.get_drivetrain_load()), "manual neutral still transmits no drivetrain load")
	car.free()


func _test_manual_shift_audio_load() -> void:
	var car: PlayerCarController = _build_car(CarSpecs.TransmissionType.MANUAL)
	car._runtime_state.current_gear = 2
	car._runtime_state.clutch_engagement = 0.0
	car._runtime_state.shift_timer = 0.20
	car._runtime_state.set_drive_input_snapshot(0.84, 0.0)

	_expect(is_equal_approx(car.get_engine_load(), 0.84), "manual shift keeps audio load tied to throttle")
	_expect(is_zero_approx(car.get_drivetrain_load()), "manual shift continues to cut wheel-side load")
	car.free()


func _test_automatic_shift_audio_load() -> void:
	var car: PlayerCarController = _build_car(CarSpecs.TransmissionType.AUTOMATIC)
	car._runtime_state.current_gear = 3
	car._runtime_state.clutch_engagement = 1.0
	car._runtime_state.shift_timer = 0.18
	car._runtime_state.set_drive_input_snapshot(0.92, 0.0)

	_expect(is_equal_approx(car.get_engine_load(), 0.92), "automatic upshift does not attenuate engine audio demand")
	_expect(is_zero_approx(car.get_drivetrain_load()), "automatic shift timer still cuts transmitted drivetrain load")
	car.free()


func _test_automatic_reverse_audio_load() -> void:
	var car: PlayerCarController = _build_car(CarSpecs.TransmissionType.AUTOMATIC)
	car._runtime_state.current_gear = -1
	car._runtime_state.clutch_engagement = 1.0
	car._runtime_state.shift_timer = 0.16
	car._runtime_state.set_drive_input_snapshot(0.0, 0.74)

	_expect(is_equal_approx(car.get_engine_load(), 0.74), "automatic reverse uses the reverse accelerator control for audio load")
	_expect(is_zero_approx(car.get_drivetrain_load()), "reverse selection delay still cuts transmitted drivetrain load")

	car._runtime_state.shift_timer = 0.0
	_expect(is_equal_approx(car.get_engine_load(), 0.74), "automatic reverse audio load remains stable after engagement")
	_expect(is_equal_approx(car.get_drivetrain_load(), 0.74), "automatic reverse drivetrain load resumes after engagement")
	car.free()


func _build_car(transmission_type: int) -> PlayerCarController:
	var car := PlayerCarController.new()
	var config := CarDriveConfig.new()
	config.transmission_type = transmission_type
	config.sanitize()
	car._drive_config = config
	car._powertrain_controller.configure(config)
	car._runtime_state.reset_drive_state(config.idle_rpm)
	car._powertrain_controller.reset(car._runtime_state)
	return car


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CAR_ENGINE_AUDIO_LOAD_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CAR_ENGINE_AUDIO_LOAD_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CAR_ENGINE_AUDIO_LOAD_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[CAR_ENGINE_AUDIO_LOAD_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CAR_ENGINE_AUDIO_LOAD_TEST] - %s" % failure_message)
	quit(1)
