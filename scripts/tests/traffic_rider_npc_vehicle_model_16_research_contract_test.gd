extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/mercedes_benz_unimog_u5023_2013.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	var research := _read_text(RESEARCH_PATH)
	for fragment: String in [
		"Mercedes-Benz Unimog U5023 single-cab dropside source with approved U4023/U5023 mechanical scope | utility vehicle | 2,032 | `approved`",
		"| 16 — Mercedes-Benz Unimog U4023 / U5023 | `docs/vehicles/traffic/mercedes_benz_unimog_u5023_2013.md` | 2 |",
		"After model 17 is approved, research continues with model 18",
	]:
		_expect(inventory.contains(fragment), "inventory preserves: %s" % fragment)
	for fragment: String in [
		"Mercedes-Benz Unimog U4023 / U5023 extreme-off-road truck — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **2 mechanically distinct Unimog 437.4 chassis configurations**",
		"Source SHA-256: `d935aeb5e9aad2e60f0ffcadc28e14edd9902302fc038cd35ef67f01da4f8966`",
		"Mercedes-Benz Unimog U5023 extreme-off-road truck",
		"Wheelbase | 3,850 mm / 3.850 m",
		"Total triangles | 2,032",
		"Source wheelbase | approximately 5.474725 source units",
		"Approximate 3,850-mm-wheelbase scale | 0.703232",
		"Approved total: 2 mechanically distinct Unimog 437.4 chassis configurations",
		"OM934 LA 5.132L turbo-diesel inline-four",
		"UG 100E-8",
		"Unimog U4023",
		"Unimog U5023",
		"portal axles",
		"Owner decision recorded",
		"Model 16 is **`approved`** with **2** configurations",
		"Research proceeds to model 17",
	]:
		_expect(research.contains(fragment), "Unimog research preserves: %s" % fragment)
	_expect(not research.contains("Workflow status: **`awaiting_owner_scope`**"), "Unimog owner gate is closed")
	_finish()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path): return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[UNIMOG_MODEL_16_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[UNIMOG_MODEL_16_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[UNIMOG_MODEL_16_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	quit(1)
