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
	_expect_fragments(_read(WORKFLOW_PATH), PackedStringArray([
		"copies every applicable research, approval, geometry, transmission, physics, audio and validation rule from PR #107",
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
	_expect_fragments(_read(INVENTORY_PATH), PackedStringArray([
		"retained vehicle identities: **18**",
		"GAZ Gazelle flatbed",
		"Gazelle: **van only**",
		"19,845 triangles",
		"Model 01 is now `researching`",
		"probable G 500 M113 5.0 V8",
	]), "inventory")
	_expect_fragments(_read(UPLOAD_PATH), PackedStringArray([
		"All 18 expected filenames are now present on the branch",
		"01 — Mercedes-Benz G-Class | present | complete",
		"14_gaz_gazelle_van.glb",
		"afc4628e07aa7006a5d11a8aff17bd100092c2f9899678cc874a4cc87f745fb7",
		"Only the Gazelle van is allowed in this branch",
	]), "source upload")
	_expect_fragments(_read(RECORDS[0]), PackedStringArray([
		"Workflow status: **`researching`**",
		"Verified source contract",
		"Represented identity assessment",
		"strongly_supported_identity",
		"Mandatory owner-scope gate",
		"PR #118",
	]), RECORDS[0])
	for index: int in range(1, RECORDS.size()):
		var path := RECORDS[index]
		_expect_fragments(_read(path), PackedStringArray([
			"Workflow status: **`source_only`**",
			"Mandatory owner-scope gate",
			"PR #118",
		]), path)
	_finish()


func _test_sources() -> void:
	for asset_path: String in SOURCE_ASSETS:
		_expect(FileAccess.file_exists(asset_path), "%s is committed" % asset_path)
		_expect(ResourceLoader.exists(asset_path, "PackedScene"), "%s imports as PackedScene" % asset_path)


func _read(path: String) -> String:
	if not FileAccess.file_exists(path): return ""
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
