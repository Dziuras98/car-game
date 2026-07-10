extends SceneTree

const MANUAL_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_6mt_specs.tres")
const AUTOMATIC_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run()
	_finish()


func _run() -> void:
	_expect(MANUAL_SPECS.validate().is_empty(), "manual production specs pass comprehensive validation")
	_expect(AUTOMATIC_SPECS.validate().is_empty(), "automatic production specs pass comprehensive validation")

	var invalid_transmission: CarSpecs = MANUAL_SPECS.duplicate(true) as CarSpecs
	invalid_transmission.automatic_transmission_enabled = true
	_expect(_contains_error(invalid_transmission.validate(), "exactly one transmission"), "mutually enabled transmission modes are rejected")

	var invalid_rpm_order: CarSpecs = MANUAL_SPECS.duplicate(true) as CarSpecs
	invalid_rpm_order.redline_rpm = invalid_rpm_order.peak_torque_rpm - 1.0
	_expect(_contains_error(invalid_rpm_order.validate(), "redline_rpm"), "invalid engine RPM ordering is rejected")

	var invalid_efficiency: CarSpecs = MANUAL_SPECS.duplicate(true) as CarSpecs
	invalid_efficiency.drivetrain_efficiency = 1.2
	_expect(_contains_error(invalid_efficiency.validate(), "drivetrain_efficiency"), "drivetrain efficiency outside zero-to-one is rejected")

	var invalid_gears: CarSpecs = MANUAL_SPECS.duplicate(true) as CarSpecs
	invalid_gears.gear_ratios = [3.0, 0.0, -1.0]
	var gear_errors: PackedStringArray = invalid_gears.validate()
	_expect(_contains_error(gear_errors, "gear_ratios[1]"), "zero forward gear ratio is rejected")
	_expect(_contains_error(gear_errors, "gear_ratios[2]"), "negative forward gear ratio is rejected")

	var invalid_tires: CarSpecs = MANUAL_SPECS.duplicate(true) as CarSpecs
	invalid_tires.handbrake_lateral_grip_multiplier = -0.1
	invalid_tires.skid_mark_min_slip = 1.1
	_expect(_contains_error(invalid_tires.validate(), "handbrake_lateral_grip_multiplier"), "negative handbrake grip multiplier is rejected")
	_expect(_contains_error(invalid_tires.validate(), "skid_mark_min_slip"), "slip threshold above one is rejected")

	var invalid_automatic: CarSpecs = AUTOMATIC_SPECS.duplicate(true) as CarSpecs
	invalid_automatic.automatic_downshift_rpm = invalid_automatic.automatic_upshift_rpm
	invalid_automatic.torque_converter_coupling_rpm = invalid_automatic.torque_converter_stall_rpm - 1.0
	_expect(_contains_error(invalid_automatic.validate(), "automatic_downshift_rpm"), "overlapping automatic shift thresholds are rejected")
	_expect(_contains_error(invalid_automatic.validate(), "torque_converter_coupling_rpm"), "invalid torque-converter RPM ordering is rejected")


func _contains_error(errors: PackedStringArray, fragment: String) -> bool:
	for error_text: String in errors:
		if fragment in error_text:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CAR_SPECS_VALIDATION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CAR_SPECS_VALIDATION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CAR_SPECS_VALIDATION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[CAR_SPECS_VALIDATION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CAR_SPECS_VALIDATION_TEST] - %s" % failure_message)
	quit(1)
