extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/mazda_3_2014.md"

var _checks: int = 0
var _failures: Array[String] = []

func _initialize() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	var research := _read_text(RESEARCH_PATH)
	for fragment: String in [
		"North American 2014 Mazda3 BM five-door high-grade 2.5-style source | passenger hatchback | 1,842 | `awaiting_owner_scope`",
		"19 mechanically consolidated global powertrain rows, including i-ACTIV AWD and sedan-only SKYACTIV-HYBRID",
		"After model 14 is approved, research continues with model 15",
	]:
		_expect(inventory.contains(fragment), "inventory preserves: %s" % fragment)
	for fragment: String in [
		"Mazda3 BM / BN five-door hatchback — research and owner-scope gate",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source SHA-256: `9b0877f05ffcbb6731b2db8a2d7dbaa07fb867c0bbab1d6596b83e2c87e055ad`",
		"North American 2014 Mazda3 five-door hatchback",
		"Wheelbase | approximately 2,700 mm / 2.700 m",
		"Total triangles | 1,842",
		"Source wheelbase | approximately 3.804384 source units",
		"Approximate wheelbase-derived scale | 0.709707",
		"Mechanically consolidated candidate total: 19 configurations",
		"1.5L SKYACTIV-G P5-VPS",
		"2.5L SKYACTIV-G PY-VPS",
		"1.5L SKYACTIV-D S5-DPTS/S5-DPTR",
		"2.2L SKYACTIV-D SH-VPTR",
		"i-ACTIV AWD",
		"SKYACTIV-HYBRID",
		"Owner scope decision — required before implementation",
		"No implementation begins after this individual decision",
	]:
		_expect(research.contains(fragment), "Mazda3 research preserves: %s" % fragment)
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