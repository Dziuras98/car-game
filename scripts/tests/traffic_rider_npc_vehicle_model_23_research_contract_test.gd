extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/volkswagen_amarok_2010.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	var research := _read_text(RESEARCH_PATH)
	for fragment: String in [
		"Volkswagen Amarok I type 2H pre-V6 Double Cab source | pickup | 2,684 | `awaiting_owner_scope`",
		"12 mechanically consolidated candidates: 5 original 122/163-PS diesel rows, 6 updated 140/180-PS diesel rows and 1 regional 2.0 TSI row",
		"After model 23 is approved, all included models will have passed their individual research gates",
	]:
		_expect(inventory.contains(fragment), "inventory preserves: %s" % fragment)
	for fragment: String in [
		"Volkswagen Amarok 2010 double-cab pre-V6 — research and owner-scope gate",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source GLB: `23_volkswagen_amarok_2010.glb`",
		"Source Git blob SHA-1: `2cb28a59e50ef4daf6707ae67a3d930de6a5687f`",
		"Source SHA-256: **pending direct binary hash capture before integration**",
		"Source triangles | 2,684",
		"Original 2010–2012 diesel range — 5 candidates",
		"Updated 2012–2016 diesel range — 6 candidates",
		"Regional petrol range — 1 candidate",
		"Mechanically consolidated candidate total: 12 pre-V6 Amarok configurations",
		"selectable 4MOTION with high/low transfer case",
		"permanent 4MOTION with Torsen-type centre differential",
		"ZF 8-speed hydrodynamic torque-converter planetary automatic",
		"Rows 5, 10 and 12 remain confirmation-gated",
		"Owner scope decision — required before implementation",
		"This is the final individual model gate",
	]:
		_expect(research.contains(fragment), "Amarok research preserves: %s" % fragment)
	_finish()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path): return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[AMAROK_MODEL_23_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[AMAROK_MODEL_23_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[AMAROK_MODEL_23_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	quit(1)