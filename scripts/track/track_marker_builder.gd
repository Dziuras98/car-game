extends RefCounted
class_name TrackMarkerBuilder

const EDGE_MARKER_SIZE: Vector3 = Vector3(0.45, 0.2, 1.4)


func build_markers(
	parent: Node3D,
	geometry: TrackGeometryData,
	material_factory: TrackMaterialFactory,
	_config: TrackGenerationConfig
) -> void:
	_create_finish_line(parent, geometry, material_factory)
	_create_edge_markers(parent, geometry, material_factory)


func _create_finish_line(
	parent: Node3D,
	geometry: TrackGeometryData,
	material_factory: TrackMaterialFactory
) -> void:
	if geometry.center_points.size() < 2:
		return

	var current: Vector3 = geometry.center_points[0]
	var tangent: Vector3 = (geometry.center_points[1] - current).normalized()
	var side: Vector3 = Vector3(-tangent.z, 0.0, tangent.x).normalized()
	var yaw: float = atan2(tangent.x, tangent.z)
	var half_width: float = geometry.half_widths[0]

	var finish_line: Node3D = Node3D.new()
	finish_line.name = "FinishLine"
	parent.add_child(finish_line)
	finish_line.owner = parent.owner

	var line_mesh: BoxMesh = BoxMesh.new()
	line_mesh.size = Vector3(half_width * 2.0, 0.04, 1.6)
	line_mesh.material = material_factory.create_finish_line_material()

	var line: MeshInstance3D = MeshInstance3D.new()
	line.name = "Stripe"
	line.mesh = line_mesh
	line.position = current + Vector3.UP * 0.05
	line.rotation.y = yaw + PI * 0.5
	finish_line.add_child(line)
	line.owner = parent.owner

	var marker_material: Material = material_factory.create_finish_marker_material()
	_add_box_mesh(finish_line, current - side * half_width + Vector3.UP * 1.8, Vector3(0.65, 3.4, 0.65), yaw, marker_material, "LeftMarker")
	_add_box_mesh(finish_line, current + side * half_width + Vector3.UP * 1.8, Vector3(0.65, 3.4, 0.65), yaw, marker_material, "RightMarker")


func _create_edge_markers(
	parent: Node3D,
	geometry: TrackGeometryData,
	material_factory: TrackMaterialFactory
) -> void:
	var transforms: Array[Transform3D] = []
	for index: int in range(0, geometry.center_points.size(), 3):
		var current: Vector3 = geometry.center_points[index]
		var side: Vector3 = geometry.right_vectors[index]
		var half_width: float = geometry.half_widths[index]
		transforms.append(Transform3D(Basis(), current - side * (half_width + 0.45) + Vector3.UP * 0.08))
		transforms.append(Transform3D(Basis(), current + side * (half_width + 0.45) + Vector3.UP * 0.08))
	if transforms.is_empty():
		return

	var marker_mesh: BoxMesh = BoxMesh.new()
	marker_mesh.size = EDGE_MARKER_SIZE
	marker_mesh.material = material_factory.create_marker_material()
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = marker_mesh
	multimesh.instance_count = transforms.size()
	for transform_index: int in range(transforms.size()):
		multimesh.set_instance_transform(transform_index, transforms[transform_index])

	var edge_markers: MultiMeshInstance3D = MultiMeshInstance3D.new()
	edge_markers.name = "EdgeMarkers"
	edge_markers.multimesh = multimesh
	parent.add_child(edge_markers)
	edge_markers.owner = parent.owner


func _add_box_mesh(parent: Node3D, position: Vector3, size: Vector3, yaw: float, material: Material, node_name: String) -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	mesh.material = material

	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.position = position
	mesh_instance.rotation.y = yaw
	parent.add_child(mesh_instance)
	mesh_instance.owner = parent.owner
