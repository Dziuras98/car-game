extends Node
class_name TorPoznanBarrierConfiguration

const RIGHT_BARRIER_EXCLUSION_META: StringName = &"right_barrier_exclusion_ranges"
const PIT_LANE_EXCLUSION_RANGES: PackedVector2Array = PackedVector2Array([
	Vector2(0.0, 0.065),
	Vector2(0.945, 1.0),
])


func _enter_tree() -> void:
	var track: GeneratedTrack = get_parent() as GeneratedTrack
	if track == null or track.track_layout == null:
		return
	track.track_layout.set_meta(
		RIGHT_BARRIER_EXCLUSION_META,
		PIT_LANE_EXCLUSION_RANGES
	)
