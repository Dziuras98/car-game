extends Node3D


@export var target_path: NodePath = ^"VehicleVisual"
@export var camera_path: NodePath = ^"Camera3D"
@export var ground_path: NodePath = ^"Ground"
@export_range(1.2, 6.0, 0.1) var framing_distance_multiplier: float = 2.8
@export var view_direction: Vector3 = Vector3(1.15, 0.58, 1.45)


func _ready() -> void:
	call_deferred("_frame_target")


func _frame_target() -> void:
	var target: Node3D = get_node_or_null(target_path) as Node3D
	var camera: Camera3D = get_node_or_null(camera_path) as Camera3D
	if target == null or camera == null:
		push_error("Car model preview requires valid target and camera paths.")
		return

	var bounds_result: Dictionary = _calculate_target_bounds(target)
	if not bool(bounds_result.get("valid", false)):
		push_error("Car model preview could not find any MeshInstance3D bounds.")
		return

	var bounds: AABB = bounds_result["bounds"] as AABB
	var center: Vector3 = target.to_global(bounds.get_center())
	var radius: float = maxf(bounds.size.length() * 0.5, 0.5)
	var direction: Vector3 = view_direction.normalized()
	if direction.is_zero_approx():
		direction = Vector3(1.0, 0.5, 1.0).normalized()

	camera.global_position = center + direction * radius * framing_distance_multiplier
	camera.look_at(center, Vector3.UP)
	camera.near = maxf(radius * 0.001, 0.01)
	camera.far = maxf(radius * 24.0, 100.0)

	var ground: Node3D = get_node_or_null(ground_path) as Node3D
	if ground != null:
		var bottom_center: Vector3 = Vector3(
			bounds.get_center().x,
			bounds.position.y,
			bounds.get_center().z
		)
		ground.global_position = target.to_global(bottom_center) - Vector3.UP * maxf(radius * 0.002, 0.005)
		var ground_scale: float = maxf(radius * 0.45, 1.0)
		ground.scale = Vector3(ground_scale, 1.0, ground_scale)


func _calculate_target_bounds(target: Node3D) -> Dictionary:
	var combined_bounds: AABB = AABB()
	var has_bounds: bool = false
	var target_inverse: Transform3D = target.global_transform.affine_inverse()
	for node: Node in target.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		var relative_transform: Transform3D = target_inverse * mesh_instance.global_transform
		var transformed_bounds: AABB = _transform_aabb(mesh_instance.get_aabb(), relative_transform)
		if not has_bounds:
			combined_bounds = transformed_bounds
			has_bounds = true
		else:
			combined_bounds = combined_bounds.merge(transformed_bounds)
	return {
		"valid": has_bounds,
		"bounds": combined_bounds,
	}


func _transform_aabb(bounds: AABB, transform: Transform3D) -> AABB:
	var result: AABB = AABB(transform * bounds.position, Vector3.ZERO)
	for x: float in [0.0, bounds.size.x]:
		for y: float in [0.0, bounds.size.y]:
			for z: float in [0.0, bounds.size.z]:
				var corner: Vector3 = bounds.position + Vector3(x, y, z)
				result = result.expand(transform * corner)
	return result
