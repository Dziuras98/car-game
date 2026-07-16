extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/mercedes_benz_sprinter_2014.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	var research := _read_text(RESEARCH_PATH)
	for fragment: String in [
		"Mercedes-Benz Sprinter W906 facelift long-wheelbase high-roof windowed single-rear-wheel van with approved RWD-only scope | full-size van | 1,536 | `approved`",
		"| 15 — Mercedes-Benz Sprinter W906 facelift RWD | `docs/vehicles/traffic/mercedes_benz_sprinter_2014.md` | 17 |",
		"After model 16 is approved, research continues with model 17",
	]:
		_expect(inventory.contains(fragment), "inventory preserves: %s" % fragment)
	for fragment: String in [
		"Mercedes-Benz Sprinter W906 facelift long high-roof van — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **17 mechanically consolidated facelift Sprinter RWD configurations**",
		"Source SHA-256: `e787e83373d2b454d4f47c46f5d5c7c2bffdf862edc9f85f8b16370bd86dbc3f`",
		"Most likely wheelbase | 4,325 mm / 4.325 m",
		"Approved total: 13 diesel RWD + 4 petrol/NGT RWD = 17 mechanically consolidated configurations",
		"5G-TRONIC/NAG1",
		"7G-TRONIC PLUS",
		"Explicitly excluded Sprinter 4x4 rows",
		"Model 15 is **`approved`** with **17** configurations",
		"Research proceeds to model 16",
	]:
		_expect(research.contains(fragment), "Sprinter research preserves: %s" % fragment)
	_expect(not research.contains("Workflow status: **`awaiting_owner_scope`**"), "Sprinter owner gate is closed")
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