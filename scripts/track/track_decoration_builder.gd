extends RefCounted
class_name TrackDecorationBuilder


func build_decorations(
	parent: Node3D,
	geometry: TrackGeometryData,
	material_factory: TrackMaterialFactory,
	config: Dictionary
) -> void:
	if not bool(config.get("has_stadium", false)):
		return

	_create_stadium(parent, geometry, material_factory, config)


func _create_stadium(
	parent: Node3D,
	geometry: TrackGeometryData,
	material_factory: TrackMaterialFactory,
	config: Dictionary
) -> void:
	var stadium: Node3D = Node3D.new()
	stadium.name = "Stadium"
	parent.add_child(stadium)
	stadium.owner = parent.owner

	_add_stadium_back_walls(
		stadium,
		geometry,
		material_factory.create_stadium_back_wall_material(),
		material_factory.create_stadium_wall_cap_material(),
		config
	)
	_add_wall_direction_arrows(stadium, geometry, material_factory.create_wall_arrow_material(), config)

	var concrete_material: Material = material_factory.create_stadium_concrete_material()
	var seat_material: Material = material_factory.create_stadium_seat_material()
	var roof_material: Material = material_factory.create_stadium_roof_material()
	var audience_materials: Array[StandardMaterial3D] = material_factory.create_audience_materials()
	var stadium_section_step: int = int(config.get("stadium_section_step", 8))
	var barrier_distance_from_road: float = float(config.get("barrier_distance_from_road", 12.0))
	var stadium_distance_from_barrier: float = float(config.get("stadium_distance_from_barrier", 24.0))

	var section_index: int = 0
	for index in range(0, geometry.center_points.size(), stadium_section_step):
		var current: Vector3 = geometry.center_points[index]
		var tangent: Vector3 = geometry.forward_vectors[index]
		var outward: Vector3 = current - geometry.center
		outward.y = 0.0
		outward = outward.normalized()
		var yaw: float = atan2(tangent.x, tangent.z)
		var base_offset: float = geometry.half_widths[index] + barrier_distance_from_road + stadium_distance_from_barrier
		var base_position: Vector3 = current + outward * base_offset

		_add_stadium_section(base_position, outward, yaw, section_index, stadium, concrete_material, seat_material, roof_material, audience_materials)
		section_index += 1

		if section_index % 5 == 0:
			_add_stadium_light(stadium, base_position + outward * 18.0, yaw, material_factory)


func _add_stadium_back_walls(
	parent: Node3D,
	geometry: TrackGeometryData,
	wall_material: Material,
	cap_material: Material,
	config: Dictionary
) -> void:
	var wall_height: float = 13.0
	var cap_half_width: float = 0.85
	var barrier_distance_from_road: float = float(config.get("barrier_distance_from_road", 12.0))
	var stadium_distance_from_barrier: float = float(config.get("stadium_distance_from_barrier", 24.0))
	var wall_vertices: PackedVector3Array = PackedVector3Array()
	var wall_indices: PackedInt32Array = PackedInt32Array()
	var cap_vertices: PackedVector3Array = PackedVector3Array()
	var cap_indices: PackedInt32Array = PackedInt32Array()

	for index in geometry.center_points.size():
		var current: Vector3 = geometry.center_points[index]
		var outward: Vector3 = current - geometry.center
		outward.y = 0.0
		outward = outward.normalized()
		var wall_offset: float = geometry.half_widths[index] + barrier_distance_from_road + stadium_distance_from_barrier + 19.0
		var wall_base_position: Vector3 = current + outward * wall_offset

		wall_vertices.append(wall_base_position)
		wall_vertices.append(wall_base_position + Vector3.UP * wall_height)
		cap_vertices.append(wall_base_position - outward * cap_half_width + Vector3.UP * wall_height)
		cap_vertices.append(wall_base_position + outward * cap_half_width + Vector3.UP * wall_height)

	for index in geometry.center_points.size():
		var next_index: int = (index + 1) % geometry.center_points.size()
		var bottom_a: int = index * 2
		var top_a: int = bottom_a + 1
		var bottom_b: int = next_index * 2
		var top_b: int = bottom_b + 1
		var cap_inner_a: int = index * 2
		var cap_outer_a: int = cap_inner_a + 1
		var cap_inner_b: int = next_index * 2
		var cap_outer_b: int = cap_inner_b + 1

		TrackSurfaceMeshBuilder.add_quad_indices(wall_indices, bottom_a, bottom_b, top_a, top_b)
		TrackSurfaceMeshBuilder.add_quad_indices(cap_indices, cap_inner_a, cap_inner_b, cap_outer_a, cap_outer_b)

	_add_array_mesh(parent, wall_vertices, wall_indices, wall_material, "StadiumBackWall")
	_add_array_mesh(parent, cap_vertices, cap_indices, cap_material, "StadiumWallCap")


func _add_wall_direction_arrows(parent: Node3D, geometry: TrackGeometryData, arrow_material: Material, config: Dictionary) -> void:
	var barrier_distance_from_road: float = float(config.get("barrier_distance_from_road", 12.0))
	var stadium_distance_from_barrier: float = float(config.get("stadium_distance_from_barrier", 24.0))
	var arrow_vertices: PackedVector3Array = PackedVector3Array()
	var arrow_indices: PackedInt32Array = PackedInt32Array()

	for index in range(0, geometry.center_points.size(), 6):
		var current: Vector3 = geometry.center_points[index]
		var tangent: Vector3 = geometry.forward_vectors[index]
		var outward: Vector3 = current - geometry.center
		outward.y = 0.0
		outward = outward.normalized()
		var wall_offset: float = geometry.half_widths[index] + barrier_distance_from_road + stadium_distance_from_barrier + 19.0
		var wall_position: Vector3 = current + outward * wall_offset - outward * 0.08 + Vector3.UP * 5.2
		var shaft_start: Vector3 = wall_position - tangent * 3.8
		var shaft_end: Vector3 = wall_position + tangent * 1.2
		var tip: Vector3 = wall_position + tangent * 4.2
		var shaft_half_height: Vector3 = Vector3.UP * 0.38
		var head_half_height: Vector3 = Vector3.UP * 1.25
		var base_index: int = arrow_vertices.size()

		arrow_vertices.append(shaft_start - shaft_half_height)
		arrow_vertices.append(shaft_end - shaft_half_height)
		arrow_vertices.append(shaft_start + shaft_half_height)
		arrow_vertices.append(shaft_end + shaft_half_height)
		arrow_vertices.append(shaft_end - head_half_height)
		arrow_vertices.append(tip)
		arrow_vertices.append(shaft_end + head_half_height)

		TrackSurfaceMeshBuilder.add_quad_indices(arrow_indices, base_index, base_index + 1, base_index + 2, base_index + 3)
		arrow_indices.append(base_index + 4)
		arrow_indices.append(base_index + 5)
		arrow_indices.append(base_index + 6)

	_add_array_mesh(parent, arrow_vertices, arrow_indices, arrow_material, "WallDirectionArrows")


func _add_stadium_section(
	base_position: Vector3,
	outward: Vector3,
	yaw: float,
	section_index: int,
	parent: Node3D,
	concrete_material: Material,
	seat_material: Material,
	roof_material: Material,
	audience_materials: Array[StandardMaterial3D]
) -> void:
	for row in 4:
		var row_position: Vector3 = base_position + outward * float(row) * 4.2 + Vector3.UP * (0.25 + float(row) * 0.85)
		_add_box_mesh(
			parent,
			row_position,
			Vector3(4.0, 0.5, 10.5),
			yaw,
			concrete_material,
			"StandStep"
		)
		_add_box_mesh(
			parent,
			row_position + Vector3.UP * 0.35 - outward * 0.7,
			Vector3(0.35, 0.28, 9.4),
			yaw,
			seat_material,
			"SeatRow"
		)

		for seat in 3:
			var lateral_offset: float = (float(seat) - 1.0) * 2.8
			var lateral: Vector3 = Vector3(cos(yaw), 0.0, -sin(yaw))
			var spectator_position: Vector3 = row_position + lateral * lateral_offset + Vector3.UP * 0.82 - outward * 0.25
			var material_index: int = (section_index + row + seat) % audience_materials.size()
			_add_box_mesh(
				parent,
				spectator_position,
				Vector3(0.55, 0.75, 0.55),
				yaw,
				audience_materials[material_index],
				"Spectator"
			)

	var roof_position: Vector3 = base_position + outward * 6.6 + Vector3.UP * 4.4
	_add_box_mesh(parent, roof_position, Vector3(13.5, 0.35, 11.5), yaw, roof_material, "GrandstandRoof")


func _add_stadium_light(
	parent: Node3D,
	position: Vector3,
	yaw: float,
	material_factory: TrackMaterialFactory
) -> void:
	_add_box_mesh(parent, position + Vector3.UP * 5.2, Vector3(0.45, 10.4, 0.45), yaw, material_factory.create_light_pole_material(), "LightPole")
	_add_box_mesh(parent, position + Vector3.UP * 10.4, Vector3(0.9, 0.8, 4.6), yaw, material_factory.create_floodlight_material(), "Floodlights")


func _add_box_mesh(parent: Node3D, position: Vector3, size: Vector3, yaw: float, material: Material, node_name: String) -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = position
	mesh_instance.rotation.y = yaw
	parent.add_child(mesh_instance)
	mesh_instance.owner = parent.owner


func _add_array_mesh(
	parent: Node3D,
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	material: Material,
	node_name: String
) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = TrackSurfaceMeshBuilder.create_array_mesh(vertices, indices)
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	mesh_instance.owner = parent.owner
