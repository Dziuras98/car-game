extends SceneTree

const SOURCE_ASSETS: PackedStringArray = PackedStringArray([
	"res://01_bmw_4_series_2014.glb",
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
])

const EXCLUDED_ASSETS: PackedStringArray = PackedStringArray([
	"res://19_scania_truck.glb",
	"res://21_generic_articulated_truck.glb",
	"res://22_generic_rigid_truck.glb",
])

const WORKFLOW_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_import_workflow.md"
const INVENTORY_PATH: String = "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const BMW_RESEARCH_PATH: String = "res://docs/vehicles/traffic/bmw_4_series_2014.md"
const SILVERADO_RESEARCH_PATH: String = "res://docs/vehicles/traffic/chevrolet_silverado_2014.md"
const CLIO_RESEARCH_PATH: String = "res://docs/vehicles/traffic/renault_clio_2013.md"
const CRUZE_RESEARCH_PATH: String = "res://docs/vehicles/traffic/chevrolet_cruze_2011.md"
const E150_RESEARCH_PATH: String = "res://docs/vehicles/traffic/ford_e150_2012.md"
const EXCURSION_RESEARCH_PATH: String = "res://docs/vehicles/traffic/ford_excursion_2000.md"
const F150_RESEARCH_PATH: String = "res://docs/vehicles/traffic/ford_f150_limited_2013.md"
const TRANSIT_CONNECT_RESEARCH_PATH: String = "res://docs/vehicles/traffic/ford_transit_connect_2011.md"
const FREELANDER_RESEARCH_PATH: String = "res://docs/vehicles/traffic/land_rover_freelander_2_2012.md"
const GOLF_RESEARCH_PATH: String = "res://docs/vehicles/traffic/volkswagen_golf_vii_2013.md"
const NOTICE_PATH: String = "res://THIRD_PARTY_NOTICES.md"
const RISK_PATH: String = "res://docs/accepted_risks.md"
const GITIGNORE_PATH: String = "res://.gitignore"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_expect(SOURCE_ASSETS.size() == 20, "inventory contains exactly 20 source GLBs")
	_test_committed_source_assets()
	_test_excluded_large_trucks()
	_test_workflow_contract()
	_test_inventory_and_global_gate()
	_test_model_scopes()
	_test_provenance_contract()
	_test_gitignore_contract()
	_finish()


func _test_committed_source_assets() -> void:
	for asset_path: String in SOURCE_ASSETS:
		_expect(FileAccess.file_exists(asset_path), "%s is committed" % asset_path)
		_expect(ResourceLoader.exists(asset_path, "PackedScene"), "%s is imported as a PackedScene" % asset_path)


func _test_excluded_large_trucks() -> void:
	for asset_path: String in EXCLUDED_ASSETS:
		_expect(not FileAccess.file_exists(asset_path), "%s remains excluded" % asset_path)


func _test_workflow_contract() -> void:
	_expect_fragments(_read_text(WORKFLOW_PATH), PackedStringArray([
		"Research the complete factory variant matrix before importing the model",
		"Stop for owner approval after research",
		"Finish all model scopes before implementing any model",
		"Keep the committed source GLB unchanged",
		"Use wheelbase as the primary scale reference",
		"Provide four independent wheel nodes",
		"Use explicit wheel bindings",
		"Match the real transmission architecture exactly",
		"Implement missing transmission types faithfully",
		"Build new engine-sound architectures from first principles",
		"Keep every model compatible with current `master` physics",
		"No model may enter `integrating` until all included models have reached `approved`",
		"Stage 11 — mandatory validation",
	]), "workflow preserves")


func _test_inventory_and_global_gate() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	_expect_fragments(inventory, PackedStringArray([
		"Mandatory status progression",
		"Global research-before-implementation gate",
		"No Traffic Rider model may enter `integrating` until every included model has reached `approved`",
		"Models 01, 02, 03, 04, 05, 06, 07, 08 and 09 have passed their individual owner-scope gates",
		"10 — Volkswagen Golf VII hatchback",
		"After model 10 is approved, research continues with model 11",
		"Total committed source geometry: **40,300 triangles**",
	]), "inventory preserves")
	for asset_path: String in SOURCE_ASSETS:
		_expect(inventory.contains(asset_path.trim_prefix("res://")), "inventory lists %s" % asset_path)


func _test_model_scopes() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	for required_fragment: String in [
		"| 01 — BMW 4 Series Coupé F32 pre-LCI | `docs/vehicles/traffic/bmw_4_series_2014.md` | 44 |",
		"| 02 — Chevrolet Silverado 1500 K2XX pre-facelift | `docs/vehicles/traffic/chevrolet_silverado_2014.md` | 4 |",
		"| 03 — Renault Clio IV X98 hatchback | `docs/vehicles/traffic/renault_clio_2013.md` | 10 |",
		"| 04 — Chevrolet Cruze J300 sedan | `docs/vehicles/traffic/chevrolet_cruze_2011.md` | 20 |",
		"| 05 — Ford E-150 Commercial Cargo Van | `docs/vehicles/traffic/ford_e150_2012.md` | 2 |",
		"| 06 — Ford Excursion pre-facelift XLT 4x2 | `docs/vehicles/traffic/ford_excursion_2000.md` | 5 |",
		"| 07 — Ford F-150 P415 SuperCrew 5.5-ft 4x2 | `docs/vehicles/traffic/ford_f150_limited_2013.md` | 7 |",
		"| 08 — Ford Transit Connect first generation | `docs/vehicles/traffic/ford_transit_connect_2011.md` | 6 |",
		"| 09 — Land Rover Freelander 2 / LR2 L359 | `docs/vehicles/traffic/land_rover_freelander_2_2012.md` | 8 |",
		"Volkswagen Golf VII five-door European pre-facelift standard TSI source | passenger hatchback | 1,982 | `awaiting_owner_scope`",
	]:
		_expect(inventory.contains(required_fragment), "inventory preserves scope: %s" % required_fragment)

	_expect_fragments(_read_text(BMW_RESEARCH_PATH), PackedStringArray([
		"Workflow status: **`approved`**",
		"Approved total: 42 standard + 2 ZHP = 44 combinations",
	]), "BMW scope preserves")
	_expect_fragments(_read_text(SILVERADO_RESEARCH_PATH), PackedStringArray([
		"Workflow status: **`approved`**",
		"Approved implementation scope: **4 mechanically distinct RWD combinations**",
	]), "Silverado scope preserves")
	var clio: String = _read_text(CLIO_RESEARCH_PATH)
	_expect_fragments(clio, PackedStringArray([
		"Workflow status: **`approved`**",
		"Approved total: 10 mechanically distinct non-R.S., non-GT configurations",
		"**exclude GT 120 EDC**",
	]), "Clio scope preserves")
	_expect(not clio.contains("| 7 | Phase 1 GT |"), "Clio GT is absent from the approved matrix")
	_expect_fragments(_read_text(CRUZE_RESEARCH_PATH), PackedStringArray([
		"Workflow status: **`approved`**",
		"Approved total: 20 mechanically distinct pre-facelift Chevrolet J300 sedan configurations",
	]), "Cruze scope preserves")
	_expect_fragments(_read_text(E150_RESEARCH_PATH), PackedStringArray([
		"Workflow status: **`approved`**",
		"Approved total: 2 regular-length E-150 Commercial Cargo Van configurations",
	]), "E-150 scope preserves")
	_expect_fragments(_read_text(EXCURSION_RESEARCH_PATH), PackedStringArray([
		"Workflow status: **`approved`**",
		"Approved total: 5 pre-facelift Ford Excursion 4x2 configurations",
		"**7.3 early**, model year 2000",
		"**7.3 late**, 2002–early 2003",
	]), "Excursion scope preserves")

	var f150: String = _read_text(F150_RESEARCH_PATH)
	_expect_fragments(f150, PackedStringArray([
		"Workflow status: **`approved`**",
		"Approved implementation scope: **7 mechanically consolidated 4x2 engine configurations**",
		"Approved total: 7 mechanically consolidated Ford F-150 P415 SuperCrew 5.5-ft 4x2 configurations",
		"22-in P275/45R22 tyres for every row",
	]), "F-150 scope preserves")
	_expect(not f150.contains("Workflow status: **`awaiting_owner_scope`**"), "F-150 owner gate is closed")

	var transit: String = _read_text(TRANSIT_CONNECT_RESEARCH_PATH)
	_expect_fragments(transit, PackedStringArray([
		"Workflow status: **`approved`**",
		"Approved implementation scope: **6 mechanically consolidated first-generation powertrain configurations**",
		"merged 75-PS early/late row",
		"dedicated BorgWarner single-speed fixed-reduction transaxle",
		"Approved total: 6 mechanically consolidated Ford Transit Connect first-generation configurations",
	]), "Transit Connect scope preserves")
	_expect(not transit.contains("Workflow status: **`awaiting_owner_scope`**"), "Transit Connect owner gate is closed")

	var freelander: String = _read_text(FREELANDER_RESEARCH_PATH)
	_expect_fragments(freelander, PackedStringArray([
		"Land Rover Freelander 2 / LR2 L359 — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **8 mechanically distinct Freelander 2 / LR2 engine, transmission and drivetrain configurations**",
		"Approved total: 8 mechanically distinct Land Rover Freelander 2 / LR2 L359 configurations",
		"front-wheel drive only",
		"on-demand AWD",
		"Model 09 is **`approved`** with **8** configurations",
		"Research proceeds to model 10",
	]), "Freelander 2 scope preserves")
	_expect(not freelander.contains("Workflow status: **`awaiting_owner_scope`**"), "Freelander 2 owner gate is closed")

	_expect_fragments(_read_text(GOLF_RESEARCH_PATH), PackedStringArray([
		"Volkswagen Golf VII hatchback — research and owner-scope gate",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source SHA-256: `d8ff27d0dd2dbfed76723cbe7c04d042af891a127a68fe0dbdbe8946f2220260`",
		"European/German-market 2013 Volkswagen Golf VII five-door hatchback",
		"Mechanically consolidated candidate total: 63 configurations",
		"DQ200 seven-speed dry DSG",
		"DQ250 six-speed wet DSG",
		"DQ381 seven-speed wet DSG",
		"DQ400e hybrid DSG",
		"e-Golf single-speed reduction",
		"Owner scope decision — required before implementation",
	]), "Golf VII gate preserves")


func _test_provenance_contract() -> void:
	_expect_fragments(_read_text(NOTICE_PATH), PackedStringArray([
		"## Sketchfab Traffic Rider NPC vehicle bundle",
		"Mason (`ModelzRipper`)",
		"CC BY-NC 4.0",
		"incomplete upstream rights chain",
	]), "third-party notice preserves")
	_expect_fragments(_read_text(RISK_PATH), PackedStringArray([
		"## Traffic Rider NPC vehicle bundle provenance",
		"The 20 source GLBs remain committed and are not added to `.gitignore`.",
		"Scania, generic articulated truck and generic rigid truck remain excluded",
	]), "accepted-risk record preserves")


func _test_gitignore_contract() -> void:
	var gitignore: String = _read_text(GITIGNORE_PATH)
	_expect(not gitignore.contains("traffic_rider_npc_vehicles"), "Traffic Rider asset directory is not ignored")
	_expect(not gitignore.contains("*.glb"), "GLB files are not globally ignored")
	for asset_path: String in SOURCE_ASSETS:
		_expect(not gitignore.contains(asset_path.trim_prefix("res://")), "%s is not explicitly ignored" % asset_path)


func _expect_fragments(text: String, fragments: PackedStringArray, label: String) -> void:
	_expect(not text.is_empty(), "%s document is readable" % label)
	for fragment: String in fragments:
		_expect(text.contains(fragment), "%s: %s" % [label, fragment])


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
		print("[TRAFFIC_RIDER_SOURCE_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRAFFIC_RIDER_SOURCE_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRAFFIC_RIDER_SOURCE_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRAFFIC_RIDER_SOURCE_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TRAFFIC_RIDER_SOURCE_CONTRACT_TEST] - %s" % failure_message)
	quit(1)