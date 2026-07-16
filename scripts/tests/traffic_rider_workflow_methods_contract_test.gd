extends SceneTree

const SUITE_PATH := "res://docs/assets/traffic_rider_npc_vehicle_workflow_suite.md"
const IMPORT_PATH := "res://docs/assets/traffic_rider_npc_vehicle_import_workflow.md"
const DATA_PATH := "res://docs/assets/traffic_rider_npc_vehicle_research_data_contract.md"
const TRANSMISSION_PATH := "res://docs/assets/traffic_rider_transmission_implementation_contract.md"
const AUDIO_PATH := "res://docs/assets/traffic_rider_engine_audio_implementation_contract.md"
const MANIFEST_PATH := "res://docs/assets/traffic_rider_npc_vehicle_research_data_manifest.data"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_suite_index()
	_test_import_workflow()
	_test_transmission_contract()
	_test_audio_contract()
	_test_all_model_records_preserve_methods()
	_finish()


func _test_suite_index() -> void:
	var text := _read_text(SUITE_PATH)
	_expect(not text.is_empty(), "workflow suite index is readable")
	for fragment: String in [
		"traffic_rider_npc_vehicle_import_workflow.md",
		"traffic_rider_npc_vehicle_research_data_contract.md",
		"traffic_rider_transmission_implementation_contract.md",
		"traffic_rider_engine_audio_implementation_contract.md",
		"traffic_rider_npc_vehicle_physics_v3_baseline.md",
		"Evidence-blocked facts remain blocked",
		"live player and explicit AI audio backend",
	]:
		_expect(text.contains(fragment), "workflow suite preserves: %s" % fragment)


func _test_import_workflow() -> void:
	var text := _read_text(IMPORT_PATH)
	_expect(not text.is_empty(), "main import workflow is readable")
	for fragment: String in [
		"Research the complete factory variant matrix before importing the model",
		"Match the real transmission architecture exactly",
		"Implement missing transmission types faithfully",
		"Build new engine-sound architectures from first principles",
		"Stage 6 — implement the exact transmission architecture",
		"Stage 8 — implement architecture-correct engine audio",
		"transmission and audio fallbacks are prohibited",
	]:
		_expect(text.contains(fragment), "main workflow preserves: %s" % fragment)


func _test_transmission_contract() -> void:
	var text := _read_text(TRANSMISSION_PATH)
	_expect(not text.is_empty(), "transmission implementation contract is readable")
	for fragment: String in [
		"complete torque path and its control states",
		"The selected gear and the torque-carrying gear may differ during a shift",
		"Planetary torque-converter automatic",
		"hydrodynamic converter torque multiplication as a function of speed ratio",
		"clutch-to-clutch/band shift phases",
		"multi-gear kickdown and skip-shift",
		"Automated manual / SMG / EPS-EAS",
		"two distinct clutch torque paths for odd/even gearsets",
		"preselected gear state",
		"wet- or dry-clutch thermal/capacity behaviour",
		"Continuously variable transmission",
		"actual launch device: clutch or torque converter",
		"Electric fixed reduction",
		"On-demand coupling: xDrive/Haldex-style systems",
		"A constant front-torque fraction plus a centre-lock correction is insufficient",
		"explicit documented states such as 2H, 4H and 4L",
		"Vehicle-specific tuning belongs in resources",
		"no gear hunting under sustained wheel slip",
		"no catalog exposure before all required data and tests pass",
	]:
		_expect(text.contains(fragment), "transmission contract preserves: %s" % fragment)


func _test_audio_contract() -> void:
	var text := _read_text(AUDIO_PATH)
	_expect(not text.is_empty(), "engine-audio implementation contract is readable")
	for fragment: String in [
		"A profile is not an engine architecture",
		"exact firing order and unequal/equal firing intervals",
		"cylinder-to-bank and bank-to-collector routing",
		"The same number of cylinders does not make two engines acoustically interchangeable",
		"Shared filters, oscillators, saturation, sample-rate helpers",
		"The base VQ backend is explicitly V6-specific",
		"Turbo or supercharger audio must be driven by a state model",
		"A limiter torque cut is not a pedal lift",
		"complete turbocharged engine does not become louder solely because extra layers were added",
		"live architecture-correct synthesizer",
		"committed baked bank",
		"live synthesis with a documented simultaneous-opponent performance budget",
		"turbocharged total level does not exceed the allowed reference merely due to added turbo layers",
		"perceptually distinguishable from unrelated layouts after normalization",
		"no generic fallback, pitch-only substitution or unrelated waveform remains",
	]:
		_expect(text.contains(fragment), "audio contract preserves: %s" % fragment)


func _test_all_model_records_preserve_methods() -> void:
	var rows := _read_csv(MANIFEST_PATH)
	_expect(rows.size() == 20, "workflow method audit covers all 20 model records")
	for row: Dictionary in rows:
		var vehicle_id := str(row.get("vehicle_id", ""))
		var record_path := "res://%s" % str(row.get("research_record", ""))
		var record := _read_text(record_path)
		_expect(not record.is_empty(), "%s research record is readable" % vehicle_id)
		var lower := record.to_lower()
		_expect(lower.contains("transmission"), "%s preserves transmission research/methods" % vehicle_id)
		_expect(lower.contains("audio"), "%s preserves engine/driveline audio research/methods" % vehicle_id)


func _read_csv(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open(path, FileAccess.READ)
	_expect(file != null, "workflow manifest is readable")
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
		print("[TRAFFIC_RIDER_WORKFLOW_METHODS_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRAFFIC_RIDER_WORKFLOW_METHODS_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRAFFIC_RIDER_WORKFLOW_METHODS_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRAFFIC_RIDER_WORKFLOW_METHODS_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TRAFFIC_RIDER_WORKFLOW_METHODS_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
