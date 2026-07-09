extends RefCounted
class_name TrackMarkerBuilder


func build_markers(
	parent: Node3D,
	geometry: TrackGeometryData,
	material_factory: TrackMaterialFactory,
	_config: Dictionary
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

	var line: MeshInstance3D = MeshInstance3D.new()
	line.name = "Stripe"
	line.mesh = line_mesh
	line.material_override = material_factory.create_finish_line_material()
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
	var edge_markers: Node3D = Node3D.new()
	edge_markers.name = "EdgeMarkers"
	parent.add_child(edge_markers)
	edge_markers.owner = parent.owner

	var marker_material: Material = material_factory.create_marker_material()
	for index in range(0, geometry.center_points.size(), 3):
		var current: Vector3 = geometry.center_points[index]
		var side: Vector3 = geometry.right_vectors[index]
		var half_width: float = geometry.half_widths[index]

		_add_edge_marker(edge_markers, current - side * (half_width + 0.45), marker_material)
		_add_edge_marker(edge_markers, current + side * (half_width + 0.45), marker_material)


func _add_edge_marker(parent: Node3D, position: Vector3, material: Material) -> void:
	var marker_mesh: BoxMesh = BoxMesh.new()
	marker_mesh.size = Vector3(0.45, 0.2, 1.4)

	var marker: MeshInstance3D = MeshInstance3D.new()
	marker.mesh = marker_mesh
	marker.material_override = material
	marker.position = position + Vector3.UP * 0.08
	parent.add_child(marker)
	marker.owner = parent.owner


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
