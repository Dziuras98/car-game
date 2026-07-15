extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/nissan_atlas_2007.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	var research := _read_text(RESEARCH_PATH)
	for fragment: String in [
		"Nissan Atlas / Cabstar F24 2007 narrow single-cab flatbed source | light flatbed truck | 1,996 | `awaiting_owner_scope`",
		"9 mechanically consolidated candidates: six Japanese Atlas QR20DE/ZD30DDTi rows and three European Cabstar YD25/ZD30 rows",
		"After model 17 is approved, research continues with model 18",
	]:
		_expect(inventory.contains(fragment), "inventory preserves: %s" % fragment)
	for fragment: String in [
		"Nissan Atlas / Cabstar F24 single-cab flatbed — research and owner-scope gate",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source GLB: `17_nissan_atlas_2007.glb`",
		"Source Git blob SHA-1: `8dcc240c7b26ec1821d30da11d3cf08e7f9daccf`",
		"Source SHA-256: **pending direct binary hash capture before integration**",
		"1,996 rendered triangles and 1,012 source vertices",
		"QR20DE 1.998L naturally aspirated petrol inline-four",
		"ZD30DDTi 2.953L common-rail turbo-diesel inline-four",
		"5-speed Aisin-family torque-converter automatic",
		"6-speed conventional manual",
		"European Nissan Cabstar F24 candidates",
		"Mechanically consolidated candidate total: 9 configurations",
		"Owner scope decision — required before implementation",
		"No implementation begins after this individual decision",
	]:
		_expect(research.contains(fragment), "Atlas research preserves: %s" % fragment)
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
