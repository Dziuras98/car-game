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

	var visuals := packed_visuals.instantiate() as CarVisualController
	_expect(visuals != null, "the standard visual wrapper instantiates as CarVisualController")
	if visuals == null:
		return
	root.add_child(visuals)

	var model := visuals.get_node_or_null("SketchfabModel") as Node3D
	_expect(model != null, "the standard visual wrapper contains the imported Sketchfab model")
	if model != null:
		_expect(absf(model.transform.basis.x.x + 100.0) < 0.001, "the standard model flips X while applying the 100x source scale")
		_expect(absf(model.transform.basis.y.y - 100.0) < 0.001, "the standard model preserves the vertical axis at 100x scale")
		_expect(absf(model.transform.basis.z.z + 100.0) < 0.001, "the standard model flips Z so the vehicle faces project forward")
		_expect(absf(model.position.y - 0.14) < 0.001, "the standard model is raised onto the gameplay ground plane")

	var bounds_state := _calculate_bounds(model)
	var mesh_count: int = bounds_state["mesh_count"]
	var bounds: AABB = bounds_state["bounds"]
	_expect(mesh_count >= 30, "the detailed standard model retains its multi-mesh structure")
	_expect(bounds.size.x > 1.95 and bounds.size.x < 2.08, "the standard model width remains near two metres including mirrors")
	_expect(bounds.size.y > 1.25 and bounds.size.y < 1.36, "the standard model height remains inside the expected Z34 range")
	_expect(bounds.size.z > 4.20 and bounds.size.z < 4.30, "the standard model length remains inside the expected Z34 range")
	_expect(absf(bounds.get_center().x) < 0.03, "the standard model stays centered laterally")
	_expect(absf(bounds.get_center().z) < 0.05, "the standard model stays centered longitudinally")
	_expect(bounds.position.y >= -0.01 and bounds.position.y < 0.03, "the standard tyres meet the gameplay ground plane")

	var low_detail := visuals.get_node_or_null("LowDetail") as Node3D
	_expect(low_detail != null, "the standard visual wrapper includes a low-detail fallback")
	_expect(visuals.get_registered_wheel_count() >= 4, "the visual controller registers wheel pivots")
	visuals.set_force_low_detail(true)
	_expect(visuals.is_using_low_detail(), "forced low-detail mode activates")
	_expect(model == null or not model.visible, "forced low-detail mode hides the imported GLB")
	_expect(low_detail != null and low_detail.visible, "forced low-detail mode shows the bounded fallback")
	visuals.queue_free()


func _test_base_scene_contract() -> void:
	var packed_scene := load(CAR_SCENE_PATH) as PackedScene
	_expect(packed_scene != null, "the base 370Z scene loads")
	if packed_scene == null:
		return

	var car := packed_scene.instantiate()
	_expect(car is PlayerCarController, "the base scene keeps PlayerCarController as its root contract")
	_expect(car.get_node_or_null("VisualRoot") is CarVisualController, "the base scene uses the visual LOD controller")
	_expect(car.get_node_or_null("VisualRoot/SketchfabModel") is Node3D, "the base scene keeps the detailed imported model")
	_expect(car.get_node_or_null("VisualRoot/LowDetail") is Node3D, "the base scene includes the low-detail opponent model")
	_expect(car.get_node_or_null("EngineAudio") is AudioStreamPlayer3D, "the engine-audio node contract is preserved")
	_expect(car.get_node_or_null("TireSquealAudio") is AudioStreamPlayer3D, "the tire-audio node contract is preserved")

	var collision := car.get_node_or_null("CollisionShape3D") as CollisionShape3D
	_expect(collision != null and collision.shape is BoxShape3D, "the standard body collision remains available")
	if collision != null and collision.shape is BoxShape3D:
		var box := collision.shape as BoxShape3D
		_expect(box.size.x >= 1.95 and box.size.x <= 1.97, "the standard collision covers the imported body width")
		_expect(box.size.y >= 1.27 and box.size.y <= 1.29, "the standard collision covers the roof height")
		_expect(box.size.z >= 4.26 and box.size.z <= 4.28, "the standard collision covers the imported body length")
	car.free()


func _calculate_bounds(root_node: Node3D) -> Dictionary:
	var state: Dictionary = {
		"initialized": false,
		"mesh_count": 0,
		"bounds": AABB(),
	}
	_collect_bounds(root_node, Transform3D.IDENTITY, state)
	_expect(state["initialized"], "the standard imported scene exposes renderable mesh bounds")
	return state


func _collect_bounds(node: Node, parent_transform: Transform3D, state: Dictionary) -> void:
	var current_transform := parent_transform
	if node is Node3D:
		current_transform = parent_transform * (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			var transformed_bounds: AABB = current_transform * mesh_instance.get_aabb()
			if state["initialized"]:
				state["bounds"] = (state["bounds"] as AABB).merge(transformed_bounds)
			else:
				state["bounds"] = transformed_bounds
				state["initialized"] = true
			state["mesh_count"] = int(state["mesh_count"]) + 1
	for child: Node in node.get_children():
		_collect_bounds(child, current_transform, state)


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
