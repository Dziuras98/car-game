extends RefCounted
class_name TrackSurfaceMeshBuilder

const TEXTURE_METERS_PER_REPEAT: float = 8.0


func build_surfaces(
	parent: Node3D,
	geometry: TrackGeometryData,
	material_factory: TrackMaterialFactory,
	config: Dictionary
) -> Dictionary:
	var track_mesh: ArrayMesh = create_track_mesh(geometry)
	var shoulder_mesh: ArrayMesh = create_shoulder_mesh(geometry)
	_create_grass(parent, material_factory, config)
	_create_shoulders(parent, shoulder_mesh, material_factory)
	_create_track(parent, track_mesh, material_factory)
	return {
		"track_mesh": track_mesh,
		"shoulder_mesh": shoulder_mesh,
	}


static func create_track_mesh(geometry: TrackGeometryData) -> ArrayMesh:
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var tangents: PackedFloat32Array = PackedFloat32Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var point_count: int = geometry.center_points.size()
	if point_count < 2:
		return create_array_mesh(vertices, indices, normals, uvs, tangents)

	var cumulative_distance: PackedFloat32Array = _build_cumulative_distances(geometry.center_points)
	var total_length: float = _get_loop_length(geometry.center_points, cumulative_distance)
	for seam_index: int in range(point_count + 1):
		var source_index: int = seam_index % point_count
		var distance: float = total_length if seam_index == point_count else cumulative_distance[source_index]
		var normal: Vector3 = _get_surface_normal(geometry, source_index)
		var tangent: Vector3 = geometry.forward_vectors[source_index].normalized()
		vertices.append(geometry.left_edge_points[source_index])
		vertices.append(geometry.right_edge_points[source_index])
		normals.append(normal)
		normals.append(normal)
		_append_tangent(tangents, tangent)
		_append_tangent(tangents, tangent)
		var longitudinal_uv: float = distance / TEXTURE_METERS_PER_REPEAT
		uvs.append(Vector2(0.0, longitudinal_uv))
		uvs.append(Vector2(1.0, longitudinal_uv))

	for index: int in range(point_count):
		var left_a: int = index * 2
		var right_a: int = left_a + 1
		var left_b: int = (index + 1) * 2
		var right_b: int = left_b + 1
		add_quad_indices(indices, left_a, left_b, right_a, right_b)

	return create_array_mesh(vertices, indices, normals, uvs, tangents)


static func create_shoulder_mesh(geometry: TrackGeometryData) -> ArrayMesh:
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var tangents: PackedFloat32Array = PackedFloat32Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var point_count: int = geometry.center_points.size()
	if point_count < 2:
		return create_array_mesh(vertices, indices, normals, uvs, tangents)

	var cumulative_distance: PackedFloat32Array = _build_cumulative_distances(geometry.center_points)
	var total_length: float = _get_loop_length(geometry.center_points, cumulative_distance)
	for seam_index: int in range(point_count + 1):
		var source_index: int = seam_index % point_count
		var distance: float = total_length if seam_index == point_count else cumulative_distance[source_index]
		var normal: Vector3 = _get_surface_normal(geometry, source_index)
		var tangent: Vector3 = geometry.forward_vectors[source_index].normalized()
		vertices.append(geometry.left_shoulder_outer_points[source_index])
		vertices.append(geometry.left_edge_points[source_index])
		vertices.append(geometry.right_edge_points[source_index])
		vertices.append(geometry.right_shoulder_outer_points[source_index])
		for vertex_index: int in range(4):
			normals.append(normal)
			_append_tangent(tangents, tangent)
		var longitudinal_uv: float = distance / TEXTURE_METERS_PER_REPEAT
		uvs.append(Vector2(0.0, longitudinal_uv))
		uvs.append(Vector2(0.42, longitudinal_uv))
		uvs.append(Vector2(0.58, longitudinal_uv))
		uvs.append(Vector2(1.0, longitudinal_uv))

	for index: int in range(point_count):
		var left_outer_a: int = index * 4
		var left_inner_a: int = left_outer_a + 1
		var right_inner_a: int = left_outer_a + 2
		var right_outer_a: int = left_outer_a + 3
		var left_outer_b: int = (index + 1) * 4
		var left_inner_b: int = left_outer_b + 1
		var right_inner_b: int = left_outer_b + 2
		var right_outer_b: int = left_outer_b + 3
		add_quad_indices(indices, left_outer_a, left_outer_b, left_inner_a, left_inner_b)
		add_quad_indices(indices, right_inner_a, right_inner_b, right_outer_a, right_outer_b)

	return create_array_mesh(vertices, indices, normals, uvs, tangents)


static func create_array_mesh(
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	normals: PackedVector3Array = PackedVector3Array(),
	uvs: PackedVector2Array = PackedVector2Array(),
	tangents: PackedFloat32Array = PackedFloat32Array()
) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	if normals.size() == vertices.size():
		arrays[Mesh.ARRAY_NORMAL] = normals
	if uvs.size() == vertices.size():
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	if tangents.size() == vertices.size() * 4:
		arrays[Mesh.ARRAY_TANGENT] = tangents

	var mesh: ArrayMesh = ArrayMesh.new()
	if not vertices.is_empty() and not indices.is_empty():
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func add_quad_indices(indices: PackedInt32Array, a: int, b: int, c: int, d: int) -> void:
	indices.append(a)
	indices.append(b)
	indices.append(c)
	indices.append(c)
	indices.append(b)
	indices.append(d)


static func _build_cumulative_distances(points: PackedVector3Array) -> PackedFloat32Array:
	var cumulative: PackedFloat32Array = PackedFloat32Array()
	var distance: float = 0.0
	for index: int in range(points.size()):
		cumulative.append(distance)
		if index + 1 < points.size():
			distance += points[index].distance_to(points[index + 1])
	return cumulative


static func _get_loop_length(points: PackedVector3Array, cumulative: PackedFloat32Array) -> float:
	if points.size() < 2:
		return 0.0
	return cumulative[-1] + points[-1].distance_to(points[0])


static func _get_surface_normal(geometry: TrackGeometryData, index: int) -> Vector3:
	var normal: Vector3 = geometry.right_vectors[index].cross(geometry.forward_vectors[index])
	if normal.length_squared() <= 0.000001:
		return Vector3.UP
	return normal.normalized()


static func _append_tangent(tangents: PackedFloat32Array, tangent: Vector3) -> void:
	var safe_tangent: Vector3 = tangent.normalized()
	tangents.append(safe_tangent.x)
	tangents.append(safe_tangent.y)
	tangents.append(safe_tangent.z)
	tangents.append(1.0)


func _create_grass(parent: Node3D, material_factory: TrackMaterialFactory, config: Dictionary) -> void:
	var grass_size: Vector2 = config.get("grass_size", Vector2(260.0, 190.0))
	var grass_mesh: BoxMesh = BoxMesh.new()
	grass_mesh.size = Vector3(grass_size.x, 0.4, grass_size.y)

	var grass_body: StaticBody3D = StaticBody3D.new()
	grass_body.name = "Grass"
	parent.add_child(grass_body)
	grass_body.owner = parent.owner
	grass_body.position.y = -0.25

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	mesh_instance.mesh = grass_mesh
	mesh_instance.material_override = material_factory.create_grass_material()
	grass_body.add_child(mesh_instance)
	mesh_instance.owner = parent.owner


func _create_shoulders(parent: Node3D, mesh: ArrayMesh, material_factory: TrackMaterialFactory) -> void:
	var shoulder_body: StaticBody3D = StaticBody3D.new()
	shoulder_body.name = "RoadsideTerrain"
	parent.add_child(shoulder_body)
	shoulder_body.owner = parent.owner

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material_factory.create_shoulder_material()
	shoulder_body.add_child(mesh_instance)
	mesh_instance.owner = parent.owner


func _create_track(parent: Node3D, mesh: ArrayMesh, material_factory: TrackMaterialFactory) -> void:
	var track_body: StaticBody3D = StaticBody3D.new()
	track_body.name = "TrackSurface"
	parent.add_child(track_body)
	track_body.owner = parent.owner

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material_factory.create_asphalt_material()
	track_body.add_child(mesh_instance)
	mesh_instance.owner = parent.owner
