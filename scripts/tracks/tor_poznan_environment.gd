extends Node3D
class_name TorPoznanEnvironment

const PIT_LANE_WIDTH: float = 6.0
const PIT_LANE_GRIP: float = 0.96
const CURB_WIDTH: float = 0.72
const CURB_HEIGHT: float = 0.08
const MIN_CURB_TURN_ANGLE: float = 0.022
const BARRIER_HIDE_Y: float = -1000.0

var _asphalt_material: StandardMaterial3D
var _concrete_material: StandardMaterial3D
var _building_material: StandardMaterial3D
var _roof_material: StandardMaterial3D
var _metal_material: StandardMaterial3D
var _glass_material: StandardMaterial3D
var _curb_red_material: StandardMaterial3D
var _curb_white_material: StandardMaterial3D
var _trunk_material: StandardMaterial3D
var _foliage_material: StandardMaterial3D


func _ready() -> void:
	_build_environment.call_deferred()


func _build_environment() -> void:
	if get_node_or_null("PitComplex") != null:
		return
	_create_materials()
	_create_pit_complex()
	_create_start_gantry()
	_create_grandstands()
	_create_trackside_forest()
	var track: GeneratedTrack = get_parent() as GeneratedTrack
	if track == null or not track.has_committed_generation():
		return
	_open_pit_lane_barrier(track)
	_create_corner_curbs(track)


func _create_materials() -> void:
	_asphalt_material = _make_material(Color(0.105, 0.11, 0.115), 0.96)
	_concrete_material = _make_material(Color(0.45, 0.46, 0.44), 0.92)
	_building_material = _make_material(Color(0.72, 0.73, 0.70), 0.88)
	_roof_material = _make_material(Color(0.17, 0.19, 0.20), 0.78)
	_metal_material = _make_material(Color(0.38, 0.40, 0.42), 0.60)
	_glass_material = _make_material(Color(0.12, 0.23, 0.29, 0.82), 0.16)
	_glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_curb_red_material = _make_material(Color(0.70, 0.035, 0.035), 0.82)
	_curb_white_material = _make_material(Color(0.90, 0.90, 0.86), 0.86)
	_trunk_material = _make_material(Color(0.19, 0.105, 0.045), 1.0)
	_foliage_material = _make_material(Color(0.055, 0.20, 0.055), 1.0)


func _create_pit_complex() -> void:
	var pit_complex: Node3D = Node3D.new()
	pit_complex.name = "PitComplex"
	add_child(pit_complex)

	_add_surface_segment(
		pit_complex,
		"PitEntry",
		Vector3(6.0, 0.03, -225.0),
		Vector3(16.0, 0.03, -194.0),
		PIT_LANE_WIDTH,
		_asphalt_material,
		PIT_LANE_GRIP
	)
	_add_surface_box(
		pit_complex,
		"PitLane",
		Vector3(16.0, 0.03, -108.0),
		Vector3(PIT_LANE_WIDTH, 0.12, 172.0),
		0.0,
		_asphalt_material,
		PIT_LANE_GRIP
	)
	_add_surface_segment(
		pit_complex,
		"PitExit",
		Vector3(16.0, 0.03, -22.0),
		Vector3(6.0, 0.03, 8.0),
		PIT_LANE_WIDTH,
		_asphalt_material,
		PIT_LANE_GRIP
	)
	_add_surface_box(
		pit_complex,
		"Paddock",
		Vector3(61.0, -0.01, -108.0),
		Vector3(72.0, 0.10, 190.0),
		0.0,
		_concrete_material,
		0.84
	)

	_add_static_box(
		pit_complex,
		"PitBuilding",
		Vector3(32.0, 4.0, -108.0),
		Vector3(18.0, 8.0, 150.0),
		_building_material,
		true
	)
	_add_visual_box(
		pit_complex,
		"PitBuildingRoof",
		Vector3(32.0, 8.35, -108.0),
		Vector3(20.0, 0.7, 154.0),
		_roof_material
	)
	for garage_index: int in range(12):
		var garage_z: float = -174.0 + float(garage_index) * 12.0
		_add_visual_box(
			pit_complex,
			"GarageDoor%02d" % garage_index,
			Vector3(22.9, 2.6, garage_z),
			Vector3(0.22, 4.6, 9.0),
			_metal_material
		)

	_add_static_box(
		pit_complex,
		"ControlTower",
		Vector3(31.0, 8.0, -13.0),
		Vector3(15.0, 16.0, 18.0),
		_building_material,
		true
	)
	_add_visual_box(
		pit_complex,
		"ControlTowerGlass",
		Vector3(22.9, 10.3, -13.0),
		Vector3(0.25, 4.2, 13.0),
		_glass_material
	)
	_add_visual_box(
		pit_complex,
		"ControlTowerRoof",
		Vector3(31.0, 16.4, -13.0),
		Vector3(17.0, 0.8, 20.0),
		_roof_material
	)

	_add_static_box(
		pit_complex,
		"PitWall",
		Vector3(9.4, 0.55, -107.0),
		Vector3(0.42, 1.1, 145.0),
		_concrete_material,
		true
	)


func _create_start_gantry() -> void:
	var gantry: Node3D = Node3D.new()
	gantry.name = "StartGantry"
	add_child(gantry)
	_add_static_box(
		gantry,
		"LeftPost",
		Vector3(-8.4, 4.0, -4.0),
		Vector3(0.7, 8.0, 0.7),
		_metal_material,
		true
	)
	_add_static_box(
		gantry,
		"RightPost",
		Vector3(8.4, 4.0, -4.0),
		Vector3(0.7, 8.0, 0.7),
		_metal_material,
		true
	)
	_add_visual_box(
		gantry,
		"Crossbeam",
		Vector3(0.0, 7.6, -4.0),
		Vector3(17.5, 0.75, 0.85),
		_metal_material
	)
	for light_index: int in range(5):
		var light_material: StandardMaterial3D = _make_material(
			Color(0.70, 0.04, 0.025) if light_index < 4 else Color(0.04, 0.55, 0.10),
			0.4
		)
		_add_visual_box(
			gantry,
			"StartLight%d" % light_index,
			Vector3(-4.0 + float(light_index) * 2.0, 7.05, -3.5),
			Vector3(0.75, 0.75, 0.25),
			light_material
		)


func _create_grandstands() -> void:
	var grandstands: Node3D = Node3D.new()
	grandstands.name = "Grandstands"
	add_child(grandstands)
	_create_grandstand(grandstands, "MainGrandstand", Vector3(-39.0, 0.0, -92.0), 0.0, 68.0)
	_create_grandstand(grandstands, "FirstCornerStand", Vector3(151.0, 0.0, 183.0), -0.45, 42.0)


func _create_grandstand(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	yaw: float,
	length: float
) -> void:
	var stand: Node3D = Node3D.new()
	stand.name = node_name
	stand.position = position
	stand.rotation.y = yaw
	parent.add_child(stand)
	for row_index: int in range(6):
		_add_visual_box(
			stand,
			"Row%d" % row_index,
			Vector3(0.0, 0.45 + float(row_index) * 0.72, float(row_index) * 1.2),
			Vector3(length, 0.55, 1.35),
			_concrete_material
		)
	_add_visual_box(
		stand,
		"Roof",
		Vector3(0.0, 6.2, 4.0),
		Vector3(length + 3.0, 0.45, 9.5),
		_roof_material
	)


func _create_trackside_forest() -> void:
	var forest: Node3D = Node3D.new()
	forest.name = "TracksideForest"
	add_child(forest)
	var positions: Array[Vector3] = []
	for z_value: int in range(-520, 451, 42):
		positions.append(Vector3(-82.0, 0.0, float(z_value)))
		positions.append(Vector3(704.0, 0.0, float(z_value + 17)))
	for x_value: int in range(-45, 681, 42):
		positions.append(Vector3(float(x_value), 0.0, 452.0))
	for x_value: int in range(80, 661, 48):
		positions.append(Vector3(float(x_value), 0.0, -545.0))
	_create_tree_multimeshes(forest, positions)


func _create_tree_multimeshes(parent: Node3D, positions: Array[Vector3]) -> void:
	var trunk_mesh: CylinderMesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.34
	trunk_mesh.bottom_radius = 0.48
	trunk_mesh.height = 4.8
	trunk_mesh.material = _trunk_material
	var crown_mesh: SphereMesh = SphereMesh.new()
	crown_mesh.radius = 2.7
	crown_mesh.height = 5.2
	crown_mesh.radial_segments = 8
	crown_mesh.rings = 5
	crown_mesh.material = _foliage_material

	var trunk_multimesh: MultiMesh = MultiMesh.new()
	trunk_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	trunk_multimesh.mesh = trunk_mesh
	trunk_multimesh.instance_count = positions.size()
	var crown_multimesh: MultiMesh = MultiMesh.new()
	crown_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	crown_multimesh.mesh = crown_mesh
	crown_multimesh.instance_count = positions.size()

	for tree_index: int in range(positions.size()):
		var position: Vector3 = positions[tree_index]
		var scale_value: float = 0.82 + float((tree_index * 37) % 31) / 100.0
		var trunk_basis: Basis = Basis.from_scale(Vector3(scale_value, scale_value, scale_value))
		var crown_basis: Basis = Basis.from_scale(Vector3(scale_value, scale_value, scale_value))
		trunk_multimesh.set_instance_transform(
			tree_index,
			Transform3D(trunk_basis, position + Vector3.UP * 2.4 * scale_value)
		)
		crown_multimesh.set_instance_transform(
			tree_index,
			Transform3D(crown_basis, position + Vector3.UP * 6.0 * scale_value)
		)

	var trunks: MultiMeshInstance3D = MultiMeshInstance3D.new()
	trunks.name = "TreeTrunks"
	trunks.multimesh = trunk_multimesh
	parent.add_child(trunks)
	var crowns: MultiMeshInstance3D = MultiMeshInstance3D.new()
	crowns.name = "TreeCrowns"
	crowns.multimesh = crown_multimesh
	parent.add_child(crowns)


func _open_pit_lane_barrier(track: GeneratedTrack) -> void:
	var barrier_root: Node = track.get_node_or_null("GeneratedContent/Barriers")
	if barrier_root == null:
		return
	var visual: MultiMeshInstance3D = barrier_root.get_node_or_null("BarrierVisuals") as MultiMeshInstance3D
	if visual == null or visual.multimesh == null:
		return
	for instance_index: int in range(visual.multimesh.instance_count):
		var transform: Transform3D = visual.multimesh.get_instance_transform(instance_index)
		if (
			transform.origin.x > 5.0
			and transform.origin.x < 50.0
			and transform.origin.z > -245.0
			and transform.origin.z < 35.0
		):
			transform.origin.y = BARRIER_HIDE_Y
			visual.multimesh.set_instance_transform(instance_index, transform)
			var collision: CollisionShape3D = barrier_root.get_node_or_null(
				"BarrierCollision%03d" % instance_index
			) as CollisionShape3D
			if collision != null:
				collision.disabled = true


func _create_corner_curbs(track: GeneratedTrack) -> void:
	var geometry: TrackGeometryData = track._geometry
	if geometry == null or geometry.center_points.size() < 3:
		return
	var red_transforms: Array[Transform3D] = []
	var white_transforms: Array[Transform3D] = []
	var point_count: int = geometry.center_points.size()
	for point_index: int in range(point_count):
		var previous_index: int = (point_index - 1 + point_count) % point_count
		var next_index: int = (point_index + 1) % point_count
		var previous_forward: Vector3 = geometry.forward_vectors[previous_index].normalized()
		var current_forward: Vector3 = geometry.forward_vectors[point_index].normalized()
		var turn_angle: float = acos(clampf(previous_forward.dot(current_forward), -1.0, 1.0))
		if turn_angle < MIN_CURB_TURN_ANGLE:
			continue
		var signed_turn: float = previous_forward.cross(current_forward).y
		if is_zero_approx(signed_turn):
			continue
		var inside_sign: float = 1.0 if signed_turn > 0.0 else -1.0
		var side: Vector3 = geometry.right_vectors[point_index].normalized()
		var tangent: Vector3 = geometry.forward_vectors[point_index].normalized()
		var half_width: float = geometry.half_widths[point_index]
		var curb_position: Vector3 = (
			geometry.center_points[point_index]
			+ side * inside_sign * (half_width - CURB_WIDTH * 0.5)
			+ Vector3.UP * (CURB_HEIGHT * 0.55)
		)
		var segment_length: float = clampf(
			geometry.center_points[point_index].distance_to(geometry.center_points[next_index]) + 0.12,
			1.0,
			14.0
		)
		var yaw: float = atan2(tangent.x, tangent.z)
		var basis: Basis = Basis(Vector3.UP, yaw).scaled(Vector3(1.0, 1.0, segment_length))
		var curb_transform: Transform3D = Transform3D(basis, curb_position)
		if point_index % 2 == 0:
			red_transforms.append(curb_transform)
		else:
			white_transforms.append(curb_transform)

	var curbs: Node3D = Node3D.new()
	curbs.name = "CornerCurbs"
	add_child(curbs)
	_create_curb_multimesh(curbs, "RedCurbs", red_transforms, _curb_red_material)
	_create_curb_multimesh(curbs, "WhiteCurbs", white_transforms, _curb_white_material)


func _create_curb_multimesh(
	parent: Node3D,
	node_name: String,
	transforms: Array[Transform3D],
	material: Material
) -> void:
	if transforms.is_empty():
		return
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(CURB_WIDTH, CURB_HEIGHT, 1.0)
	mesh.material = material
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for transform_index: int in range(transforms.size()):
		multimesh.set_instance_transform(transform_index, transforms[transform_index])
	var instance: MultiMeshInstance3D = MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	parent.add_child(instance)


func _add_surface_segment(
	parent: Node3D,
	node_name: String,
	start: Vector3,
	finish: Vector3,
	width: float,
	material: Material,
	grip: float
) -> void:
	var direction: Vector3 = finish - start
	var midpoint: Vector3 = (start + finish) * 0.5
	var yaw: float = atan2(direction.x, direction.z)
	_add_surface_box(
		parent,
		node_name,
		midpoint,
		Vector3(width, 0.12, direction.length()),
		yaw,
		material,
		grip
	)


func _add_surface_box(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	size: Vector3,
	yaw: float,
	material: Material,
	grip: float
) -> void:
	var body: TrackSurfaceBody = TrackSurfaceBody.new()
	body.name = node_name
	body.position = position
	body.rotation.y = yaw
	body.grip_multiplier = grip
	parent.add_child(body)
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.name = "Mesh"
	visual.mesh = mesh
	body.add_child(visual)
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	body.add_child(collision)


func _add_static_box(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	size: Vector3,
	material: Material,
	with_collision: bool
) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.position = position
	parent.add_child(body)
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.name = "Mesh"
	visual.mesh = mesh
	body.add_child(visual)
	if with_collision:
		var shape: BoxShape3D = BoxShape3D.new()
		shape.size = size
		var collision: CollisionShape3D = CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		collision.shape = shape
		body.add_child(collision)


func _add_visual_box(
	parent: Node3D,
	node_name: String,
	position: Vector3,
	size: Vector3,
	material: Material
) -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.name = node_name
	visual.position = position
	visual.mesh = mesh
	parent.add_child(visual)


func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
