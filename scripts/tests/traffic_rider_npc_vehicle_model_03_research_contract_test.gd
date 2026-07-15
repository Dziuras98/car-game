extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/renault_clio_2013.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_inventory_gate()
	_test_research_record()
	_finish()


func _test_inventory_gate() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	_expect(not inventory.is_empty(), "vehicle inventory is readable")
	_expect(
		inventory.contains("Renault Clio IV X98 five-door hatchback Phase 1 | passenger hatchback | 2,118 | `awaiting_owner_scope`"),
		"model 03 remains blocked at its owner-scope gate"
	)
	_expect(
		inventory.contains("docs/vehicles/traffic/renault_clio_2013.md"),
		"inventory links the Renault Clio research record"
	)
	_expect(
		inventory.contains("12 engine/calibration/transmission rows; 13 physical configurations after R.S. Sport/Cup split"),
		"inventory records the complete Clio candidate scope"
	)
	_expect(
		inventory.contains("After model 03 is approved, research continues with model 04"),
		"research order advances without implementation"
	)


func _test_research_record() -> void:
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not research.is_empty(), "Renault Clio research record is readable")
	for required_fragment: String in [
		"Renault Clio IV X98 Phase 1",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source SHA-256: `48081738ea28f0ef1360461c7790dadc4c4acc8547b5ac872dcd3a12606438b4`",
		"standard non-R.S. body",
		"Wheelbase | 2.589 m",
		"Total triangles | 2,118",
		"Approximate wheelbase-derived scale | 0.684016",
		"12 candidate engine/calibration/transmission rows",
		"13 candidate physical catalog configurations",
		"D4F-740 1.2 16V",
		"H4Bt/H4B 0.9 Energy TCe",
		"K9K-612 1.5 dCi",
		"H5Ft/H5F 1.2 TCe",
		"M5Mt/MR16DDT 1.6",
		"six-speed dry dual-clutch transmission",
		"Sport and Cup chassis are materially separate configurations",
		"R.S. 220 EDC Trophy",
		"disputed Phase 1 dCi 90 EDC",
		"Owner scope decision — required before implementation",
		"No implementation begins after this individual decision",
	]:
		_expect(research.contains(required_fragment), "Renault Clio research preserves: %s" % required_fragment)


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
		print("[CLIO_MODEL_03_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CLIO_MODEL_03_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CLIO_MODEL_03_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[CLIO_MODEL_03_RESEARCH_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CLIO_MODEL_03_RESEARCH_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
