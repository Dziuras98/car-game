extends SceneTree

const MANIFEST_PATH := "res://docs/assets/traffic_rider_source_inspection.data"
const GENERATOR_PATH := "res://tools/assets/inspect_traffic_rider_sources.py"
const EXPECTED_MODEL_COUNT := 20
const EXPECTED_TOTAL_FACES := 40300
const DUAL_REAR_WHEEL_MODELS: Dictionary = {
	"renault_maxity_2008": true,
	"nissan_atlas_2007": true,
	"nissan_atleon_2004": true,
}

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var rows := _read_csv(MANIFEST_PATH)
	_expect(FileAccess.file_exists(GENERATOR_PATH), "deterministic all-source inspection generator is committed")
	_expect(rows.size() == EXPECTED_MODEL_COUNT, "source inspection contains all 20 approved source models")
	var model_numbers: Dictionary = {}
	var vehicle_ids: Dictionary = {}
	var total_faces: int = 0
	var dual_rear_models: Dictionary = {}
	for row: Dictionary in rows:
		var model_number := str(row.get("model_number", "")).to_int()
		var vehicle_id := str(row.get("vehicle_id", ""))
		var source_path := "res://%s" % str(row.get("source_path", ""))
		var expected_sha := str(row.get("source_sha256", ""))
		var faces := str(row.get("total_faces", "")).to_int()
		total_faces += faces
		_expect(model_number > 0, "%s has a positive model number" % vehicle_id)
		_expect(not model_numbers.has(model_number), "model number is unique: %d" % model_number)
		model_numbers[model_number] = true
		_expect(not vehicle_id.is_empty(), "source inspection vehicle ID is present")
		_expect(not vehicle_ids.has(vehicle_id), "source inspection vehicle ID is unique: %s" % vehicle_id)
		vehicle_ids[vehicle_id] = true
		_expect(FileAccess.file_exists(source_path), "%s source file is committed" % vehicle_id)
		_expect(expected_sha.length() == 64 and expected_sha.is_valid_hex_number(false), "%s source SHA-256 is valid" % vehicle_id)
		if FileAccess.file_exists(source_path):
			_expect(FileAccess.get_sha256(source_path) == expected_sha, "%s source bytes match inspected SHA-256" % vehicle_id)
		_expect(str(row.get("inspection_status", "")) == "verified", "%s inspection completed successfully" % vehicle_id)
		_expect(str(row.get("geometry_node_count", "")).to_int() == 3, "%s has body plus two axle geometry nodes" % vehicle_id)
		_expect(not str(row.get("body_node", "")).is_empty(), "%s body node is retained" % vehicle_id)
		_expect(not str(row.get("rear_axle_node", "")).is_empty(), "%s rear axle node is retained" % vehicle_id)
		_expect(not str(row.get("front_axle_node", "")).is_empty(), "%s front axle node is retained" % vehicle_id)
		_expect(faces > 0, "%s total triangle count is positive" % vehicle_id)
		_expect(str(row.get("body_faces", "")).to_int() > 0, "%s body triangle count is positive" % vehicle_id)
		_expect(str(row.get("rear_left_faces", "")).to_int() == str(row.get("rear_right_faces", "")).to_int(), "%s rear axle splits symmetrically" % vehicle_id)
		_expect(str(row.get("front_left_faces", "")).to_int() == str(row.get("front_right_faces", "")).to_int(), "%s front axle splits symmetrically" % vehicle_id)
		_expect(str(row.get("measured_source_wheelbase", "")).to_float() > 0.0, "%s measured source wheelbase is positive" % vehicle_id)
		_expect(str(row.get("split_crossing_faces", "")).to_int() == 0, "%s axle split loses no crossing triangles" % vehicle_id)
		var topology := str(row.get("rear_wheel_topology", ""))
		_expect(topology in ["single_per_side", "dual_per_side"], "%s rear-wheel topology is explicit" % vehicle_id)
		if topology == "dual_per_side":
			dual_rear_models[vehicle_id] = true
			_expect(str(row.get("rear_left_faces", "")).to_int() > str(row.get("front_left_faces", "")).to_int(), "%s dual rear assembly contains more geometry than one front wheel" % vehicle_id)
	_expect(total_faces == EXPECTED_TOTAL_FACES, "source inspection preserves the complete 40,300-triangle bundle scope")
	_expect(dual_rear_models.size() == DUAL_REAR_WHEEL_MODELS.size(), "exactly three models use dual rear tyres")
	for vehicle_id: String in DUAL_REAR_WHEEL_MODELS:
		_expect(dual_rear_models.has(vehicle_id), "%s retains dual-per-side rear-wheel topology" % vehicle_id)
	_finish()


func _read_csv(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open(path, FileAccess.READ)
	_expect(file != null, "source inspection manifest is readable")
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


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRAFFIC_RIDER_SOURCE_INSPECTION_MANIFEST_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRAFFIC_RIDER_SOURCE_INSPECTION_MANIFEST_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRAFFIC_RIDER_SOURCE_INSPECTION_MANIFEST_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRAFFIC_RIDER_SOURCE_INSPECTION_MANIFEST_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TRAFFIC_RIDER_SOURCE_INSPECTION_MANIFEST_TEST] - %s" % failure_message)
	quit(1)
