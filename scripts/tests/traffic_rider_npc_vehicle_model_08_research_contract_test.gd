extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/ford_transit_connect_2011.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not inventory.is_empty(), "vehicle inventory is readable")
	_expect(not research.is_empty(), "Transit Connect research record is readable")
	for required_fragment: String in [
		"Ford Transit Connect XLT Premium Wagon 2011, long wheelbase and high roof | compact van | 1,650 | `awaiting_owner_scope`",
		"7 mechanically distinct powertrain rows; 6 without Azure Electric; 6 if the 75-PS diesels are merged; 1 strict source XLT Premium Wagon row",
		"After model 08 is approved, research continues with model 09",
	]:
		_expect(inventory.contains(required_fragment), "inventory preserves: %s" % required_fragment)
	for required_fragment: String in [
		"Ford Transit Connect first generation — research and owner-scope gate",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source SHA-256: `e506579960a582b33c7f91c9b3a6086f99cb9e97158f635c4e614de69d5b862b`",
		"North American 2011 Ford Transit Connect XLT Premium Wagon",
		"Wheelbase | 114.6 in / 2.91084 m",
		"Total triangles | 1,650",
		"Approximate wheelbase-derived scale | 0.700555",
		"Core candidate total: 7 mechanically distinct powertrain rows",
		"1.8L Zetec/Duratec 16-valve",
		"early 75-PS calibration",
		"1.8L Duratorq TDCi 90 PS",
		"1.8L Duratorq TDCi 110 PS",
		"2.0L Duratec DOHC",
		"4F27E",
		"Azure Dynamics Transit Connect Electric",
		"BorgWarner single-speed reduction transaxle",
		"All first-generation production powertrains are front-engine and front-wheel drive",
		"Owner scope decision — required before implementation",
		"No implementation begins after this individual decision",
	]:
		_expect(research.contains(required_fragment), "Transit Connect research preserves: %s" % required_fragment)
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
		print("[FORD_TRANSIT_CONNECT_MODEL_08_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[FORD_TRANSIT_CONNECT_MODEL_08_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[FORD_TRANSIT_CONNECT_MODEL_08_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[FORD_TRANSIT_CONNECT_MODEL_08_RESEARCH_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[FORD_TRANSIT_CONNECT_MODEL_08_RESEARCH_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
