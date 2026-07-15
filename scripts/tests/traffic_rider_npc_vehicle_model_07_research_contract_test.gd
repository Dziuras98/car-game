extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/ford_f150_limited_2013.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not inventory.is_empty(), "vehicle inventory is readable")
	_expect(not research.is_empty(), "Ford F-150 P415 research record is readable")
	for required_fragment: String in [
		"Ford F-150 Limited 2013 source; expanded 2009–2014 P415 SuperCrew 5.5-ft research | pickup | 1,758 | `awaiting_owner_scope`",
		"11 mechanically consolidated generation rows; 3.5 EcoBoost fixed to 4x2 and one standard axle; 7 rows if the same 4x2-only policy is applied to every engine",
		"After model 07 is approved, research continues with model 08",
	]:
		_expect(inventory.contains(required_fragment), "inventory preserves: %s" % required_fragment)
	for required_fragment: String in [
		"Ford F-150 P415 SuperCrew 5.5-ft box — research and owner-scope gate",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source SHA-256: `3be44b7f8f563efc57d259e0a3902dc55b2b347a0b34b2b90f55d75f541f6587`",
		"2013 Ford F-150 Limited SuperCrew with the 5.5-ft Styleside box",
		"Wheelbase | 144.5 in / 3.6703 m",
		"Total triangles | 1,758",
		"Approximate wheelbase-derived scale | 0.684403",
		"complete **2009–2014 P415 model-year generation**",
		"2009–2010",
		"2011–2014",
		"4.6L Modular SOHC 2-valve",
		"4.6L Modular SOHC 3-valve",
		"5.4L Triton Modular SOHC 3-valve",
		"3.7L Duratec Ti-VCT",
		"5.0L Coyote Ti-VCT",
		"3.5L EcoBoost DOHC twin-turbocharged direct-injected V6",
		"6.2L Boss SOHC",
		"4R75E-family 4-speed torque-converter automatic",
		"6R80-family 6-speed torque-converter automatic",
		"Mechanically consolidated candidate total: 11 rows",
		"3.5L EcoBoost scope to **4x2 only**",
		"one verified factory-standard rear-axle ratio",
		"The 3.5L EcoBoost was not a 2009–2010 factory engine",
		"2009–2012",
		"2013–2014",
		"Owner scope decision — remaining questions",
		"No implementation begins after this partial decision",
	]:
		_expect(research.contains(required_fragment), "Ford F-150 P415 research preserves: %s" % required_fragment)
	_expect(
		not research.contains("| 3.5L EcoBoost twin-turbo DI V6, 365 hp / 420 lb-ft | 6R80-family 6-speed torque-converter automatic | 4x4 |"),
		"owner-fixed EcoBoost 4x4 row remains excluded"
	)
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
		print("[FORD_F150_P415_MODEL_07_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[FORD_F150_P415_MODEL_07_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[FORD_F150_P415_MODEL_07_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[FORD_F150_P415_MODEL_07_RESEARCH_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[FORD_F150_P415_MODEL_07_RESEARCH_CONTRACT_TEST] - %s" % failure_message)
	quit(1)