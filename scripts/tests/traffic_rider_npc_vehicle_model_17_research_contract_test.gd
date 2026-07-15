extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/nissan_atlas_2007.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	var research := _read_text(RESEARCH_PATH)
	for fragment: String in [
		"Nissan Atlas / Cabstar F24 2007 narrow single-cab flatbed source with approved RWD scope | light flatbed truck | 1,996 | `approved`",
		"| 17 — Nissan Atlas / Cabstar F24 | `docs/vehicles/traffic/nissan_atlas_2007.md` | 8 |",
		"After model 18 is approved, research continues with model 20",
	]:
		_expect(inventory.contains(fragment), "inventory preserves: %s" % fragment)
	for fragment: String in [
		"Nissan Atlas / Cabstar F24 single-cab flatbed — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **8 RWD Nissan Atlas / Cabstar F24 configurations**",
		"Source Git blob SHA-1: `8dcc240c7b26ec1821d30da11d3cf08e7f9daccf`",
		"Source SHA-256: **pending direct binary hash capture before integration**",
		"1,996 rendered triangles and 1,012 source vertices",
		"QR20DE 1.998L naturally aspirated petrol inline-four",
		"ZD30DDTi 2.953L common-rail turbo-diesel inline-four",
		"5-speed Aisin-family torque-converter automatic",
		"Approved total: 5 Japanese RWD + 3 European RWD = 8 Nissan Atlas / Cabstar F24 configurations",
		"Explicitly excluded 4WD configuration",
		"Owner decision recorded",
		"Model 17 is **`approved`** with **8** configurations",
		"Research proceeds to model 18",
	]:
		_expect(research.contains(fragment), "Atlas research preserves: %s" % fragment)
	_expect(not research.contains("Workflow status: **`awaiting_owner_scope`**"), "Atlas owner gate is closed")
	_finish()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path): return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[ATLAS_MODEL_17_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[ATLAS_MODEL_17_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ATLAS_MODEL_17_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	quit(1)
