extends SceneTree

const FORWARD_GEAR_COUNT: int = 3
const REDLINE_RPM: float = 6500.0
const UPSHIFT_RPM: float = 6200.0
const DOWNSHIFT_RPM: float = 2100.0
const KICKDOWN_THROTTLE: float = 0.82
const KICKDOWN_RPM: float = 5200.0
const SAFE_LOWER_GEAR_RPM: float = 6000.0

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_full_throttle_upshift_hold()
	_test_hold_release_conditions()
	_finish()


func _test_full_throttle_upshift_hold() -> void:
	var transmission: AutomaticTransmissionModel = AutomaticTransmissionModel.new()
	var requested_gear: int = _request_gear(
		transmission,
		1,
		10.0,
		REDLINE_RPM,
		1.0
	)
	_expect(requested_gear == 2, "full-throttle redline requests an upshift")

	requested_gear = _request_gear(
		transmission,
		2,
		10.1,
		4000.0,
		1.0
	)
	_expect(
		requested_gear == 2,
		"post-upshift hold blocks immediate kickdown while vehicle speed is stalled"
	)

	requested_gear = _request_gear(
		transmission,
		2,
		12.1,
		4000.0,
		1.0
	)
	_expect(
		requested_gear == 1,
		"vehicle acceleration releases the hold and restores normal kickdown"
	)


func _test_hold_release_conditions() -> void:
	var throttle_release_transmission: AutomaticTransmissionModel = AutomaticTransmissionModel.new()
	_request_gear(throttle_release_transmission, 1, 10.0, REDLINE_RPM, 1.0)
	var requested_gear: int = _request_gear(
		throttle_release_transmission,
		2,
		10.1,
		4000.0,
		0.5
	)
	_expect(requested_gear == 2, "lifting throttle clears the hold without forcing a downshift")
	requested_gear = _request_gear(
		throttle_release_transmission,
		2,
		10.1,
		4000.0,
		1.0
	)
	_expect(requested_gear == 1, "kickdown is available again after throttle is reapplied")

	var brake_release_transmission: AutomaticTransmissionModel = AutomaticTransmissionModel.new()
	_request_gear(brake_release_transmission, 1, 10.0, REDLINE_RPM, 1.0)
	requested_gear = _request_gear(
		brake_release_transmission,
		2,
		10.1,
		4000.0,
		0.0,
		1.0
	)
	_expect(requested_gear == 1, "braking bypasses the hold and permits a safe downshift")

	var low_rpm_transmission: AutomaticTransmissionModel = AutomaticTransmissionModel.new()
	_request_gear(low_rpm_transmission, 1, 10.0, REDLINE_RPM, 1.0)
	requested_gear = _request_gear(
		low_rpm_transmission,
		2,
		10.1,
		DOWNSHIFT_RPM,
		1.0
	)
	_expect(requested_gear == 1, "very low engine RPM releases the hold to prevent lugging")


func _request_gear(
	transmission: AutomaticTransmissionModel,
	current_gear: int,
	forward_speed: float,
	engine_rpm: float,
	throttle: float,
	brake: float = 0.0
) -> int:
	return transmission.get_requested_gear(
		current_gear,
		FORWARD_GEAR_COUNT,
		forward_speed,
		engine_rpm,
		throttle,
		brake,
		0.0,
		REDLINE_RPM,
		UPSHIFT_RPM,
		DOWNSHIFT_RPM,
		KICKDOWN_THROTTLE,
		KICKDOWN_RPM,
		SAFE_LOWER_GEAR_RPM
	)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[AUTOMATIC_SHIFT_HUNTING_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[AUTOMATIC_SHIFT_HUNTING_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[AUTOMATIC_SHIFT_HUNTING_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[AUTOMATIC_SHIFT_HUNTING_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[AUTOMATIC_SHIFT_HUNTING_TEST] - %s" % failure_message)
	quit(1)
