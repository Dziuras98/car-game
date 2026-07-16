extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/renault_maxity_2008.md"

var _checks: int = 0
var _failures: Array[String] = []

func _initialize() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	var research := _read_text(RESEARCH_PATH)
	for fragment: String in [
		"Renault Maxity original-body single-cab short-wheelbase box truck with approved complete six-powertrain scope | light box truck | 2,102 | `approved`",
		"| 12 — Renault Maxity F24 original body | `docs/vehicles/traffic/renault_maxity_2008.md` | 6 |",
		"After model 13 is approved, research continues with model 14",
	]:
		_expect(inventory.contains(fragment), "inventory preserves: %s" % fragment)
	for fragment: String in [
		"Renault Maxity F24 single-cab box truck — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **6 mechanically consolidated Renault Maxity powertrain configurations**",
		"Approved total: 5 diesel + 1 electric = 6 mechanically consolidated configurations",
		"Renault Maxity Electric by PVI",
		"dedicated single-speed fixed-reduction electric driveline",
		"Model 12 is **`approved`** with **6** configurations",
		"Research proceeds to model 13",
	]:
		_expect(research.contains(fragment), "Maxity scope preserves: %s" % fragment)
	_expect(not research.contains("Workflow status: **`awaiting_owner_scope`**"), "Maxity owner gate is closed")
	_finish()

func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path): return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[RENAULT_MAXITY_MODEL_12_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[RENAULT_MAXITY_MODEL_12_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)

func _finish() -> void:
	if _failures.is_empty():
		print("[RENAULT_MAXITY_MODEL_12_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	quit(1)
