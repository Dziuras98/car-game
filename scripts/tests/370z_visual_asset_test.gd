extends SceneTree

const CAR_SCENE_PATH: String = "res://scenes/cars/370z.tscn"
const VISUAL_ASSET_PATHS: Array[String] = [
	"res://assets/cars/nissan/370z/370z_2016_eu_body_front.obj",
	"res://assets/cars/nissan/370z/370z_2016_eu_body_center.obj",
	"res://assets/cars/nissan/370z/370z_2016_eu_rear_and_details.obj",
	"res://assets/cars/nissan/370z/370z_2016_eu_glass_lighting_trim.obj",
	"res://assets/cars/nissan/370z/370z_2016_eu_wheel.obj",
]
const VISUAL_NODE_PATHS: Array[String] = [
	"VisualRoot/BodyFront",
	"VisualRoot/BodyCenter",
	"VisualRoot/RearAndDetails",
	"VisualRoot/GlassLightingTrim",
	"VisualRoot/WheelFrontLeft",
	"VisualRoot/WheelFrontRight",
	"VisualRoot/WheelRearLeft",
	"VisualRoot/WheelRearRight",
]

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_visual_assets_import()
	_test_base_scene_contract()
	_finish()


func _test_visual_assets_import() -> void:
	var surface_count: int = 0
	for asset_path: String in VISUAL_ASSET_PATHS:
		var mesh := load(asset_path) as Mesh
		_expect(mesh != null, "%s imports as a Mesh" % asset_path)
		if mesh != null:
			surface_count += mesh.get_surface_count()
	_expect(surface_count >= 5, "the visual asset exposes at least one imported surface per source mesh")


func _test_base_scene_contract() -> void:
	var packed_scene := load(CAR_SCENE_PATH) as PackedScene
	_expect(packed_scene != null, "the base 370Z scene loads")
	if packed_scene == null:
		return

	var car := packed_scene.instantiate()
	_expect(car is PlayerCarController, "the base scene keeps PlayerCarController as its root contract")
	for node_path: String in VISUAL_NODE_PATHS:
		_expect(car.get_node_or_null(node_path) is MeshInstance3D, "%s is present as a MeshInstance3D" % node_path)

	_expect(car.get_node_or_null("LowerBody") == null, "the legacy box-based LowerBody visual is removed")
	_expect(car.get_node_or_null("LongHood") == null, "the legacy box-based LongHood visual is removed")
	_expect(car.get_node_or_null("EngineAudio") is AudioStreamPlayer3D, "the engine-audio node contract is preserved")
	_expect(car.get_node_or_null("TireSquealAudio") is AudioStreamPlayer3D, "the tire-audio node contract is preserved")

	var front_left := car.get_node_or_null("VisualRoot/WheelFrontLeft") as MeshInstance3D
	var front_right := car.get_node_or_null("VisualRoot/WheelFrontRight") as MeshInstance3D
	var rear_left := car.get_node_or_null("VisualRoot/WheelRearLeft") as MeshInstance3D
	var rear_right := car.get_node_or_null("VisualRoot/WheelRearRight") as MeshInstance3D
	if front_left != null and front_right != null:
		_expect(is_equal_approx(absf(front_right.position.x - front_left.position.x), 1.55), "front wheel track matches the 2016 European specification")
	if rear_left != null and rear_right != null:
		_expect(is_equal_approx(absf(rear_right.position.x - rear_left.position.x), 1.595), "rear wheel track matches the 2016 European specification")
	if front_left != null and rear_left != null:
		_expect(is_equal_approx(absf(rear_left.position.z - front_left.position.z), 2.55), "wheelbase matches the 2016 European specification")

	car.free()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[370Z_VISUAL_ASSET_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[370Z_VISUAL_ASSET_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[370Z_VISUAL_ASSET_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[370Z_VISUAL_ASSET_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[370Z_VISUAL_ASSET_TEST] - %s" % failure_message)
	quit(1)
