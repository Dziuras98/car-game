extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/ford_excursion_2000.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not inventory.is_empty(), "vehicle inventory is readable")
	_expect(not research.is_empty(), "Ford Excursion research record is readable")
	for required_fragment: String in [
		"Ford Excursion 2000 pre-facelift XLT, approved 4x2 engine scope | SUV | 2,180 | `approved`",
		"| 06 — Ford Excursion pre-facelift XLT 4x2 | `docs/vehicles/traffic/ford_excursion_2000.md` | 5 |",
		"The next research target is model 07 — Ford F-150 Limited 2013",
	]:
		_expect(inventory.contains(required_fragment), "inventory preserves: %s" % required_fragment)
	for required_fragment: String in [
		"Ford Excursion — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **5 pre-facelift XLT-style Ford Excursion 4x2 engine/calibration configurations**",
		"Source SHA-256: `7e6909692533a21392cb7bdfa03f52db5fe58da59fba6ea5727a76070d91baf7`",
		"Wheelbase | 137.1 in / 3.48234 m",
		"Total triangles | 2,180",
		"Approximate wheelbase-derived scale | 0.682952",
		"5.4L Triton Modular SOHC 2-valve",
		"6.8L Triton Modular SOHC 2-valve",
		"**7.3 early**, model year 2000",
		"**7.3 late**, 2002–early 2003",
		"6.0L Power Stroke / Navistar VT365",
		"Ford 4R100 4-speed planetary torque-converter automatic",
		"Ford TorqShift 5R110W 5-speed planetary torque-converter automatic",
		"4x2 RWD; one verified standard axle ratio and differential",
		"Approved total: 5 pre-facelift Ford Excursion 4x2 configurations",
		"every part-time 4x4 configuration",
		"the intermediate 2001 7.3L calibration",
		"the 2005 facelift appearance",
		"the Mexico-only 2006 continuation",
		"Missing expected variants: **none identified by the owner**",
		"Model 06 is **`approved`** with **5** configurations",
		"Research proceeds to model 07",
	]:
		_expect(research.contains(required_fragment), "Ford Excursion approval preserves: %s" % required_fragment)
	_expect(not research.contains("Workflow status: **`awaiting_owner_scope`**"), "Ford Excursion approval gate is closed")
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
		print("[FORD_EXCURSION_MODEL_06_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[FORD_EXCURSION_MODEL_06_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[FORD_EXCURSION_MODEL_06_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[FORD_EXCURSION_MODEL_06_RESEARCH_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[FORD_EXCURSION_MODEL_06_RESEARCH_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
