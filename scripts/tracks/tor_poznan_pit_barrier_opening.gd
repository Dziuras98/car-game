extends Node
class_name TorPoznanPitBarrierOpening

const GAP_MIN_X: float = 5.0
const GAP_MAX_X: float = 50.0
const GAP_MIN_Z: float = -245.0
const GAP_MAX_Z: float = 35.0

var removed_segment_count: int = 0


func _ready() -> void:
	_rebuild_barrier_without_pit_segments.call_deferred()


func _rebuild_barrier_without_pit_segments() -> void:
	removed_segment_count = 0
	var track: GeneratedTrack = get_parent() as GeneratedTrack
	if track == null or not track.has_committed_generation():
		return
	var barrier_root: Node = track.get_node_or_null("GeneratedContent/Barriers")
	if barrier_root == null:
		return
	var visual: MultiMeshInstance3D = barrier_root.get_node_or_null("BarrierVisuals") as MultiMeshInstance3D
	if visual == null or visual.multimesh == null:
		return

	var source: MultiMesh = visual.multimesh
	var retained_transforms: Array[Transform3D] = []
	for instance_index: int in range(source.instance_count):
		var transform: Transform3D = source.get_instance_transform(instance_index)
		if _belongs_to_pit_opening(transform.origin):
			removed_segment_count += 1
			var collision: CollisionShape3D = barrier_root.get_node_or_null(
				"BarrierCollision%03d" % instance_index
			) as CollisionShape3D
			if collision != null:
				collision.disabled = true
			continue
		retained_transforms.append(transform)

	if removed_segment_count == 0:
		return
	var replacement: MultiMesh = MultiMesh.new()
	replacement.transform_format = source.transform_format
	replacement.mesh = source.mesh
	replacement.use_colors = source.use_colors
	replacement.use_custom_data = source.use_custom_data
	replacement.instance_count = retained_transforms.size()
	for retained_index: int in range(retained_transforms.size()):
		replacement.set_instance_transform(retained_index, retained_transforms[retained_index])
	visual.multimesh = replacement


func has_opening() -> bool:
	return removed_segment_count > 0


func _belongs_to_pit_opening(position: Vector3) -> bool:
	return (
		position.x > GAP_MIN_X
		and position.x < GAP_MAX_X
		and position.z > GAP_MIN_Z
		and position.z < GAP_MAX_Z
	)
