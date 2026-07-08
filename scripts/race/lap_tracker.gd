extends RefCounted
class_name LapTracker

signal participant_finished(car: PlayerCarController)

var lap_count: int = 3

var _track: Node3D
var _race_points: Array[Vector3] = []
var _participants: Array[PlayerCarController] = []
var _participant_laps: Array[int] = []
var _participant_progress: Array[int] = []
var _participant_finished: Array[bool] = []
var _participant_lap_armed: Array[bool] = []
var _finish_order: Array[PlayerCarController] = []


func prepare(
	track: Node3D,
	target_lap_count: int,
	player_car: PlayerCarController,
	opponents: Array[PlayerCarController]
) -> void:
	clear()
	_track = track
	lap_count = maxi(target_lap_count, 1)
	_refresh_race_points()

	if player_car != null:
		_register_participant(player_car)

	for opponent: PlayerCarController in opponents:
		_register_participant(opponent)


func clear() -> void:
	_race_points.clear()
	_participants.clear()
	_participant_laps.clear()
	_participant_progress.clear()
	_participant_finished.clear()
	_participant_lap_armed.clear()
	_finish_order.clear()


func update_positions() -> void:
	if _race_points.is_empty():
		_refresh_race_points()
		if _race_points.is_empty():
			return

	for participant_index: int in _participants.size():
		var car: PlayerCarController = _participants[participant_index]
		if not is_instance_valid(car) or _participant_finished[participant_index]:
			continue

		var previous_index: int = _participant_progress[participant_index]
		var current_index: int = _get_nearest_race_point_index(car.global_position)
		_participant_progress[participant_index] = current_index

		if _is_lap_arming_progress(current_index):
			_participant_lap_armed[participant_index] = true

		if _participant_lap_armed[participant_index] and _crossed_finish_line(previous_index, current_index):
			_participant_lap_armed[participant_index] = false
			_participant_laps[participant_index] += 1
			if _participant_laps[participant_index] >= lap_count:
				_mark_participant_finished(participant_index)


func get_completed_laps(car: PlayerCarController) -> int:
	var participant_index: int = _participants.find(car)
	if participant_index < 0:
		return 0

	return _participant_laps[participant_index]


func get_current_lap(car: PlayerCarController) -> int:
	return clampi(get_completed_laps(car) + 1, 1, lap_count)


func get_participant_count() -> int:
	return _participants.size()


func get_race_position(car: PlayerCarController) -> int:
	if car == null:
		return 1

	var ordered_participants: Array[PlayerCarController] = get_result_order()
	var player_position: int = ordered_participants.find(car)
	if player_position < 0:
		return 1

	return player_position + 1


func get_result_order() -> Array[PlayerCarController]:
	var ordered: Array[PlayerCarController] = []
	for finished_car: PlayerCarController in _finish_order:
		if is_instance_valid(finished_car) and not ordered.has(finished_car):
			ordered.append(finished_car)

	var remaining: Array[PlayerCarController] = []
	for car: PlayerCarController in _participants:
		if is_instance_valid(car) and not ordered.has(car):
			remaining.append(car)

	remaining.sort_custom(Callable(self, "_sort_participants_by_progress"))
	ordered.append_array(remaining)
	return ordered


func _refresh_race_points() -> void:
	_race_points.clear()
	if _track == null or not _track.has_method("get_racing_line_points"):
		return

	var local_points: Array = _track.call("get_racing_line_points")
	for point: Variant in local_points:
		if point is Vector3:
			_race_points.append(_track.to_global(point))


func _register_participant(car: PlayerCarController) -> void:
	if car == null:
		return

	_participants.append(car)
	_participant_laps.append(0)
	_participant_progress.append(_get_nearest_race_point_index(car.global_position))
	_participant_finished.append(false)
	_participant_lap_armed.append(false)


func _get_nearest_race_point_index(position: Vector3) -> int:
	var nearest_index: int = 0
	var nearest_distance: float = INF

	for point_index: int in _race_points.size():
		var distance: float = position.distance_squared_to(_race_points[point_index])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = point_index

	return nearest_index


func _crossed_finish_line(previous_index: int, current_index: int) -> bool:
	if _race_points.size() < 4:
		return false

	var finish_exit_index: int = floori(float(_race_points.size()) * 0.75)
	var finish_entry_index: int = ceili(float(_race_points.size()) * 0.25)
	return previous_index >= finish_exit_index and current_index <= finish_entry_index


func _is_lap_arming_progress(current_index: int) -> bool:
	if _race_points.size() < 4:
		return false

	var arming_start_index: int = floori(float(_race_points.size()) * 0.35)
	var arming_end_index: int = ceili(float(_race_points.size()) * 0.85)
	return current_index >= arming_start_index and current_index <= arming_end_index


func _mark_participant_finished(participant_index: int) -> void:
	_participant_finished[participant_index] = true
	var car: PlayerCarController = _participants[participant_index]
	_finish_order.append(car)
	participant_finished.emit(car)


func _sort_participants_by_progress(a: PlayerCarController, b: PlayerCarController) -> bool:
	return _get_race_distance_score(a) > _get_race_distance_score(b)


func _get_race_distance_score(car: PlayerCarController) -> int:
	var participant_index: int = _participants.find(car)
	if participant_index < 0:
		return -1

	return _participant_laps[participant_index] * maxi(_race_points.size(), 1) + _participant_progress[participant_index]
