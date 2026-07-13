extends CarVisualController
class_name FiatPunto176VisualController

const TARGET_BODY_LENGTH: float = 3.76


func _ready() -> void:
	_resolve_visual_roots()
	_normalize_detailed_model()
	super._ready()


func _configure_wheel_visuals() -> void:
	if _wheel_visuals_configured or not is_inside_tree():
		return
	_resolve_visual_roots()
	# The source GLB does not expose a stable, documented wheel-node contract.
	# Keep the detailed mesh intact and animate the explicit low-detail wheels.
	_collect_low_detail_wheel_nodes()
	_wheel_visuals_configured = true


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
	# Sketchfab exports commonly face the opposite project-forward direction.
	_detailed_root.rotation.y += PI


func _collect_bounds(node: Node, parent_transform: Transform3D, state: Dictionary) -> void:
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
