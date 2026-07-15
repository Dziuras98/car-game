extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/ford_f150_limited_2013.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not research.is_empty(), "Ford F-150 P415 research record is readable")
	for required_fragment: String in [
		"Ford F-150 P415 SuperCrew 5.5-ft box — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **7 mechanically consolidated 4x2 engine configurations**",
		"Source SHA-256: `3be44b7f8f563efc57d259e0a3902dc55b2b347a0b34b2b90f55d75f541f6587`",
		"Total triangles | 1,758",
		"Approximate wheelbase-derived scale | 0.684403",
		"4.6L Modular SOHC 2-valve",
		"4.6L Modular SOHC 3-valve",
		"5.4L Triton Modular SOHC 3-valve",
		"3.7L Duratec Ti-VCT",
		"5.0L Coyote Ti-VCT",
		"3.5L EcoBoost DOHC twin-turbo",
		"6.2L Boss SOHC",
		"Ford 4R75E-family 4-speed",
		"Ford 6R80-family 6-speed",
		"Approved total: 7 mechanically consolidated Ford F-150 P415 SuperCrew 5.5-ft 4x2 configurations",
		"simulate gasoline only",
		"source-like 2013 Limited exterior and chassis presentation",
		"22-in P275/45R22 tyres for every row",
		"sport-tuned shock calibration for every row",
		"Model 07 is **`approved`** with **7** configurations",
		"Research proceeds to model 08",
	]:
		_expect(research.contains(required_fragment), "F-150 approval preserves: %s" % required_fragment)
	_expect(not research.contains("Workflow status: **`awaiting_owner_scope`**"), "F-150 owner gate is closed")
	_expect(not research.contains("| 4x4 |"), "F-150 approved matrix contains no 4x4 row")
	_finish()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[FORD_F150_MODEL_07_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[FORD_F150_MODEL_07_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[FORD_F150_MODEL_07_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[FORD_F150_MODEL_07_RESEARCH_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[FORD_F150_MODEL_07_RESEARCH_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
