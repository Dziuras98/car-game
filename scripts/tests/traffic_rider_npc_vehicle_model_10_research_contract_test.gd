extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/volkswagen_golf_vii_2013.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not inventory.is_empty(), "vehicle inventory is readable")
	_expect(not research.is_empty(), "Golf VII research record is readable")
	for required_fragment: String in [
		"Volkswagen Golf VII five-door source with approved standard TSI/TDI and e-Golf scope | passenger hatchback | 1,982 | `approved`",
		"| 10 — Volkswagen Golf VII five-door hatchback | `docs/vehicles/traffic/volkswagen_golf_vii_2013.md` | 38 |",
		"After model 11 is approved, research continues with model 12",
	]:
		_expect(inventory.contains(required_fragment), "inventory preserves: %s" % required_fragment)
	for required_fragment: String in [
		"Volkswagen Golf VII hatchback — research and approved scope",
		"Workflow status: **`approved`**",
		"Source SHA-256: `d8ff27d0dd2dbfed76723cbe7c04d042af891a127a68fe0dbdbe8946f2220260`",
		"Approved implementation scope: **38 mechanically consolidated five-door Golf VII configurations**",
		"Approved standard petrol matrix — 22 configurations",
		"Approved ordinary-diesel matrix — 14 configurations",
		"Approved electric matrix — 2 configurations",
		"Approved total: 22 standard petrol + 14 ordinary diesel + 2 electric = 38 configurations",
		"DQ200 7-speed dry DSG",
		"DQ250 6-speed wet DSG",
		"DQ381 7-speed wet DSG",
		"EQ270-family single-speed fixed-reduction transaxle",
		"exclude every GTI, GTI Performance, Clubsport, Clubsport S, TCR and Golf R row",
		"exclude GTE and every TGI/CNG row",
		"do not store DPF, OPF, emissions-standard, stop/start or similar aftertreatment/revision states",
		"Model 10 is **`approved`** with **38** configurations",
		"Research proceeds to model 11",
	]:
		_expect(research.contains(required_fragment), "Golf VII approved scope preserves: %s" % required_fragment)
	_expect(not research.contains("Workflow status: **`awaiting_owner_scope`**"), "Golf VII owner gate is closed")
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
		print("[VOLKSWAGEN_GOLF_VII_MODEL_10_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[VOLKSWAGEN_GOLF_VII_MODEL_10_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[VOLKSWAGEN_GOLF_VII_MODEL_10_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[VOLKSWAGEN_GOLF_VII_MODEL_10_RESEARCH_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[VOLKSWAGEN_GOLF_VII_MODEL_10_RESEARCH_CONTRACT_TEST] - %s" % failure_message)
	quit(1)