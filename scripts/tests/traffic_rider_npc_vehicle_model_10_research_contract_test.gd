extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/volkswagen_golf_vii_2013.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not inventory.is_empty(), "vehicle inventory is readable")
	_expect(not research.is_empty(), "Golf VII research record is readable")
	for required_fragment: String in [
		"Volkswagen Golf VII five-door European pre-facelift standard TSI source | passenger hatchback | 1,982 | `awaiting_owner_scope`",
		"63 mechanically consolidated European hatchback powertrain rows: 26 standard petrol/TGI, 17 diesel, 17 performance petrol and 3 electrified",
		"After model 10 is approved, research continues with model 11",
	]:
		_expect(inventory.contains(required_fragment), "inventory preserves: %s" % required_fragment)
	for required_fragment: String in [
		"Volkswagen Golf VII hatchback — research and owner-scope gate",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source SHA-256: `d8ff27d0dd2dbfed76723cbe7c04d042af891a127a68fe0dbdbe8946f2220260`",
		"European/German-market 2013 Volkswagen Golf VII five-door hatchback",
		"Wheelbase | 2,637 mm / 2.637 m",
		"Total triangles | 1,982",
		"Approximate wheelbase-derived scale | 0.682000",
		"Standard petrol/TGI subtotal: 26 configurations",
		"Diesel subtotal: 17 configurations",
		"Performance petrol subtotal: 17 configurations",
		"Electrified subtotal: 3 configurations",
		"Mechanically consolidated candidate total: 63 configurations",
		"DQ200 seven-speed dry DSG",
		"DQ250 six-speed wet DSG",
		"DQ381 seven-speed wet DSG",
		"DQ400e hybrid DSG",
		"e-Golf single-speed reduction",
		"VAQ electronically controlled front differential",
		"torsion-beam rear axle",
		"multi-link rear axle",
		"Owner scope decision — required before implementation",
		"No implementation begins after this individual decision",
	]:
		_expect(research.contains(required_fragment), "Golf VII research preserves: %s" % required_fragment)
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
		print("[VOLKSWAGEN_GOLF_VII_MODEL_10_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[VOLKSWAGEN_GOLF_VII_MODEL_10_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[VOLKSWAGEN_GOLF_VII_MODEL_10_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[VOLKSWAGEN_GOLF_VII_MODEL_10_RESEARCH_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[VOLKSWAGEN_GOLF_VII_MODEL_10_RESEARCH_CONTRACT_TEST] - %s" % failure_message)
	quit(1)