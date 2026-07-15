extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/mazda_2_2011.md"

var _checks: int = 0
var _failures: Array[String] = []

func _initialize() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	var research := _read_text(RESEARCH_PATH)
	for fragment: String in [
		"North American 2011 Mazda2 Sport five-door facelift source | passenger hatchback | 1,770 | `awaiting_owner_scope`",
		"16 mechanically consolidated global hatchback powertrain rows, including e-4WD and Demio EV",
		"After model 13 is approved, research continues with model 14",
	]:
		_expect(inventory.contains(fragment), "inventory preserves: %s" % fragment)
	for fragment: String in [
		"Mazda2 / Demio DE five-door hatchback — research and owner-scope gate",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source SHA-256: `39bd570da17e3b84382910f7b9561daa91e23c9cb3ce6b098cb8f4381d7e2a0e`",
		"North American 2011 Mazda2 Sport five-door hatchback",
		"Total triangles | 1,770",
		"Source wheelbase | approximately 3.581292 source units",
		"Approximate wheelbase-derived scale | 0.695056",
		"Mechanically consolidated candidate total: 16 configurations",
		"1.3L SKYACTIV-G P3-VPS",
		"Mazda e-4WD electric rear-axle traction assist",
		"Demio EV permanent-magnet synchronous traction motor",
		"4-speed planetary torque-converter automatic",
		"continuously variable transaxle",
		"Owner scope decision — required before implementation",
		"No implementation begins after this individual decision",
	]:
		_expect(research.contains(fragment), "Mazda2 research preserves: %s" % fragment)
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
