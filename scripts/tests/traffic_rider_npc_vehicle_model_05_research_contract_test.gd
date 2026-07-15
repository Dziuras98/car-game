extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/ford_e150_2012.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not inventory.is_empty(), "vehicle inventory is readable")
	_expect(not research.is_empty(), "Ford E-150 research record is readable")
	for required_fragment: String in [
		"Ford E-150 Commercial Cargo Van, regular length, merged 2008–2014 engine scope | full-size van | 1,844 | `approved`",
		"| 05 — Ford E-150 Commercial Cargo Van | `docs/vehicles/traffic/ford_e150_2012.md` | 2 |",
		"Ford Excursion 2000 pre-facelift XLT, drivetrain unresolved visually | SUV | 2,180 | `awaiting_owner_scope`",
	]:
		_expect(inventory.contains(required_fragment), "inventory preserves: %s" % required_fragment)
	for required_fragment: String in [
		"Ford E-150 Commercial Cargo Van — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **2 regular-length E-150 Commercial Cargo Van engine configurations**",
		"Model-year coverage: **2008–2014, merged into each engine row**",
		"Source SHA-256: `b8fb9a407b091108ea4c36f12f609e65ae587108085ec4ac6e019842a9396c6e`",
		"Total triangles | 1,844",
		"Approximate wheelbase-derived scale | 0.712154",
		"4.6L Triton Modular SOHC naturally aspirated cross-plane V8",
		"5.4L Triton Modular SOHC naturally aspirated cross-plane V8",
		"Approved total: 2 regular-length E-150 Commercial Cargo Van configurations",
		"do not create separate catalog rows for model-year eras",
		"open differential only",
		"simulate gasoline only",
		"Model 05 is **`approved`** with **2** configurations",
		"Research proceeds to model 06",
	]:
		_expect(research.contains(required_fragment), "Ford E-150 approval preserves: %s" % required_fragment)
	_expect(not research.contains("Approved total: 8 regular-length"), "year-era catalog rows were removed")
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
		print("[FORD_E150_MODEL_05_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[FORD_E150_MODEL_05_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[FORD_E150_MODEL_05_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[FORD_E150_MODEL_05_RESEARCH_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[FORD_E150_MODEL_05_RESEARCH_CONTRACT_TEST] - %s" % failure_message)
	quit(1)