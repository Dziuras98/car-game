extends SceneTree

const SOURCE_PATH := "res://assets/third_party/sketchfab/traffic_rider_npc_vehicles/bmw_4_series_f32/source/01_bmw_4_series_2014.glb"
const REPORT_PATH := "res://build/test-logs/traffic-rider-bmw-f32-source-inspection.json"
const BODY_MESH_NAME := "AI_Bmw4_High_BMW_4_Series_2014_0"
const FRONT_WHEEL_MESH_NAME := "on_teker_wheel_0"
const REAR_WHEEL_MESH_NAME := "arka_teker_wheel_0"
const EXPECTED_TRIANGLES := 1780
const EXPECTED_SOURCE_WHEELBASE := 4.0489
const WHEELBASE_TOLERANCE := 0.01
const SIDE_EPSILON := 0.00001

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var source_scene := ResourceLoader.load(SOURCE_PATH) as PackedScene
	_expect(source_scene != null, "BMW F32 source scene loads")
	if source_scene == null:
		_finish()
		return
	var source_root: Node = source_scene.instantiate()
	_expect(source_root != null, "BMW F32 source scene instantiates")
	if source_root == null:
		_finish()
		return
	root.add_child(source_root)
	var mesh_instances: Array[MeshInstance3D] = []
	_collect_mesh_instances(source_root, mesh_instances)
	_expect(mesh_instances.size() == 3, "source contains exactly three mesh instances")

	var report: Dictionary = {
		"source_path": SOURCE_PATH,
		"source_sha256": FileAccess.get_sha256(SOURCE_PATH),
		"root_name": String(source_root.name),
		"meshes": [],
	}
	var total_triangles: int = 0
	var named_instances: Dictionary = {}
	for mesh_instance: MeshInstance3D in mesh_instances:
		named_instances[String(mesh_instance.name)] = mesh_instance
		var mesh_report := _inspect_mesh(mesh_instance)
		total_triangles += int(mesh_report.get("triangle_count", 0))
		(report["meshes"] as Array).append(mesh_report)
	report["total_triangles"] = total_triangles
	_expect(total_triangles == EXPECTED_TRIANGLES, "source triangle count remains %d" % EXPECTED_TRIANGLES)
	for required_name: String in [BODY_MESH_NAME, FRONT_WHEEL_MESH_NAME, REAR_WHEEL_MESH_NAME]:
		_expect(named_instances.has(required_name), "source contains mesh %s" % required_name)

	if named_instances.has(FRONT_WHEEL_MESH_NAME) and named_instances.has(REAR_WHEEL_MESH_NAME):
		var front_analysis := _inspect_wheel_pair(named_instances[FRONT_WHEEL_MESH_NAME] as MeshInstance3D)
		var rear_analysis := _inspect_wheel_pair(named_instances[REAR_WHEEL_MESH_NAME] as MeshInstance3D)
		report["front_wheels"] = front_analysis
		report["rear_wheels"] = rear_analysis
		_validate_wheel_pair(front_analysis, "front")
		_validate_wheel_pair(rear_analysis, "rear")
		var front_axle_z := _average_side_axis(front_analysis, "center", 2)
		var rear_axle_z := _average_side_axis(rear_analysis, "center", 2)
		var measured_wheelbase := absf(front_axle_z - rear_axle_z)
		report["measured_source_wheelbase"] = measured_wheelbase
		report["wheelbase_scale_to_2_810_m"] = 2.810 / measured_wheelbase if measured_wheelbase > 0.0 else 0.0
		report["source_axle_midpoint_z"] = (front_axle_z + rear_axle_z) * 0.5
		var front_ground_y := minf(
			_float_from_side(front_analysis, "negative_x", "minimum", 1),
			_float_from_side(front_analysis, "positive_x", "minimum", 1)
		)
		var rear_ground_y := minf(
			_float_from_side(rear_analysis, "negative_x", "minimum", 1),
			_float_from_side(rear_analysis, "positive_x", "minimum", 1)
		)
		report["source_ground_y"] = minf(front_ground_y, rear_ground_y)
		_expect(absf(measured_wheelbase - EXPECTED_SOURCE_WHEELBASE) <= WHEELBASE_TOLERANCE, "wheelbase measurement matches recorded source evidence")

	_write_report(report)
	source_root.queue_free()
	_finish()


func _collect_mesh_instances(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node as MeshInstance3D)
	for child: Node in node.get_children():
		_collect_mesh_instances(child, output)


func _inspect_mesh(mesh_instance: MeshInstance3D) -> Dictionary:
	var mesh: Mesh = mesh_instance.mesh
	var surface_reports: Array[Dictionary] = []
	var triangle_count: int = 0
	if mesh != null:
		for surface_index: int in range(mesh.get_surface_count()):
			var arrays: Array = mesh.surface_get_arrays(surface_index)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var surface_triangles: int = int(indices.size() / 3) if not indices.is_empty() else int(vertices.size() / 3)
			triangle_count += surface_triangles
			surface_reports.append({
				"surface_index": surface_index,
				"primitive": int(mesh.surface_get_primitive_type(surface_index)),
				"format": int(mesh.surface_get_format(surface_index)),
				"vertex_count": vertices.size(),
				"index_count": indices.size(),
				"triangle_count": surface_triangles,
				"material_class": "" if mesh.surface_get_material(surface_index) == null else mesh.surface_get_material(surface_index).get_class(),
			})
	return {
		"name": String(mesh_instance.name),
		"node_path": String(mesh_instance.get_path()),
		"global_transform": _transform_to_dictionary(mesh_instance.global_transform),
		"local_aabb": _aabb_to_dictionary(mesh_instance.get_aabb()),
		"surface_count": 0 if mesh == null else mesh.get_surface_count(),
		"triangle_count": triangle_count,
		"surfaces": surface_reports,
	}


func _inspect_wheel_pair(mesh_instance: MeshInstance3D) -> Dictionary:
	var negative_x := _new_side_accumulator()
	var positive_x := _new_side_accumulator()
	var centre_crossing_triangles: int = 0
	var mesh: Mesh = mesh_instance.mesh
	if mesh != null:
		for surface_index: int in range(mesh.get_surface_count()):
			var arrays: Array = mesh.surface_get_arrays(surface_index)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var triangle_indices: PackedInt32Array = indices
			if triangle_indices.is_empty():
				triangle_indices = PackedInt32Array()
				triangle_indices.resize(vertices.size())
				for vertex_index: int in range(vertices.size()):
					triangle_indices[vertex_index] = vertex_index
			for index_offset: int in range(0, triangle_indices.size(), 3):
				if index_offset + 2 >= triangle_indices.size():
					break
				var positions: Array[Vector3] = []
				for corner: int in range(3):
					var source_vertex: Vector3 = vertices[triangle_indices[index_offset + corner]]
					positions.append(mesh_instance.global_transform * source_vertex)
				var triangle_min_x := minf(minf(positions[0].x, positions[1].x), positions[2].x)
				var triangle_max_x := maxf(maxf(positions[0].x, positions[1].x), positions[2].x)
				if triangle_min_x < -SIDE_EPSILON and triangle_max_x > SIDE_EPSILON:
					centre_crossing_triangles += 1
				var centroid_x := (positions[0].x + positions[1].x + positions[2].x) / 3.0
				var accumulator: Dictionary = negative_x if centroid_x < 0.0 else positive_x
				_accumulate_triangle(accumulator, positions)
	return {
		"negative_x": _finalize_side(negative_x),
		"positive_x": _finalize_side(positive_x),
		"centre_crossing_triangles": centre_crossing_triangles,
	}


func _new_side_accumulator() -> Dictionary:
	return {
		"triangle_count": 0,
		"point_count": 0,
		"minimum": Vector3(INF, INF, INF),
		"maximum": Vector3(-INF, -INF, -INF),
	}


func _accumulate_triangle(accumulator: Dictionary, positions: Array[Vector3]) -> void:
	accumulator["triangle_count"] = int(accumulator["triangle_count"]) + 1
	for position: Vector3 in positions:
		accumulator["point_count"] = int(accumulator["point_count"]) + 1
		accumulator["minimum"] = (accumulator["minimum"] as Vector3).min(position)
		accumulator["maximum"] = (accumulator["maximum"] as Vector3).max(position)


func _finalize_side(accumulator: Dictionary) -> Dictionary:
	var minimum: Vector3 = accumulator["minimum"]
	var maximum: Vector3 = accumulator["maximum"]
	var has_geometry := int(accumulator["triangle_count"]) > 0
	if not has_geometry:
		minimum = Vector3.ZERO
		maximum = Vector3.ZERO
	var size := maximum - minimum
	return {
		"triangle_count": accumulator["triangle_count"],
		"point_count": accumulator["point_count"],
		"minimum": _vector_to_array(minimum),
		"maximum": _vector_to_array(maximum),
		"center": _vector_to_array((minimum + maximum) * 0.5),
		"size": _vector_to_array(size),
		"estimated_radius_yz": maxf(size.y, size.z) * 0.5,
	}


func _validate_wheel_pair(analysis: Dictionary, axle_label: String) -> void:
	for side_key: String in ["negative_x", "positive_x"]:
		var side: Dictionary = analysis[side_key]
		_expect(int(side["triangle_count"]) > 0, "%s %s wheel geometry is present" % [axle_label, side_key])
	_expect(int(analysis["centre_crossing_triangles"]) == 0, "%s wheel pair has no triangles crossing the vehicle centre plane" % axle_label)


func _average_side_axis(analysis: Dictionary, vector_key: String, axis: int) -> float:
	return (
		_float_from_side(analysis, "negative_x", vector_key, axis)
		+ _float_from_side(analysis, "positive_x", vector_key, axis)
	) * 0.5


func _float_from_side(analysis: Dictionary, side_key: String, vector_key: String, axis: int) -> float:
	var values: Array = (analysis[side_key] as Dictionary)[vector_key]
	return float(values[axis])


func _write_report(report: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_PATH.get_base_dir()))
	var file := FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	_expect(file != null, "source inspection report can be written")
	if file != null:
		file.store_string(JSON.stringify(report, "\t", false))
		file.close()


func _vector_to_array(value: Vector3) -> Array[float]:
	return [value.x, value.y, value.z]


func _aabb_to_dictionary(value: AABB) -> Dictionary:
	return {
		"position": _vector_to_array(value.position),
		"size": _vector_to_array(value.size),
	}


func _transform_to_dictionary(value: Transform3D) -> Dictionary:
	return {
		"basis_x": _vector_to_array(value.basis.x),
		"basis_y": _vector_to_array(value.basis.y),
		"basis_z": _vector_to_array(value.basis.z),
		"origin": _vector_to_array(value.origin),
	}


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRAFFIC_RIDER_BMW_F32_SOURCE_INSPECTION][PASS] %s" % message)
	else:
		_failures.append(message)
		push_error("[TRAFFIC_RIDER_BMW_F32_SOURCE_INSPECTION][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRAFFIC_RIDER_BMW_F32_SOURCE_INSPECTION] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRAFFIC_RIDER_BMW_F32_SOURCE_INSPECTION] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	quit(1)
