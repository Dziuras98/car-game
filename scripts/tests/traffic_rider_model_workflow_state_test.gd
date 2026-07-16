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
	_test_recovery_report()
	_finish()


func _test_counts_and_cross_references(states: Array[Dictionary], research_by_id: Dictionary) -> void:
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
			str(research.get("approved_variants", "")).to_int() == approved_count,
			"%s workflow count matches retained approved scope" % vehicle_id
		)
		_expect(
			str(research.get("workflow_status", "")) == str(row.get("workflow_status", "")),
			"%s workflow status matches retained research state" % vehicle_id
		)
	_expect(total_approved == EXPECTED_APPROVED_COUNT, "workflow state preserves all 285 approved configurations")


func _test_sequential_execution(states: Array[Dictionary]) -> void:
	var integrating_indices: Array[int] = []
	var first_not_integrated: int = states.size()
	for index: int in range(states.size()):
		var status := str(states[index].get("workflow_status", ""))
		if status != "integrated" and first_not_integrated == states.size():
			first_not_integrated = index
		if status == "integrating":
			integrating_indices.append(index)
		_expect(status in ["approved", "integrating", "integrated"], "%s uses a valid workflow status" % str(states[index].get("vehicle_id", "")))

	_expect(integrating_indices.size() == 1, "exactly one model is integrating")
	if integrating_indices.size() != 1:
		return
	var active_index: int = integrating_indices[0]
	_expect(active_index == first_not_integrated, "the first non-integrated model is the only active row")
	var active_model_number: String = str(states[active_index].get("model_number", "")).strip_edges()

	for index: int in range(states.size()):
		var row: Dictionary = states[index]
		var vehicle_id := str(row.get("vehicle_id", ""))
		var status := str(row.get("workflow_status", ""))
		if index < active_index:
			_expect(status == "integrated", "%s is integrated before the active model" % vehicle_id)
			_expect(str(row.get("visual_stage", "")) == "complete", "%s integrated visual stage is complete" % vehicle_id)
			_expect(str(row.get("scene_stage", "")) == "complete", "%s integrated scene stage is complete" % vehicle_id)
			_expect(str(row.get("catalog_stage", "")) == "complete", "%s integrated catalog stage is complete" % vehicle_id)
		elif index == active_index:
			_expect(status == "integrating", "%s is the active integration row" % vehicle_id)
			_expect(str(row.get("research_stage", "")) == "complete", "%s active research scope is complete" % vehicle_id)
			_expect(str(row.get("visual_stage", "")) != "queued", "%s active visual stage has started" % vehicle_id)
		else:
			_expect(status == "approved", "%s remains approved behind the active row" % vehicle_id)
			_expect(str(row.get("visual_stage", "")) == "queued", "%s visual stage remains queued" % vehicle_id)
			_expect(str(row.get("catalog_stage", "")) == "queued", "%s catalog stage remains queued" % vehicle_id)
			_expect(
				str(row.get("primary_blocker", "")).begins_with("waiting_for_model_%s" % active_model_number),
				"%s explicitly records the active-model sequence blocker" % vehicle_id
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
