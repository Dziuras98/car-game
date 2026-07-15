extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/nissan_atleon_2004.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	var research := _read_text(RESEARCH_PATH)
	for fragment: String in [
		"Nissan Atleon 2004 pre-facelift single-cab box truck | medium box truck | 2,076 | `awaiting_owner_scope`",
		"4 mechanically consolidated RWD engine rows: BD30Ti 110, B4.40Ti 140, B6.60TiL 165 and B6.60TiH 210",
		"After model 18 is approved, research continues with model 20",
	]:
		_expect(inventory.contains(fragment), "inventory preserves: %s" % fragment)
	for fragment: String in [
		"Nissan Atleon 2004 pre-facelift box truck — research and owner-scope gate",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source GLB: `18_nissan_atleon_2004.glb`",
		"Source Git blob SHA-1: `680e31baa11e5d7abf8d13b95b2638eb3db32e69`",
		"Source SHA-256: **pending direct binary hash capture before integration**",
		"Source triangles | 2,076",
		"BD30Ti 2.953L turbo-diesel inline-four",
		"B4.40Ti 3.989L turbo-diesel inline-four",
		"B6.60TiL 5.985L turbo-diesel inline-six",
		"B6.60TiH 5.985L turbo-diesel inline-six",
		"Mechanically consolidated candidate total: 4 pre-facelift RWD configurations",
		"Unresolved 4WD branch",
		"Owner scope decision — required before implementation",
		"No implementation begins after this individual decision",
	]:
		_expect(research.contains(fragment), "Atleon research preserves: %s" % fragment)
	_finish()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path): return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[ATLEON_MODEL_18_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[ATLEON_MODEL_18_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[ATLEON_MODEL_18_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	quit(1)
