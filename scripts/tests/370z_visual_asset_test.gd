extends SceneTree

const CAR_SCENE_PATH: String = "res://scenes/cars/370z.tscn"
const VISUAL_SCENE_PATH: String = "res://scenes/cars/370z_z34_visuals.tscn"
const VISUAL_ASSET_PATH: String = "res://assets/third_party/sketchfab/nissan_370z_2013/2013_nissan_370z.glb"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_visual_asset_import()
	_test_base_scene_contract()
	_finish()


func _test_visual_asset_import() -> void:
	var imported_model := load(VISUAL_ASSET_PATH) as PackedScene
	_expect(imported_model != null, "the standard Sketchfab GLB imports as a PackedScene")

	var packed_visuals := load(VISUAL_SCENE_PATH) as PackedScene
	_expect(packed_visuals != null, "the standard 370Z visual wrapper scene loads")
	if packed_visuals == null:
		return

	var visuals := packed_visuals.instantiate() as Node3D
	_expect(visuals != null, "the standard visual wrapper instantiates")
	if visuals == null:
		return

	var model := visuals.get_node_or_null("SketchfabModel") as Node3D
	_expect(model != null, "the standard visual wrapper contains the imported Sketchfab model")
	if model != null:
		_expect(absf(model.transform.basis.x.x + 100.0) < 0.001, "the standard model flips X while applying the 100x source scale")
		_expect(absf(model.transform.basis.y.y - 100.0) < 0.001, "the standard model preserves the vertical axis at 100x scale")
		_expect(absf(model.transform.basis.z.z + 100.0) < 0.001, "the standard model flips Z so the vehicle faces project forward")
		_expect(absf(model.position.y - 0.14) < 0.001, "the standard model is raised onto the gameplay ground plane")

	var meshes: Array[MeshInstance3D] = []
	_collect_mesh_instances(visuals, meshes)
	_expect(meshes.size() >= 30, "the detailed standard model retains its multi-mesh structure")
	var bounds := _calculate_bounds(visuals, meshes)
	_expect(bounds.size.x > 1.95 and bounds.size.x < 2.08, "the standard model width remains near two metres including mirrors")
	_expect(bounds.size.y > 1.25 and bounds.size.y < 1.36, "the standard model height remains inside the expected Z34 range")
	_expect(bounds.size.z > 4.20 and bounds.size.z < 4.30, "the standard model length remains inside the expected Z34 range")
	_expect(absf(bounds.get_center().x) < 0.03, "the standard model stays centered laterally")
	_expect(absf(bounds.get_center().z) < 0.05, "the standard model stays centered longitudinally")
	_expect(bounds.position.y >= -0.01 and bounds.position.y < 0.03, "the standard tyres meet the gameplay ground plane")
	visuals.free()


func _test_base_scene_contract() -> void:
	var packed_scene := load(CAR_SCENE_PATH) as PackedScene
	_expect(packed_scene != null, "the base 370Z scene loads")
	if packed_scene == null:
		return

	var car := packed_scene.instantiate()
	_expect(car is PlayerCarController, "the base scene keeps PlayerCarController as its root contract")
	_expect(car.get_node_or_null("VisualRoot/SketchfabModel") is Node3D, "the base scene uses the detailed Sketchfab visual model")
	_expect(car.get_node_or_null("VisualRoot/BodyFront") == null, "the legacy split OBJ body is no longer instantiated")
	_expect(car.get_node_or_null("VisualRoot/WheelFrontLeft") == null, "the legacy standalone wheel meshes are no longer instantiated")
	_expect(car.get_node_or_null("RearSpoilerBridge") == null, "the legacy spoiler bridge is removed")
	_expect(car.get_node_or_null("EngineAudio") is AudioStreamPlayer3D, "the engine-audio node contract is preserved")
	_expect(car.get_node_or_null("TireSquealAudio") is AudioStreamPlayer3D, "the tire-audio node contract is preserved")

	var collision := car.get_node_or_null("CollisionShape3D") as CollisionShape3D
	_expect(collision != null and collision.shape is BoxShape3D, "the standard body collision remains available")
	if collision != null and collision.shape is BoxShape3D:
		var box := collision.shape as BoxShape3D
		_expect(box.size.x >= 1.83 and box.size.x <= 1.85, "the standard collision keeps the intended body width")
		_expect(box.size.z >= 4.19 and box.size.z <= 4.21, "the standard collision keeps the intended body length")
	car.free()


func _collect_mesh_instances(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node as MeshInstance3D)
	for child: Node in node.get_children():
		_collect_mesh_instances(child, output)


func _calculate_bounds(root: Node3D, meshes: Array[MeshInstance3D]) -> AABB:
	var bounds := AABB()
	var initialized := false
	for mesh_instance: MeshInstance3D in meshes:
		if mesh_instance.mesh == null:
			continue
		var relative_transform: Transform3D = root.global_transform.affine_inverse() * mesh_instance.global_transform
		var transformed_bounds: AABB = relative_transform * mesh_instance.get_aabb()
		if initialized:
			bounds = bounds.merge(transformed_bounds)
		else:
			bounds = transformed_bounds
			initialized = true
	_expect(initialized, "the standard imported scene exposes renderable mesh bounds")
	return bounds


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
