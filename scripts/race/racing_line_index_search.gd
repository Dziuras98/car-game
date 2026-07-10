extends RefCounted
class_name RacingLineIndexSearch

var search_points_behind: int = 4
var search_points_ahead: int = 14
var recovery_distance_squared: float = 45.0 * 45.0
var full_scan_interval_updates: int = 120

var _updates_since_full_scan: int = 0
var _last_distance_check_count: int = 0


func configure(
	points_behind: int,
	points_ahead: int,
	recovery_distance: float,
	full_scan_interval: int
) -> void:
	search_points_behind = maxi(points_behind, 0)
	search_points_ahead = maxi(points_ahead, 0)
	recovery_distance_squared = maxf(recovery_distance, 1.0) * maxf(recovery_distance, 1.0)
	full_scan_interval_updates = maxi(full_scan_interval, 1)
	reset()


func reset() -> void:
	_updates_since_full_scan = 0
	_last_distance_check_count = 0


func find_nearest_index(
	points: Array[Vector3],
	position: Vector3,
	previous_index: int
) -> int:
	_last_distance_check_count = 0
	if points.is_empty():
		return 0

	var point_count: int = points.size()
	if previous_index < 0 or previous_index >= point_count:
		return _full_scan(points, position)

	_updates_since_full_scan += 1
	var window_size: int = mini(
		point_count,
		search_points_behind + search_points_ahead + 1
	)
	var window_start: int = (
		previous_index - mini(search_points_behind, point_count - 1) + point_count
	) % point_count
	var closest_index: int = previous_index
	var closest_distance_squared: float = INF

	for offset: int in range(window_size):
		var point_index: int = (window_start + offset) % point_count
		var distance_squared: float = position.distance_squared_to(points[point_index])
		_last_distance_check_count += 1
		if distance_squared < closest_distance_squared:
			closest_distance_squared = distance_squared
			closest_index = point_index

	if (
		closest_distance_squared > recovery_distance_squared
		or _updates_since_full_scan >= full_scan_interval_updates
	):
		return _full_scan(points, position)

	return closest_index


func get_last_distance_check_count() -> int:
	return _last_distance_check_count


func _full_scan(points: Array[Vector3], position: Vector3) -> int:
	var closest_index: int = 0
	var closest_distance_squared: float = INF
	for point_index: int in range(points.size()):
		var distance_squared: float = position.distance_squared_to(points[point_index])
		_last_distance_check_count += 1
		if distance_squared < closest_distance_squared:
			closest_distance_squared = distance_squared
			closest_index = point_index

	_updates_since_full_scan = 0
	return closest_index
