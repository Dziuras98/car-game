extends SceneTree

const MANUAL_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_6mt_specs.tres")
const AUTOMATIC_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")
const CVT_SPECS: CarSpecs = preload("res://resources/cars/fiat/punto_176_1995/specs/punto_60_cvt_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run()
	_finish()


func _run() -> void:
	_expect(MANUAL_SPECS.validate().is_empty(), "manual production specs pass comprehensive validation")
	_expect(AUTOMATIC_SPECS.validate().is_empty(), "automatic production specs pass comprehensive validation")
	_expect(CVT_SPECS.validate().is_empty(), "CVT production specs pass comprehensive validation")
	_expect(MANUAL_SPECS.is_manual_transmission() and not MANUAL_SPECS.is_automatic_transmission() and not MANUAL_SPECS.is_cvt_transmission(), "manual specs expose one exclusive transmission mode")
	_expect(AUTOMATIC_SPECS.is_automatic_transmission() and not AUTOMATIC_SPECS.is_manual_transmission() and not AUTOMATIC_SPECS.is_cvt_transmission(), "automatic specs expose one exclusive transmission mode")
	_expect(CVT_SPECS.is_cvt_transmission() and not CVT_SPECS.is_manual_transmission() and not CVT_SPECS.is_automatic_transmission(), "CVT specs expose one exclusive transmission mode")
	_expect(CVT_SPECS.uses_geared_transmission() and not CVT_SPECS.uses_discrete_gears(), "CVT is powered without declaring fake discrete gears")

	var invalid_transmission: CarSpecs = MANUAL_SPECS.duplicate(true) as CarSpecs
	invalid_transmission.transmission_type = 999
	_expect(_contains_error(invalid_transmission.validate(), "transmission_type"), "invalid transmission enum values are rejected")

	var compatibility_selection: CarSpecs = MANUAL_SPECS.duplicate(true) as CarSpecs
	compatibility_selection.transmission_type = CarSpecs.TransmissionType.AUTOMATIC
	_expect(compatibility_selection.is_automatic_transmission(), "enum assignment selects automatic mode")
	_expect(not compatibility_selection.is_manual_transmission(), "enum state cannot expose both transmission modes")

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
	invalid_tires.longitudinal_grip_coefficient = 0.0
	invalid_tires.longitudinal_peak_slip_ratio = 0.0
	invalid_tires.longitudinal_slide_grip_multiplier = 1.1
	invalid_tires.skid_mark_min_slip = 1.1
	var tire_errors: PackedStringArray = invalid_tires.validate()
	_expect(_contains_error(tire_errors, "handbrake_lateral_grip_multiplier"), "negative handbrake grip multiplier is rejected")
	_expect(_contains_error(tire_errors, "longitudinal_grip_coefficient"), "non-positive longitudinal grip coefficient is rejected")
	_expect(_contains_error(tire_errors, "longitudinal_peak_slip_ratio"), "non-positive peak longitudinal slip ratio is rejected")
	_expect(_contains_error(tire_errors, "longitudinal_slide_grip_multiplier"), "sliding longitudinal grip above the peak is rejected")
	_expect(_contains_error(tire_errors, "skid_mark_min_slip"), "slip threshold above one is rejected")

	var invalid_automatic: CarSpecs = AUTOMATIC_SPECS.duplicate(true) as CarSpecs
	invalid_automatic.automatic_downshift_rpm = invalid_automatic.automatic_upshift_rpm
	invalid_automatic.torque_converter_coupling_rpm = invalid_automatic.torque_converter_stall_rpm - 1.0
	_expect(_contains_error(invalid_automatic.validate(), "automatic_downshift_rpm"), "overlapping automatic shift thresholds are rejected")
	_expect(_contains_error(invalid_automatic.validate(), "torque_converter_coupling_rpm"), "invalid torque-converter RPM ordering is rejected")

	var invalid_cvt: CarSpecs = CVT_SPECS.duplicate(true) as CarSpecs
	invalid_cvt.cvt_max_ratio = 0.0
	invalid_cvt.cvt_target_rpm_max = invalid_cvt.cvt_target_rpm_min - 1.0
	invalid_cvt.cvt_clutch_full_rpm = invalid_cvt.cvt_clutch_engagement_rpm
	var cvt_errors: PackedStringArray = invalid_cvt.validate()
	_expect(_contains_error(cvt_errors, "cvt_max_ratio"), "CVT shortest ratio must be positive")
	_expect(_contains_error(cvt_errors, "cvt_target_rpm_max"), "CVT target RPM ordering is validated")
	_expect(_contains_error(cvt_errors, "cvt_clutch_full_rpm"), "CVT clutch RPM ordering is validated")


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
