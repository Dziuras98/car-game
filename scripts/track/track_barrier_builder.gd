extends RefCounted
class_name TrackBarrierBuilder

const BARRIER_SIZE: Vector3 = Vector3(0.35, 0.95, 4.2)


func build_barriers(
	parent: Node3D,
	geometry: TrackGeometryData,
	material_factory: TrackMaterialFactory,
	config: Dictionary
) -> void:
	var barriers: StaticBody3D = StaticBody3D.new()
	barriers.name = "Barriers"
	parent.add_child(barriers)
	barriers.owner = parent.owner

	var transforms: Array[Transform3D] = _build_segment_transforms(
		geometry,
		float(config.get("barrier_distance_from_road", 12.0))
	)
	if transforms.is_empty():
		return

	var barrier_mesh: BoxMesh = BoxMesh.new()
	barrier_mesh.size = BARRIER_SIZE
	barrier_mesh.material = material_factory.create_barrier_material()
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = barrier_mesh
	multimesh.instance_count = transforms.size()

	var visual: MultiMeshInstance3D = MultiMeshInstance3D.new()
	visual.name = "BarrierVisuals"
	visual.multimesh = multimesh
	barriers.add_child(visual)
	visual.owner = parent.owner

	var barrier_shape: BoxShape3D = BoxShape3D.new()
	barrier_shape.size = BARRIER_SIZE
	for transform_index: int in range(transforms.size()):
		multimesh.set_instance_transform(transform_index, transforms[transform_index])
		var collision: CollisionShape3D = CollisionShape3D.new()
		collision.name = "BarrierCollision%03d" % transform_index
		collision.shape = barrier_shape
		collision.transform = transforms[transform_index]
		barriers.add_child(collision)
		collision.owner = parent.owner


func _build_segment_transforms(
	geometry: TrackGeometryData,
	barrier_distance_from_road: float
) -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	var safe_distance: float = maxf(barrier_distance_from_road, 0.0)
	for index: int in range(0, geometry.center_points.size(), 2):
		var current: Vector3 = geometry.center_points[index]
		var tangent: Vector3 = geometry.forward_vectors[index]
		var side: Vector3 = geometry.right_vectors[index]
		var yaw: float = atan2(tangent.x, tangent.z)
		var barrier_offset: float = geometry.half_widths[index] + safe_distance
		var basis: Basis = Basis(Vector3.UP, yaw)
		transforms.append(
			Transform3D(basis, current - side * barrier_offset + Vector3.UP * 0.45)
		)
		transforms.append(
			Transform3D(basis, current + side * barrier_offset + Vector3.UP * 0.45)
		)
	return transforms
