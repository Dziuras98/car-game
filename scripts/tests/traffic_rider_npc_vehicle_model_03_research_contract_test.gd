extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/renault_clio_2013.md"
const CLIO_SCOPE_PREFIX := "| 03 — Renault Clio IV X98 hatchback |"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_inventory_scope()
	_test_research_record()
	_finish()


func _test_inventory_scope() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	_expect(not inventory.is_empty(), "vehicle inventory is readable")
	_expect(
		inventory.contains("Renault Clio IV X98 five-door hatchback, Phase 1 source with approved Phase 1/Phase 2 scope | passenger hatchback | 2,118 | `approved`"),
		"model 03 remains approved"
	)
	var scope_line := _find_line_starting_with(inventory, CLIO_SCOPE_PREFIX)
	_expect(not scope_line.is_empty(), "inventory contains the dedicated Clio scope row")
	_expect(
		scope_line.contains("| 10 |"),
		"inventory records ten approved Clio configurations"
	)
	_expect(
		scope_line.contains("standard non-R.S., non-GT hatchback scope across Phase 1, Phase 2 and Clio Génération"),
		"inventory preserves the approved body and phase scope"
	)
	_expect(
		scope_line.contains("no GT, LPG, R.S., Estate, emissions-package or duplicate calibration rows"),
		"inventory records the final Clio exclusions"
	)
	_expect(
		not inventory.contains("| 03 — Renault Clio IV X98 hatchback | `docs/vehicles/traffic/renault_clio_2013.md` | 11 |"),
		"later approvals do not reopen the ten-row Clio scope"
	)
	_expect(
		inventory.contains("| 04 — Chevrolet Cruze J300 sedan | `docs/vehicles/traffic/chevrolet_cruze_2011.md` | 20 |"),
		"implementation order continues to the independently approved model 04 scope"
	)


func _test_research_record() -> void:
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not research.is_empty(), "Renault Clio research record is readable")
	for required_fragment: String in [
		"Renault Clio IV X98 — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **10 mechanically distinct non-R.S., non-GT hatchback configurations**",
		"Source SHA-256: `48081738ea28f0ef1360461c7790dadc4c4acc8547b5ac872dcd3a12606438b4`",
		"Wheelbase | 2.589 m",
		"Total triangles | 2,118",
		"Approximate wheelbase-derived scale | 0.684016",
		"Approved total: 10 mechanically distinct non-R.S., non-GT configurations",
		"H4B/H4Bt 0.9 TCe turbo I3, 75 PS",
		"H5F/H5Ft 1.2 TCe direct-injection turbo I4, 120 PS / approximately 205 Nm",
		"K9K 1.5 dCi turbo-diesel I4, 110 PS / approximately 260 Nm",
		"six-speed dry dual-clutch transmission",
		"exclude every LPG/bi-fuel variant",
		"**exclude GT 120 EDC**",
		"Phase 2 and Clio Génération rows require an accurate facelift derivative",
		"Model 03 is **`approved`** with **10** configurations",
		"Research proceeds to model 04",
	]:
		_expect(research.contains(required_fragment), "Renault Clio approval preserves: %s" % required_fragment)
	_expect(not research.contains("| 7 | Phase 1 GT |"), "GT 120 EDC is absent from the approved matrix")


func _find_line_starting_with(text: String, prefix: String) -> String:
	for line: String in text.split("\n"):
		if line.begins_with(prefix):
			return line
	return ""


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
		print("[CLIO_MODEL_03_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CLIO_MODEL_03_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CLIO_MODEL_03_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[CLIO_MODEL_03_RESEARCH_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CLIO_MODEL_03_RESEARCH_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
