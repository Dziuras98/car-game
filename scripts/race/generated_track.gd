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


func _ready() -> void:
	_rebuild_track()


func _rebuild_track() -> void:
	if not is_inside_tree():
		return

	_clear_generated_children()
	_create_grass()
	_create_shoulders()
	_create_track()
	_create_edge_markers()
	_create_barriers()


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
