extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/mazda_2_2011.md"

var _checks: int = 0
var _failures: Array[String] = []

func _initialize() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	var research := _read_text(RESEARCH_PATH)
	for fragment: String in [
		"North American 2011 Mazda2 Sport five-door facelift source with approved complete global powertrain scope | passenger hatchback | 1,770 | `approved`",
		"| 13 — Mazda2 / Demio DE five-door hatchback | `docs/vehicles/traffic/mazda_2_2011.md` | 16 |",
		"Models 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12 and 13 have passed their individual owner-scope gates",
	]:
		_expect(inventory.contains(fragment), "inventory preserves: %s" % fragment)
	for fragment: String in [
		"Mazda2 / Demio DE five-door hatchback — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **16 mechanically distinct Mazda2 / Demio DE five-door configurations**",
		"Source SHA-256: `39bd570da17e3b84382910f7b9561daa91e23c9cb3ce6b098cb8f4381d7e2a0e`",
		"North American 2011 Mazda2 Sport five-door hatchback",
		"Mazda e-4WD electric rear-axle traction assist",
		"1.3L SKYACTIV-G P3-VPS",
		"Demio EV permanent-magnet synchronous motor",
		"Approved total: 16 mechanically distinct Mazda2 / Demio DE five-door configurations",
		"Model 13 is **`approved`** with **16** configurations",
		"Research proceeds to model 14",
	]:
		_expect(research.contains(fragment), "Mazda2 research preserves: %s" % fragment)
	_expect(not research.contains("Workflow status: **`awaiting_owner_scope`**"), "Mazda2 owner gate is closed")
	_finish()

func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path): return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[MAZDA2_MODEL_13_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[MAZDA2_MODEL_13_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)

func _finish() -> void:
	if _failures.is_empty():
		print("[MAZDA2_MODEL_13_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	quit(1)