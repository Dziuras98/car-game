extends RefCounted
class_name TrackBarrierBuilder

const BARRIER_SIZE: Vector3 = Vector3(0.35, 0.95, 4.2)


func build_barriers(
	parent: Node3D,
	geometry: TrackGeometryData,
	material_factory: TrackMaterialFactory,
	config: Dictionary
) -> void:
	var barrier_distance_from_road: float = float(config.get("barrier_distance_from_road", 12.0))
	var barrier_material: Material = material_factory.create_barrier_material()
	var barriers: StaticBody3D = StaticBody3D.new()
	barriers.name = "Barriers"
	parent.add_child(barriers)
	barriers.owner = parent.owner

	var barrier_mesh: BoxMesh = BoxMesh.new()
	barrier_mesh.size = BARRIER_SIZE
	var barrier_shape: BoxShape3D = BoxShape3D.new()
	barrier_shape.size = BARRIER_SIZE

	for index: int in range(0, geometry.center_points.size(), 2):
		var current: Vector3 = geometry.center_points[index]
		var tangent: Vector3 = geometry.forward_vectors[index]
		var side: Vector3 = geometry.right_vectors[index]
		var yaw: float = atan2(tangent.x, tangent.z)
		var barrier_offset: float = geometry.half_widths[index] + barrier_distance_from_road

		_add_barrier_segment(barriers, current - side * barrier_offset, yaw, barrier_material, barrier_mesh, barrier_shape)
		_add_barrier_segment(barriers, current + side * barrier_offset, yaw, barrier_material, barrier_mesh, barrier_shape)


func _add_barrier_segment(
	parent: StaticBody3D,
	position: Vector3,
	yaw: float,
	material: Material,
	shared_mesh: BoxMesh,
	shared_shape: BoxShape3D
) -> void:
	var segment_transform: Transform3D = Transform3D(Basis(Vector3.UP, yaw), position + Vector3.UP * 0.45)

	var barrier: MeshInstance3D = MeshInstance3D.new()
	barrier.name = "BarrierVisual"
	barrier.mesh = shared_mesh
	barrier.material_override = material
	barrier.transform = segment_transform
	parent.add_child(barrier)
	barrier.owner = parent.owner

	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "BarrierCollision"
	collision.shape = shared_shape
	collision.transform = segment_transform
	parent.add_child(collision)
	collision.owner = parent.owner
