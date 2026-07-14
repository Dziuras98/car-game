extends CarVisualController
class_name PolonezCaroMr93VisualController

const TARGET_BODY_LENGTH: float = 4.318
const DETAILED_ROOT_NAME: StringName = &"SketchfabModel"
const LOW_DETAIL_ROOT_NAME: StringName = &"LowDetail"


func _ready() -> void:
	_resolve_visual_roots()
	_normalize_detailed_model()
	super._ready()
	_configure_wheel_visuals()


func get_registered_wheel_count() -> int:
	_configure_wheel_visuals()
	return _low_detail_wheel_nodes.size()


func update_vehicle_visuals(
	delta: float,
	forward_speed: float,
	steering_input: float,
	wheel_radius_override: float = -1.0
) -> void:
	_configure_wheel_visuals()
	super.update_vehicle_visuals(
		delta,
		forward_speed,
		steering_input,
		wheel_radius_override
	)


func _resolve_visual_roots() -> void:
	# Resolve the two wrapper-owned roots by direct child identity. This avoids
	# inherited exported NodePath state becoming stale when the visual scene is
	# instanced and renamed to VisualRoot by the vehicle scene.
	_detailed_root = _find_direct_node3d(self, DETAILED_ROOT_NAME)
	_low_detail_root = _find_direct_node3d(self, LOW_DETAIL_ROOT_NAME)


func _configure_wheel_visuals() -> void:
	if _wheel_visuals_configured and _low_detail_wheel_nodes.size() == LOW_DETAIL_WHEEL_NAMES.size():
		return
	_resolve_visual_roots()
	_collect_low_detail_wheel_nodes()
	_wheel_visuals_configured = _low_detail_wheel_nodes.size() == LOW_DETAIL_WHEEL_NAMES.size()


func _collect_low_detail_wheel_nodes() -> void:
	_low_detail_wheel_nodes.clear()
	_low_detail_base_rotations.clear()
	_low_detail_front_flags.clear()
	if _low_detail_root == null:
		return
	for wheel_name: StringName in LOW_DETAIL_WHEEL_NAMES:
		var wheel: Node3D = _find_direct_node3d(_low_detail_root, wheel_name)
		if wheel == null:
			continue
		_low_detail_wheel_nodes.append(wheel)
		_low_detail_base_rotations.append(wheel.rotation)
		_low_detail_front_flags.append(
			wheel_name == &"WheelFrontLeft" or wheel_name == &"WheelFrontRight"
		)


func _find_direct_node3d(parent: Node, target_name: StringName) -> Node3D:
	if parent == null:
		return null
	for child: Node in parent.get_children():
		if child.name == target_name and child is Node3D:
			return child as Node3D
	return null


func _normalize_detailed_model() -> void:
	if _detailed_root == null:
		return
	_detailed_root.transform = Transform3D.IDENTITY
	var bounds_state: Dictionary = {
		"initialized": false,
		"bounds": AABB(),
	}
	_collect_bounds(_detailed_root, Transform3D.IDENTITY, bounds_state)
	if not bool(bounds_state["initialized"]):
		return
	var bounds: AABB = bounds_state["bounds"] as AABB
	if bounds.size.x > bounds.size.z:
		_detailed_root.rotation.y = -PI * 0.5
		bounds_state["initialized"] = false
		bounds_state["bounds"] = AABB()
		_collect_bounds(_detailed_root, Transform3D.IDENTITY, bounds_state)
		bounds = bounds_state["bounds"] as AABB
	var source_length: float = maxf(bounds.size.z, 0.001)
	var uniform_scale: float = TARGET_BODY_LENGTH / source_length
	_detailed_root.scale = Vector3.ONE * uniform_scale
	var center: Vector3 = bounds.get_center()
	_detailed_root.position = Vector3(
		-center.x * uniform_scale,
		-bounds.position.y * uniform_scale + 0.01,
		-center.z * uniform_scale
	)
	_detailed_root.rotation.y += PI


func _collect_bounds(
	node: Node,
	parent_transform: Transform3D,
	state: Dictionary
) -> void:
	var current_transform: Transform3D = parent_transform
	if node is Node3D:
		current_transform = parent_transform * (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			var transformed_bounds: AABB = current_transform * mesh_instance.get_aabb()
			if bool(state["initialized"]):
				state["bounds"] = (state["bounds"] as AABB).merge(transformed_bounds)
			else:
				state["bounds"] = transformed_bounds
				state["initialized"] = true
	for child: Node in node.get_children():
		_collect_bounds(child, current_transform, state)
