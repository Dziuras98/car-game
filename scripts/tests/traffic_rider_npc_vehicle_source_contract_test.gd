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
	_test_model_01_scope()
	_test_model_02_scope()
	_test_model_03_scope()
	_test_model_04_gate()
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
	var workflow: String = _read_text(WORKFLOW_PATH)
	_expect(not workflow.is_empty(), "workflow document is readable")
	for required_fragment: String in [
		"Research the complete factory variant matrix before importing the model",
		"Stop for owner approval after research",
		"Finish all model scopes before implementing any model",
		"Keep the committed source GLB unchanged",
		"Calibrate every model independently",
		"Use wheelbase as the primary scale reference",
		"Provide four independent wheel nodes",
		"Use explicit wheel bindings",
		"Match the real transmission architecture exactly",
		"Implement missing transmission types faithfully",
		"Reproduce performance from evidence, not from labels",
		"Build new engine-sound architectures from first principles",
		"Keep every model compatible with current `master` physics",
		"Stage 0 — complete vehicle and powertrain research",
		"A single row labelled only `automatic` is insufficient",
		"Mandatory owner decision gate",
		"Do you want all of them imported, or only a selected subset?",
		"No model may enter `integrating` until all included models have reached `approved`",
		"Stage 6 — implement the exact transmission architecture",
		"A classic automatic must never be represented as an automated manual",
		"A DCT must not be approximated by shortening a conventional automatic shift delay",
		"Do not force an unsupported transmission through a fallback path",
		"Do not match acceleration by using a false peak torque",
		"Mandatory `master` physics synchronization",
		"recalibrate every affected model to current physics",
		"must not use an unrelated cylinder layout as its primary waveform",
		"Stage 11 — mandatory validation",
		"Per-model integration record",
	]:
		_expect(workflow.contains(required_fragment), "workflow preserves: %s" % required_fragment)


func _test_inventory_and_global_gate() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	_expect(not inventory.is_empty(), "vehicle inventory is readable")
	for required_fragment: String in [
		"Mandatory status progression",
		"source_only",
		"researching",
		"awaiting_owner_scope",
		"approved",
		"integrating",
		"integrated",
		"Global research-before-implementation gate",
		"No Traffic Rider model may enter `integrating` until every included model has reached `approved`",
		"Models 01, 02 and 03 have passed their individual owner-scope gates",
		"Only after all 20 scopes are approved does implementation begin",
		"Total committed source geometry: **40,300 triangles**",
	]:
		_expect(inventory.contains(required_fragment), "inventory preserves: %s" % required_fragment)
	for asset_path: String in SOURCE_ASSETS:
		_expect(inventory.contains(asset_path.trim_prefix("res://")), "inventory lists %s" % asset_path)


func _test_model_01_scope() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	_expect(
		inventory.contains("| 01 — BMW 4 Series Coupé F32 pre-LCI | `docs/vehicles/traffic/bmw_4_series_2014.md` | 44 |"),
		"inventory records 44 approved BMW combinations"
	)
	var research: String = _read_text(BMW_RESEARCH_PATH)
	for required_fragment: String in [
		"Workflow status: **`approved`**",
		"Approved implementation scope: **44 mechanically distinct pre-LCI combinations**",
		"Approved total: 42 standard + 2 ZHP = 44 combinations",
		"Owner decision recorded",
		"Visual scope: **strictly pre-LCI**",
	]:
		_expect(research.contains(required_fragment), "BMW scope preserves: %s" % required_fragment)


func _test_model_02_scope() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	_expect(
		inventory.contains("| 02 — Chevrolet Silverado 1500 K2XX pre-facelift | `docs/vehicles/traffic/chevrolet_silverado_2014.md` | 4 |"),
		"inventory records four approved Silverado combinations"
	)
	var research: String = _read_text(SILVERADO_RESEARCH_PATH)
	for required_fragment: String in [
		"Workflow status: **`approved`**",
		"Approved implementation scope: **4 mechanically distinct RWD combinations**",
		"Approved total: 4 RWD combinations",
		"Hydra-Matic 6L80 6AT, RPO MYC",
		"Hydra-Matic 8L90 8AT, RPO M5U",
		"gasoline only",
	]:
		_expect(research.contains(required_fragment), "Silverado scope preserves: %s" % required_fragment)


func _test_model_03_scope() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	_expect(
		inventory.contains("| 03 — Renault Clio IV X98 hatchback | `docs/vehicles/traffic/renault_clio_2013.md` | 10 |"),
		"inventory records ten approved Clio combinations"
	)
	var research: String = _read_text(CLIO_RESEARCH_PATH)
	for required_fragment: String in [
		"Workflow status: **`approved`**",
		"Approved implementation scope: **10 mechanically distinct non-R.S., non-GT hatchback configurations**",
		"Approved total: 10 mechanically distinct non-R.S., non-GT configurations",
		"**exclude GT 120 EDC**",
		"six-speed dry dual-clutch transmission",
		"Model 03 is **`approved`** with **10** configurations",
	]:
		_expect(research.contains(required_fragment), "Clio scope preserves: %s" % required_fragment)
	_expect(not research.contains("| 7 | Phase 1 GT |"), "Clio GT is absent from the approved matrix")


func _test_model_04_gate() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	_expect(
		inventory.contains("Chevrolet Cruze J300 North American LS sedan, pre-facelift source | passenger sedan | 2,444 | `awaiting_owner_scope`"),
		"model 04 is at the owner-scope gate"
	)
	_expect(
		inventory.contains("26 base engine/transmission rows; 2 strict North American LS visual matches"),
		"inventory records Cruze candidate totals"
	)
	var research: String = _read_text(CRUZE_RESEARCH_PATH)
	for required_fragment: String in [
		"Chevrolet Cruze J300 sedan — research and owner-scope gate",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source SHA-256: `ac6af7b6894a8bbe327f4250b16ab5176ad16743f7141afbe6c0efc9cd61f251`",
		"2011-model-year North American Chevrolet Cruze LS sedan",
		"Total triangles | 2,444",
		"26 candidate engine/transmission rows",
		"strict unmodified North American LS source-texture scope: **2 rows**",
		"Hydra-Matic 6T30",
		"GM 6T40",
		"GM 6T45",
		"Aisin AF40-6",
		"Owner scope decision — required before implementation",
		"No implementation begins after this individual decision",
	]:
		_expect(research.contains(required_fragment), "Cruze gate preserves: %s" % required_fragment)


func _test_provenance_contract() -> void:
	var notice: String = _read_text(NOTICE_PATH)
	_expect(notice.contains("## Sketchfab Traffic Rider NPC vehicle bundle"), "third-party notice records the bundle")
	_expect(notice.contains("Mason (`ModelzRipper`)"), "third-party notice preserves uploader attribution")
	_expect(notice.contains("CC BY-NC 4.0"), "third-party notice preserves the uploader-stated license")
	_expect(notice.contains("incomplete upstream rights chain"), "third-party notice preserves the provenance warning")

	var risks: String = _read_text(RISK_PATH)
	_expect(risks.contains("## Traffic Rider NPC vehicle bundle provenance"), "accepted-risk record covers the bundle")
	_expect(
		risks.contains("The 20 source GLBs remain committed and are not added to `.gitignore`."),
		"accepted-risk record preserves committed source assets"
	)
	_expect(
		risks.contains("Scania, generic articulated truck and generic rigid truck remain excluded"),
		"accepted-risk record preserves heavy-truck exclusions"
	)


func _test_gitignore_contract() -> void:
	var gitignore: String = _read_text(GITIGNORE_PATH)
	_expect(not gitignore.contains("traffic_rider_npc_vehicles"), "Traffic Rider asset directory is not ignored")
	_expect(not gitignore.contains("*.glb"), "GLB files are not globally ignored")
	for asset_path: String in SOURCE_ASSETS:
		_expect(not gitignore.contains(asset_path.trim_prefix("res://")), "%s is not explicitly ignored" % asset_path)


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
