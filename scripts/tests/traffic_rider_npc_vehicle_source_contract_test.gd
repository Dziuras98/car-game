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

const WORKFLOW_PATH := "res://docs/assets/traffic_rider_npc_vehicle_import_workflow.md"
const INVENTORY_PATH := "res://docs/assets/traffic_rider_npc_vehicle_inventory.md"
const NOTICE_PATH := "res://THIRD_PARTY_NOTICES.md"
const RISK_PATH := "res://docs/accepted_risks.md"
const GITIGNORE_PATH := "res://.gitignore"

const APPROVED_SCOPE_PATHS: Dictionary = {
	"res://docs/vehicles/traffic/bmw_4_series_2014.md": "Approved total: 42 standard + 2 ZHP = 44 combinations",
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

const AMAROK_RESEARCH_PATH := "res://docs/vehicles/traffic/volkswagen_amarok_2010.md"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_expect(SOURCE_ASSETS.size() == 20, "inventory contains exactly 20 source GLBs")
	_test_assets()
	_test_workflow()
	_test_inventory()
	_test_approved_scopes()
	_test_physics_dependency()
	_test_provenance()
	_test_gitignore()
	_finish()


func _test_assets() -> void:
	for asset_path: String in SOURCE_ASSETS:
		_expect(FileAccess.file_exists(asset_path), "%s is committed" % asset_path)
		_expect(ResourceLoader.exists(asset_path, "PackedScene"), "%s imports as PackedScene" % asset_path)
	for asset_path: String in EXCLUDED_ASSETS:
		_expect(not FileAccess.file_exists(asset_path), "%s remains excluded" % asset_path)


func _test_workflow() -> void:
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
	]), "workflow")


func _test_inventory() -> void:
	var inventory := _read_text(INVENTORY_PATH)
	_expect_fragments(inventory, PackedStringArray([
		"Mandatory status progression",
		"Global research-before-implementation gate",
		"Mandatory physics dependency gate — PR #118",
		"Research and owner-scope approval have been completed for all 20 included models",
		"All 20 models have passed their individual owner-scope gates",
		"Combined approved scope: **285 mechanically consolidated configurations**",
		"| 20 — Škoda Octavia III Combi pre-facelift | `docs/vehicles/traffic/skoda_octavia_combi_2013.md` | 35 |",
		"| 23 — Volkswagen Amarok I full generation | `docs/vehicles/traffic/volkswagen_amarok_2010.md` | 19 |",
		"PR #118 — `Rework per-wheel vehicle physics and recalibrate DPI v3`",
		"No implementation work may begin while this dependency remains unresolved",
		"Dual-rear-wheel source models additionally require all physical rear tyres",
		"Total committed source geometry: **40,300 triangles**",
	]), "inventory")
	for asset_path: String in SOURCE_ASSETS:
		_expect(inventory.contains(asset_path.trim_prefix("res://")), "inventory lists %s" % asset_path)
	for fragment: String in [
		"Nissan Atleon 2004 pre-facelift single-cab box truck with approved four-engine RWD scope | medium box truck | 2,076 | `approved`",
		"Škoda Octavia III type 5E Combi 2013 standard pre-facelift source with approved non-Scout scope | passenger estate | 2,010 | `approved`",
		"Volkswagen Amarok I type 2H original Double Cab source with approved full-generation scope | pickup | 2,684 | `approved`",
	]:
		_expect(inventory.contains(fragment), "inventory preserves scope: %s" % fragment)
	_expect(not inventory.contains("## Active owner-scope gates"), "inventory has no unresolved owner-scope gate")


func _test_approved_scopes() -> void:
	_expect(APPROVED_SCOPE_PATHS.size() == 20, "all 20 model records are approved")
	for path: String in APPROVED_SCOPE_PATHS:
		var text := _read_text(path)
		_expect_fragments(text, PackedStringArray([
			"Workflow status: **`approved`**",
			APPROVED_SCOPE_PATHS[path],
		]), "approved scope %s" % path)
		_expect(not text.contains("Workflow status: **`awaiting_owner_scope`**"), "%s owner gate is closed" % path)


func _test_physics_dependency() -> void:
	_expect_fragments(_read_text(AMAROK_RESEARCH_PATH), PackedStringArray([
		"Volkswagen Amarok I type 2H full-generation Double Cab — research and approved scope",
		"Workflow status: **`approved`**",
		"Approved implementation scope: **19 full-generation Volkswagen Amarok I configurations**",
		"Mandatory PR #118 implementation dependency",
		"PR #118, **Rework per-wheel vehicle physics and recalibrate DPI v3**",
		"No Traffic Rider vehicle may enter `integrating`",
		"All 20 Traffic Rider model scopes are now approved",
	]), "physics dependency")


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
	if not FileAccess.file_exists(path): return ""
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