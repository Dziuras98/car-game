extends SceneTree

const POWER_DIVISOR: float = 9549.2966
const POWER_TOLERANCE_KW: float = 0.02
const PEAK_RPM_TOLERANCE: float = 1.0
const CURVE_CASES: Array[Dictionary] = [
	{
		"path": "res://resources/cars/fiat/punto_176_1995/specs/176a6_1108_fire_torque_curve.tres",
		"code": "176A6.000",
		"peak_torque_nm": 85.0,
		"peak_torque_rpm": 3500.0,
		"power_peak_kw": 40.0,
		"power_peak_rpm": 5500.0,
	},
	{
		"path": "res://resources/cars/fiat/punto_176_1995/specs/176a7_1242_fire_spi_torque_curve.tres",
		"code": "176A7.000",
		"peak_torque_nm": 96.0,
		"peak_torque_rpm": 3000.0,
		"power_peak_kw": 43.0,
		"power_peak_rpm": 5500.0,
	},
	{
		"path": "res://resources/cars/fiat/punto_176_1995/specs/176a8_1242_fire_mpi_torque_curve.tres",
		"code": "176A8.000",
		"peak_torque_nm": 106.0,
		"peak_torque_rpm": 4000.0,
		"power_peak_kw": 54.0,
		"power_peak_rpm": 6000.0,
	},
	{
		"path": "res://resources/cars/fiat/punto_176_1995/specs/176a9_1581_sohc_mpi_torque_curve.tres",
		"code": "176A9.000",
		"peak_torque_nm": 127.0,
		"peak_torque_rpm": 2750.0,
		"power_peak_kw": 65.0,
		"power_peak_rpm": 5750.0,
	},
	{
		"path": "res://resources/cars/fiat/punto_176_1995/specs/176a4_1372_turbo_torque_curve.tres",
		"code": "176A4.000",
		"peak_torque_nm": 204.0,
		"peak_torque_rpm": 3000.0,
		"power_peak_kw": 98.0,
		"power_peak_rpm": 5750.0,
	},
	{
		"path": "res://resources/cars/fiat/punto_176_1995/specs/176b3_1698_d_torque_curve.tres",
		"code": "176B3.000",
		"peak_torque_nm": 98.0,
		"peak_torque_rpm": 2500.0,
		"power_peak_kw": 42.0,
		"power_peak_rpm": 4500.0,
	},
	{
		"path": "res://resources/cars/fiat/punto_176_1995/specs/176a5_1698_td_torque_curve.tres",
		"code": "176A5.000",
		"peak_torque_nm": 134.0,
		"peak_torque_rpm": 2500.0,
		"power_peak_kw": 52.0,
		"power_peak_rpm": 4500.0,
	},
]

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	for curve_case: Dictionary in CURVE_CASES:
		_test_curve(curve_case)
	_finish()


func _test_curve(curve_case: Dictionary) -> void:
	var path: String = str(curve_case["path"])
	var code: String = str(curve_case["code"])
	var peak_torque_nm: float = float(curve_case["peak_torque_nm"])
	var peak_torque_rpm: float = float(curve_case["peak_torque_rpm"])
	var power_peak_kw: float = float(curve_case["power_peak_kw"])
	var power_peak_rpm: float = float(curve_case["power_peak_rpm"])
	var curve := load(path) as EngineTorqueCurve
	_expect(curve != null, "%s curve resource loads" % code)
	if curve == null:
		return
	var validation_errors: PackedStringArray = curve.validate()
	_expect(validation_errors.is_empty(), "%s curve resource validates" % code)
	if not validation_errors.is_empty():
		return
	_expect(
		absf(curve.sample(peak_torque_rpm) - 1.0) < 0.00001,
		"%s reaches its exact torque anchor" % code
	)
	var anchor_power_kw: float = _power_kw(
		peak_torque_nm * curve.sample(power_peak_rpm),
		power_peak_rpm
	)
	_expect(
		absf(anchor_power_kw - power_peak_kw) <= POWER_TOLERANCE_KW,
		"%s reaches its exact power anchor" % code
	)
	var maximum_power_kw: float = -1.0
	var maximum_power_rpm: float = 0.0
	var first_rpm: int = int(round(curve.rpm_points[0]))
	var last_rpm: int = int(round(curve.rpm_points[curve.rpm_points.size() - 1]))
	for rpm: int in range(first_rpm, last_rpm + 1):
		var sampled_power_kw: float = _power_kw(
			peak_torque_nm * curve.sample(float(rpm)),
			float(rpm)
		)
		if sampled_power_kw > maximum_power_kw:
			maximum_power_kw = sampled_power_kw
			maximum_power_rpm = float(rpm)
	_expect(
		maximum_power_kw <= power_peak_kw + POWER_TOLERANCE_KW,
		"%s never exceeds its published maximum power" % code
	)
	_expect(
		absf(maximum_power_rpm - power_peak_rpm) <= PEAK_RPM_TOLERANCE,
		"%s power maximum occurs at the published RPM" % code
	)
	_expect(
		curve.sample(float(last_rpm)) < curve.sample(power_peak_rpm),
		"%s torque falls after the power peak" % code
	)


func _power_kw(torque_nm: float, rpm: float) -> float:
	return torque_nm * rpm / POWER_DIVISOR


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[FIAT_PUNTO_ENGINE_CURVES_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[FIAT_PUNTO_ENGINE_CURVES_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[FIAT_PUNTO_ENGINE_CURVES_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[FIAT_PUNTO_ENGINE_CURVES_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[FIAT_PUNTO_ENGINE_CURVES_TEST] - %s" % failure_message)
	quit(1)
