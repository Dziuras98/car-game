extends CarVisualController
class_name BmwE46VisualController

const TARGET_BODY_LENGTH_M: float = 4.471
const MIN_VALID_MODEL_LENGTH_M: float = 0.1

var _detailed_scale_correction: float = 1.0


func _ready() -> void:
	_normalize_detailed_model_scale()
	super._ready()


func get_detailed_model_size_m() -> Vector3:
	var detailed_root: Node3D = get_node_or_null(detailed_root_path) as Node3D
	if detailed_root == null:
		return Vector3.ZERO
	return _calculate_mesh_bounds_in_controller_space(detailed_root).size


func get_detailed_scale_correction() -> float:
	return _detailed_scale_correction


func _normalize_detailed_model_scale() -> void:
	var detailed_root: Node3D = get_node_or_null(detailed_root_path) as Node3D
	if detailed_root == null:
		push_error("BMW E46 detailed visual root is missing.")
		return
	var current_bounds: AABB = _calculate_mesh_bounds_in_controller_space(detailed_root)
	var current_length: float = current_bounds.size.z
	if not is_finite(current_length) or current_length < MIN_VALID_MODEL_LENGTH_M:
		push_error("BMW E46 detailed model has invalid longitudinal bounds.")
		return
	_detailed_scale_correction = TARGET_BODY_LENGTH_M / current_length
	if not is_finite(_detailed_scale_correction) or _detailed_scale_correction <= 0.0:
		_detailed_scale_correction = 1.0
		push_error("BMW E46 detailed model produced an invalid scale correction.")
		return
	detailed_root.scale = detailed_root.scale * _detailed_scale_correction


func _calculate_mesh_bounds_in_controller_space(root: Node3D) -> AABB:
	var controller_inverse: Transform3D = global_transform.affine_inverse()
	var pending: Array[Node] = [root]
	var combined := AABB()
	var has_point: bool = false
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		for child: Node in node.get_children():
			pending.append(child)
		var mesh_instance := node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var mesh_bounds: AABB = mesh_instance.get_aabb()
		var mesh_to_controller: Transform3D = controller_inverse * mesh_instance.global_transform
		for corner_index: int in 8:
			var corner := Vector3(
				mesh_bounds.end.x if (corner_index & 1) != 0 else mesh_bounds.position.x,
				mesh_bounds.end.y if (corner_index & 2) != 0 else mesh_bounds.position.y,
				mesh_bounds.end.z if (corner_index & 4) != 0 else mesh_bounds.position.z
			)
			var point: Vector3 = mesh_to_controller * corner
			if not has_point:
				combined = AABB(point, Vector3.ZERO)
				has_point = true
			else:
				combined = combined.expand(point)
	return combined


func _get_explicit_detailed_wheel_specs() -> Array[Dictionary]:
	return [
		{
			"wheel_id": &"front_left",
			"pivot_parent_path": NodePath("."),
			"pivot_position": Vector3(-0.75, 0.32, -1.36),
			"steers": true,
			"steering_direction": -1.0,
			"spin_direction": 1.0,
			"spin_node_paths": [NodePath("DetailedWheelProxyFrontLeft")],
		},
		{
			"wheel_id": &"front_right",
			"pivot_parent_path": NodePath("."),
			"pivot_position": Vector3(0.75, 0.32, -1.36),
			"steers": true,
			"steering_direction": -1.0,
			"spin_direction": 1.0,
			"spin_node_paths": [NodePath("DetailedWheelProxyFrontRight")],
		},
		{
			"wheel_id": &"rear_left",
			"pivot_parent_path": NodePath("."),
			"pivot_position": Vector3(-0.75, 0.32, 1.36),
			"steers": false,
			"spin_direction": 1.0,
			"spin_node_paths": [NodePath("DetailedWheelProxyRearLeft")],
		},
		{
			"wheel_id": &"rear_right",
			"pivot_parent_path": NodePath("."),
			"pivot_position": Vector3(0.75, 0.32, 1.36),
			"steers": false,
			"spin_direction": 1.0,
			"spin_node_paths": [NodePath("DetailedWheelProxyRearRight")],
		},
	]
