extends RefCounted
class_name RacingLineProjector

const MIN_SEGMENT_LENGTH_SQUARED: float = 0.000001
const MIN_LOCAL_SEARCH_RADIUS: int = 2
const MAX_LOCAL_SEARCH_RADIUS: int = 16
const MIN_REACQUIRE_DISTANCE: float = 8.0
const MIN_TELEPORT_DISTANCE: float = 12.0

var _points: Array[Vector3] = []
var _cumulative_distances: PackedFloat32Array = PackedFloat32Array()
var _track_length: float = 0.0
var _average_segment_length: float = 1.0


func configure(
	points: Array[Vector3],
	cumulative_distances: PackedFloat32Array,
	track_length: float
) -> void:
	_points.clear()
	_points.append_array(points)
	_cumulative_distances = cumulative_distances.duplicate()
	_track_length = maxf(track_length, 0.0)
	_average_segment_length = (
		_track_length / float(_points.size())
		if not _points.is_empty() and _track_length > 0.0
		else 1.0
	)


func clear() -> void:
	_points.clear()
	_cumulative_distances.clear()
	_track_length = 0.0
	_average_segment_length = 1.0


func is_configured() -> bool:
	return (
		_points.size() >= 2
		and _cumulative_distances.size() == _points.size()
		and _track_length > 0.0
	)


func project(
	position: Vector3,
	previous_segment_index: int = -1,
	previous_position: Vector3 = Vector3.ZERO,
	has_previous_projection: bool = false
) -> RacingLineProjection:
	if not is_configured():
		return null
	if (
		not has_previous_projection
		or previous_segment_index < 0
		or previous_segment_index >= _points.size()
	):
		return _search_all_segments(position)

	var displacement: float = position.distance_to(previous_position)
	var teleport_distance: float = maxf(
		MIN_TELEPORT_DISTANCE,
		_average_segment_length * float(MAX_LOCAL_SEARCH_RADIUS)
	)
	if displacement > teleport_distance:
		return _search_all_segments(position)

	var local_radius: int = clampi(
		ceili(displacement / maxf(_average_segment_length, 0.1)) + MIN_LOCAL_SEARCH_RADIUS,
		MIN_LOCAL_SEARCH_RADIUS,
		MAX_LOCAL_SEARCH_RADIUS
	)
	if local_radius * 2 + 1 >= _points.size():
		return _search_all_segments(position)

	var local_projection: RacingLineProjection = _search_local_segments(
		position,
		previous_segment_index,
		local_radius
	)
	if local_projection == null:
		return _search_all_segments(position)

	var reacquire_distance: float = maxf(
		MIN_REACQUIRE_DISTANCE,
		displacement * 2.0 + _average_segment_length * 2.0
	)
	if local_projection.distance_squared > reacquire_distance * reacquire_distance:
		return _search_all_segments(position)
	return local_projection


func _search_all_segments(position: Vector3) -> RacingLineProjection:
	var result: RacingLineProjection = RacingLineProjection.new()
	result.used_global_search = true
	for segment_index: int in range(_points.size()):
		_consider_segment(result, position, segment_index)
	return result if result.is_valid() else null


func _search_local_segments(
	position: Vector3,
	center_segment_index: int,
	radius: int
) -> RacingLineProjection:
	var result: RacingLineProjection = RacingLineProjection.new()
	var visited_indices: Dictionary = {}
	for offset: int in range(-radius, radius + 1):
		var segment_index: int = posmod(center_segment_index + offset, _points.size())
		if visited_indices.has(segment_index):
			continue
		visited_indices[segment_index] = true
		_consider_segment(result, position, segment_index)
	return result if result.is_valid() else null


func _consider_segment(
	result: RacingLineProjection,
	position: Vector3,
	segment_index: int
) -> void:
	result.segment_checks += 1
	var next_index: int = (segment_index + 1) % _points.size()
	var segment_start: Vector3 = _points[segment_index]
	var segment_vector: Vector3 = _points[next_index] - segment_start
	var segment_length_squared: float = segment_vector.length_squared()
	if segment_length_squared <= MIN_SEGMENT_LENGTH_SQUARED:
		return

	var interpolation: float = clampf(
		(position - segment_start).dot(segment_vector) / segment_length_squared,
		0.0,
		1.0
	)
	var projected_position: Vector3 = segment_start + segment_vector * interpolation
	var distance_squared: float = position.distance_squared_to(projected_position)
	if distance_squared >= result.distance_squared:
		return

	result.segment_index = segment_index
	result.distance_squared = distance_squared
	result.progress_distance = clampf(
		_cumulative_distances[segment_index]
		+ sqrt(segment_length_squared) * interpolation,
		0.0,
		_track_length
	)
