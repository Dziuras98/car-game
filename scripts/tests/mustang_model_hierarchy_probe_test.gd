extends SceneTree

const MODEL: PackedScene = preload("res://1967_ford_mustang_shelby_cobra_gt500.glb")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var instance: Node = MODEL.instantiate()
	root.add_child(instance)
	await process_frame
	print("[MUSTANG_MODEL_PROBE] BEGIN")
	var state: Dictionary = {
		"initialized": false,
		"bounds": AABB(),
		"mesh_count": 0,
	}
	_dump_node(instance, instance, Transform3D.IDENTITY, state)
	print("[MUSTANG_MODEL_PROBE] MESH_COUNT=%d" % int(state["mesh_count"]))
	if bool(state["initialized"]):
		var bounds: AABB = state["bounds"] as AABB
		print("[MUSTANG_MODEL_PROBE] BOUNDS_POSITION=%s" % str(bounds.position))
		print("[MUSTANG_MODEL_PROBE] BOUNDS_SIZE=%s" % str(bounds.size))
		print("[MUSTANG_MODEL_PROBE] BOUNDS_CENTER=%s" % str(bounds.get_center()))
	print("[MUSTANG_MODEL_PROBE] END")
	instance.queue_free()
	await process_frame
	quit(0)


func _dump_node(node: Node, model_root: Node, parent_transform: Transform3D, state: Dictionary) -> void:
	var current_transform: Transform3D = parent_transform
	if node is Node3D:
		current_transform = parent_transform * (node as Node3D).transform
	var relative_path: String = str(model_root.get_path_to(node))
	var type_name: String = node.get_class()
	if node is MeshInstance3D:
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		var local_bounds: AABB = mesh_instance.get_aabb()
		var transformed_bounds: AABB = current_transform * local_bounds
		print("[MUSTANG_MODEL_PROBE] MESH path=%s type=%s local=%s transformed=%s" % [relative_path, type_name, str(local_bounds), str(transformed_bounds)])
		if bool(state["initialized"]):
			state["bounds"] = (state["bounds"] as AABB).merge(transformed_bounds)
		else:
			state["bounds"] = transformed_bounds
			state["initialized"] = true
		state["mesh_count"] = int(state["mesh_count"]) + 1
	else:
		print("[MUSTANG_MODEL_PROBE] NODE path=%s type=%s" % [relative_path, type_name])
	for child: Node in node.get_children():
		_dump_node(child, model_root, current_transform, state)
