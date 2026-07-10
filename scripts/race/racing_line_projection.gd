extends RefCounted
class_name RacingLineProjection

var segment_index: int = -1
var progress_distance: float = 0.0
var distance_squared: float = INF
var used_global_search: bool = false
var segment_checks: int = 0


func is_valid() -> bool:
	return (
		segment_index >= 0
		and is_finite(progress_distance)
		and is_finite(distance_squared)
		and distance_squared >= 0.0
	)
