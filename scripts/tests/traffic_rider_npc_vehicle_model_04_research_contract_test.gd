extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/chevrolet_cruze_2011.md"

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
		inventory.contains("Chevrolet Cruze J300 North American LS sedan, pre-facelift source and approved global pre-facelift scope | passenger sedan | 2,444 | `approved`"),
		"model 04 has passed its owner-scope gate"
	)
	_expect(
		inventory.contains("| 04 — Chevrolet Cruze J300 sedan | `docs/vehicles/traffic/chevrolet_cruze_2011.md` | 20 |"),
		"inventory records twenty approved Cruze configurations"
	)
	_expect(
		inventory.contains("The next research target is model 05 — Ford E-150 2012"),
		"research order advances without implementation"
	)


func _test_research_record() -> void:
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not research.is_empty(), "Chevrolet Cruze research record is readable")
	for required_fragment: String in [
		"Chevrolet Cruze J300 sedan — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **20 mechanically distinct pre-facelift Chevrolet-badged J300 sedan configurations**",
		"Source SHA-256: `ac6af7b6894a8bbe327f4250b16ab5176ad16743f7141afbe6c0efc9cd61f251`",
		"2011-model-year North American Chevrolet Cruze LS sedan",
		"Wheelbase | 2.685 m",
		"Total triangles | 2,444",
		"Approximate wheelbase-derived scale | 0.675724",
		"Approved total: 20 mechanically distinct pre-facelift Chevrolet J300 sedan configurations",
		"LUW/LWE 1.8 naturally aspirated I4",
		"LUJ/LUV 1.4 turbo I4",
		"LUZ/Multijet 2.0 turbo-diesel I4",
		"VM Motori/RA420 2.0 VCDi",
		"Family Z/LLW 2.0 VCDi",
		"China J300, from late 2011, pre-facelift body",
		"approved, gasoline only",
		"Hydra-Matic 6T30",
		"Hydra-Matic 6T40",
		"GM 6T45",
		"Aisin AF40-6",
		"original rows 7–8: facelift-era European A14NET",
		"original rows 16–17: facelift-era A17DTS",
		"original row 26: petrol/LPG bi-fuel",
		"all North American Eco manual/automatic package subdivisions",
		"Provisional rows are approved for catalog scope immediately",
		"Missing expected variants: **none identified by the owner**",
		"Model 04 is **`approved`** with **20** configurations",
		"Research proceeds to model 05",
	]:
		_expect(research.contains(required_fragment), "Chevrolet Cruze approval preserves: %s" % required_fragment)

	_expect(not research.contains("Workflow status: **`awaiting_owner_scope`**"), "Cruze owner gate is closed")
	_expect(not research.contains("A17DTS/1.7 VCDi turbo-diesel I4, approximately 110 PS / 280 Nm | conventional 6MT | **approved"), "facelift-only 1.7 diesel is not approved")


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
		print("[CRUZE_MODEL_04_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CRUZE_MODEL_04_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CRUZE_MODEL_04_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[CRUZE_MODEL_04_RESEARCH_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CRUZE_MODEL_04_RESEARCH_CONTRACT_TEST] - %s" % failure_message)
	quit(1)