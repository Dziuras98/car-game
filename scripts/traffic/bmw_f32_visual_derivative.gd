extends Node3D

const BODY_MESH_NAME := "AI_Bmw4_High_BMW_4_Series_2014_0"
const FRONT_WHEEL_MESH_NAME := "on_teker_0"
const REAR_WHEEL_MESH_NAME := "arka_teker_0"

@export var visual_scale: float = 0.6940157
@export var source_model_path: NodePath = ^"Body/SourceModel"
@export var front_left_path: NodePath = ^"WheelFrontLeft"
@export var front_right_path: NodePath = ^"WheelFrontRight"
@export var rear_left_path: NodePath = ^"WheelRearLeft"
@export var rear_right_path: NodePath = ^"WheelRearRight"

var _processed: bool = false


func _ready() -> void:
	_build_derivative()


func is_processed() -> bool:
	return _processed


func _build_derivative() -> void:
	var source_model := get_node_or_null(source_model_path) as Node3D
	if source_model == null:
		push_error("BMW F32 derivative requires the committed SourceModel node.")
		return

	var records: Array[Dictionary] = []
	_collect_mesh_records(source_model, Transform3D.IDENTITY, records)
	var body_record := _find_record(records, BODY_MESH_NAME)
	var front_record := _find_record(records, FRONT_WHEEL_MESH_NAME)
	var rear_record := _find_record(records, REAR_WHEEL_MESH_NAME)
	if body_record.is_empty() or front_record.is_empty() or rear_record.is_empty():
		push_error("BMW F32 derivative could not resolve the exact source mesh nodes.")
		return

	var front_bounds := _measure_pair(front_record)
	var rear_bounds := _measure_pair(rear_record)
	if not _pair_is_separable(front_bounds) or not _pair_is_separable(rear_bounds):
		push_error("BMW F32 source wheel pairs are not safely separable by the recorded lateral plane.")
		return

	var source_to_project := _build_source_to_project(front_bounds, rear_bounds)
	source_model.transform = source_to_project

	var front_pair := _split_pair(front_record, front_bounds, source_to_project)
	var rear_pair := _split_pair(rear_record, rear_bounds, source_to_project)
	if front_pair.is_empty() or rear_pair.is_empty():
		push_error("BMW F32 wheel mesh separation failed.")
		return

	(front_record["instance"] as MeshInstance3D).visible = false
	(rear_record["instance"] as MeshInstance3D).visible = false

	if not _install_pair(front_pair, front_left_path, front_right_path):
		return
	if not _install_pair(rear_pair, rear_left_path, rear_right_path):
		return
	_processed = true


func _collect_mesh_records(
	node: Node,
	parent_transform: Transform3D,
	records: Array[Dictionary]
) -> void:
	var local_transform := Transform3D.IDENTITY
	if node is Node3D:
		local_transform = (node as Node3D).transform
	var source_transform := parent_transform * local_transform
	if node is MeshInstance3D:
		records.append({
			"instance": node as MeshInstance3D,
			"source_transform": source_transform,
		})
	for child: Node in node.get_children():
		_collect_mesh_records(child, source_transform, records)


func _find_record(records: Array[Dictionary], node_name: String) -> Dictionary:
	for record: Dictionary in records:
		var instance: MeshInstance3D = record["instance"]
		if String(instance.name) == node_name:
			return record
	return {}


func _measure_pair(record: Dictionary) -> Dictionary:
	var instance: MeshInstance3D = record["instance"]
	var source_transform: Transform3D = record["source_transform"]
	var split_x := (source_transform * instance.get_aabb().get_center()).x
	var negative := _new_bounds()
	var positive := _new_bounds()
	var crossing_triangles := 0
	var mesh: Mesh = instance.mesh
	if mesh == null:
		return {}

	for surface_index: int in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface_index)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var triangle_indices := _triangle_indices(arrays, vertices.size())
		for offset: int in range(0, triangle_indices.size(), 3):
			if offset + 2 >= triangle_indices.size():
				break
			var source_positions: Array[Vector3] = []
			for corner: int in range(3):
				source_positions.append(
					source_transform * vertices[triangle_indices[offset + corner]]
				)
			var minimum_x := minf(
				minf(source_positions[0].x, source_positions[1].x),
				source_positions[2].x
			)
			var maximum_x := maxf(
				maxf(source_positions[0].x, source_positions[1].x),
				source_positions[2].x
			)
			if minimum_x < split_x and maximum_x > split_x:
				crossing_triangles += 1
			var centroid_x := (
				source_positions[0].x + source_positions[1].x + source_positions[2].x
			) / 3.0
			_accumulate_triangle(
				negative if centroid_x < split_x else positive,
				source_positions
			)

	return {
		"split_x": split_x,
		"negative": _finish_bounds(negative),
		"positive": _finish_bounds(positive),
		"crossing_triangles": crossing_triangles,
	}


func _pair_is_separable(bounds: Dictionary) -> bool:
	if bounds.is_empty() or int(bounds.get("crossing_triangles", -1)) != 0:
		return false
	return (
		int((bounds["negative"] as Dictionary).get("triangle_count", 0)) == 162
		and int((bounds["positive"] as Dictionary).get("triangle_count", 0)) == 162
	)


func _build_source_to_project(front: Dictionary, rear: Dictionary) -> Transform3D:
	var front_center := _pair_center(front)
	var rear_center := _pair_center(rear)
	var source_center := Vector3(
		(front_center.x + rear_center.x) * 0.5,
		minf(_pair_minimum_y(front), _pair_minimum_y(rear)),
		(front_center.z + rear_center.z) * 0.5
	)
	var basis := Basis(
		Vector3(-visual_scale, 0.0, 0.0),
		Vector3(0.0, visual_scale, 0.0),
		Vector3(0.0, 0.0, -visual_scale)
	)
	return Transform3D(basis, -(basis * source_center))


func _split_pair(
	record: Dictionary,
	bounds: Dictionary,
	source_to_project: Transform3D
) -> Dictionary:
	var negative_hub_source := _dictionary_vector(bounds["negative"], "center")
	var positive_hub_source := _dictionary_vector(bounds["positive"], "center")
	var negative_hub_project := source_to_project * negative_hub_source
	var positive_hub_project := source_to_project * positive_hub_source
	var negative_mesh := _build_side_mesh(
		record,
		float(bounds["split_x"]),
		true,
		source_to_project,
		negative_hub_project
	)
	var positive_mesh := _build_side_mesh(
		record,
		float(bounds["split_x"]),
		false,
		source_to_project,
		positive_hub_project
	)
	if negative_mesh == null or positive_mesh == null:
		return {}
	return {
		"negative": {
			"mesh": negative_mesh,
			"position": negative_hub_project,
		},
		"positive": {
			"mesh": positive_mesh,
			"position": positive_hub_project,
		},
	}


func _build_side_mesh(
	record: Dictionary,
	split_x: float,
	negative_side: bool,
	source_to_project: Transform3D,
	hub_project: Vector3
) -> ArrayMesh:
	var instance: MeshInstance3D = record["instance"]
	var source_transform: Transform3D = record["source_transform"]
	var source_mesh: Mesh = instance.mesh
	if source_mesh == null:
		return null
	var output := ArrayMesh.new()

	for surface_index: int in range(source_mesh.get_surface_count()):
		var source_arrays: Array = source_mesh.surface_get_arrays(surface_index)
		var source_vertices: PackedVector3Array = source_arrays[Mesh.ARRAY_VERTEX]
		var source_normals: PackedVector3Array = source_arrays[Mesh.ARRAY_NORMAL]
		var source_tangents: PackedFloat32Array = source_arrays[Mesh.ARRAY_TANGENT]
		var source_colors: PackedColorArray = source_arrays[Mesh.ARRAY_COLOR]
		var source_uvs: PackedVector2Array = source_arrays[Mesh.ARRAY_TEX_UV]
		var source_uv2s: PackedVector2Array = source_arrays[Mesh.ARRAY_TEX_UV2]
		var triangle_indices := _triangle_indices(source_arrays, source_vertices.size())

		var vertices := PackedVector3Array()
		var normals := PackedVector3Array()
		var tangents := PackedFloat32Array()
		var colors := PackedColorArray()
		var uvs := PackedVector2Array()
		var uv2s := PackedVector2Array()
		var indices := PackedInt32Array()

		for offset: int in range(0, triangle_indices.size(), 3):
			if offset + 2 >= triangle_indices.size():
				break
			var source_positions: Array[Vector3] = []
			for corner: int in range(3):
				source_positions.append(
					source_transform * source_vertices[triangle_indices[offset + corner]]
				)
			var centroid_x := (
				source_positions[0].x + source_positions[1].x + source_positions[2].x
			) / 3.0
			if (centroid_x < split_x) != negative_side:
				continue

			for corner: int in range(3):
				var source_index := triangle_indices[offset + corner]
				vertices.append(source_to_project * source_positions[corner] - hub_project)
				if source_index < source_normals.size():
					var source_normal := source_transform.basis * source_normals[source_index]
					normals.append((source_to_project.basis * source_normal).normalized())
				if (source_index + 1) * 4 <= source_tangents.size():
					var tangent_offset := source_index * 4
					var source_tangent := Vector3(
						source_tangents[tangent_offset],
						source_tangents[tangent_offset + 1],
						source_tangents[tangent_offset + 2]
					)
					var project_tangent := (
						source_to_project.basis * (source_transform.basis * source_tangent)
					).normalized()
					tangents.append(project_tangent.x)
					tangents.append(project_tangent.y)
					tangents.append(project_tangent.z)
					tangents.append(source_tangents[tangent_offset + 3])
				if source_index < source_colors.size():
					colors.append(source_colors[source_index])
				if source_index < source_uvs.size():
					uvs.append(source_uvs[source_index])
				if source_index < source_uv2s.size():
					uv2s.append(source_uv2s[source_index])
				indices.append(indices.size())

		if vertices.is_empty():
			continue
		var output_arrays: Array = []
		output_arrays.resize(Mesh.ARRAY_MAX)
		output_arrays[Mesh.ARRAY_VERTEX] = vertices
		output_arrays[Mesh.ARRAY_INDEX] = indices
		if normals.size() == vertices.size():
			output_arrays[Mesh.ARRAY_NORMAL] = normals
		if tangents.size() == vertices.size() * 4:
			output_arrays[Mesh.ARRAY_TANGENT] = tangents
		if colors.size() == vertices.size():
			output_arrays[Mesh.ARRAY_COLOR] = colors
		if uvs.size() == vertices.size():
			output_arrays[Mesh.ARRAY_TEX_UV] = uvs
		if uv2s.size() == vertices.size():
			output_arrays[Mesh.ARRAY_TEX_UV2] = uv2s
		output.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, output_arrays)
		output.surface_set_material(
			output.get_surface_count() - 1,
			source_mesh.surface_get_material(surface_index)
		)

	return output


func _triangle_indices(arrays: Array, vertex_count: int) -> PackedInt32Array:
	var result: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if not result.is_empty():
		return result
	result.resize(vertex_count)
	for index: int in range(vertex_count):
		result[index] = index
	return result


func _install_pair(
	pair: Dictionary,
	left_path: NodePath,
	right_path: NodePath
) -> bool:
	var negative: Dictionary = pair["negative"]
	var positive: Dictionary = pair["positive"]
	var negative_position: Vector3 = negative["position"]
	var positive_position: Vector3 = positive["position"]
	var left_data := negative if negative_position.x < positive_position.x else positive
	var right_data := positive if negative_position.x < positive_position.x else negative
	return _install_wheel(left_path, left_data) and _install_wheel(right_path, right_data)


func _install_wheel(path: NodePath, data: Dictionary) -> bool:
	var wheel := get_node_or_null(path) as Node3D
	if wheel == null:
		push_error("BMW F32 derivative is missing explicit wheel node: %s" % path)
		return false
	var geometry := wheel.get_node_or_null(^"Geometry") as MeshInstance3D
	if geometry == null:
		push_error("BMW F32 derivative wheel is missing its Geometry node: %s" % path)
		return false
	wheel.position = data["position"]
	geometry.mesh = data["mesh"]
	return true


func _new_bounds() -> Dictionary:
	return {
		"triangle_count": 0,
		"minimum": Vector3(INF, INF, INF),
		"maximum": Vector3(-INF, -INF, -INF),
	}


func _accumulate_triangle(bounds: Dictionary, positions: Array[Vector3]) -> void:
	bounds["triangle_count"] = int(bounds["triangle_count"]) + 1
	for position: Vector3 in positions:
		bounds["minimum"] = (bounds["minimum"] as Vector3).min(position)
		bounds["maximum"] = (bounds["maximum"] as Vector3).max(position)


func _finish_bounds(bounds: Dictionary) -> Dictionary:
	var minimum: Vector3 = bounds["minimum"]
	var maximum: Vector3 = bounds["maximum"]
	return {
		"triangle_count": bounds["triangle_count"],
		"minimum": minimum,
		"maximum": maximum,
		"center": (minimum + maximum) * 0.5,
	}


func _pair_center(pair: Dictionary) -> Vector3:
	return (
		_dictionary_vector(pair["negative"], "center")
		+ _dictionary_vector(pair["positive"], "center")
	) * 0.5


func _pair_minimum_y(pair: Dictionary) -> float:
	return minf(
		_dictionary_vector(pair["negative"], "minimum").y,
		_dictionary_vector(pair["positive"], "minimum").y
	)


func _dictionary_vector(dictionary: Dictionary, key: String) -> Vector3:
	return dictionary[key] as Vector3
