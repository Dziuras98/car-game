extends SceneTree

const SUPPORT_PATH := "res://resources/cars/bmw/4_series_f32/data/bmw_f32_official_powertrain_support.data"
const MATRIX_PATH := "res://resources/cars/bmw/4_series_f32/data/bmw_f32_variant_matrix.data"
const ENGINE_PATH := "res://resources/cars/bmw/4_series_f32/data/bmw_f32_engines.data"
const DYNAMICS_PATH := "res://resources/cars/bmw/4_series_f32/data/bmw_f32_verified_dynamics.data"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var support_rows := _read_csv(SUPPORT_PATH)
	var matrix_rows := _read_csv(MATRIX_PATH)
	var engine_rows := _read_csv(ENGINE_PATH)
	var dynamics_rows := _read_csv(DYNAMICS_PATH)
	_expect(support_rows.size() == 13, "official support table contains the 13 retained evidence applications")
	var matrix_by_id := _index_by(matrix_rows, "candidate_id")
	var engine_by_key := _index_by(engine_rows, "engine_key")
	var dynamics_by_id := _index_by(dynamics_rows, "candidate_id")
	var evidence_ids: Dictionary = {}
	var conflict_rows: Array[Dictionary] = []
	for row: Dictionary in support_rows:
		var evidence_id := str(row.get("evidence_id", ""))
		var candidate_id := str(row.get("candidate_id", ""))
		var engine_key := str(row.get("engine_key", ""))
		_expect(not evidence_id.is_empty(), "support row has an evidence ID")
		_expect(not evidence_ids.has(evidence_id), "support evidence ID is unique: %s" % evidence_id)
		evidence_ids[evidence_id] = true
		_expect(matrix_by_id.has(candidate_id), "support row references approved candidate %s" % candidate_id)
		_expect(engine_by_key.has(engine_key), "support row references retained engine %s" % engine_key)
		_expect(str(row.get("runtime_eligibility", "")) == "support_only", "%s remains support-only" % evidence_id)
		_expect(str(row.get("evidence_status", "")).begins_with("official_"), "%s records official evidence class" % evidence_id)
		_expect(str(row.get("source_url", "")).begins_with("https://www.press.bmwgroup.com/"), "%s uses an official BMW source" % evidence_id)
		_expect(not str(row.get("blocking_reason", "")).is_empty(), "%s retains an explicit runtime blocker" % evidence_id)
		_expect(not dynamics_by_id.has(candidate_id), "%s does not duplicate or promote a verified dynamics row" % evidence_id)
		var transmission_type := str(row.get("transmission_type", ""))
		var ratios := str(row.get("forward_ratios", "")).split(";", false)
		_expect(ratios.size() == (6 if transmission_type == "6mt" else 8), "%s has a complete support ratio set" % evidence_id)
		for ratio_text: String in ratios:
			_expect(ratio_text.to_float() > 0.0, "%s forward ratio is positive" % evidence_id)
		_expect(str(row.get("reverse_ratio", "")).to_float() > 0.0, "%s reverse ratio is positive" % evidence_id)
		_expect(str(row.get("final_drive", "")).to_float() > 0.0, "%s final drive is positive" % evidence_id)
		if str(row.get("field_scope", "")) == "calibration_conflict_evidence":
			conflict_rows.append(row)
		if str(row.get("source_body", "")) == "F36 Gran Coupe":
			_expect(
				str(row.get("blocking_reason", "")).contains("pre-LCI F32 body"),
				"%s cannot supply body-specific F32 dynamics" % evidence_id
			)
	_expect(conflict_rows.size() == 2, "420i B48 manual/automatic calibration conflict has two official F32 evidence rows")
	_test_420i_conflict(conflict_rows, engine_by_key)
	_finish()


func _test_420i_conflict(conflict_rows: Array[Dictionary], engine_by_key: Dictionary) -> void:
	var torque_by_transmission: Dictionary = {}
	for row: Dictionary in conflict_rows:
		torque_by_transmission[str(row.get("transmission_type", ""))] = str(row.get("torque_nm", "")).to_int()
	_expect(torque_by_transmission.get("6mt", 0) == 290, "official later F32 support records 420i manual at 290 Nm")
	_expect(torque_by_transmission.get("8at", 0) == 270, "official later F32 support records 420i automatic at 270 Nm")
	_expect(engine_by_key.has("b48b20_135"), "shared B48 420i engine row exists for migration review")
	if engine_by_key.has("b48b20_135"):
		var current: Dictionary = engine_by_key["b48b20_135"]
		_expect(str(current.get("implementation_status", "")) == "planned", "conflicted shared B48 row remains unavailable")
		_expect(str(current.get("torque_nm", "")).to_int() == 290, "test exposes the currently shared 290 Nm value that requires split or correction")


func _read_csv(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open(path, FileAccess.READ)
	_expect(file != null, "%s is readable" % path)
	if file == null:
		return rows
	var header := file.get_csv_line()
	while not file.eof_reached():
		var values := file.get_csv_line()
		if values.size() == 1 and values[0].strip_edges().is_empty():
			continue
		var row: Dictionary = {}
		for index: int in range(header.size()):
			row[header[index]] = values[index] if index < values.size() else ""
		rows.append(row)
	file.close()
	return rows


func _index_by(rows: Array[Dictionary], field: String) -> Dictionary:
	var result: Dictionary = {}
	for row: Dictionary in rows:
		var key := str(row.get(field, ""))
		if not key.is_empty():
			result[key] = row
	return result


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[BMW_F32_OFFICIAL_POWERTRAIN_SUPPORT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[BMW_F32_OFFICIAL_POWERTRAIN_SUPPORT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[BMW_F32_OFFICIAL_POWERTRAIN_SUPPORT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[BMW_F32_OFFICIAL_POWERTRAIN_SUPPORT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[BMW_F32_OFFICIAL_POWERTRAIN_SUPPORT_TEST] - %s" % failure_message)
	quit(1)
