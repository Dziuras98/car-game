extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/mercedes_benz_sprinter_2014.md"

var _checks: int = 0
var _failures: Array[String] = []

func _initialize() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	var research := _read_text(RESEARCH_PATH)
	for fragment: String in [
		"Mercedes-Benz Sprinter W906 facelift long-wheelbase high-roof windowed single-rear-wheel van | full-size van | 1,536 | `awaiting_owner_scope`",
		"21 mechanically consolidated facelift powertrain rows: OM651/OM642 diesel, M271 petrol/NGT, RWD and Sprinter 4x4, with 6MT/5AT/7AT architectures",
		"After model 15 is approved, research continues with model 16",
	]:
		_expect(inventory.contains(fragment), "inventory preserves: %s" % fragment)
	for fragment: String in [
		"Mercedes-Benz Sprinter W906 facelift long high-roof van — research and owner-scope gate",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source SHA-256: `e787e83373d2b454d4f47c46f5d5c7c2bffdf862edc9f85f8b16370bd86dbc3f`",
		"facelift Mercedes-Benz Sprinter W906/NCV3",
		"Most likely wheelbase | 4,325 mm / 4.325 m",
		"Total triangles | 1,536",
		"Source wheelbase | approximately 5.539680 source units",
		"Approximate 4,325-mm-wheelbase scale | 0.780731",
		"Mechanically consolidated candidate total: 21 configurations",
		"OM651 2.143L four-cylinder diesel",
		"OM642 3.0L V6 diesel",
		"M271 E18 ML",
		"7G-TRONIC PLUS",
		"5G-TRONIC/NAG1",
		"selectable Sprinter 4x4",
		"Owner scope decision — required before implementation",
		"No implementation begins after this individual decision",
	]:
		_expect(research.contains(fragment), "Sprinter research preserves: %s" % fragment)
	_finish()

func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path): return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[SPRINTER_MODEL_15_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[SPRINTER_MODEL_15_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)

func _finish() -> void:
	if _failures.is_empty():
		print("[SPRINTER_MODEL_15_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	quit(1)