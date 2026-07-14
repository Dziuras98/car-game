extends CarVisualController
class_name PolonezCaroMr93VisualController

const TARGET_BODY_LENGTH: float = 4.318


func _ready() -> void:
	_resolve_visual_roots()
	_normalize_detailed_model()
	super._ready()


func _configure_wheel_visuals() -> void:
	if not is_inside_tree():
		return
	if _wheel_visuals_configured and _low_detail_wheel_nodes.size() == 4:
		return
	_resolve_visual_roots()
	# The imported Sketchfab hierarchy is not a stable wheel-animation contract.
	# Preserve its authored hierarchy and animate the explicit low-detail wheels.
	_collect_low_detail_wheel_nodes()
	_wheel_visuals_configured = _low_detail_wheel_nodes.size() == 4


func _collect_low_detail_wheel_nodes() -> void:
	_low_detail_wheel_nodes.clear()
	_low_detail_base_rotations.clear()
	_low_detail_front_flags.clear()
	var search_root: Node = _low_detail_root if _low_detail_root != null else self
	for wheel_name: StringName in LOW_DETAIL_WHEEL_NAMES:
		var wheel: Node3D = _find_node3d_by_name(search_root, wheel_name)
		if wheel == null and search_root != self:
			wheel = _find_node3d_by_name(self, wheel_name)
		if wheel == null:
			continue
		_low_detail_wheel_nodes.append(wheel)
		_low_detail_base_rotations.append(wheel.rotation)
		_low_detail_front_flags.append(
			wheel_name == &"WheelFrontLeft" or wheel_name == &"WheelFrontRight"
		)


func _find_node3d_by_name(root: Node, target_name: StringName) -> Node3D:
	if root.name == target_name and root is Node3D:
		return root as Node3D
	for child: Node in root.get_children():
		var match_node: Node3D = _find_node3d_by_name(child, target_name)
		if match_node != null:
			return match_node
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
