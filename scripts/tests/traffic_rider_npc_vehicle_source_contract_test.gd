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
const BMW_F32_RESEARCH_PATH: String = "res://docs/vehicles/traffic/bmw_4_series_2014.md"
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
	_test_research_and_owner_gate_contract()
	_test_powertrain_fidelity_contract()
	_test_physics_and_audio_contract()
	_test_inventory_status_contract()
	_test_first_model_research_gate()
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
		"Keep the committed source GLB unchanged",
		"Calibrate every model independently",
		"Use wheelbase as the primary scale reference",
		"Provide four independent wheel nodes",
		"Use explicit wheel bindings",
		"Stage 11 — mandatory validation",
		"Per-model integration record",
	]:
		_expect(workflow.contains(required_fragment), "workflow preserves: %s" % required_fragment)

	var inventory: String = _read_text(INVENTORY_PATH)
	_expect(not inventory.is_empty(), "vehicle inventory is readable")
	_expect(inventory.contains("Total committed source geometry: **40,300 triangles**"), "inventory records the inspected source triangle total")
	for asset_path: String in SOURCE_ASSETS:
		_expect(inventory.contains(asset_path.trim_prefix("res://")), "inventory lists %s" % asset_path)


func _test_research_and_owner_gate_contract() -> void:
	var workflow: String = _read_text(WORKFLOW_PATH)
	for required_fragment: String in [
		"Research the complete factory variant matrix before importing the model",
		"Stage 0 — complete vehicle and powertrain research",
		"Enumerate every factory combination",
		"A single row labelled only `automatic` is insufficient",
		"Mandatory owner decision gate",
		"Do you want all of them imported, or only a selected subset?",
		"Is any engine, transmission, drivetrain or model-year variant missing from this list?",
		"A model must not skip `awaiting_owner_scope`",
	]:
		_expect(workflow.contains(required_fragment), "research/owner gate preserves: %s" % required_fragment)


func _test_powertrain_fidelity_contract() -> void:
	var workflow: String = _read_text(WORKFLOW_PATH)
	for required_fragment: String in [
		"Match the real transmission architecture exactly",
		"Implement missing transmission types faithfully",
		"Stage 6 — implement the exact transmission architecture",
		"A classic automatic must never be represented as an automated manual",
		"A DCT must not be approximated by shortening a conventional automatic shift delay",
		"create a dedicated transmission model",
		"Do not force an unsupported transmission through a fallback path",
		"Reproduce performance from evidence, not from labels",
		"sampled full-load torque curve",
		"Do not match acceleration by using a false peak torque",
	]:
		_expect(workflow.contains(required_fragment), "powertrain fidelity preserves: %s" % required_fragment)


func _test_physics_and_audio_contract() -> void:
	var workflow: String = _read_text(WORKFLOW_PATH)
	for required_fragment: String in [
		"Keep every model compatible with current `master` physics",
		"Mandatory `master` physics synchronization",
		"all models and variants added earlier in the PR",
		"recalibrate every affected model in the PR to the new physics",
		"Build new engine-sound architectures from first principles",
		"build a new architecture-specific synthesis model from first principles",
		"must not use an unrelated cylinder layout as its primary waveform",
		"perceptual distinction from unrelated engine layouts",
	]:
		_expect(workflow.contains(required_fragment), "physics/audio fidelity preserves: %s" % required_fragment)


func _test_inventory_status_contract() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	for required_fragment: String in [
		"Mandatory status progression",
		"source_only",
		"researching",
		"awaiting_owner_scope",
		"approved",
		"integrating",
		"integrated",
		"Integration remains blocked until the owner confirms whether to import all variants or a subset",
	]:
		_expect(inventory.contains(required_fragment), "inventory status gate preserves: %s" % required_fragment)


func _test_first_model_research_gate() -> void:
	var inventory: String = _read_text(INVENTORY_PATH)
	_expect(
		inventory.contains("BMW 4 Series Coupé F32 pre-LCI | passenger coupe | 1,780 | `awaiting_owner_scope`"),
		"model 01 remains blocked at the owner-scope gate"
	)
	_expect(
		inventory.contains("docs/vehicles/traffic/bmw_4_series_2014.md"),
		"inventory links the BMW F32 research record"
	)

	var research: String = _read_text(BMW_F32_RESEARCH_PATH)
	_expect(not research.is_empty(), "BMW F32 research record is readable")
	for required_fragment: String in [
		"BMW 4 Series Coupé F32 pre-LCI",
		"Workflow status: **`awaiting_owner_scope`**",
		"Source SHA-256: `fab5af5379c45f780f2ccc608560b99cb441ebf0f66c06e8eef0cb7fcd28d510`",
		"**42**",
		"23 petrol + 19 diesel",
		"ZF 8HP-family torque-converter automatics",
		"B38",
		"N20",
		"B48",
		"N55",
		"B58",
		"N47",
		"B47",
		"N57",
		"Owner scope decision — required before implementation",
		"Is any expected engine, transmission, drivetrain or model-year variant missing",
		"No implementation starts until this decision is recorded",
	]:
		_expect(research.contains(required_fragment), "BMW F32 research preserves: %s" % required_fragment)


func _test_provenance_contract() -> void:
	var notice: String = _read_text(NOTICE_PATH)
	_expect(notice.contains("## Sketchfab Traffic Rider NPC vehicle bundle"), "third-party notice records the bundle")
	_expect(notice.contains("Mason (`ModelzRipper`)"), "third-party notice preserves uploader attribution")
	_expect(notice.contains("CC BY-NC 4.0"), "third-party notice preserves the uploader-stated license")
	_expect(notice.contains("incomplete upstream rights chain"), "third-party notice preserves the provenance warning")

	var risks: String = _read_text(RISK_PATH)
	_expect(risks.contains("## Traffic Rider NPC vehicle bundle provenance"), "accepted-risk record covers the bundle")
	_expect(risks.contains("The 20 source GLBs remain committed and are not added to `.gitignore`."), "accepted-risk record preserves committed source assets")
	_expect(risks.contains("Scania, generic articulated truck and generic rigid truck remain excluded"), "accepted-risk record preserves the heavy-truck exclusion")


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
