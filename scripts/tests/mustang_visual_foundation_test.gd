extends SceneTree

const SOURCE_MODEL_PATH: String = "res://1967_ford_mustang_shelby_cobra_gt500.glb"
const VISUAL_SCENE_PATH: String = "res://scenes/cars/mustang_shelby_gt500_1967_visuals.tscn"
const LOW_DETAIL_SCENE_PATH: String = "res://scenes/cars/mustang_shelby_gt500_1967_low_detail_visuals.tscn"
const PREVIEW_SCENE_PATH: String = "res://scenes/dev/mustang_shelby_gt500_1967_visual_preview.tscn"
const REQUIRED_WHEEL_IDS: Array[StringName] = [
	&"front_left",
	&"front_right",
	&"rear_left",
	&"rear_right",
]
const REQUIRED_LOW_DETAIL_WHEELS: Array[StringName] = [
	&"WheelFrontLeft",
	&"WheelFrontRight",
	&"WheelRearLeft",
	&"WheelRearRight",
]

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_source_and_visual_wrapper()
	_test_low_detail_contract()
	await _test_preview_scene()
	_finish()


func _test_source_and_visual_wrapper() -> void:
	var source_model: PackedScene = load(SOURCE_MODEL_PATH) as PackedScene
	_expect(source_model != null, "the uploaded Mustang GLB imports as a PackedScene")

	var packed_visuals: PackedScene = load(VISUAL_SCENE_PATH) as PackedScene
	_expect(packed_visuals != null, "the Mustang visual wrapper scene loads")
	if packed_visuals == null:
		return

	var visuals: MustangShelbyGT5001967VisualController = packed_visuals.instantiate() as MustangShelbyGT5001967VisualController
	_expect(visuals != null, "the Mustang wrapper instantiates as its model-specific CarVisualController")
	if visuals == null:
		return

	root.add_child(visuals)
	await process_frame
	var alignment: Node3D = visuals.get_node_or_null("ModelAlignment") as Node3D
	var detailed: Node3D = visuals.get_node_or_null("ModelAlignment/DetailedModel") as Node3D
	var low_detail: Node3D = visuals.get_node_or_null("LowDetail") as Node3D
	_expect(alignment != null, "the wrapper exposes an isolated alignment root")
	_expect(detailed != null, "the wrapper contains the imported detailed model")
	_expect(low_detail != null, "the wrapper contains a low-detail fallback")
	if detailed != null:
		_expect(absf(detailed.transform.basis.x.x + 100.0) < 0.001, "the source X axis is flipped while applying the 100x source scale")
		_expect(absf(detailed.transform.basis.y.y - 100.0) < 0.001, "the source vertical axis is preserved at 100x scale")
		_expect(absf(detailed.transform.basis.z.z + 100.0) < 0.001, "the source front axis is rotated into project forward")

	_expect(visuals.get_detailed_wheel_binding_count() == 4, "the detailed model registers exactly four wheel assemblies")
	_expect(visuals.get_low_detail_wheel_binding_count() == 4, "the low-detail model registers exactly four wheel assemblies")
	_expect(visuals.get_registered_wheel_count() == 4, "the visual controller exposes four logical wheels")
	for wheel_id: StringName in REQUIRED_WHEEL_IDS:
		_expect(visuals.get_detailed_wheel_spin_pivot(wheel_id) != null, "%s has a detailed spin pivot" % wheel_id)
		_expect(visuals.get_detailed_wheel_steering_pivot(wheel_id) != null, "%s has a detailed steering pivot" % wheel_id)

	var bounds_state: Dictionary = _calculate_bounds(alignment)
	var bounds: AABB = bounds_state["bounds"] as AABB
	_expect(int(bounds_state["mesh_count"]) == 71, "the detailed model retains all 71 imported render meshes")
	_expect(bounds.size.x > 1.78 and bounds.size.x < 1.81, "the detailed model width matches the measured source bounds")
	_expect(bounds.size.y > 1.34 and bounds.size.y < 1.37, "the detailed model height matches the measured source bounds")
	_expect(bounds.size.z > 4.80 and bounds.size.z < 4.84, "the detailed model length matches the measured source bounds")
	_expect(absf(bounds.position.y) < 0.01, "the detailed tyres are aligned with the gameplay ground plane")

	visuals.set_force_low_detail(true)
	_expect(visuals.is_using_low_detail(), "forced low-detail mode activates")
	_expect(alignment == null or not alignment.visible, "forced low-detail mode hides the imported model")
	_expect(low_detail != null and low_detail.visible, "forced low-detail mode shows the fallback model")
	visuals.queue_free()
	await process_frame


func _test_low_detail_contract() -> void:
	var packed_low_detail: PackedScene = load(LOW_DETAIL_SCENE_PATH) as PackedScene
	_expect(packed_low_detail != null, "the Mustang low-detail scene loads")
	if packed_low_detail == null:
		return

	var low_detail: Node3D = packed_low_detail.instantiate() as Node3D
	_expect(low_detail != null, "the Mustang low-detail scene instantiates as Node3D")
	if low_detail == null:
		return

	for wheel_name: StringName in REQUIRED_LOW_DETAIL_WHEELS:
		var wheel: Node3D = low_detail.get_node_or_null(NodePath(String(wheel_name))) as Node3D
		_expect(wheel != null, "the low-detail scene exposes %s" % wheel_name)
		_expect(wheel == null or wheel.get_node_or_null("Mesh") is MeshInstance3D, "%s contains renderable wheel geometry" % wheel_name)
	low_detail.free()


func _test_preview_scene() -> void:
	var packed_preview: PackedScene = load(PREVIEW_SCENE_PATH) as PackedScene
	_expect(packed_preview != null, "the Mustang visual preview scene loads")
	if packed_preview == null:
		return

	var preview: Node3D = packed_preview.instantiate() as Node3D
	_expect(preview != null, "the Mustang visual preview scene instantiates")
	if preview == null:
		return

	root.add_child(preview)
	await process_frame
	await process_frame
	_expect(preview.get_node_or_null("VehicleVisual") is MustangShelbyGT5001967VisualController, "the preview contains the completed Mustang visual controller")
	_expect(preview.get_node_or_null("Camera3D") is Camera3D, "the preview contains a framing camera")
	_expect(preview.get_node_or_null("Ground") is MeshInstance3D, "the preview contains a ground reference")
	preview.queue_free()
	await process_frame


func _calculate_bounds(root_node: Node3D) -> Dictionary:
	var state: Dictionary = {
		"initialized": false,
		"mesh_count": 0,
		"bounds": AABB(),
	}
	_collect_bounds(root_node, Transform3D.IDENTITY, state)
	_expect(bool(state["initialized"]), "the detailed model exposes renderable mesh bounds")
	return state


func _collect_bounds(node: Node, parent_transform: Transform3D, state: Dictionary) -> void:
	var current_transform: Transform3D = parent_transform
	if node is Node3D:
		current_transform = parent_transform * (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance.mesh != null:
			var transformed_bounds: AABB = current_transform * mesh_instance.get_aabb()
			if bool(state["initialized"]):
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
		print("[MUSTANG_VISUAL_FOUNDATION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[MUSTANG_VISUAL_FOUNDATION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[MUSTANG_VISUAL_FOUNDATION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[MUSTANG_VISUAL_FOUNDATION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[MUSTANG_VISUAL_FOUNDATION_TEST] - %s" % failure_message)
	quit(1)
