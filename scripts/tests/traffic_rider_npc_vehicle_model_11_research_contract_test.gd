extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/kia_ceed_2012.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not inventory.is_empty(), "vehicle inventory is readable")
	_expect(not research.is_empty(), "Kia cee'd research record is readable")
	for required_fragment: String in [
		"Kia cee'd JD five-door European pre-facelift standard EcoDynamics-style source with approved complete powertrain scope | passenger hatchback | 2,134 | `approved`",
		"| 11 — Kia cee'd JD five-door hatchback | `docs/vehicles/traffic/kia_ceed_2012.md` | 15 |",
		"After model 12 is approved, research continues with model 13",
	]:
		_expect(inventory.contains(required_fragment), "inventory preserves: %s" % required_fragment)
	for required_fragment: String in [
		"Kia cee'd JD five-door hatchback — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **15 mechanically consolidated Kia cee'd JD five-door configurations**",
		"Source SHA-256: `bc84bc41e7a4ca000826b38153a64b3f66d0d2532c068da30038046d614ac941`",
		"European/UK-market Kia cee'd JD five-door hatchback",
		"Wheelbase | 2,650 mm / 2.650 m",
		"Total triangles | 2,134",
		"Approximate wheelbase-derived scale | 0.682033",
		"merged 110-PS pre-/post-facelift row",
		"Approved total: 8 petrol + 7 diesel = 15 mechanically consolidated configurations",
		"6-speed dry dual-clutch transaxle",
		"6-speed planetary torque-converter automatic",
		"7-speed dry dual-clutch transaxle",
		"Model 11 is **`approved`** with **15** configurations",
		"Research proceeds to model 12",
	]:
		_expect(research.contains(required_fragment), "Kia cee'd research preserves: %s" % required_fragment)
	_expect(not research.contains("Workflow status: **`awaiting_owner_scope`**"), "Kia cee'd owner gate is closed")
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
		print("[KIA_CEED_MODEL_11_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[KIA_CEED_MODEL_11_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[KIA_CEED_MODEL_11_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[KIA_CEED_MODEL_11_RESEARCH_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[KIA_CEED_MODEL_11_RESEARCH_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
