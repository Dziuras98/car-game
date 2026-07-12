extends SceneTree

const VISUAL_SCENES: Dictionary = {
	"standard": "res://scenes/cars/370z_z34_visuals.tscn",
	"nismo": "res://scenes/cars/370z_nismo_visuals.tscn",
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for label: String in VISUAL_SCENES:
		var packed_scene := load(VISUAL_SCENES[label]) as PackedScene
		if packed_scene == null:
			push_error("[WHEEL_DIAGNOSTIC] Could not load %s visual scene." % label)
			quit(1)
			return
		var visual := packed_scene.instantiate() as CarVisualController
		if visual == null:
			push_error("[WHEEL_DIAGNOSTIC] Could not instantiate %s visual controller." % label)
			quit(1)
			return
		root.add_child(visual)
		await process_frame
		var model := visual.get_node_or_null("SketchfabModel") as Node3D
		if model == null:
			push_error("[WHEEL_DIAGNOSTIC] %s visual has no SketchfabModel." % label)
			visual.queue_free()
			quit(1)
			return
		print("[WHEEL_DIAGNOSTIC] BEGIN %s registered=%d" % [label, visual.get_registered_wheel_count()])
		_dump_candidates(model, model, false)
		print("[WHEEL_DIAGNOSTIC] END %s" % label)
		visual.queue_free()
		await process_frame
	quit(0)


func _dump_candidates(root_node: Node3D, node: Node, candidate_ancestor: bool) -> void:
	var normalized_name: String = node.name.to_lower()
	var is_candidate: bool = (
		"wheel" in normalized_name
		or "tire" in normalized_name
		or "tyre" in normalized_name
		or "rim" in normalized_name
	)
	if is_candidate:
		var node_3d := node as Node3D
		var path: String = str(root_node.get_path_to(node))
		var parent_path: String = str(root_node.get_path_to(node.get_parent()))
		var mesh_info: String = "none"
		if node is MeshInstance3D:
			var mesh_instance := node as MeshInstance3D
			if mesh_instance.mesh != null:
				var bounds: AABB = mesh_instance.get_aabb()
				mesh_info = "aabb_pos=%s aabb_size=%s surfaces=%d" % [
					str(bounds.position),
					str(bounds.size),
					mesh_instance.mesh.get_surface_count(),
				]
		var relative_transform: Transform3D = root_node.global_transform.affine_inverse() * node_3d.global_transform
		print(
			"[WHEEL_DIAGNOSTIC] candidate path=%s parent=%s type=%s nested_candidate=%s children=%d local_pos=%s local_rot_deg=%s local_scale=%s relative_origin=%s relative_basis_x=%s relative_basis_y=%s relative_basis_z=%s %s" % [
				path,
				parent_path,
				node.get_class(),
				str(candidate_ancestor),
				node.get_child_count(),
				str(node_3d.position),
				str(node_3d.rotation_degrees),
				str(node_3d.scale),
				str(relative_transform.origin),
				str(relative_transform.basis.x),
				str(relative_transform.basis.y),
				str(relative_transform.basis.z),
				mesh_info,
			]
		)
	for child: Node in node.get_children():
		_dump_candidates(root_node, child, candidate_ancestor or is_candidate)
