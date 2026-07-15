extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/ford_e150_2012.md"

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
		inventory.contains("Ford E-150 Commercial Cargo Van, regular length, approved 2008–2014 high-tier exterior scope | full-size van | 1,844 | `approved`"),
		"model 05 has passed the owner-scope gate"
	)
	_expect(
		inventory.contains("| 05 — Ford E-150 Commercial Cargo Van | `docs/vehicles/traffic/ford_e150_2012.md` | 8 |"),
		"inventory records eight approved Ford E-150 configurations"
	)
	_expect(
		inventory.contains("Models 01, 02, 03, 04 and 05 have passed their individual owner-scope gates"),
		"inventory records the first five approved scopes"
	)
	_expect(
		inventory.contains("The next research target is model 06 — Ford Excursion 2000"),
		"research advances to model 06 without implementation"
	)


func _test_research_record() -> void:
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not research.is_empty(), "Ford E-150 research record is readable")
	for required_fragment: String in [
		"Ford E-150 Commercial Cargo Van — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **8 distinct 2008–2014 regular-length E-150 Commercial Cargo Van year-era/engine configurations**",
		"Source SHA-256: `b8fb9a407b091108ea4c36f12f609e65ae587108085ec4ac6e019842a9396c6e`",
		"Wheelbase | 138.0 in / 3.5052 m",
		"Total triangles | 1,844",
		"Approximate wheelbase-derived scale | 0.712154",
		"### 2008",
		"were **not yet FFV**",
		"### 2009–2010",
		"both the 4.6L and 5.4L became FFV-capable",
		"### 2011–2013",
		"AdvanceTrac with RSC became standard equipment",
		"### 2014",
		"dual sealed-beam headlamps",
		"4.6L Triton Modular SOHC naturally aspirated cross-plane V8",
		"5.4L Triton Modular SOHC naturally aspirated cross-plane V8",
		"four-speed planetary torque-converter automatic with overdrive",
		"Approved total: 8 regular-length E-150 Commercial Cargo Van year-era/engine configurations",
		"one standard factory rear-axle ratio verified for that exact year, engine and body",
		"an open differential",
		"selectable E85 state",
		"CNG/LPG Gaseous Engine Prep",
		"Crew Van Package",
		"E-150 Extended Cargo Van",
		"E-250 and E-350 full-body vans",
		"Model 05 is **`approved`** with **8** configurations",
		"Research proceeds to model 06",
	]:
		_expect(research.contains(required_fragment), "Ford E-150 approval preserves: %s" % required_fragment)
	_expect(
		not research.contains("Workflow status: **`awaiting_owner_scope`**"),
		"Ford E-150 no longer remains at the owner-scope gate"
	)


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
		print("[FORD_E150_MODEL_05_RESEARCH_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[FORD_E150_MODEL_05_RESEARCH_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[FORD_E150_MODEL_05_RESEARCH_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[FORD_E150_MODEL_05_RESEARCH_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[FORD_E150_MODEL_05_RESEARCH_CONTRACT_TEST] - %s" % failure_message)
	quit(1)