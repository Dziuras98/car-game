extends SceneTree

const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const RESEARCH_PATH: String = "res://docs/vehicles/traffic/ford_e150_2012.md"

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
		inventory.contains("Ford E-150 Commercial Cargo Van, regular length, high-series exterior, 2012 | full-size van | 1,844 | `awaiting_owner_scope`"),
		"model 05 is blocked at its owner-scope gate"
	)
	_expect(
		inventory.contains("docs/vehicles/traffic/ford_e150_2012.md"),
		"inventory links the Ford E-150 research record"
	)
	_expect(
		inventory.contains("2 strict-source engine/transmission rows; 4 with both axle ratios; 8 with open/LSD split; 6/12/24 equivalents across all E-150 cargo/Wagon bodies"),
		"inventory records the complete Ford E-150 candidate structure"
	)
	_expect(
		inventory.contains("After model 05 is approved, research continues with model 06"),
		"research order advances without implementation"
	)


func _test_research_record() -> void:
	var research: String = _read_text(RESEARCH_PATH)
	_expect(not research.is_empty(), "Ford E-150 research record is readable")
	for required_fragment: String in [
		"Ford E-150 Commercial Cargo Van — research and owner-scope gate",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source SHA-256: `b8fb9a407b091108ea4c36f12f609e65ae587108085ec4ac6e019842a9396c6e`",
		"2012 Ford E-150 Commercial Cargo Van, regular length, rear-wheel drive",
		"Wheelbase | 138.0 in / 3.5052 m",
		"Total triangles | 1,844",
		"Approximate wheelbase-derived scale | 0.712154",
		"strict source body: **2 engine/transmission rows**",
		"all 2012 E-150 full-body variants: **6 body/engine/transmission rows**",
		"4.6L Triton Modular SOHC naturally aspirated V8, FFV",
		"225 hp @ 4,800 rpm; 286 lb-ft",
		"5.4L Triton Modular SOHC naturally aspirated V8, FFV",
		"255 hp @ 4,500 rpm; 350 lb-ft",
		"four-speed torque-converter automatic with overdrive",
		"3.73:1 and 4.10:1 rear axle ratios",
		"limited-slip rear axle",
		"**4 engine/final-drive configurations**",
		"**8 engine/final-drive/differential configurations**",
		"factory flexible-fuel engines capable of gasoline, E85 or intermediate blends",
		"5.4L CNG/LPG Gaseous Engine Prep Package",
		"Crew Van Package",
		"Ford Twin-I-Beam front suspension",
		"solid rear drive axle on dual-stage leaf springs",
		"Owner scope decision — required before implementation",
		"No implementation begins after this decision",
	]:
		_expect(research.contains(required_fragment), "Ford E-150 research preserves: %s" % required_fragment)


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
