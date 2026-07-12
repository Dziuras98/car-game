extends SceneTree

const MANUAL_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_6mt_specs.tres")
const AUTOMATIC_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run()
	_finish()


func _run() -> void:
	_expect(MANUAL_SPECS.validate().is_empty(), "manual production specs satisfy relational validation")
	_expect(AUTOMATIC_SPECS.validate().is_empty(), "automatic production specs satisfy relational validation")

	var ascending_gears: CarSpecs = MANUAL_SPECS.duplicate(true) as CarSpecs
	ascending_gears.gear_ratios = [3.0, 3.2, 1.0]
	_expect(_contains_error(ascending_gears.validate(), "strictly descending"), "non-descending forward ratios are rejected")

	var impossible_top_speed: CarSpecs = MANUAL_SPECS.duplicate(true) as CarSpecs
	impossible_top_speed.max_forward_speed = 500.0
	_expect(_contains_error(impossible_top_speed.validate(), "max_forward_speed"), "top speed beyond gearing and rev limiter is rejected")

	var low_downshift: CarSpecs = AUTOMATIC_SPECS.duplicate(true) as CarSpecs
	low_downshift.automatic_downshift_rpm = low_downshift.idle_rpm - 1.0
	_expect(_contains_error(low_downshift.validate(), "automatic_downshift_rpm"), "automatic downshift below idle is rejected")

	var high_upshift: CarSpecs = AUTOMATIC_SPECS.duplicate(true) as CarSpecs
	high_upshift.automatic_upshift_rpm = high_upshift.redline_rpm + 1.0
	_expect(_contains_error(high_upshift.validate(), "automatic_upshift_rpm"), "automatic upshift above redline is rejected")

	var invalid_kickdown: CarSpecs = AUTOMATIC_SPECS.duplicate(true) as CarSpecs
	invalid_kickdown.automatic_kickdown_rpm = invalid_kickdown.redline_rpm + 1.0
	_expect(_contains_error(invalid_kickdown.validate(), "automatic_kickdown_rpm"), "kickdown RPM outside the operating range is rejected")

	var invalid_converter: CarSpecs = AUTOMATIC_SPECS.duplicate(true) as CarSpecs
	invalid_converter.torque_converter_coupling_rpm = invalid_converter.redline_rpm + 1.0
	_expect(_contains_error(invalid_converter.validate(), "torque_converter_coupling_rpm"), "converter coupling above redline is rejected")

	var zero_stiffness: CarSpecs = MANUAL_SPECS.duplicate(true) as CarSpecs
	zero_stiffness.suspension_stiffness = 0.0
	_expect(
		_contains_error(zero_stiffness.validate(), "suspension_stiffness must be finite and greater than zero"),
		"zero suspension stiffness is rejected"
	)

	var insufficient_support: CarSpecs = MANUAL_SPECS.duplicate(true) as CarSpecs
	insufficient_support.suspension_stiffness = (
		insufficient_support.gravity
		* CarSpecs.MIN_SUSPENSION_SUPPORT_RESERVE
		/ float(GroundContactModel.PROBE_COUNT)
		- 0.01
	)
	_expect(
		_contains_error(insufficient_support.validate(), "across all probes"),
		"suspension without a gravity-support reserve is rejected"
	)


func _contains_error(errors: PackedStringArray, fragment: String) -> bool:
	for error_text: String in errors:
		if fragment in error_text:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CAR_SPECS_RELATIONSHIP_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CAR_SPECS_RELATIONSHIP_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CAR_SPECS_RELATIONSHIP_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[CAR_SPECS_RELATIONSHIP_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CAR_SPECS_RELATIONSHIP_TEST] - %s" % failure_message)
	quit(1)
