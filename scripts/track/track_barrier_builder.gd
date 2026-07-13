extends RefCounted
class_name TrackBarrierBuilder

const BARRIER_SIZE: Vector3 = Vector3(0.35, 0.95, 4.2)
const LEFT_BARRIER_EXCLUSION_META: StringName = &"left_barrier_exclusion_ranges"
const RIGHT_BARRIER_EXCLUSION_META: StringName = &"right_barrier_exclusion_ranges"


func build_barriers(
	parent: Node3D,
	geometry: TrackGeometryData,
	material_factory: TrackMaterialFactory,
	config: TrackGenerationConfig
) -> void:
	var barriers: StaticBody3D = StaticBody3D.new()
	barriers.name = "Barriers"
	parent.add_child(barriers)
	barriers.owner = parent.owner

	var transforms: Array[Transform3D] = _build_segment_transforms(geometry, config)
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
	config: TrackGenerationConfig
) -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	var point_count: int = geometry.center_points.size()
	var default_distance: float = config.barrier_distance_from_road if config != null else 12.0
	var layout: TrackLayoutResource = config.track_layout if config != null else null
	for index: int in range(0, point_count, 2):
		var current: Vector3 = geometry.center_points[index]
		var tangent: Vector3 = geometry.forward_vectors[index]
		var side: Vector3 = geometry.right_vectors[index]
		var yaw: float = atan2(tangent.x, tangent.z)
		var progress: float = float(index) / float(point_count)
		var local_distance: float = default_distance
		if layout != null:
			local_distance = layout.get_barrier_distance_at(progress)
		var barrier_offset: float = geometry.half_widths[index] + maxf(local_distance, 0.0)
		var basis: Basis = Basis(Vector3.UP, yaw)
		if not _is_progress_excluded(layout, LEFT_BARRIER_EXCLUSION_META, progress):
			transforms.append(
				Transform3D(basis, current - side * barrier_offset + Vector3.UP * 0.45)
			)
		if not _is_progress_excluded(layout, RIGHT_BARRIER_EXCLUSION_META, progress):
			transforms.append(
				Transform3D(basis, current + side * barrier_offset + Vector3.UP * 0.45)
			)
	return transforms


func _is_progress_excluded(
	layout: TrackLayoutResource,
	metadata_name: StringName,
	progress: float
) -> bool:
	if layout == null or not layout.has_meta(metadata_name):
		return false
	var raw_ranges: Variant = layout.get_meta(metadata_name)
	if typeof(raw_ranges) != TYPE_PACKED_VECTOR2_ARRAY:
		return false
	var ranges: PackedVector2Array = raw_ranges
	for progress_range: Vector2 in ranges:
		var minimum_progress: float = minf(progress_range.x, progress_range.y)
		var maximum_progress: float = maxf(progress_range.x, progress_range.y)
		if progress >= minimum_progress and progress <= maximum_progress:
			return true
	return false
