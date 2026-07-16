extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/land_rover_freelander_2_2012.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not inventory.is_empty(), "vehicle inventory is readable")
	_expect(not research.is_empty(), "Freelander 2 research record is readable")
	for required_fragment: String in [
		"Land Rover LR2 HSE 2012 with approved complete Freelander 2 L359 powertrain scope | SUV | 2,130 | `approved`",
		"| 09 — Land Rover Freelander 2 / LR2 L359 | `docs/vehicles/traffic/land_rover_freelander_2_2012.md` | 8 |",
		"After model 10 is approved, research continues with model 11",
	]:
		_expect(inventory.contains(required_fragment), "inventory preserves: %s" % required_fragment)
	for required_fragment: String in [
		"Land Rover Freelander 2 / LR2 L359 — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **8 mechanically distinct Freelander 2 / LR2 engine, transmission and drivetrain configurations**",
		"Source SHA-256: `ba2cd619b59ff52a0e44ff48e17ea5fc91f89d59cdb4012597dc3b2628a20191`",
		"North American 2012 Land Rover LR2 HSE",
		"Wheelbase | approximately 2,660 mm / 2.660 m",
		"Total triangles | 2,130",
		"Approximate wheelbase-derived scale | 0.685986",
		"Approved total: 8 mechanically distinct Land Rover Freelander 2 / LR2 L359 configurations",
		"Volvo SI6 3.2L naturally aspirated transverse inline-six",
		"2.2L eD4 turbo-diesel inline-four",
		"2.2L SD4 turbo-diesel inline-four",
		"2.0L Si4 direct-injected turbocharged petrol inline-four",
		"Aisin AWF21 / TF-80SC-family",
		"front-wheel drive only",
		"on-demand AWD",
		"one common HSE-style version without trim duplication",
		"Exclude LPG and other conversions",
		"Model 09 is **`approved`** with **8** configurations",
		"Research proceeds to model 10",
	]:
		_expect(research.contains(required_fragment), "Freelander 2 research preserves: %s" % required_fragment)
	_expect(not research.contains("Workflow status: **`awaiting_owner_scope`**"), "Freelander 2 owner gate is closed")
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
		print("[LAND_ROVER_FREELANDER_MODEL_09_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[LAND_ROVER_FREELANDER_MODEL_09_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[LAND_ROVER_FREELANDER_MODEL_09_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[LAND_ROVER_FREELANDER_MODEL_09_RESEARCH_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[LAND_ROVER_FREELANDER_MODEL_09_RESEARCH_CONTRACT_TEST] - %s" % failure_message)
	quit(1)