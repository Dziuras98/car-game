@tool
extends Node3D

@export var track_width: float = 14.0:
	set(value):
		track_width = value
		_rebuild_track()
@export var grass_size: Vector2 = Vector2(260.0, 190.0):
	set(value):
		grass_size = value
		_rebuild_track()
@export var shoulder_width: float = 10.0:
	set(value):
		shoulder_width = value
		_rebuild_track()
@export var barrier_distance_from_road: float = 12.0:
	set(value):
		barrier_distance_from_road = value
		_rebuild_track()
@export var width_variation: float = 0.28:
	set(value):
		width_variation = clampf(value, 0.0, 0.45)
		_rebuild_track()
@export var has_stadium: bool = false:
	set(value):
		has_stadium = value
		_rebuild_track()
@export_range(4, 18, 1) var stadium_section_step: int = 8:
	set(value):
		stadium_section_step = maxi(value, 4)
		_rebuild_track()
@export var stadium_distance_from_barrier: float = 24.0:
	set(value):
		stadium_distance_from_barrier = maxf(value, 8.0)
		_rebuild_track()

var _track_body: StaticBody3D
var _track_mesh: MeshInstance3D
var _track_collision: CollisionShape3D
var _grass_body: StaticBody3D
var _grass_mesh: MeshInstance3D
var _grass_collision: CollisionShape3D
var _shoulder_body: StaticBody3D
var _shoulder_mesh: MeshInstance3D
var _shoulder_collision: CollisionShape3D
var _edge_markers: Node3D
var _barriers: Node3D
var _stadium: Node3D
var _finish_line: Node3D


func _ready() -> void:
	_rebuild_track()


func _rebuild_track() -> void:
	if not is_inside_tree():
		return

	_clear_generated_children()
	_create_grass()
	_create_shoulders()
	_create_track()
	_create_finish_line()
	_create_edge_markers()
	_create_barriers()
	if has_stadium:
		_create_stadium()


func _clear_generated_children() -> void:
	for child in get_children():
		child.queue_free()


func _create_grass() -> void:
	var grass_material: StandardMaterial3D = StandardMaterial3D.new()
	grass_material.albedo_color = Color(0.11, 0.36, 0.16, 1.0)
	grass_material.roughness = 0.9

	var grass_mesh: BoxMesh = BoxMesh.new()
	grass_mesh.size = Vector3(grass_size.x, 0.4, grass_size.y)

	var grass_shape: BoxShape3D = BoxShape3D.new()
	grass_shape.size = Vector3(grass_size.x, 0.4, grass_size.y)

	_grass_body = StaticBody3D.new()
	_grass_body.name = "Grass"
	add_child(_grass_body)
	_grass_body.owner = owner
	_grass_body.position.y = -0.25

	_grass_collision = CollisionShape3D.new()
	_grass_collision.name = "CollisionShape3D"
	_grass_collision.shape = grass_shape
	_grass_body.add_child(_grass_collision)
	_grass_collision.owner = owner

	_grass_mesh = MeshInstance3D.new()
	_grass_mesh.name = "MeshInstance3D"
	_grass_mesh.mesh = grass_mesh
	_grass_mesh.material_override = grass_material
	_grass_body.add_child(_grass_mesh)
	_grass_mesh.owner = owner


func _create_shoulders() -> void:
	var points: Array[Vector3] = _get_track_points()
	var vertices: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()

	for index in points.size():
		var previous: Vector3 = points[(index - 1 + points.size()) % points.size()]
		var current: Vector3 = points[index]
		var next: Vector3 = points[(index + 1) % points.size()]
		var tangent: Vector3 = (next - previous).normalized()
		var side: Vector3 = Vector3(-tangent.z, 0.0, tangent.x).normalized()
		var half_width: float = _get_half_width(index, points.size())

		vertices.append(current - side * (half_width + shoulder_width))
		vertices.append(current - side * half_width)
		vertices.append(current + side * half_width)
		vertices.append(current + side * (half_width + shoulder_width))

	for index in points.size():
		var next_index: int = (index + 1) % points.size()
		var left_outer_a: int = index * 4
		var left_inner_a: int = left_outer_a + 1
		var right_inner_a: int = left_outer_a + 2
		var right_outer_a: int = left_outer_a + 3
		var left_outer_b: int = next_index * 4
		var left_inner_b: int = left_outer_b + 1
		var right_inner_b: int = left_outer_b + 2
		var right_outer_b: int = left_outer_b + 3

		_add_quad_indices(indices, left_outer_a, left_outer_b, left_inner_a, left_inner_b)
		_add_quad_indices(indices, right_inner_a, right_inner_b, right_outer_a, right_outer_b)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	var shoulder_mesh: ArrayMesh = ArrayMesh.new()
	shoulder_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var shoulder_material: StandardMaterial3D = StandardMaterial3D.new()
	shoulder_material.albedo_color = Color(0.12, 0.33, 0.13, 1.0)
	shoulder_material.roughness = 0.95

	_shoulder_body = StaticBody3D.new()
	_shoulder_body.name = "RoadsideTerrain"
	add_child(_shoulder_body)
	_shoulder_body.owner = owner

	_shoulder_collision = CollisionShape3D.new()
	_shoulder_collision.name = "CollisionShape3D"
	_shoulder_collision.shape = shoulder_mesh.create_trimesh_shape()
	_shoulder_body.add_child(_shoulder_collision)
	_shoulder_collision.owner = owner

	_shoulder_mesh = MeshInstance3D.new()
	_shoulder_mesh.name = "MeshInstance3D"
	_shoulder_mesh.mesh = shoulder_mesh
	_shoulder_mesh.material_override = shoulder_material
	_shoulder_body.add_child(_shoulder_mesh)
	_shoulder_mesh.owner = owner


func _create_track() -> void:
	var points: Array[Vector3] = _get_track_points()
	var vertices: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()

	for index in points.size():
		var previous: Vector3 = points[(index - 1 + points.size()) % points.size()]
		var current: Vector3 = points[index]
		var next: Vector3 = points[(index + 1) % points.size()]
		var tangent: Vector3 = (next - previous).normalized()
		var side: Vector3 = Vector3(-tangent.z, 0.0, tangent.x).normalized()
		var half_width: float = _get_half_width(index, points.size())

		vertices.append(current - side * half_width)
		vertices.append(current + side * half_width)

	for index in points.size():
		var next_index: int = (index + 1) % points.size()
		var left_a: int = index * 2
		var right_a: int = left_a + 1
		var left_b: int = next_index * 2
		var right_b: int = left_b + 1

		_add_quad_indices(indices, left_a, left_b, right_a, right_b)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	var asphalt_mesh: ArrayMesh = ArrayMesh.new()
	asphalt_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var asphalt_material: StandardMaterial3D = StandardMaterial3D.new()
	asphalt_material.albedo_color = Color(0.055, 0.06, 0.065, 1.0)
	asphalt_material.roughness = 0.92

	_track_body = StaticBody3D.new()
	_track_body.name = "TrackSurface"
	add_child(_track_body)
	_track_body.owner = owner

	_track_collision = CollisionShape3D.new()
	_track_collision.name = "CollisionShape3D"
	_track_collision.shape = asphalt_mesh.create_trimesh_shape()
	_track_body.add_child(_track_collision)
	_track_collision.owner = owner

	_track_mesh = MeshInstance3D.new()
	_track_mesh.name = "MeshInstance3D"
	_track_mesh.mesh = asphalt_mesh
	_track_mesh.material_override = asphalt_material
	_track_body.add_child(_track_mesh)
	_track_mesh.owner = owner


func _create_finish_line() -> void:
	var points: Array[Vector3] = _get_track_points()
	if points.size() < 2:
		return

	var current: Vector3 = points[0]
	var next: Vector3 = points[1]
	var tangent: Vector3 = (next - current).normalized()
	var side: Vector3 = Vector3(-tangent.z, 0.0, tangent.x).normalized()
	var yaw: float = atan2(tangent.x, tangent.z)
	var half_width: float = _get_half_width(0, points.size())

	_finish_line = Node3D.new()
	_finish_line.name = "FinishLine"
	add_child(_finish_line)
	_finish_line.owner = owner

	var stripe_material: StandardMaterial3D = StandardMaterial3D.new()
	stripe_material.albedo_color = Color(0.96, 0.96, 0.92, 1.0)
	stripe_material.roughness = 0.62

	var line_mesh: BoxMesh = BoxMesh.new()
	line_mesh.size = Vector3(half_width * 2.0, 0.04, 1.6)

	var line: MeshInstance3D = MeshInstance3D.new()
	line.name = "Stripe"
	line.mesh = line_mesh
	line.material_override = stripe_material
	line.position = current + Vector3.UP * 0.05
	line.rotation.y = yaw + PI * 0.5
	_finish_line.add_child(line)
	line.owner = owner

	var marker_material: StandardMaterial3D = StandardMaterial3D.new()
	marker_material.albedo_color = Color(1.0, 0.08, 0.06, 1.0)
	marker_material.emission_enabled = true
	marker_material.emission = Color(0.7, 0.02, 0.01, 1.0)
	marker_material.emission_energy_multiplier = 0.35

	_add_box_mesh(_finish_line, current - side * half_width + Vector3.UP * 1.8, Vector3(0.65, 3.4, 0.65), yaw, marker_material, "LeftMarker")
	_add_box_mesh(_finish_line, current + side * half_width + Vector3.UP * 1.8, Vector3(0.65, 3.4, 0.65), yaw, marker_material, "RightMarker")


func _create_edge_markers() -> void:
	var points: Array[Vector3] = _get_track_points()
	var marker_material: StandardMaterial3D = StandardMaterial3D.new()
	marker_material.albedo_color = Color(0.9, 0.9, 0.82, 1.0)
	marker_material.roughness = 0.7

	_edge_markers = Node3D.new()
	_edge_markers.name = "EdgeMarkers"
	add_child(_edge_markers)
	_edge_markers.owner = owner

	for index in range(0, points.size(), 3):
		var previous: Vector3 = points[(index - 1 + points.size()) % points.size()]
		var current: Vector3 = points[index]
		var next: Vector3 = points[(index + 1) % points.size()]
		var tangent: Vector3 = (next - previous).normalized()
		var side: Vector3 = Vector3(-tangent.z, 0.0, tangent.x).normalized()
		var half_width: float = _get_half_width(index, points.size())

		_add_edge_marker(current - side * (half_width + 0.45), marker_material)
		_add_edge_marker(current + side * (half_width + 0.45), marker_material)


func _create_barriers() -> void:
	var points: Array[Vector3] = _get_track_points()
	var barrier_material: StandardMaterial3D = StandardMaterial3D.new()
	barrier_material.albedo_color = Color(0.64, 0.68, 0.7, 1.0)
	barrier_material.metallic = 0.2
	barrier_material.roughness = 0.55

	_barriers = Node3D.new()
	_barriers.name = "Barriers"
	add_child(_barriers)
	_barriers.owner = owner

	for index in range(0, points.size(), 2):
		var previous: Vector3 = points[(index - 1 + points.size()) % points.size()]
		var current: Vector3 = points[index]
		var next: Vector3 = points[(index + 1) % points.size()]
		var tangent: Vector3 = (next - previous).normalized()
		var side: Vector3 = Vector3(-tangent.z, 0.0, tangent.x).normalized()
		var yaw: float = atan2(tangent.x, tangent.z)
		var barrier_offset: float = _get_half_width(index, points.size()) + barrier_distance_from_road

		_add_barrier_segment(current - side * barrier_offset, yaw, barrier_material)
		_add_barrier_segment(current + side * barrier_offset, yaw, barrier_material)


func _create_stadium() -> void:
	var points: Array[Vector3] = _get_track_points()
	var center: Vector3 = _get_points_center(points)

	var concrete_material: StandardMaterial3D = StandardMaterial3D.new()
	concrete_material.albedo_color = Color(0.42, 0.43, 0.42, 1.0)
	concrete_material.roughness = 0.78

	var seat_material: StandardMaterial3D = StandardMaterial3D.new()
	seat_material.albedo_color = Color(0.76, 0.08, 0.06, 1.0)
	seat_material.roughness = 0.55

	var roof_material: StandardMaterial3D = StandardMaterial3D.new()
	roof_material.albedo_color = Color(0.12, 0.12, 0.13, 1.0)
	roof_material.roughness = 0.5

	var back_wall_material: StandardMaterial3D = StandardMaterial3D.new()
	back_wall_material.albedo_color = Color(0.24, 0.25, 0.26, 1.0)
	back_wall_material.roughness = 0.82
	back_wall_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var wall_cap_material: StandardMaterial3D = StandardMaterial3D.new()
	wall_cap_material.albedo_color = Color(0.16, 0.17, 0.18, 1.0)
	wall_cap_material.roughness = 0.7
	wall_cap_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var wall_arrow_material: StandardMaterial3D = StandardMaterial3D.new()
	wall_arrow_material.albedo_color = Color(1.0, 0.88, 0.12, 1.0)
	wall_arrow_material.emission_enabled = true
	wall_arrow_material.emission = Color(1.0, 0.68, 0.08, 1.0)
	wall_arrow_material.emission_energy_multiplier = 0.35
	wall_arrow_material.roughness = 0.48
	wall_arrow_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var audience_materials: Array[StandardMaterial3D] = []
	for color: Color in [
		Color(0.1, 0.18, 0.9, 1.0),
		Color(0.95, 0.82, 0.08, 1.0),
		Color(0.92, 0.16, 0.12, 1.0),
		Color(0.92, 0.92, 0.9, 1.0),
		Color(0.08, 0.55, 0.18, 1.0),
	]:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 0.65
		audience_materials.append(material)

	_stadium = Node3D.new()
	_stadium.name = "Stadium"
	add_child(_stadium)
	_stadium.owner = owner

	_add_stadium_back_walls(points, center, back_wall_material, wall_cap_material)
	_add_wall_direction_arrows(points, center, wall_arrow_material)

	var section_index: int = 0
	for index in range(0, points.size(), stadium_section_step):
		var previous: Vector3 = points[(index - 1 + points.size()) % points.size()]
		var current: Vector3 = points[index]
		var next: Vector3 = points[(index + 1) % points.size()]
		var tangent: Vector3 = (next - previous).normalized()
		var outward: Vector3 = (current - center)
		outward.y = 0.0
		outward = outward.normalized()
		var yaw: float = atan2(tangent.x, tangent.z)
		var base_offset: float = _get_half_width(index, points.size()) + barrier_distance_from_road + stadium_distance_from_barrier
		var base_position: Vector3 = current + outward * base_offset

		_add_stadium_section(base_position, outward, yaw, section_index, concrete_material, seat_material, roof_material, audience_materials)
		section_index += 1

		if section_index % 5 == 0:
			_add_stadium_light(base_position + outward * 18.0, yaw)


func _add_stadium_back_walls(
	points: Array[Vector3],
	center: Vector3,
	wall_material: Material,
	cap_material: Material
) -> void:
	var wall_height: float = 13.0
	var cap_half_width: float = 0.85
	var wall_vertices: PackedVector3Array = PackedVector3Array()
	var wall_indices: PackedInt32Array = PackedInt32Array()
	var cap_vertices: PackedVector3Array = PackedVector3Array()
	var cap_indices: PackedInt32Array = PackedInt32Array()

	for index in points.size():
		var current: Vector3 = points[index]
		var outward: Vector3 = current - center
		outward.y = 0.0
		outward = outward.normalized()
		var wall_offset: float = _get_half_width(index, points.size()) + barrier_distance_from_road + stadium_distance_from_barrier + 19.0
		var wall_base_position: Vector3 = current + outward * wall_offset

		wall_vertices.append(wall_base_position)
		wall_vertices.append(wall_base_position + Vector3.UP * wall_height)
		cap_vertices.append(wall_base_position - outward * cap_half_width + Vector3.UP * wall_height)
		cap_vertices.append(wall_base_position + outward * cap_half_width + Vector3.UP * wall_height)

	for index in points.size():
		var next_index: int = (index + 1) % points.size()
		var bottom_a: int = index * 2
		var top_a: int = bottom_a + 1
		var bottom_b: int = next_index * 2
		var top_b: int = bottom_b + 1
		var cap_inner_a: int = index * 2
		var cap_outer_a: int = cap_inner_a + 1
		var cap_inner_b: int = next_index * 2
		var cap_outer_b: int = cap_inner_b + 1

		_add_quad_indices(wall_indices, bottom_a, bottom_b, top_a, top_b)
		_add_quad_indices(cap_indices, cap_inner_a, cap_inner_b, cap_outer_a, cap_outer_b)

	_add_array_mesh(_stadium, wall_vertices, wall_indices, wall_material, "StadiumBackWall")
	_add_array_mesh(_stadium, cap_vertices, cap_indices, cap_material, "StadiumWallCap")


func _add_wall_direction_arrows(points: Array[Vector3], center: Vector3, arrow_material: Material) -> void:
	var arrow_vertices: PackedVector3Array = PackedVector3Array()
	var arrow_indices: PackedInt32Array = PackedInt32Array()

	for index in range(0, points.size(), 6):
		var previous: Vector3 = points[(index - 1 + points.size()) % points.size()]
		var current: Vector3 = points[index]
		var next: Vector3 = points[(index + 1) % points.size()]
		var tangent: Vector3 = (next - previous).normalized()
		var outward: Vector3 = current - center
		outward.y = 0.0
		outward = outward.normalized()
		var wall_offset: float = _get_half_width(index, points.size()) + barrier_distance_from_road + stadium_distance_from_barrier + 19.0
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

		_add_quad_indices(arrow_indices, base_index, base_index + 1, base_index + 2, base_index + 3)
		arrow_indices.append(base_index + 4)
		arrow_indices.append(base_index + 5)
		arrow_indices.append(base_index + 6)

	_add_array_mesh(_stadium, arrow_vertices, arrow_indices, arrow_material, "WallDirectionArrows")


func _add_stadium_section(
	base_position: Vector3,
	outward: Vector3,
	yaw: float,
	section_index: int,
	concrete_material: Material,
	seat_material: Material,
	roof_material: Material,
	audience_materials: Array[StandardMaterial3D]
) -> void:
	for row in 4:
		var row_position: Vector3 = base_position + outward * float(row) * 4.2 + Vector3.UP * (0.25 + float(row) * 0.85)
		_add_box_mesh(
			_stadium,
			row_position,
			Vector3(4.0, 0.5, 10.5),
			yaw,
			concrete_material,
			"StandStep"
		)
		_add_box_mesh(
			_stadium,
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
				_stadium,
				spectator_position,
				Vector3(0.55, 0.75, 0.55),
				yaw,
				audience_materials[material_index],
				"Spectator"
			)

	var roof_position: Vector3 = base_position + outward * 6.6 + Vector3.UP * 4.4
	_add_box_mesh(_stadium, roof_position, Vector3(13.5, 0.35, 11.5), yaw, roof_material, "GrandstandRoof")


func _add_stadium_light(position: Vector3, yaw: float) -> void:
	var pole_material: StandardMaterial3D = StandardMaterial3D.new()
	pole_material.albedo_color = Color(0.18, 0.19, 0.2, 1.0)
	pole_material.metallic = 0.35
	pole_material.roughness = 0.45

	var light_material: StandardMaterial3D = StandardMaterial3D.new()
	light_material.albedo_color = Color(1.0, 0.92, 0.66, 1.0)
	light_material.emission_enabled = true
	light_material.emission = Color(1.0, 0.86, 0.45, 1.0)
	light_material.emission_energy_multiplier = 0.9

	_add_box_mesh(_stadium, position + Vector3.UP * 5.2, Vector3(0.45, 10.4, 0.45), yaw, pole_material, "LightPole")
	_add_box_mesh(_stadium, position + Vector3.UP * 10.4, Vector3(0.9, 0.8, 4.6), yaw, light_material, "Floodlights")


func _add_edge_marker(position: Vector3, material: Material) -> void:
	var marker_mesh: BoxMesh = BoxMesh.new()
	marker_mesh.size = Vector3(0.45, 0.2, 1.4)

	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.mesh = marker_mesh
	marker.material_override = material
	marker.position = position + Vector3.UP * 0.08
	_edge_markers.add_child(marker)
	marker.owner = owner


func _add_barrier_segment(position: Vector3, yaw: float, material: Material) -> void:
	var barrier_mesh: BoxMesh = BoxMesh.new()
	barrier_mesh.size = Vector3(0.35, 0.95, 4.2)

	var barrier: MeshInstance3D = MeshInstance3D.new()
	barrier.mesh = barrier_mesh
	barrier.material_override = material
	barrier.position = position + Vector3.UP * 0.45
	barrier.rotation.y = yaw
	_barriers.add_child(barrier)
	barrier.owner = owner


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
	mesh_instance.owner = owner


func _add_array_mesh(
	parent: Node3D,
	vertices: PackedVector3Array,
	indices: PackedInt32Array,
	material: Material,
	node_name: String
) -> void:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	mesh_instance.owner = owner


func _add_quad_indices(indices: PackedInt32Array, a: int, b: int, c: int, d: int) -> void:
	indices.append(a)
	indices.append(b)
	indices.append(c)
	indices.append(c)
	indices.append(b)
	indices.append(d)


func _get_track_points() -> Array[Vector3]:
	var control_points: Array[Vector3] = [
		Vector3(0.0, 0.0, 0.0),
		Vector3(0.0, 0.0, -90.0),
		Vector3(0.0, 0.0, -170.0),
		Vector3(18.0, 0.4, -230.0),
		Vector3(60.0, 1.2, -270.0),
		Vector3(105.0, 1.8, -282.0),
		Vector3(150.0, 1.2, -270.0),
		Vector3(192.0, 0.4, -230.0),
		Vector3(210.0, 0.0, -170.0),
		Vector3(210.0, 0.0, -90.0),
		Vector3(210.0, 0.0, 0.0),
		Vector3(210.0, 0.0, 90.0),
		Vector3(192.0, 0.4, 150.0),
		Vector3(150.0, 1.2, 190.0),
		Vector3(105.0, 1.8, 202.0),
		Vector3(60.0, 1.2, 190.0),
		Vector3(18.0, 0.4, 150.0),
		Vector3(0.0, 0.0, 90.0),
	]

	var sampled_points: Array[Vector3] = []
	for index in control_points.size():
		var p0: Vector3 = control_points[(index - 1 + control_points.size()) % control_points.size()]
		var p1: Vector3 = control_points[index]
		var p2: Vector3 = control_points[(index + 1) % control_points.size()]
		var p3: Vector3 = control_points[(index + 2) % control_points.size()]

		for step in 6:
			var t: float = float(step) / 6.0
			sampled_points.append(_catmull_rom(p0, p1, p2, p3, t))

	return sampled_points


func get_racing_line_points() -> Array[Vector3]:
	return _get_track_points()


func _get_points_center(points: Array[Vector3]) -> Vector3:
	var center: Vector3 = Vector3.ZERO
	for point: Vector3 in points:
		center += point
	return center / float(points.size())


func _get_half_width(index: int, point_count: int) -> float:
	var progress: float = float(index) / float(point_count)
	var turn_blend: float = maxf(
		clampf(1.0 - absf(progress - 0.29) / 0.16, 0.0, 1.0),
		clampf(1.0 - absf(progress - 0.79) / 0.16, 0.0, 1.0)
	)
	var width_scale: float = 1.0 + turn_blend * width_variation
	return track_width * clampf(width_scale, 0.7, 1.45) * 0.5


func _catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2: float = t * t
	var t3: float = t2 * t
	return 0.5 * (
		(2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)
