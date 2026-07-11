extends SceneTree

const CAR_SCENE_PATH: String = "res://scenes/cars/370z.tscn"
const LAMP_MOUNT_PATH: String = "res://assets/cars/nissan/370z/370z_2016_eu_lamp_mounts.obj"
const SPOILER_BRIDGE_PATH: String = "res://assets/cars/nissan/370z/370z_2016_eu_spoiler_bridge.obj"
const VISUAL_ASSET_PATHS: Array[String] = [
	"res://assets/cars/nissan/370z/370z_2016_eu_body_front.obj",
	"res://assets/cars/nissan/370z/370z_2016_eu_body_center.obj",
	"res://assets/cars/nissan/370z/370z_2016_eu_rear_and_details.obj",
	"res://assets/cars/nissan/370z/370z_2016_eu_glass_lighting_trim.obj",
	"res://assets/cars/nissan/370z/370z_2016_eu_wheel.obj",
	LAMP_MOUNT_PATH,
	SPOILER_BRIDGE_PATH,
]
const VISUAL_NODE_PATHS: Array[String] = [
	"VisualRoot/BodyFront",
	"VisualRoot/BodyCenter",
	"VisualRoot/RearAndDetails",
	"VisualRoot/LampMounts",
	"VisualRoot/RearSpoilerBridge",
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
	_test_attachment_mounting_geometry()
	_test_base_scene_contract()
	_finish()


func _test_visual_assets_import() -> void:
	var surface_count: int = 0
	for asset_path: String in VISUAL_ASSET_PATHS:
		var mesh := load(asset_path) as Mesh
		_expect(mesh != null, "%s imports as a Mesh" % asset_path)
		if mesh != null:
			surface_count += mesh.get_surface_count()
	_expect(surface_count >= 7, "the visual asset exposes at least one imported surface per source mesh")


func _test_attachment_mounting_geometry() -> void:
	var lamp_mounts := load(LAMP_MOUNT_PATH) as Mesh
	_expect(lamp_mounts != null, "lamp mounting pockets import")
	if lamp_mounts != null:
		var lamp_bounds: AABB = lamp_mounts.get_aabb()
		_expect(lamp_bounds.position.y <= 0.5521, "headlight pockets extend into the front body surface")
		_expect(lamp_bounds.end.y >= 0.9219, "taillight pockets reach the lamp undersides")
		_expect(lamp_bounds.position.z <= -2.0099, "headlight pockets cover the forward lamp tips")
		_expect(lamp_bounds.end.z >= 1.9649, "taillight pockets cover the rear lamp tips")

	var spoiler_bridge := load(SPOILER_BRIDGE_PATH) as Mesh
	_expect(spoiler_bridge != null, "rear spoiler bridge imports")
	if spoiler_bridge != null:
		var spoiler_bounds: AABB = spoiler_bridge.get_aabb()
		_expect(spoiler_bounds.position.y <= 0.7001, "spoiler bridge intersects the rear deck")
		_expect(spoiler_bounds.end.y >= 0.9679, "spoiler bridge reaches the spoiler underside")
		_expect(spoiler_bounds.position.z <= 1.6551, "spoiler bridge starts under the spoiler leading edge")
		_expect(spoiler_bounds.end.z >= 1.8849, "spoiler bridge reaches the spoiler trailing edge")


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
