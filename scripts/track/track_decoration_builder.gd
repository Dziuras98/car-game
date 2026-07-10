extends RefCounted
class_name TrackDecorationBuilder

const STAND_STEP_SIZE: Vector3 = Vector3(4.0, 0.5, 10.5)
const SEAT_ROW_SIZE: Vector3 = Vector3(0.35, 0.28, 9.4)
const SPECTATOR_SIZE: Vector3 = Vector3(0.55, 0.75, 0.55)
const ROOF_SIZE: Vector3 = Vector3(13.5, 0.35, 11.5)
const LIGHT_POLE_SIZE: Vector3 = Vector3(0.45, 10.4, 0.45)
const FLOODLIGHT_SIZE: Vector3 = Vector3(0.9, 0.8, 4.6)


func build_decorations(
	parent: Node3D,
	geometry: TrackGeometryData,
	material_factory: TrackMaterialFactory,
	config: TrackGenerationConfig
) -> void:
	if config == null or not config.has_stadium or geometry.center_points.is_empty():
		return
	_create_stadium(parent, geometry, material_factory, config)


func _create_stadium(
	parent: Node3D,
	geometry: TrackGeometryData,
	material_factory: TrackMaterialFactory,
	config: TrackGenerationConfig
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
	_add_wall_direction_arrows(
		stadium,
		geometry,
		material_factory.create_wall_arrow_material(),
		config
	)

	var concrete_transforms: Array = []
	var seat_transforms: Array = []
	var roof_transforms: Array = []
	var pole_transforms: Array = []
	var floodlight_transforms: Array = []
	var audience_materials: Array[StandardMaterial3D] = material_factory.create_audience_materials()
	var spectator_transforms: Array = []
	for _material_index: int in range(audience_materials.size()):
		spectator_transforms.append([])

	var stadium_section_step: int = maxi(config.stadium_section_step, 1)
	var barrier_distance_from_road: float = maxf(config.barrier_distance_from_road, 0.0)
	var stadium_distance_from_barrier: float = maxf(config.stadium_distance_from_barrier, 0.0)
	var section_index: int = 0
	for index: int in range(0, geometry.center_points.size(), stadium_section_step):
		var current: Vector3 = geometry.center_points[index]
		var tangent: Vector3 = geometry.forward_vectors[index]
		var outward: Vector3 = _get_local_outward(geometry, index)
		var yaw: float = atan2(tangent.x, tangent.z)
		var basis: Basis = Basis(Vector3.UP, yaw)
		var base_offset: float = (
			geometry.half_widths[index]
			+ barrier_distance_from_road
			+ stadium_distance_from_barrier
		)
		var base_position: Vector3 = current + outward * base_offset
		var lateral: Vector3 = Vector3(cos(yaw), 0.0, -sin(yaw))

		for row: int in range(4):
			var row_position: Vector3 = (
				base_position
				+ outward * float(row) * 4.2
				+ Vector3.UP * (0.25 + float(row) * 0.85)
			)
			concrete_transforms.append(Transform3D(basis, row_position))
			seat_transforms.append(
				Transform3D(basis, row_position + Vector3.UP * 0.35 - outward * 0.7)
			)

			if not audience_materials.is_empty():
				for seat: int in range(3):
					var lateral_offset: float = (float(seat) - 1.0) * 2.8
					var spectator_position: Vector3 = (
						row_position
						+ lateral * lateral_offset
						+ Vector3.UP * 0.82
						- outward * 0.25
					)
					var material_index: int = (
						section_index + row + seat
					) % audience_materials.size()
					var material_transforms: Array = spectator_transforms[material_index]
					material_transforms.append(Transform3D(basis, spectator_position))

		roof_transforms.append(
			Transform3D(basis, base_position + outward * 6.6 + Vector3.UP * 4.4)
		)
		section_index += 1
		if section_index % 5 == 0:
			var light_base: Vector3 = base_position + outward * 18.0
			pole_transforms.append(Transform3D(basis, light_base + Vector3.UP * 5.2))
			floodlight_transforms.append(
				Transform3D(basis, light_base + Vector3.UP * 10.4)
			)

	_add_box_batch(
		stadium,
		"StandSteps",
		STAND_STEP_SIZE,
		material_factory.create_stadium_concrete_material(),
		concrete_transforms
	)
	_add_box_batch(
		stadium,
		"SeatRows",
		SEAT_ROW_SIZE,
		material_factory.create_stadium_seat_material(),
		seat_transforms
	)
	_add_box_batch(
		stadium,
		"GrandstandRoofs",
		ROOF_SIZE,
		material_factory.create_stadium_roof_material(),
		roof_transforms
	)
	_add_box_batch(
		stadium,
		"LightPoles",
		LIGHT_POLE_SIZE,
		material_factory.create_light_pole_material(),
		pole_transforms
	)
	_add_box_batch(
		stadium,
		"Floodlights",
		FLOODLIGHT_SIZE,
		material_factory.create_floodlight_material(),
		floodlight_transforms
	)
	for material_index: int in range(audience_materials.size()):
		_add_box_batch(
			stadium,
			"Spectators%02d" % material_index,
			SPECTATOR_SIZE,
			audience_materials[material_index],
			spectator_transforms[material_index]
		)


func _get_local_outward(geometry: TrackGeometryData, index: int) -> Vector3:
	var right: Vector3 = geometry.right_vectors[index]
	if right.length_squared() <= 0.000001:
		right = Vector3.RIGHT
	else:
		right = right.normalized()
	var from_center: Vector3 = geometry.center_points[index] - geometry.center
	var direction_sign: float = signf(from_center.dot(right))
	if is_zero_approx(direction_sign):
		direction_sign = 1.0
	return right * direction_sign


func _add_stadium_back_walls(
	parent: Node3D,
	geometry: TrackGeometryData,
	wall_material: Material,
	cap_material: Material,
	config: TrackGenerationConfig
) -> void:
	var wall_height: float = 13.0
	var cap_half_width: float = 0.85
	var barrier_distance_from_road: float = maxf(config.barrier_distance_from_road, 0.0)
	var stadium_distance_from_barrier: float = maxf(config.stadium_distance_from_barrier, 0.0)
	var wall_vertices: PackedVector3Array = PackedVector3Array()
	var wall_indices: PackedInt32Array = PackedInt32Array()
	var cap_vertices: PackedVector3Array = PackedVector3Array()
	var cap_indices: PackedInt32Array = PackedInt32Array()

	for index: int in range(geometry.center_points.size()):
		var outward: Vector3 = _get_local_outward(geometry, index)
		var wall_offset: float = (
			geometry.half_widths[index]
			+ barrier_distance_from_road
			+ stadium_distance_from_barrier
			+ 19.0
		)
		var wall_base_position: Vector3 = geometry.center_points[index] + outward * wall_offset
		wall_vertices.append(wall_base_position)
		wall_vertices.append(wall_base_position + Vector3.UP * wall_height)
		cap_vertices.append(wall_base_position - outward * cap_half_width + Vector3.UP * wall_height)
		cap_vertices.append(wall_base_position + outward * cap_half_width + Vector3.UP * wall_height)

	for index: int in range(geometry.center_points.size()):
		var next_index: int = (index + 1) % geometry.center_points.size()
		var bottom_a: int = index * 2
		var top_a: int = bottom_a + 1
		var bottom_b: int = next_index * 2
		var top_b: int = bottom_b + 1
		TrackSurfaceMeshBuilder.add_quad_indices(
			wall_indices,
			bottom_a,
			bottom_b,
			top_a,
			top_b
		)
		TrackSurfaceMeshBuilder.add_quad_indices(
			cap_indices,
			bottom_a,
			bottom_b,
			top_a,
			top_b
		)

	_add_array_mesh(parent, wall_vertices, wall_indices, wall_material, "StadiumBackWall")
	_add_array_mesh(parent, cap_vertices, cap_indices, cap_material, "StadiumWallCap")


func _add_wall_direction_arrows(
	parent: Node3D,
	geometry: TrackGeometryData,
	arrow_material: Material,
	config: TrackGenerationConfig
) -> void:
	var barrier_distance_from_road: float = maxf(config.barrier_distance_from_road, 0.0)
	var stadium_distance_from_barrier: float = maxf(config.stadium_distance_from_barrier, 0.0)
	var arrow_vertices: PackedVector3Array = PackedVector3Array()
	var arrow_indices: PackedInt32Array = PackedInt32Array()

	for index: int in range(0, geometry.center_points.size(), 6):
		var current: Vector3 = geometry.center_points[index]
		var tangent: Vector3 = geometry.forward_vectors[index]
		var outward: Vector3 = _get_local_outward(geometry, index)
		var wall_offset: float = (
			geometry.half_widths[index]
			+ barrier_distance_from_road
			+ stadium_distance_from_barrier
			+ 19.0
		)
		var wall_position: Vector3 = (
			current + outward * wall_offset - outward * 0.08 + Vector3.UP * 5.2
		)
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
		TrackSurfaceMeshBuilder.add_quad_indices(
			arrow_indices,
			base_index,
			base_index + 1,
			base_index + 2,
			base_index + 3
		)
		arrow_indices.append(base_index + 4)
		arrow_indices.append(base_index + 5)
		arrow_indices.append(base_index + 6)

	_add_array_mesh(
		parent,
		arrow_vertices,
		arrow_indices,
		arrow_material,
		"WallDirectionArrows"
	)


func _add_box_batch(
	parent: Node3D,
	node_name: String,
	size: Vector3,
	material: Material,
	transforms: Array
) -> void:
	if transforms.is_empty():
		return
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for transform_index: int in range(transforms.size()):
		multimesh.set_instance_transform(
			transform_index,
			transforms[transform_index] as Transform3D
		)
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	parent.add_child(instance)
	instance.owner = parent.owner


func _add_array_mesh(
	parent: Node3D,
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	material: Material,
	node_name: String
) -> void:
	if vertices.is_empty() or indices.is_empty():
		return
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = TrackSurfaceMeshBuilder.create_array_mesh(vertices, indices)
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	mesh_instance.owner = parent.owner
