extends RefCounted
class_name TrackBarrierBuilder


func build_barriers(
	parent: Node3D,
	geometry: TrackGeometryData,
	material_factory: TrackMaterialFactory,
	config: Dictionary
) -> void:
	var barrier_distance_from_road: float = float(config.get("barrier_distance_from_road", 12.0))
	var barrier_material: Material = material_factory.create_barrier_material()
	var barriers: Node3D = Node3D.new()
	barriers.name = "Barriers"
	parent.add_child(barriers)
	barriers.owner = parent.owner

	for index in range(0, geometry.center_points.size(), 2):
		var current: Vector3 = geometry.center_points[index]
		var tangent: Vector3 = geometry.forward_vectors[index]
		var side: Vector3 = geometry.right_vectors[index]
		var yaw: float = atan2(tangent.x, tangent.z)
		var barrier_offset: float = geometry.half_widths[index] + barrier_distance_from_road

		_add_barrier_segment(barriers, current - side * barrier_offset, yaw, barrier_material)
		_add_barrier_segment(barriers, current + side * barrier_offset, yaw, barrier_material)


func _add_barrier_segment(parent: Node3D, position: Vector3, yaw: float, material: Material) -> void:
	var barrier_mesh: BoxMesh = BoxMesh.new()
	barrier_mesh.size = Vector3(0.35, 0.95, 4.2)

	var barrier: MeshInstance3D = MeshInstance3D.new()
	barrier.mesh = barrier_mesh
	barrier.material_override = material
	barrier.position = position + Vector3.UP * 0.45
	barrier.rotation.y = yaw
	parent.add_child(barrier)
	barrier.owner = parent.owner
