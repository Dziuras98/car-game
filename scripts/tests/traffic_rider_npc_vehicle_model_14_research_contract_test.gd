extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/mazda_3_2014.md"

var _checks: int = 0
var _failures: Array[String] = []

func _initialize() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	var research := _read_text(RESEARCH_PATH)
	for fragment: String in [
		"North American 2014 Mazda3 BM five-door high-grade 2.5-style source with approved global BM/BN/BY scope | passenger hatchback | 1,842 | `approved`",
		"| 14 — Mazda3 BM / BN / BY | `docs/vehicles/traffic/mazda_3_2014.md` | 19 |",
		"After model 15 is approved, research continues with model 16",
	]:
		_expect(inventory.contains(fragment), "inventory preserves: %s" % fragment)
	for fragment: String in [
		"Mazda3 BM / BN five-door hatchback — research and approved scope",
		"Workflow status: **`approved`**",
		"Source SHA-256: `9b0877f05ffcbb6731b2db8a2d7dbaa07fb867c0bbab1d6596b83e2c87e055ad`",
		"Approved implementation scope: **19 mechanically distinct Mazda3 / Axela BM, BN and BY configurations**",
		"Wheelbase | approximately 2,700 mm / 2.700 m",
		"Total triangles | 1,842",
		"Approximate wheelbase-derived scale | 0.709707",
		"regional 1.6L MZR Z6 MPI",
		"i-ACTIV AWD",
		"Axela SKYACTIV-HYBRID",
		"Approved total: 11 petrol + 7 diesel + 1 hybrid = 19 mechanically distinct configurations",
		"Model 14 is **`approved`** with **19** configurations",
		"Research proceeds to model 15",
	]:
		_expect(research.contains(fragment), "Mazda3 research preserves: %s" % fragment)
	_expect(not research.contains("Workflow status: **`awaiting_owner_scope`**"), "Mazda3 owner gate is closed")
	_finish()

func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path): return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()

func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[MAZDA3_MODEL_14_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[MAZDA3_MODEL_14_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)

func _finish() -> void:
	if _failures.is_empty():
		print("[MAZDA3_MODEL_14_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	quit(1)