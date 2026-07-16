extends SceneTree

const CURVE_PATH := "res://resources/cars/bmw/4_series_f32/data/bmw_f32_torque_curve_evidence.data"
const ENGINE_PATH := "res://resources/cars/bmw/4_series_f32/data/bmw_f32_engines.data"
const VARIANT_PATH := "res://resources/cars/bmw/4_series_f32/data/bmw_f32_variant_matrix.data"

const EXPECTED_ENGINE_COUNT := 17
const EXPECTED_VARIANT_COUNT := 44

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var curves := _read_csv(CURVE_PATH)
	var engines := _read_csv(ENGINE_PATH)
	var variants := _read_csv(VARIANT_PATH)
	_expect(curves.size() == EXPECTED_ENGINE_COUNT, "torque-curve evidence covers all 17 engine calibrations")
	_expect(engines.size() == EXPECTED_ENGINE_COUNT, "engine dataset contains 17 calibrations")
	_expect(variants.size() == EXPECTED_VARIANT_COUNT, "variant matrix contains 44 approved rows")
	var curves_by_key := _index_unique(curves, "engine_key", "curve")
	var engines_by_key := _index_unique(engines, "engine_key", "engine")
	_expect(curves_by_key.size() == EXPECTED_ENGINE_COUNT, "torque-curve engine keys are unique")
	_expect(engines_by_key.size() == EXPECTED_ENGINE_COUNT, "engine keys are unique")
	_test_curve_rows(curves, engines_by_key)
	_test_every_variant_is_curve_gated(variants, curves_by_key)
	_test_launch_plateau_rows(curves_by_key)
	_test_b48_conflict(curves_by_key)
	_finish()


func _test_curve_rows(curves: Array[Dictionary], engines_by_key: Dictionary) -> void:
	for row: Dictionary in curves:
		var engine_key := str(row.get("engine_key", ""))
		var status := str(row.get("curve_status", ""))
		_expect(engines_by_key.has(engine_key), "%s references a retained engine calibration" % engine_key)
		_expect(status in ["peak_only", "peak_plateau_only", "official_source_conflict"], "%s uses an explicit incomplete-curve status" % engine_key)
		_expect(str(row.get("retained_curve_points", "")).is_empty(), "%s does not invent sampled curve points" % engine_key)
		_expect(str(row.get("runtime_eligibility", "")) == "blocked", "%s remains blocked from runtime" % engine_key)
		_expect(not str(row.get("blocking_reason", "")).is_empty(), "%s records a curve-specific blocker" % engine_key)
		_expect(not str(row.get("source_id", "")).is_empty(), "%s records its evidence source class" % engine_key)
		_expect(_has_positive_power(row), "%s retains a positive factory power anchor" % engine_key)
		_expect(_positive_float(row, "peak_torque_nm"), "%s retains a positive factory torque anchor" % engine_key)
		if engines_by_key.has(engine_key):
			var engine: Dictionary = engines_by_key[engine_key]
			_expect(_same_power_anchor(row, engine), "%s curve power anchor agrees with engine data" % engine_key)
			_expect(is_equal_approx(str(row.get("peak_torque_nm", "0")).to_float(), str(engine.get("torque_nm", "0")).to_float()), "%s curve torque anchor agrees with engine data" % engine_key)


func _test_every_variant_is_curve_gated(
	variants: Array[Dictionary],
	curves_by_key: Dictionary
) -> void:
	for row: Dictionary in variants:
		var candidate_id := str(row.get("candidate_id", ""))
		var engine_key := str(row.get("engine_key", ""))
		_expect(curves_by_key.has(engine_key), "%s has a curve-evidence row" % candidate_id)
		if not curves_by_key.has(engine_key):
			continue
		var curve: Dictionary = curves_by_key[engine_key]
		_expect(str(curve.get("runtime_eligibility", "")) == "blocked", "%s cannot create CarSpecs before its sampled curve exists" % candidate_id)
		_expect(str(row.get("implementation_status", "")) != "integrated", "%s is not falsely marked integrated" % candidate_id)


func _test_launch_plateau_rows(curves_by_key: Dictionary) -> void:
	var expected: Dictionary = {
		"n20b20_180": ["5000-6500", "1250-4800"],
		"n55b30_225": ["5800-6000", "1200-5000"],
		"n47d20_135": ["4000", "1750-2750"],
	}
	for engine_key: String in expected:
		_expect(curves_by_key.has(engine_key), "%s launch plateau row exists" % engine_key)
		if not curves_by_key.has(engine_key):
			continue
		var row: Dictionary = curves_by_key[engine_key]
		var anchors: Array = expected[engine_key]
		_expect(str(row.get("curve_status", "")) == "peak_plateau_only", "%s is classified as plateau-only rather than sampled" % engine_key)
		_expect(str(row.get("power_rpm", "")) == str(anchors[0]), "%s retains the official power RPM range" % engine_key)
		_expect(str(row.get("torque_rpm", "")) == str(anchors[1]), "%s retains the official torque plateau" % engine_key)


func _test_b48_conflict(curves_by_key: Dictionary) -> void:
	_expect(curves_by_key.has("b48b20_135"), "420i B48 curve row exists")
	if not curves_by_key.has("b48b20_135"):
		return
	var row: Dictionary = curves_by_key["b48b20_135"]
	_expect(str(row.get("curve_status", "")) == "official_source_conflict", "420i B48 curve remains conflict-gated")
	_expect(str(row.get("transmission_specific", "")) == "true", "420i B48 requires transmission-specific calibration review")
	_expect(str(row.get("notes", "")).contains("290 Nm manual or 270 Nm automatic"), "420i B48 row preserves the official transmission torque discrepancy")


func _has_positive_power(row: Dictionary) -> bool:
	return (
		_positive_float(row, "peak_power_kw")
		or _positive_float(row, "peak_power_ps")
		or _positive_float(row, "peak_power_hp")
	)


func _same_power_anchor(curve: Dictionary, engine: Dictionary) -> bool:
	for field: String in ["power_kw", "power_ps", "power_hp"]:
		var curve_field := "peak_%s" % field
		var curve_value := str(curve.get(curve_field, "")).strip_edges()
		var engine_value := str(engine.get(field, "")).strip_edges()
		if curve_value.is_empty() and engine_value.is_empty():
			continue
		if not curve_value.is_valid_float() or not engine_value.is_valid_float():
			return false
		if not is_equal_approx(curve_value.to_float(), engine_value.to_float()):
			return false
	return true


func _positive_float(row: Dictionary, field: String) -> bool:
	var text := str(row.get(field, "")).strip_edges()
	return text.is_valid_float() and text.to_float() > 0.0


func _read_csv(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open(path, FileAccess.READ)
	_expect(file != null, "%s is readable" % path)
	if file == null:
		return rows
	var header: PackedStringArray = file.get_csv_line()
	while not file.eof_reached():
		var values: PackedStringArray = file.get_csv_line()
		if values.size() == 1 and values[0].strip_edges().is_empty():
			continue
		var row: Dictionary = {}
		for index: int in range(header.size()):
			row[header[index]] = values[index] if index < values.size() else ""
		rows.append(row)
	file.close()
	return rows


func _index_unique(rows: Array[Dictionary], field: String, label: String) -> Dictionary:
	var result: Dictionary = {}
	for row: Dictionary in rows:
		var key := str(row.get(field, ""))
		_expect(not key.is_empty(), "%s %s is present" % [label, field])
		if key.is_empty():
			continue
		_expect(not result.has(key), "%s key is unique: %s" % [label, key])
		result[key] = row
	return result


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[BMW_F32_TORQUE_CURVE_EVIDENCE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[BMW_F32_TORQUE_CURVE_EVIDENCE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[BMW_F32_TORQUE_CURVE_EVIDENCE_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[BMW_F32_TORQUE_CURVE_EVIDENCE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[BMW_F32_TORQUE_CURVE_EVIDENCE_TEST] - %s" % failure_message)
	quit(1)
