extends SceneTree

const WORKFLOW_PATH := "res://docs/assets/voyage_3_outlaw_vehicle_import_workflow.md"
const INVENTORY_PATH := "res://docs/assets/voyage_3_outlaw_vehicle_inventory.md"
const UPLOAD_PATH := "res://docs/assets/voyage_3_outlaw_source_upload.md"

const SOURCE_ASSETS: PackedStringArray = PackedStringArray([
	"res://01_mercedes_benz_g_class.glb",
	"res://02_bmw_m3_e92.glb",
	"res://03_mitsubishi_lancer_evolution.glb",
	"res://04_liaz_bus.glb",
	"res://05_lada_2104.glb",
	"res://06_lada_2112.glb",
	"res://07_uaz_hunter_police.glb",
	"res://08_mercedes_benz_s_class_s600.glb",
	"res://09_lada_niva.glb",
	"res://10_kamaz_military.glb",
	"res://11_honda_jazz_saw.glb",
	"res://12_lada_kalina.glb",
	"res://13_lada_granta.glb",
	"res://14_gaz_gazelle_van.glb",
	"res://15_vaz_1111_oka.glb",
	"res://16_lada_2107.glb",
	"res://17_lada_2115_samara.glb",
	"res://18_gaz_volga_rust.glb",
])

const RECORDS: PackedStringArray = PackedStringArray([
	"res://docs/vehicles/traffic/mercedes_benz_g_class.md",
	"res://docs/vehicles/traffic/bmw_m3_e92.md",
	"res://docs/vehicles/traffic/mitsubishi_lancer_evolution.md",
	"res://docs/vehicles/traffic/liaz_bus.md",
	"res://docs/vehicles/traffic/lada_2104.md",
	"res://docs/vehicles/traffic/lada_2112.md",
	"res://docs/vehicles/traffic/uaz_hunter_police.md",
	"res://docs/vehicles/traffic/mercedes_benz_s_class_s600.md",
	"res://docs/vehicles/traffic/lada_niva.md",
	"res://docs/vehicles/traffic/kamaz_military.md",
	"res://docs/vehicles/traffic/honda_jazz_saw.md",
	"res://docs/vehicles/traffic/lada_kalina.md",
	"res://docs/vehicles/traffic/lada_granta.md",
	"res://docs/vehicles/traffic/gaz_gazelle_van.md",
	"res://docs/vehicles/traffic/vaz_1111_oka.md",
	"res://docs/vehicles/traffic/lada_2107.md",
	"res://docs/vehicles/traffic/lada_2115_samara.md",
	"res://docs/vehicles/traffic/gaz_volga_rust.md",
])

var _checks := 0
var _failures: Array[String] = []


func _initialize() -> void:
	_expect(SOURCE_ASSETS.size() == 18, "exactly 18 retained source GLBs")
	_expect(RECORDS.size() == 18, "exactly 18 retained model records")
	_test_sources()
	_test_workflow_contract()
	_test_inventory_contract()
	_test_upload_contract()
	_test_model_01_contract()
	_test_queued_records()
	_finish()


func _test_workflow_contract() -> void:
	_expect_fragments(_read(WORKFLOW_PATH), PackedStringArray([
		"authoritative orchestration procedure",
		"traffic_rider_transmission_implementation_contract.md",
		"traffic_rider_engine_audio_implementation_contract.md",
		"traffic_rider_npc_vehicle_research_data_contract.md",
		"traffic_rider_npc_vehicle_physics_v3_baseline.md",
		"traffic_rider_npc_vehicle_workflow_suite.md",
		"No abbreviated model note may weaken or replace those contracts",
		"No model may enter `integrating` until all 18 included models have reached `approved`",
		"3743f5e95391b63a97e81b95050984b8240b7f30",
		"Retain research as structured input",
		"Treat the transmission and driveline as a complete torque path",
		"Define player and AI audio backends explicitly",
		"Factory special-order vehicles",
		"Structured migration gate",
		"selectable 4WD requires real 2H/4H/4L/range semantics",
		"Limiter torque cut is not pedal lift",
		"Windows export and packaged smoke test",
		"Model 02 remains queued until model 01 reaches `integrated`",
		"fc81ebccf14687d6fa6b941dd23e4d60993487a9",
	]), "workflow")


func _test_inventory_contract() -> void:
	_expect_fragments(_read(INVENTORY_PATH), PackedStringArray([
		"retained vehicle identities: **18**",
		"Gazelle: **van only**",
		"19,845 triangles",
		"PR #118 is merged",
		"exclude all G 500 Guard B4/B6/B7 derivatives",
		"include the original G 63 AMG V12",
		"ten currently identified mechanically distinct candidate configurations",
		"Model 02 queued until model 01 is `integrated`",
	]), "inventory")


func _test_upload_contract() -> void:
	_expect_fragments(_read(UPLOAD_PATH), PackedStringArray([
		"All 18 expected filenames are now present on the branch",
		"01 — Mercedes-Benz G-Class | present | complete",
		"14_gaz_gazelle_van.glb",
		"afc4628e07aa7006a5d11a8aff17bd100092c2f9899678cc874a4cc87f745fb7",
		"Only the Gazelle van is allowed in this branch",
	]), "source upload")


func _test_model_01_contract() -> void:
	var record := _read(RECORDS[0])
	_expect_fragments(record, PackedStringArray([
		"Workflow status: **`researching`**",
		"Verified source contract",
		"Owner scope directions recorded during research",
		"Exclude every G 500 Guard derivative",
		"Include the original G 63 AMG V12 special-order model",
		"current requested scope contains **10 mechanically distinct configurations**",
		"`w463_g63_v12_m137`",
		"M137 E63 / M137.980",
		"326 kW / 444 PS",
		"620 Nm",
		"`strongly_supported_factory_special_order`",
		"`rejected_by_owner_scope`",
		"dedicated naturally aspirated V12 audio architecture",
		"PR #118 is merged",
	]), RECORDS[0])


func _test_queued_records() -> void:
	for index: int in range(1, RECORDS.size()):
		var path := RECORDS[index]
		_expect_fragments(_read(path), PackedStringArray([
			"Workflow status: **`source_only`**",
			"Mandatory owner-scope gate",
		]), path)


func _test_sources() -> void:
	for asset_path: String in SOURCE_ASSETS:
		_expect(FileAccess.file_exists(asset_path), "%s is committed" % asset_path)
		_expect(ResourceLoader.exists(asset_path, "PackedScene"), "%s imports as PackedScene" % asset_path)


func _read(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()


func _expect_fragments(text: String, fragments: PackedStringArray, label: String) -> void:
	_expect(not text.is_empty(), "%s is readable" % label)
	for fragment: String in fragments:
		_expect(text.contains(fragment), "%s contains %s" % [label, fragment])


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[VOYAGE_3_WORKFLOW_CONTRACT][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[VOYAGE_3_WORKFLOW_CONTRACT][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[VOYAGE_3_WORKFLOW_CONTRACT] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[VOYAGE_3_WORKFLOW_CONTRACT] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	quit(1)
