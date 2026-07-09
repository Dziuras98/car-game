extends RefCounted
class_name TrackSurfaceMeshBuilder


func build_surfaces(
	parent: Node3D,
	geometry: TrackGeometryData,
	material_factory: TrackMaterialFactory,
	config: Dictionary
) -> void:
	_create_grass(parent, material_factory, config)
	_create_shoulders(parent, geometry, material_factory)
	_create_track(parent, geometry, material_factory)


static func create_track_mesh(geometry: TrackGeometryData) -> ArrayMesh:
	var vertices: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var point_count: int = geometry.center_points.size()

	for index in point_count:
		vertices.append(geometry.left_edge_points[index])
		vertices.append(geometry.right_edge_points[index])

	for index in point_count:
		var next_index: int = (index + 1) % point_count
		var left_a: int = index * 2
		var right_a: int = left_a + 1
		var left_b: int = next_index * 2
		var right_b: int = left_b + 1

		add_quad_indices(indices, left_a, left_b, right_a, right_b)

	return create_array_mesh(vertices, indices)


static func create_shoulder_mesh(geometry: TrackGeometryData) -> ArrayMesh:
	var vertices: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var point_count: int = geometry.center_points.size()

	for index in point_count:
		vertices.append(geometry.left_shoulder_outer_points[index])
		vertices.append(geometry.left_edge_points[index])
		vertices.append(geometry.right_edge_points[index])
		vertices.append(geometry.right_shoulder_outer_points[index])

	for index in point_count:
		var next_index: int = (index + 1) % point_count
		var left_outer_a: int = index * 4
		var left_inner_a: int = left_outer_a + 1
		var right_inner_a: int = left_outer_a + 2
		var right_outer_a: int = left_outer_a + 3
		var left_outer_b: int = next_index * 4
		var left_inner_b: int = left_outer_b + 1
		var right_inner_b: int = left_outer_b + 2
		var right_outer_b: int = left_outer_b + 3

		add_quad_indices(indices, left_outer_a, left_outer_b, left_inner_a, left_inner_b)
		add_quad_indices(indices, right_inner_a, right_inner_b, right_outer_a, right_outer_b)

	return create_array_mesh(vertices, indices)


static func create_array_mesh(vertices: PackedVector3Array, indices: PackedInt32Array) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func add_quad_indices(indices: PackedInt32Array, a: int, b: int, c: int, d: int) -> void:
	indices.append(a)
	indices.append(b)
	indices.append(c)
	indices.append(c)
	indices.append(b)
	indices.append(d)


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


func _create_shoulders(parent: Node3D, geometry: TrackGeometryData, material_factory: TrackMaterialFactory) -> void:
	var shoulder_body: StaticBody3D = StaticBody3D.new()
	shoulder_body.name = "RoadsideTerrain"
	parent.add_child(shoulder_body)
	shoulder_body.owner = parent.owner

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	mesh_instance.mesh = create_shoulder_mesh(geometry)
	mesh_instance.material_override = material_factory.create_shoulder_material()
	shoulder_body.add_child(mesh_instance)
	mesh_instance.owner = parent.owner


func _create_track(parent: Node3D, geometry: TrackGeometryData, material_factory: TrackMaterialFactory) -> void:
	var track_body: StaticBody3D = StaticBody3D.new()
	track_body.name = "TrackSurface"
	parent.add_child(track_body)
	track_body.owner = parent.owner

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = "MeshInstance3D"
	mesh_instance.mesh = create_track_mesh(geometry)
	mesh_instance.material_override = material_factory.create_asphalt_material()
	track_body.add_child(mesh_instance)
	mesh_instance.owner = parent.owner
