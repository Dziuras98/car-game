extends SceneTree

const MANIFEST_PATH := "res://docs/assets/traffic_rider_npc_vehicle_research_data_manifest.data"
const CONTRACT_PATH := "res://docs/assets/traffic_rider_npc_vehicle_research_data_contract.md"
const EXPECTED_MODELS := 20
const EXPECTED_APPROVED_VARIANTS := 285
const ALLOWED_DATA_STATUSES: PackedStringArray = PackedStringArray([
	"research_record_only",
	"partial_verified",
	"complete_verified",
])

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var rows := _read_csv(MANIFEST_PATH)
	_expect(rows.size() == EXPECTED_MODELS, "research-data manifest contains all 20 models")
	_expect(FileAccess.file_exists(CONTRACT_PATH), "research-data retention contract is committed")

	var model_numbers: Dictionary = {}
	var vehicle_ids: Dictionary = {}
	var approved_total := 0
	var integrating_count := 0
	for row: Dictionary in rows:
		var model_number := str(row.get("model_number", ""))
		var vehicle_id := str(row.get("vehicle_id", ""))
		var record_path := "res://%s" % str(row.get("research_record", ""))
		var workflow_status := str(row.get("workflow_status", ""))
		var data_status := str(row.get("structured_data_status", ""))
		var approved_text := str(row.get("approved_variants", ""))

		_expect(not model_number.is_empty(), "manifest model number is present")
		_expect(not model_numbers.has(model_number), "manifest model number is unique: %s" % model_number)
		model_numbers[model_number] = true
		_expect(not vehicle_id.is_empty(), "manifest vehicle id is present")
		_expect(not vehicle_ids.has(vehicle_id), "manifest vehicle id is unique: %s" % vehicle_id)
		vehicle_ids[vehicle_id] = true
		_expect(FileAccess.file_exists(record_path), "%s research record is readable" % vehicle_id)
		_expect(approved_text.is_valid_int() and approved_text.to_int() > 0, "%s approved count is positive" % vehicle_id)
		approved_total += approved_text.to_int() if approved_text.is_valid_int() else 0
		_expect(ALLOWED_DATA_STATUSES.has(data_status), "%s has a recognized structured-data status" % vehicle_id)
		_expect(workflow_status == "approved" or workflow_status == "integrating" or workflow_status == "integrated", "%s workflow status is recognized" % vehicle_id)
		if workflow_status == "integrating":
			integrating_count += 1
		if workflow_status == "integrated":
			_expect(data_status == "complete_verified", "%s cannot be integrated without complete structured data" % vehicle_id)
		_validate_data_root(row)

	_expect(approved_total == EXPECTED_APPROVED_VARIANTS, "manifest approved counts sum to 285")
	_expect(integrating_count == 1, "exactly one model is currently integrating")
	_expect(str(rows[0].get("model_number", "")) == "01", "implementation order starts with model 01")
	_expect(str(rows[0].get("vehicle_id", "")) == "bmw_4_series_f32", "BMW F32 is the active model")
	_expect(str(rows[0].get("structured_data_status", "")) == "partial_verified", "BMW F32 partial migration is explicit")
	_finish()


func _validate_data_root(row: Dictionary) -> void:
	var vehicle_id := str(row.get("vehicle_id", ""))
	var data_status := str(row.get("structured_data_status", ""))
	var root_text := str(row.get("structured_data_root", "")).strip_edges()
	if data_status == "research_record_only":
		_expect(root_text.is_empty(), "%s does not claim a nonexistent structured-data root" % vehicle_id)
		return
	_expect(not root_text.is_empty(), "%s declares a structured-data root" % vehicle_id)
	var root_path := "res://%s" % root_text
	_expect(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(root_path)), "%s structured-data root exists" % vehicle_id)
	if vehicle_id == "bmw_4_series_f32":
		for filename: String in [
			"bmw_f32_variant_matrix.data",
			"bmw_f32_engines.data",
			"bmw_f32_verified_dynamics.data",
			"README.md",
		]:
			_expect(FileAccess.file_exists("%s/%s" % [root_path, filename]), "BMW F32 retains %s" % filename)


func _read_csv(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open(path, FileAccess.READ)
	_expect(file != null, "research-data manifest is readable")
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


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRAFFIC_RIDER_RESEARCH_DATA_MANIFEST_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[TRAFFIC_RIDER_RESEARCH_DATA_MANIFEST_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRAFFIC_RIDER_RESEARCH_DATA_MANIFEST_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRAFFIC_RIDER_RESEARCH_DATA_MANIFEST_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	quit(1)
