extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/volkswagen_amarok_2010.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	var research := _read_text(RESEARCH_PATH)
	for fragment: String in [
		"Volkswagen Amarok I type 2H original Double Cab source with approved full-generation scope | pickup | 2,684 | `approved`",
		"| 23 — Volkswagen Amarok I full generation | `docs/vehicles/traffic/volkswagen_amarok_2010.md` | 19 |",
		"Combined approved scope: **285 mechanically consolidated configurations**",
		"PR #118 — `Rework per-wheel vehicle physics and recalibrate DPI v3`",
		"No implementation work may begin while this dependency remains unresolved",
	]:
		_expect(inventory.contains(fragment), "inventory preserves: %s" % fragment)
	for fragment: String in [
		"Volkswagen Amarok I type 2H full-generation Double Cab — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **19 full-generation Volkswagen Amarok I configurations**",
		"Source GLB: `23_volkswagen_amarok_2010.glb`",
		"Source Git blob SHA-1: `2cb28a59e50ef4daf6707ae67a3d930de6a5687f`",
		"Source SHA-256: **pending direct binary hash capture before integration**",
		"Source triangles | 2,684",
		"Nine production engine calibrations are retained",
		"Original 2010–2012 diesel range — 5 configurations",
		"Updated 2012–2016 four-cylinder diesel range — 6 configurations",
		"Regional four-cylinder petrol range — 1 configuration",
		"2016-onward V6 diesel range — 7 configurations",
		"EA897 evo DDXA 3.0 V6 TDI 120 kW / 163 PS",
		"EA897 evo DDXB 3.0 V6 TDI 150 kW / 204 PS",
		"EA897 evo DDXC 3.0 V6 TDI 165 kW / 224 PS",
		"EA897 evo DDXE 3.0 V6 TDI 190 kW / 258 PS",
		"Australian TDI500 calibration",
		"Approved total: 5 original diesel + 6 updated diesel + 1 regional petrol + 7 V6 = 19 full-generation Amarok I configurations",
		"selectable 4MOTION with high/low transfer case",
		"permanent 4MOTION with torque-sensing centre differential",
		"ZF-engineered 8-speed hydrodynamic torque-converter planetary automatic",
		"Rows 5, 10, 12, 13, 14, 15 and 18 remain confirmation-gated",
		"Mandatory PR #118 implementation dependency",
		"No Traffic Rider vehicle may enter `integrating`",
		"All 20 Traffic Rider model scopes are now approved",
	]:
		_expect(research.contains(fragment), "Amarok research preserves: %s" % fragment)
	_expect(not research.contains("Workflow status: **`awaiting_owner_scope`**"), "Amarok owner gate is closed")
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