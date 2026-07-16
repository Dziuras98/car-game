extends SceneTree

const WORKFLOW_PATH := "res://docs/assets/voyage_3_outlaw_vehicle_import_workflow.md"
const INVENTORY_PATH := "res://docs/assets/voyage_3_outlaw_vehicle_inventory.md"
const UPLOAD_PATH := "res://docs/assets/voyage_3_outlaw_source_upload.md"
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
	_expect(RECORDS.size() == 18, "exactly 18 retained model records")
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
	]), "inventory")
	_expect_fragments(_read(UPLOAD_PATH), PackedStringArray([
		"The GitHub connector used to create this draft cannot transfer local binary files",
		"14_gaz_gazelle_van.glb",
		"afc4628e07aa7006a5d11a8aff17bd100092c2f9899678cc874a4cc87f745fb7",
		"Only the Gazelle van is allowed in this branch",
	]), "source upload")
	for path: String in RECORDS:
		_expect_fragments(_read(path), PackedStringArray([
			"Workflow status: **`source_only`**",
			"Mandatory owner-scope gate",
			"PR #118",
		]), path)
	_finish()

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
