extends SceneTree

const CAR_CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const TRACK_CATALOG: TrackCatalog = preload("res://resources/tracks/catalog.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_car_scene_root_validation()
	_test_ai_car_scene_root_validation()
	_test_track_scene_root_validation()
	_finish()


func _test_car_scene_root_validation() -> void:
	var source: CarVariantDefinition = CAR_CATALOG.get_all_variants()[0]
	var variant: CarVariantDefinition = source.duplicate(true) as CarVariantDefinition
	variant.car_scene = _pack_plain_node_scene()
	var errors: PackedStringArray = variant.validate()
	_expect(
		"car_scene must instantiate PlayerCarController on its root node" in errors,
		"car catalog validation rejects a non-controller player-car scene root"
	)


func _test_ai_car_scene_root_validation() -> void:
	var source: CarVariantDefinition = null
	for candidate: CarVariantDefinition in CAR_CATALOG.get_all_variants():
		if candidate != null and candidate.ai_eligible:
			source = candidate
			break
	_expect(source != null, "catalog provides an AI-eligible fixture variant")
	if source == null:
		return
	var variant: CarVariantDefinition = source.duplicate(true) as CarVariantDefinition
	variant.ai_car_scene = _pack_plain_node_scene()
	var errors: PackedStringArray = variant.validate()
	_expect(
		"ai_car_scene must instantiate PlayerCarController on its root node" in errors,
		"car catalog validation rejects a non-controller AI scene root"
	)
	_expect(not variant.is_ai_eligible_for_race(), "invalid AI scene root cannot remain race eligible")


func _test_track_scene_root_validation() -> void:
	var source: TrackDefinition = TRACK_CATALOG.get_default_track()
	_expect(source != null, "track catalog provides a default definition fixture")
	if source == null:
		return
	var definition: TrackDefinition = source.duplicate(true) as TrackDefinition
	definition.track_scene = _pack_plain_node_scene()
	_expect(not definition.is_valid(), "track definition rejects a non-GeneratedTrack scene root")


func _pack_plain_node_scene() -> PackedScene:
	var root_node: Node3D = Node3D.new()
	var scene: PackedScene = PackedScene.new()
	var result: Error = scene.pack(root_node)
	root_node.free()
	assert(result == OK)
	return scene


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[SCENE_ROOT_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[SCENE_ROOT_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SCENE_ROOT_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[SCENE_ROOT_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[SCENE_ROOT_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
