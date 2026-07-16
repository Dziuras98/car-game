extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/nissan_atleon_2004.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	var research := _read_text(RESEARCH_PATH)
	for fragment: String in [
		"Nissan Atleon 2004 pre-facelift single-cab box truck with approved four-engine RWD scope | medium box truck | 2,076 | `approved`",
		"| 18 — Nissan Atleon 2004 pre-facelift | `docs/vehicles/traffic/nissan_atleon_2004.md` | 4 |",
		"After model 20 is approved, research continues with model 23",
	]:
		_expect(inventory.contains(fragment), "inventory preserves: %s" % fragment)
	for fragment: String in [
		"Nissan Atleon 2004 pre-facelift box truck — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **4 pre-facelift Nissan Atleon RWD configurations**",
		"Source GLB: `18_nissan_atleon_2004.glb`",
		"Source Git blob SHA-1: `680e31baa11e5d7abf8d13b95b2638eb3db32e69`",
		"Source SHA-256: **pending direct binary hash capture before integration**",
		"Source triangles | 2,076",
		"BD30Ti 2.953L turbo-diesel inline-four",
		"B4.40Ti 3.989L turbo-diesel inline-four",
		"B6.60TiL 5.985L turbo-diesel inline-six",
		"B6.60TiH 5.985L turbo-diesel inline-six",
		"Approved total: 4 pre-facelift Nissan Atleon RWD configurations",
		"Explicitly excluded 4WD branch",
		"Owner decision recorded",
		"Model 18 is **`approved`** with **4** configurations",
		"Research proceeds to model 20",
	]:
		_expect(research.contains(fragment), "Atleon research preserves: %s" % fragment)
	_expect(not research.contains("Workflow status: **`awaiting_owner_scope`**"), "Atleon owner gate is closed")
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
