extends SceneTree

const MODEL_01_SOURCE := "res://assets/third_party/sketchfab/traffic_rider_npc_vehicles/bmw_4_series_f32/source/01_bmw_4_series_2014.glb"
const MODEL_01_SOURCE_SHA256 := "fab5af5379c45f780f2ccc608560b99cb441ebf0f66c06e8eef0cb7fcd28d510"
const MODEL_01_PROCESSED := "res://assets/third_party/sketchfab/traffic_rider_npc_vehicles/bmw_4_series_f32/processed/bmw_4_series_f32_processed.glb"
const MODEL_01_PROCESSED_SHA256 := "bd0dc99b51e9756b800aeece83e2cea794b69aa182b583487fccf50e53237369"
const MODEL_01_PROCESSOR := "res://tools/assets/process_traffic_rider_bmw_f32.py"
const MODEL_01_PROCESSOR_REPORT := "res://docs/assets/traffic_rider_bmw_f32_processed_visual.json"
const MODEL_01_OLD_SOURCE := "res://01_bmw_4_series_2014.glb"
const MODEL_01_VISUAL_SCENE := "res://scenes/traffic/vehicles/bmw_4_series_f32_visuals.tscn"
const MODEL_01_VISUAL_DEFINITION := "res://resources/traffic/vehicles/bmw_4_series_f32.tres"
const MODEL_01_RESEARCH_PATH := "res://docs/vehicles/traffic/bmw_4_series_2014.md"
const PHYSICS_BASELINE := "3743f5e95391b63a97e81b95050984b8240b7f30"

const SOURCE_ASSETS := [
	MODEL_01_SOURCE,
	"res://02_chevrolet_silverado_2014.glb",
	"res://03_renault_clio_2013.glb",
	"res://04_chevrolet_cruze_2011.glb",
	"res://05_ford_e150_2012.glb",
	"res://06_ford_excursion_2000.glb",
	"res://07_ford_f150_limited_2013.glb",
	"res://08_ford_transit_connect_2011.glb",
	"res://09_land_rover_freelander_2_2012.glb",
	"res://10_volkswagen_golf_vii_2013.glb",
	"res://11_kia_ceed_2012.glb",
	"res://12_renault_maxity_2008.glb",
	"res://13_mazda_2_2011.glb",
	"res://14_mazda_3_2014.glb",
	"res://15_mercedes_benz_sprinter_2014.glb",
	"res://16_mercedes_benz_unimog_u5023_2013.glb",
	"res://17_nissan_atlas_2007.glb",
	"res://18_nissan_atleon_2004.glb",
	"res://20_skoda_octavia_combi_2013.glb",
	"res://23_volkswagen_amarok_2010.glb",
]

const EXCLUDED_ASSETS := [
	"res://19_scania_truck.glb",
	"res://21_generic_articulated_truck.glb",
	"res://22_generic_rigid_truck.glb",
]

const WORKFLOW_PATH := "res://docs/assets/traffic_rider_npc_vehicle_import_workflow.md"
const INVENTORY_PATH := "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const NOTICE_PATH := "res://THIRD_PARTY_NOTICES.md"
const RISK_PATH := "res://docs/accepted_risks.md"
const GITIGNORE_PATH := "res://.gitignore"

const APPROVED_SCOPE_PATHS: Dictionary = {
	"res://docs/vehicles/traffic/chevrolet_silverado_2014.md": "Approved implementation scope: **4 mechanically distinct RWD combinations**",
	"res://docs/vehicles/traffic/renault_clio_2013.md": "Approved total: 10 mechanically distinct non-R.S., non-GT configurations",
	"res://docs/vehicles/traffic/chevrolet_cruze_2011.md": "Approved total: 20 mechanically distinct pre-facelift Chevrolet J300 sedan configurations",
	"res://docs/vehicles/traffic/ford_e150_2012.md": "Approved total: 2 regular-length E-150 Commercial Cargo Van configurations",
	"res://docs/vehicles/traffic/ford_excursion_2000.md": "Approved total: 5 pre-facelift Ford Excursion 4x2 configurations",
	"res://docs/vehicles/traffic/ford_f150_limited_2013.md": "Approved total: 7 mechanically consolidated Ford F-150 P415 SuperCrew 5.5-ft 4x2 configurations",
	"res://docs/vehicles/traffic/ford_transit_connect_2011.md": "Approved total: 6 mechanically consolidated Ford Transit Connect first-generation configurations",
	"res://docs/vehicles/traffic/land_rover_freelander_2_2012.md": "Approved total: 8 mechanically distinct Land Rover Freelander 2 / LR2 L359 configurations",
	"res://docs/vehicles/traffic/volkswagen_golf_vii_2013.md": "Approved total: 22 standard petrol + 14 ordinary diesel + 2 electric = 38 configurations",
	"res://docs/vehicles/traffic/kia_ceed_2012.md": "Approved total: 8 petrol + 7 diesel = 15 mechanically consolidated configurations",
	"res://docs/vehicles/traffic/renault_maxity_2008.md": "Approved total: 5 diesel + 1 electric = 6 mechanically consolidated configurations",
	"res://docs/vehicles/traffic/mazda_2_2011.md": "Approved total: 16 mechanically distinct Mazda2 / Demio DE five-door configurations",
	"res://docs/vehicles/traffic/mazda_3_2014.md": "Approved total: 11 petrol + 7 diesel + 1 hybrid = 19 mechanically distinct configurations",
	"res://docs/vehicles/traffic/mercedes_benz_sprinter_2014.md": "Approved total: 13 diesel RWD + 4 petrol/NGT RWD = 17 mechanically consolidated configurations",
	"res://docs/vehicles/traffic/mercedes_benz_unimog_u5023_2013.md": "Approved total: 2 mechanically distinct Unimog 437.4 chassis configurations",
	"res://docs/vehicles/traffic/nissan_atlas_2007.md": "Approved total: 5 Japanese RWD + 3 European RWD = 8 Nissan Atlas / Cabstar F24 configurations",
	"res://docs/vehicles/traffic/nissan_atleon_2004.md": "Approved total: 4 pre-facelift Nissan Atleon RWD configurations",
	"res://docs/vehicles/traffic/skoda_octavia_combi_2013.md": "Approved total: 23 standard FWD + 5 ordinary 4×4 + 7 RS Combi = 35 configurations",
	"res://docs/vehicles/traffic/volkswagen_amarok_2010.md": "Approved total: 5 original diesel + 6 updated diesel + 1 regional petrol + 7 V6 = 19 full-generation Amarok I configurations",
}

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_expect(SOURCE_ASSETS.size() == 20, "inventory contains exactly 20 source GLBs")
	_test_assets()
	_test_workflow()
	_test_inventory()
	_test_scope_states()
	_test_model_01_integration()
	_test_provenance()
	_test_gitignore()
	_finish()


func _test_assets() -> void:
	for asset_path: String in SOURCE_ASSETS:
		_expect(FileAccess.file_exists(asset_path), "%s is committed" % asset_path)
		_expect(ResourceLoader.exists(asset_path, "PackedScene"), "%s imports as PackedScene" % asset_path)
	_expect(not FileAccess.file_exists(MODEL_01_OLD_SOURCE), "model 01 root source duplicate is removed")
	_expect(FileAccess.get_sha256(MODEL_01_SOURCE) == MODEL_01_SOURCE_SHA256, "model 01 source bytes remain unchanged")
	_expect(FileAccess.file_exists(MODEL_01_PROCESSED), "model 01 processed GLB is committed")
	_expect(ResourceLoader.exists(MODEL_01_PROCESSED, "PackedScene"), "model 01 processed GLB imports as PackedScene")
	_expect(FileAccess.get_sha256(MODEL_01_PROCESSED) == MODEL_01_PROCESSED_SHA256, "model 01 processed GLB is deterministic")
	_expect(FileAccess.file_exists(MODEL_01_PROCESSOR), "model 01 processor is committed")
	_expect(FileAccess.file_exists(MODEL_01_PROCESSOR_REPORT), "model 01 processor report is committed")
	for asset_path: String in EXCLUDED_ASSETS:
		_expect(not FileAccess.file_exists(asset_path), "%s remains excluded" % asset_path)


func _test_workflow() -> void:
	_expect_fragments(_read_text(WORKFLOW_PATH), PackedStringArray([
		"Research the complete factory variant matrix before importing the model",
		"Stop for owner approval after research",
		"Keep the committed source GLB unchanged",
		"Use wheelbase as the primary scale reference",
		"Provide four independent wheel nodes",
		"Use explicit wheel bindings",
		"Match the real transmission architecture exactly",
		"Build new engine-sound architectures from first principles",
		"Stage 11 — mandatory validation",
	]), "workflow")


func _test_inventory() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	_expect_fragments(inventory, PackedStringArray([
		"Combined approved scope: **285 mechanically consolidated configurations**",
		"PR #118, **Rework per-wheel vehicle physics and recalibrate DPI v3**, was merged into `master`",
		PHYSICS_BASELINE,
		"| 1 | `%s` | BMW 4 Series Coupé F32 pre-LCI | passenger coupe | 1,780 | `integrating` |" % MODEL_01_SOURCE.trim_prefix("res://"),
		"Total committed source geometry: **40,300 triangles**",
		"model 02 remains queued until model 01 reaches `integrated`",
	]), "inventory")
	for asset_path: String in SOURCE_ASSETS:
		_expect(inventory.contains(asset_path.trim_prefix("res://")), "inventory lists %s" % asset_path)


func _test_scope_states() -> void:
	_expect(APPROVED_SCOPE_PATHS.size() == 19, "nineteen later model records remain approved")
	for path: String in APPROVED_SCOPE_PATHS:
		var text := _read_text(path)
		_expect_fragments(text, PackedStringArray([
			"Workflow status: **`approved`**",
			APPROVED_SCOPE_PATHS[path],
		]), "approved scope %s" % path)


func _test_model_01_integration() -> void:
	var record := _read_text(MODEL_01_RESEARCH_PATH)
	_expect_fragments(record, PackedStringArray([
		"Workflow status: **`integrating`**",
		PHYSICS_BASELINE,
		"Approved total: 42 standard + 2 ZHP = 44 combinations",
		MODEL_01_SOURCE.trim_prefix("res://"),
		MODEL_01_PROCESSED.trim_prefix("res://"),
		"`processed_visual_ready` is now `true`",
		"No powertrain, mass, gearing, tire, audio or performance value has been guessed",
	]), "model 01 integration record")
	_expect(ResourceLoader.exists(MODEL_01_VISUAL_SCENE, "PackedScene"), "model 01 visual wrapper imports")
	var definition := ResourceLoader.load(MODEL_01_VISUAL_DEFINITION) as TrafficVehicleVisualDefinition
	_expect(definition != null, "model 01 visual definition loads")
	if definition != null:
		_expect(definition.validate().is_empty(), "model 01 visual definition validates")
		_expect(definition.vehicle_id == &"bmw_4_series_f32", "model 01 vehicle id is stable")
		_expect(is_equal_approx(definition.visual_scale, definition.wheelbase_m / definition.source_wheelbase_units), "model 01 scale is wheelbase-derived")
		_expect(definition.processed_visual_ready, "model 01 exposes a validated processed visual")
		_expect(definition.processed_path == MODEL_01_PROCESSED, "model 01 definition references the canonical processed GLB")
		_expect(definition.processed_sha256 == MODEL_01_PROCESSED_SHA256, "model 01 definition records the processed GLB hash")
		_expect(not definition.body_path.is_empty(), "model 01 has an explicit body binding")
		_expect(not definition.front_left_wheel_path.is_empty(), "model 01 has an explicit front-left wheel binding")
		_expect(not definition.front_right_wheel_path.is_empty(), "model 01 has an explicit front-right wheel binding")
		_expect(not definition.rear_left_wheel_path.is_empty(), "model 01 has an explicit rear-left wheel binding")
		_expect(not definition.rear_right_wheel_path.is_empty(), "model 01 has an explicit rear-right wheel binding")


func _test_provenance() -> void:
	_expect_fragments(_read_text(NOTICE_PATH), PackedStringArray([
		"## Sketchfab Traffic Rider NPC vehicle bundle",
		"Mason (`ModelzRipper`)",
		"CC BY-NC 4.0",
		"incomplete upstream rights chain",
	]), "third-party notice")
	_expect_fragments(_read_text(RISK_PATH), PackedStringArray([
		"## Traffic Rider NPC vehicle bundle provenance",
		"The 20 source GLBs remain committed and are not added to `.gitignore`.",
		"Scania, generic articulated truck and generic rigid truck remain excluded",
	]), "accepted-risk record")


func _test_gitignore() -> void:
	var gitignore := _read_text(GITIGNORE_PATH)
	_expect(not gitignore.contains("traffic_rider_npc_vehicles"), "Traffic Rider assets are not ignored")
	_expect(not gitignore.contains("*.glb"), "GLBs are not globally ignored")


func _expect_fragments(text: String, fragments: PackedStringArray, label: String) -> void:
	_expect(not text.is_empty(), "%s document is readable" % label)
	for fragment: String in fragments:
		_expect(text.contains(fragment), "%s preserves: %s" % [label, fragment])


func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRAFFIC_RIDER_SOURCE_CONTRACT_TEST][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[TRAFFIC_RIDER_SOURCE_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRAFFIC_RIDER_SOURCE_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRAFFIC_RIDER_SOURCE_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	quit(1)
