extends SceneTree

const DEFAULT_CAR_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_6mt_specs.tres")

const REMOVED_CONTROLLER_TUNING_PROPERTIES: Array[StringName] = [
	&"acceleration",
	&"brake_deceleration",
	&"max_forward_speed",
	&"idle_rpm",
	&"redline_rpm",
	&"manual_transmission_enabled",
	&"automatic_transmission_enabled",
	&"gear_ratios",
	&"vehicle_mass",
	&"lateral_grip",
	&"gravity",
]

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run()
	_finish()


func _run() -> void:
	_test_specs_config_mapping()
	_test_controller_exposes_only_specs_tuning()
	_test_transmission_config_helpers()
	_test_runtime_state_reset()
	_test_gear_text()


func _test_specs_config_mapping() -> void:
	var specs_config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(DEFAULT_CAR_SPECS)
	_expect(specs_config != null, "config builder accepts CarSpecs")
	if specs_config == null:
		return

	_expect(not specs_config.gear_ratios.is_empty(), "config built from specs has gear ratios")
	_expect(is_equal_approx(specs_config.max_forward_speed, DEFAULT_CAR_SPECS.max_forward_speed), "config copies max speed from CarSpecs")
	_expect(is_equal_approx(specs_config.idle_rpm, DEFAULT_CAR_SPECS.idle_rpm), "config copies idle RPM from CarSpecs")
	_expect(specs_config.is_manual_transmission() == DEFAULT_CAR_SPECS.is_manual_transmission(), "config copies transmission mode from CarSpecs")


func _test_controller_exposes_only_specs_tuning() -> void:
	var controller: PlayerCarController = PlayerCarController.new()
	var property_names: Dictionary = {}
	for property_info: Dictionary in controller.get_property_list():
		property_names[StringName(property_info.get("name", ""))] = true

	_expect(property_names.has(&"car_specs"), "controller exposes CarSpecs resource")
	for removed_property: StringName in REMOVED_CONTROLLER_TUNING_PROPERTIES:
		_expect(not property_names.has(removed_property), "controller no longer exports legacy tuning property %s" % str(removed_property))

	controller.free()


func _test_transmission_config_helpers() -> void:
	var transmission_config: CarDriveConfig = CarDriveConfig.new()
	transmission_config.transmission_type = CarSpecs.TransmissionType.MANUAL
	_expect(transmission_config.uses_geared_transmission(), "manual config uses geared transmission")
	transmission_config.transmission_type = CarSpecs.TransmissionType.AUTOMATIC
	_expect(transmission_config.uses_geared_transmission(), "automatic config uses geared transmission")
	transmission_config.transmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE
	_expect(not transmission_config.uses_geared_transmission(), "non-transmission config does not use geared transmission")


func _test_runtime_state_reset() -> void:
	var runtime_state: CarRuntimeState = CarRuntimeState.new()
	runtime_state.forward_speed = 12.0
	runtime_state.lateral_speed = 3.0
	runtime_state.engine_rpm = 4300.0
	runtime_state.current_gear = 4
	runtime_state.shift_timer = 0.2
	runtime_state.throttle_input = 0.7
	runtime_state.brake_input = 0.4
	runtime_state.tire_slip_intensity = 0.8
	runtime_state.reset_drive_state(850.0)
	_expect(is_equal_approx(runtime_state.forward_speed, 0.0), "reset clears forward speed")
	_expect(is_equal_approx(runtime_state.lateral_speed, 0.0), "reset clears lateral speed")
	_expect(is_equal_approx(runtime_state.engine_rpm, 850.0), "reset applies requested idle rpm")
	_expect(runtime_state.current_gear == 1, "reset returns to first gear")
	_expect(is_equal_approx(runtime_state.shift_timer, 0.0), "reset clears shift timer")
	_expect(is_equal_approx(runtime_state.throttle_input, 0.0), "reset clears throttle input")
	_expect(is_equal_approx(runtime_state.brake_input, 0.0), "reset clears brake input")
	_expect(is_equal_approx(runtime_state.tire_slip_intensity, 0.0), "reset clears tire slip")


func _test_gear_text() -> void:
	_expect(_manual_gear_text(-1) == "R", "manual reverse text is R")
	_expect(_manual_gear_text(0) == "N", "manual neutral text is N")
	_expect(_manual_gear_text(1) == "1", "manual first gear text is 1")
	_expect(_manual_gear_text(2) == "2", "manual second gear text is 2")
	_expect(_automatic_gear_text(-1) == "R", "automatic reverse text is R")
	_expect(_automatic_gear_text(1) == "D1", "automatic first drive text is D1")
	_expect(_automatic_gear_text(2) == "D2", "automatic second drive text is D2")


func _manual_gear_text(gear: int) -> String:
	var config: CarDriveConfig = CarDriveConfig.new()
	config.transmission_type = CarSpecs.TransmissionType.MANUAL
	var state: CarRuntimeState = CarRuntimeState.new()
	state.current_gear = gear
	var powertrain: CarPowertrainController = CarPowertrainController.new()
	powertrain.configure(config)
	return powertrain.get_gear_text(state)


func _automatic_gear_text(gear: int) -> String:
	var config: CarDriveConfig = CarDriveConfig.new()
	config.transmission_type = CarSpecs.TransmissionType.AUTOMATIC
	var state: CarRuntimeState = CarRuntimeState.new()
	state.current_gear = gear
	var powertrain: CarPowertrainController = CarPowertrainController.new()
	powertrain.configure(config)
	return powertrain.get_gear_text(state)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CAR_RUNTIME_CONFIG_TEST][PASS] %s" % message)
		return

	_failures.append(message)
	push_error("[CAR_RUNTIME_CONFIG_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CAR_RUNTIME_CONFIG_TEST] Passed: %d checks" % _checks)
		quit(0)
		return

	push_error("[CAR_RUNTIME_CONFIG_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CAR_RUNTIME_CONFIG_TEST] - %s" % failure_message)
	quit(1)
