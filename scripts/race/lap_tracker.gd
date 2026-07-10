extends RefCounted
class_name LapTracker

signal participant_finished(car: PlayerCarController)

var lap_count: int = 3

var _track: Node3D
var _race_points: Array[Vector3] = []
var _checkpoint_count: int = 0
var _participants: Array[PlayerCarController] = []
var _participant_laps: Array[int] = []
var _participant_progress: Array[int] = []
var _participant_finished: Array[bool] = []
var _participant_next_checkpoint: Array[int] = []
var _participant_rejected_crossings: Array[int] = []
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
	_refresh_checkpoint_count()
	_connect_track_checkpoint_signal()

	if player_car != null:
		_register_participant(player_car)

	for opponent: PlayerCarController in opponents:
		_register_participant(opponent)


func clear() -> void:
	_disconnect_track_checkpoint_signal()
	_track = null
	_race_points.clear()
	_checkpoint_count = 0
	_participants.clear()
	_participant_laps.clear()
	_participant_progress.clear()
	_participant_finished.clear()
	_participant_next_checkpoint.clear()
	_participant_rejected_crossings.clear()
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

		_participant_progress[participant_index] = _get_nearest_race_point_index(car.global_position)


func register_checkpoint_crossing(
	car: PlayerCarController,
	checkpoint_index: int,
	is_forward: bool
) -> bool:
	var participant_index: int = _participants.find(car)
	if participant_index < 0 or _participant_finished[participant_index]:
		return false
	if _checkpoint_count <= 0:
		_reject_crossing(participant_index)
		return false
	if not is_forward:
		_reject_crossing(participant_index)
		return false
	if checkpoint_index < 0 or checkpoint_index > _checkpoint_count:
		_reject_crossing(participant_index)
		return false

	var expected_checkpoint: int = _participant_next_checkpoint[participant_index]
	if checkpoint_index != expected_checkpoint:
		_reject_crossing(participant_index)
		if checkpoint_index == 0:
			_participant_next_checkpoint[participant_index] = 1
		return false

	if checkpoint_index == 0:
		_participant_next_checkpoint[participant_index] = 1
		_participant_laps[participant_index] += 1
		if _participant_laps[participant_index] >= lap_count:
			_mark_participant_finished(participant_index)
		return true

	if checkpoint_index >= _checkpoint_count:
		_participant_next_checkpoint[participant_index] = 0
	else:
		_participant_next_checkpoint[participant_index] = checkpoint_index + 1
	return true


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


func get_expected_checkpoint_index_for_test(car: PlayerCarController) -> int:
	var participant_index: int = _participants.find(car)
	if participant_index < 0:
		return -1
	return _participant_next_checkpoint[participant_index]


func get_rejected_crossing_count_for_test(car: PlayerCarController) -> int:
	var participant_index: int = _participants.find(car)
	if participant_index < 0:
		return 0
	return _participant_rejected_crossings[participant_index]


func _refresh_race_points() -> void:
	_race_points.clear()
	if _track == null or not _track.has_method("get_racing_line_points"):
		return

	var local_points: Array = _track.call("get_racing_line_points")
	for point: Variant in local_points:
		if point is Vector3:
			_race_points.append(_track.to_global(point))


func _refresh_checkpoint_count() -> void:
	_checkpoint_count = 0
	if _track == null or not _track.has_method("get_checkpoint_count"):
		return
	_checkpoint_count = maxi(int(_track.call("get_checkpoint_count")), 0)


func _connect_track_checkpoint_signal() -> void:
	if _track == null or not _track.has_signal("checkpoint_crossed"):
		return

	var callback: Callable = Callable(self, "_on_track_checkpoint_crossed")
	if not _track.is_connected("checkpoint_crossed", callback):
		_track.connect("checkpoint_crossed", callback)


func _disconnect_track_checkpoint_signal() -> void:
	if not is_instance_valid(_track) or not _track.has_signal("checkpoint_crossed"):
		return

	var callback: Callable = Callable(self, "_on_track_checkpoint_crossed")
	if _track.is_connected("checkpoint_crossed", callback):
		_track.disconnect("checkpoint_crossed", callback)


func _register_participant(car: PlayerCarController) -> void:
	if car == null:
		return

	_participants.append(car)
	_participant_laps.append(0)
	_participant_progress.append(_get_nearest_race_point_index(car.global_position))
	_participant_finished.append(false)
	_participant_next_checkpoint.append(1)
	_participant_rejected_crossings.append(0)


func _get_nearest_race_point_index(position: Vector3) -> int:
	var nearest_index: int = 0
	var nearest_distance: float = INF

	for point_index: int in _race_points.size():
		var distance: float = position.distance_squared_to(_race_points[point_index])
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = point_index

	return nearest_index


func _reject_crossing(participant_index: int) -> void:
	_participant_rejected_crossings[participant_index] += 1


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


func _on_track_checkpoint_crossed(
	car: PlayerCarController,
	checkpoint_index: int,
	is_forward: bool
) -> void:
	register_checkpoint_crossing(car, checkpoint_index, is_forward)
