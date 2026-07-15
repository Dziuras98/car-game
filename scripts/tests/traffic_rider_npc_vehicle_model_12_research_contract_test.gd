extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/renault_maxity_2008.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not inventory.is_empty(), "vehicle inventory is readable")
	_expect(not research.is_empty(), "Renault Maxity research record is readable")
	for required_fragment: String in [
		"Renault Maxity original-body single-cab short-wheelbase box truck with dual rear wheels | light box truck | 2,102 | `awaiting_owner_scope`",
		"6 mechanically consolidated powertrain rows: five diesel calibrations and Maxity Electric",
		"After model 12 is approved, research continues with model 13",
	]:
		_expect(inventory.contains(required_fragment), "inventory preserves: %s" % required_fragment)
	for required_fragment: String in [
		"Renault Maxity F24 single-cab box truck — research and owner-scope gate",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source SHA-256: `37dd295636b56ebaecee37c1d461ee64349ee0c0bb697dfb484e94e49b0132f3`",
		"single cab, enclosed box body and dual rear wheels",
		"Provisional source wheelbase | 2,500 mm / 2.500 m",
		"Total triangles | 2,102",
		"Source wheelbase | approximately 3.912804 source units",
		"Provisional 2,500-mm-wheelbase scale | approximately 0.638928",
		"Mechanically consolidated candidate total: 6 configurations",
		"DXi2.5 / Nissan YD25DDTi",
		"DXi3 / Nissan ZD30DDTi",
		"Renault Maxity Electric by PVI",
		"dedicated single-speed fixed-reduction electric driveline",
		"five- and six-speed diesel gearboxes are conventional driver-operated manuals",
		"Owner scope decision — required before implementation",
		"No implementation begins after this individual decision",
	]:
		_expect(research.contains(required_fragment), "Renault Maxity research preserves: %s" % required_fragment)
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
		print("[RENAULT_MAXITY_MODEL_12_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[RENAULT_MAXITY_MODEL_12_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[RENAULT_MAXITY_MODEL_12_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[RENAULT_MAXITY_MODEL_12_RESEARCH_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[RENAULT_MAXITY_MODEL_12_RESEARCH_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
