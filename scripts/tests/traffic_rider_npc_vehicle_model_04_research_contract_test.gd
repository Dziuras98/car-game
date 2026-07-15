extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/chevrolet_cruze_2011.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_inventory_gate()
	_test_research_record()
	_finish()


func _test_inventory_gate() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	_expect(not inventory.is_empty(), "vehicle inventory is readable")
	_expect(
		inventory.contains("Chevrolet Cruze J300 North American LS sedan, pre-facelift source | passenger sedan | 2,444 | `awaiting_owner_scope`"),
		"model 04 is blocked at its owner-scope gate"
	)
	_expect(
		inventory.contains("docs/vehicles/traffic/chevrolet_cruze_2011.md"),
		"inventory links the Cruze research record"
	)
	_expect(
		inventory.contains("26 base engine/transmission rows; 2 strict North American LS visual matches"),
		"inventory records Cruze candidate scopes"
	)
	_expect(
		inventory.contains("After model 04 is approved, research continues with model 05"),
		"research order advances without implementation"
	)


func _test_research_record() -> void:
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not research.is_empty(), "Chevrolet Cruze research record is readable")
	for required_fragment: String in [
		"Chevrolet Cruze J300 sedan — research and owner-scope gate",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source SHA-256: `ac6af7b6894a8bbe327f4250b16ab5176ad16743f7141afbe6c0efc9cd61f251`",
		"2011-model-year North American Chevrolet Cruze LS sedan",
		"Wheelbase | 2.685 m",
		"Total triangles | 2,444",
		"Approximate wheelbase-derived scale | 0.675724",
		"26 candidate engine/transmission rows",
		"strict unmodified North American LS source-texture scope: **2 rows**",
		"LUW/LWE 1.8 naturally aspirated I4",
		"LUJ/LUV 1.4 turbo I4",
		"A14NET-family 1.4 turbo I4",
		"A17DTS/1.7 VCDi",
		"VM Motori/RA420 2.0 VCDi",
		"Family Z/LLW 2.0 VCDi",
		"LUZ/Multijet 2.0 turbo-diesel",
		"Hydra-Matic 6T30",
		"GM 6T40",
		"GM 6T45",
		"Aisin AF40-6",
		"China J300, from late 2011",
		"Brazil/South America",
		"Eco variants are not badge-only changes",
		"Owner scope decision — required before implementation",
		"No implementation begins after this individual decision",
	]:
		_expect(research.contains(required_fragment), "Chevrolet Cruze research preserves: %s" % required_fragment)


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
