extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/skoda_octavia_combi_2013.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	var research := _read_text(RESEARCH_PATH)
	for fragment: String in [
		"Škoda Octavia III type 5E Combi 2013 standard pre-facelift source with approved non-Scout scope | passenger estate | 2,010 | `approved`",
		"| 20 — Škoda Octavia III Combi pre-facelift | `docs/vehicles/traffic/skoda_octavia_combi_2013.md` | 35 |",
		"Models 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 16, 17, 18 and 20 have passed their individual owner-scope gates",
		"23 — Volkswagen Amarok I pre-V6",
	]:
		_expect(inventory.contains(fragment), "inventory preserves: %s" % fragment)
	for fragment: String in [
		"Škoda Octavia III Combi 2013 pre-facelift — research and approved scope",
		"Workflow status: **`approved`**",
		"Source GLB: `20_skoda_octavia_combi_2013.glb`",
		"Source Git blob SHA-1: `5f19949ae8f6d29ba0e4a58caeaf14d4044b75ec`",
		"Source SHA-256: **pending direct binary hash capture before integration**",
		"Source triangles | 2,010",
		"Approved total: 23 standard FWD + 5 ordinary 4×4 + 7 RS Combi = 35 configurations",
		"Standard-body petrol and G-TEC FWD — 15 configurations",
		"Standard-body diesel FWD — 8 configurations",
		"Standard/L&K-style 4×4 — 5 configurations",
		"Octavia RS Combi — 7 mechanically accurate, visually homogenized configurations",
		"Explicitly excluded Scout configurations",
		"DQ200 7-speed dry-clutch DSG",
		"DQ250 6-speed wet-clutch DSG",
		"Haldex fifth-generation AWD",
		"standard-body visual homogenization for every RS row",
		"Model 20 is **`approved`** with **35** configurations",
	]:
		_expect(research.contains(fragment), "Octavia approved scope preserves: %s" % fragment)
	_expect(not research.contains("Workflow status: **`awaiting_owner_scope`**"), "Octavia owner gate is closed")
	_finish()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path): return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[OCTAVIA_MODEL_20_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[OCTAVIA_MODEL_20_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[OCTAVIA_MODEL_20_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	quit(1)