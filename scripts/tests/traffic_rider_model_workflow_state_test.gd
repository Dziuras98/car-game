extends SceneTree

const STATE_PATH := "res://docs/assets/traffic_rider_model_workflow_state.data"
const RESEARCH_MANIFEST_PATH := "res://docs/assets/traffic_rider_npc_vehicle_research_data_manifest.data"
const RECOVERY_REPORT_PATH := "res://docs/assets/traffic_rider_research_history_recovery.md"

const EXPECTED_MODEL_COUNT := 20
const EXPECTED_APPROVED_COUNT := 285

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var states := _read_csv(STATE_PATH)
	var research_rows := _read_csv(RESEARCH_MANIFEST_PATH)
	_expect(states.size() == EXPECTED_MODEL_COUNT, "workflow state contains all 20 included models")
	_expect(research_rows.size() == EXPECTED_MODEL_COUNT, "research manifest contains all 20 included models")
	var research_by_id := _index_unique(research_rows, "vehicle_id", "research manifest")
	var state_by_id := _index_unique(states, "vehicle_id", "workflow state")
	_expect(research_by_id.size() == EXPECTED_MODEL_COUNT, "research manifest vehicle IDs are unique")
	_expect(state_by_id.size() == EXPECTED_MODEL_COUNT, "workflow state vehicle IDs are unique")
	_test_counts_and_cross_references(states, research_by_id)
	_test_sequential_execution(states)
	_test_bmw_state(state_by_id)
	_test_recovery_report()
	_finish()


func _test_counts_and_cross_references(
	states: Array[Dictionary],
	research_by_id: Dictionary
) -> void:
	var total_approved: int = 0
	for index: int in range(states.size()):
		var row: Dictionary = states[index]
		var vehicle_id := str(row.get("vehicle_id", ""))
		var order := str(row.get("order", "")).to_int()
		var approved_count := str(row.get("approved_count", "")).to_int()
		total_approved += approved_count
		_expect(order == index + 1, "%s has stable sequential order %d" % [vehicle_id, index + 1])
		_expect(research_by_id.has(vehicle_id), "%s exists in the retained research manifest" % vehicle_id)
		if not research_by_id.has(vehicle_id):
			continue
		var research: Dictionary = research_by_id[vehicle_id]
		_expect(
			str(research.get("approved_count", "")).to_int() == approved_count,
			"%s workflow count matches retained approved scope" % vehicle_id
		)
		_expect(
			str(research.get("workflow_status", "")) == str(row.get("workflow_status", "")),
			"%s workflow status matches retained research state" % vehicle_id
		)
	_expect(total_approved == EXPECTED_APPROVED_COUNT, "workflow state preserves all 285 approved configurations")


func _test_sequential_execution(states: Array[Dictionary]) -> void:
	var integrating_indices: Array[int] = []
	var integrated_seen: bool = true
	for index: int in range(states.size()):
		var row: Dictionary = states[index]
		var vehicle_id := str(row.get("vehicle_id", ""))
		var status := str(row.get("workflow_status", ""))
		if status == "integrating":
			integrating_indices.append(index)
		_expect(status in ["approved", "integrating", "integrated"], "%s uses a valid workflow status" % vehicle_id)
		if status == "integrated":
			_expect(integrated_seen, "%s is integrated only after all earlier rows" % vehicle_id)
		elif status == "integrating":
			_expect(integrated_seen, "%s starts integration only after all earlier rows" % vehicle_id)
			integrated_seen = false
		else:
			integrated_seen = false
		if index > 0:
			_expect(
				status == "approved",
				"%s remains approved and queued while model 01 is incomplete" % vehicle_id
			)
			_expect(str(row.get("visual_stage", "")) == "queued", "%s visual stage remains queued" % vehicle_id)
			_expect(str(row.get("catalog_stage", "")) == "queued", "%s catalog stage remains queued" % vehicle_id)
			_expect(
				str(row.get("primary_blocker", "")).begins_with("waiting_for_model_01"),
				"%s explicitly records the ascending-order blocker" % vehicle_id
			)
	_expect(integrating_indices.size() == 1, "exactly one model is integrating")
	if integrating_indices.size() == 1:
		_expect(integrating_indices[0] == 0, "model 01 is the only active integration row")


func _test_bmw_state(state_by_id: Dictionary) -> void:
	_expect(state_by_id.has("bmw_4_series_f32"), "BMW F32 workflow row exists")
	if not state_by_id.has("bmw_4_series_f32"):
		return
	var row: Dictionary = state_by_id["bmw_4_series_f32"]
	_expect(str(row.get("workflow_status", "")) == "integrating", "BMW F32 remains integrating")
	_expect(str(row.get("research_stage", "")) == "complete", "BMW F32 research scope is complete")
	_expect(str(row.get("data_stage", "")) == "partial_verified", "BMW F32 exact data remains partial")
	_expect(str(row.get("visual_stage", "")) == "complete", "BMW F32 processed visual is complete")
	_expect(
		str(row.get("transmission_stage", "")) == "shared_capability_implemented",
		"BMW F32 records the phased planetary automatic capability"
	)
	_expect(
		str(row.get("driveline_stage", "")) == "shared_capability_implemented",
		"BMW F32 records the dynamic transfer-clutch capability"
	)
	_expect(
		str(row.get("audio_stage", "")) == "shared_inline_architecture_implemented",
		"BMW F32 records the inline engine-audio architecture"
	)
	_expect(str(row.get("physics_stage", "")) == "blocked_data", "BMW F32 physics calibration is data-blocked")
	_expect(str(row.get("scene_stage", "")) == "blocked_data", "BMW F32 playable scenes are data-blocked")
	_expect(str(row.get("catalog_stage", "")) == "blocked_data", "BMW F32 catalog exposure is data-blocked")
	_expect(
		str(row.get("primary_blocker", "")).contains("36 dynamics rows"),
		"BMW F32 records the exact remaining data blocker"
	)


func _test_recovery_report() -> void:
	var report := _read_text(RECOVERY_REPORT_PATH)
	_expect(not report.is_empty(), "research-history recovery report is readable")
	for fragment: String in [
		"**265** non-base commits",
		"**210** unique retained text versions",
		"**3,933** lines",
		"does **not** contain complete runtime-grade parameter tables",
		"only complete factory dynamics table recovered",
		"reporting all 285 configurations as implemented would be false",
	]:
		_expect(report.contains(fragment), "recovery report preserves: %s" % fragment)


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


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRAFFIC_RIDER_MODEL_WORKFLOW_STATE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRAFFIC_RIDER_MODEL_WORKFLOW_STATE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRAFFIC_RIDER_MODEL_WORKFLOW_STATE_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRAFFIC_RIDER_MODEL_WORKFLOW_STATE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TRAFFIC_RIDER_MODEL_WORKFLOW_STATE_TEST] - %s" % failure_message)
	quit(1)
