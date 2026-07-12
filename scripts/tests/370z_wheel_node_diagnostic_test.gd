extends SceneTree

const VISUAL_SCENE_PATH: String = "res://scenes/cars/370z_z34_visuals.tscn"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed_scene := load(VISUAL_SCENE_PATH) as PackedScene
	if packed_scene == null:
		push_error("[WHEEL_HIERARCHY] Could not load standard 370Z visual scene.")
		quit(1)
		return
	var visual := packed_scene.instantiate() as CarVisualController
	if visual == null:
		push_error("[WHEEL_HIERARCHY] Could not instantiate standard visual controller.")
		quit(1)
		return
	root.add_child(visual)
	await process_frame
	var model := visual.get_node_or_null("SketchfabModel") as Node3D
	if model == null:
		push_error("[WHEEL_HIERARCHY] Standard visual has no SketchfabModel.")
		visual.queue_free()
		quit(1)
		return
	var imported_root := model.get_node_or_null("Sketchfab_model/FINAL_MODEL_fbx/RootNode") as Node3D
	if imported_root == null:
		push_error("[WHEEL_HIERARCHY] Imported standard model root was not found.")
		visual.queue_free()
		quit(1)
		return
	print("[WHEEL_HIERARCHY] BEGIN")
	_dump_tree(imported_root, imported_root, 0)
	print("[WHEEL_HIERARCHY] END")
	visual.queue_free()
	await process_frame
	quit(0)


func _dump_tree(root_node: Node3D, node: Node, depth: int) -> void:
	if node is Node3D:
		var node_3d := node as Node3D
		var relative_transform: Transform3D = root_node.global_transform.affine_inverse() * node_3d.global_transform
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
		print(
			"[WHEEL_HIERARCHY] depth=%d path=%s type=%s children=%d local_pos=%s local_rot_deg=%s local_scale=%s relative_origin=%s %s" % [
				depth,
				str(root_node.get_path_to(node)),
				node.get_class(),
				node.get_child_count(),
				str(node_3d.position),
				str(node_3d.rotation_degrees),
				str(node_3d.scale),
				str(relative_transform.origin),
				mesh_info,
			]
		)
	for child: Node in node.get_children():
		_dump_tree(root_node, child, depth + 1)
