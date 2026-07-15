extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/ford_f150_limited_2013.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not inventory.is_empty(), "vehicle inventory is readable")
	_expect(not research.is_empty(), "Ford F-150 Limited research record is readable")
	for required_fragment: String in [
		"Ford F-150 Limited SuperCrew 5.5-ft box, 2013 source | pickup | 1,758 | `awaiting_owner_scope`",
		"2 base drivetrain rows; up to 4 with separate 3.55/3.73 electronic-locking axle ratios",
		"After model 07 is approved, research continues with model 08",
	]:
		_expect(inventory.contains(required_fragment), "inventory preserves: %s" % required_fragment)
	for required_fragment: String in [
		"Ford F-150 Limited SuperCrew — research and owner-scope gate",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source SHA-256: `3be44b7f8f563efc57d259e0a3902dc55b2b347a0b34b2b90f55d75f541f6587`",
		"2013 Ford F-150 Limited SuperCrew with the 5.5-ft Styleside box",
		"Wheelbase | 144.5 in / 3.6703 m",
		"Total triangles | 1,758",
		"Approximate wheelbase-derived scale | 0.684403",
		"3.5L EcoBoost V6",
		"365 hp at 5,000 rpm",
		"420 lb-ft / 569 Nm at 2,500 rpm",
		"working identification **6R80**",
		"Base candidate total: 2 engine/transmission/drivetrain rows",
		"3.55 electronic-locking rear axle",
		"3.73 electronic-locking rear axle",
		"automatic/selectable 4x4 with two-speed transfer case",
		"22-inch polished wheels",
		"P275/45R22",
		"Owner scope decision — required before implementation",
		"No implementation begins after this individual decision",
	]:
		_expect(research.contains(required_fragment), "Ford F-150 Limited research preserves: %s" % required_fragment)
	_finish()


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[FORD_F150_LIMITED_MODEL_07_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[FORD_F150_LIMITED_MODEL_07_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[FORD_F150_LIMITED_MODEL_07_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[FORD_F150_LIMITED_MODEL_07_RESEARCH_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[FORD_F150_LIMITED_MODEL_07_RESEARCH_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
