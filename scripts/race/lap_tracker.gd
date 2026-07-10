extends RefCounted
class_name LapTracker

signal participant_finished(car: PlayerCarController)

var lap_count: int = 3

var _track: GeneratedTrack
var _race_points: Array[Vector3] = []
var _cumulative_distances: PackedFloat32Array = PackedFloat32Array()
var _track_length: float = 0.0
var _checkpoint_count: int = 0
var _participant_states: Dictionary = {}
var _participant_order: Array[int] = []
var _finish_order: Array[PlayerCarController] = []


func prepare(
	track: GeneratedTrack,
	target_lap_count: int,
	player_car: PlayerCarController,
	opponents: Array[PlayerCarController]
) -> bool:
	clear()
	_track = track
	lap_count = maxi(target_lap_count, 1)
	_refresh_track_contract()
	if not _has_valid_track_contract():
		clear()
		return false
	_connect_track_signals()

	if player_car != null:
		_register_participant(player_car)
	for opponent: PlayerCarController in opponents:
		_register_participant(opponent)
	return get_participant_count() > 0


func clear() -> void:
	_disconnect_track_signals()
	_track = null
	_race_points.clear()
	_cumulative_distances.clear()
	_track_length = 0.0
	_checkpoint_count = 0
	_participant_states.clear()
	_participant_order.clear()
	_finish_order.clear()


func update_positions() -> void:
	if _race_points.size() < 2:
		_refresh_track_contract()
		if _race_points.size() < 2:
			return

	_remove_invalid_participants()
	for participant_id: int in _participant_order:
		var state: ParticipantRaceState = _participant_states.get(participant_id) as ParticipantRaceState
		if state == null or state.finished or not is_instance_valid(state.car):
			continue
		_update_participant_projection(state)


func register_checkpoint_crossing(
	car: PlayerCarController,
	checkpoint_index: int,
	is_forward: bool
) -> bool:
	var state: ParticipantRaceState = _get_state(car)
	if state == null or state.finished:
		return false
	if _checkpoint_count <= 0:
		_reject_crossing(state)
		return false
	if not is_forward:
		_reject_crossing(state)
		return false
	if checkpoint_index < 0 or checkpoint_index > _checkpoint_count:
		_reject_crossing(state)
		return false

	if checkpoint_index != state.next_checkpoint:
		_reject_crossing(state)
		if checkpoint_index == 0:
			state.next_checkpoint = 1
		return false

	if checkpoint_index == 0:
		state.next_checkpoint = 1
		state.completed_laps += 1
		if state.completed_laps >= lap_count:
			_mark_participant_finished(state)
		return true

	if checkpoint_index >= _checkpoint_count:
		state.next_checkpoint = 0
	else:
		state.next_checkpoint = checkpoint_index + 1
	return true


func get_completed_laps(car: PlayerCarController) -> int:
	var state: ParticipantRaceState = _get_state(car)
	return state.completed_laps if state != null else 0


func get_current_lap(car: PlayerCarController) -> int:
	return clampi(get_completed_laps(car) + 1, 1, lap_count)


func get_participant_count() -> int:
	var valid_count: int = 0
	for participant_id: int in _participant_order:
		var state: ParticipantRaceState = _participant_states.get(participant_id) as ParticipantRaceState
		if state != null and is_instance_valid(state.car):
			valid_count += 1
	return valid_count


func get_race_position(car: PlayerCarController) -> int:
	if car == null:
		return 1
	var ordered_participants: Array[PlayerCarController] = get_result_order()
	var player_position: int = ordered_participants.find(car)
	return player_position + 1 if player_position >= 0 else 1


func get_result_order() -> Array[PlayerCarController]:
	var ordered: Array[PlayerCarController] = []
	for finished_car: PlayerCarController in _finish_order:
		if is_instance_valid(finished_car) and not ordered.has(finished_car):
			ordered.append(finished_car)

	var remaining: Array[PlayerCarController] = []
	for participant_id: int in _participant_order:
		var state: ParticipantRaceState = _participant_states.get(participant_id) as ParticipantRaceState
		if state != null and is_instance_valid(state.car) and not ordered.has(state.car):
			remaining.append(state.car)
	remaining.sort_custom(Callable(self, "_sort_participants_by_progress"))
	ordered.append_array(remaining)
	return ordered


func get_expected_checkpoint_index(car: PlayerCarController) -> int:
	var state: ParticipantRaceState = _get_state(car)
	return state.next_checkpoint if state != null else -1


func get_rejected_crossing_count(car: PlayerCarController) -> int:
	var state: ParticipantRaceState = _get_state(car)
	return state.rejected_crossings if state != null else 0


func get_progress_distance(car: PlayerCarController) -> float:
	var state: ParticipantRaceState = _get_state(car)
	return state.progress_distance if state != null else 0.0


func get_track_length() -> float:
	return _track_length


func _has_valid_track_contract() -> bool:
	if _track == null:
		push_error("LapTracker requires a GeneratedTrack.")
		return false
	if _race_points.size() < 2:
		push_error("LapTracker requires at least two racing-line points.")
		return false
	if _checkpoint_count <= 0:
		push_error("LapTracker requires a positive checkpoint count.")
		return false
	return true


func _refresh_track_contract() -> void:
	_refresh_race_points()
	_refresh_checkpoint_count()


func _refresh_race_points() -> void:
	_race_points.clear()
	_cumulative_distances.clear()
	_track_length = 0.0
	if _track == null:
		return

	for local_point: Vector3 in _track.get_racing_line_points():
		_race_points.append(_track.to_global(local_point))
	_rebuild_distance_cache()


func _rebuild_distance_cache() -> void:
	_cumulative_distances.clear()
	_track_length = 0.0
	if _race_points.size() < 2:
		return
	for point_index: int in range(_race_points.size()):
		_cumulative_distances.append(_track_length)
		var next_index: int = (point_index + 1) % _race_points.size()
		_track_length += _race_points[point_index].distance_to(_race_points[next_index])


func _refresh_checkpoint_count() -> void:
	_checkpoint_count = maxi(_track.get_checkpoint_count(), 0) if _track != null else 0


func _connect_track_signals() -> void:
	if _track == null:
		return
	var checkpoint_callback: Callable = Callable(self, "_on_track_checkpoint_crossed")
	if not _track.checkpoint_crossed.is_connected(checkpoint_callback):
		_track.checkpoint_crossed.connect(checkpoint_callback)
	var geometry_callback: Callable = Callable(self, "_on_track_geometry_rebuilt")
	if not _track.geometry_rebuilt.is_connected(geometry_callback):
		_track.geometry_rebuilt.connect(geometry_callback)


func _disconnect_track_signals() -> void:
	if not is_instance_valid(_track):
		return
	var checkpoint_callback: Callable = Callable(self, "_on_track_checkpoint_crossed")
	if _track.checkpoint_crossed.is_connected(checkpoint_callback):
		_track.checkpoint_crossed.disconnect(checkpoint_callback)
	var geometry_callback: Callable = Callable(self, "_on_track_geometry_rebuilt")
	if _track.geometry_rebuilt.is_connected(geometry_callback):
		_track.geometry_rebuilt.disconnect(geometry_callback)


func _register_participant(car: PlayerCarController) -> void:
	if car == null:
		return
	var participant_id: int = car.get_instance_id()
	if _participant_states.has(participant_id):
		return
	var state: ParticipantRaceState = ParticipantRaceState.new(car)
	_participant_states[participant_id] = state
	_participant_order.append(participant_id)
	_update_participant_projection(state)


func _get_state(car: PlayerCarController) -> ParticipantRaceState:
	if car == null:
		return null
	return _participant_states.get(car.get_instance_id()) as ParticipantRaceState


func _remove_invalid_participants() -> void:
	for order_index: int in range(_participant_order.size() - 1, -1, -1):
		var participant_id: int = _participant_order[order_index]
		var state: ParticipantRaceState = _participant_states.get(participant_id) as ParticipantRaceState
		if state == null or not is_instance_valid(state.car):
			_participant_order.remove_at(order_index)
			_participant_states.erase(participant_id)


func _update_participant_projection(state: ParticipantRaceState) -> void:
	if state == null or not is_instance_valid(state.car) or _race_points.size() < 2:
		return
	var position: Vector3 = state.car.global_position
	var best_distance_squared: float = INF
	var best_progress_distance: float = 0.0
	var best_segment_index: int = 0

	for segment_index: int in range(_race_points.size()):
		var next_index: int = (segment_index + 1) % _race_points.size()
		var segment_start: Vector3 = _race_points[segment_index]
		var segment_vector: Vector3 = _race_points[next_index] - segment_start
		var segment_length_squared: float = segment_vector.length_squared()
		if segment_length_squared <= 0.000001:
			continue
		var interpolation: float = clampf(
			(position - segment_start).dot(segment_vector) / segment_length_squared,
			0.0,
			1.0
		)
		var projected_position: Vector3 = segment_start + segment_vector * interpolation
		var distance_squared: float = position.distance_squared_to(projected_position)
		if distance_squared < best_distance_squared:
			best_distance_squared = distance_squared
			best_segment_index = segment_index
			best_progress_distance = (
				_cumulative_distances[segment_index]
				+ sqrt(segment_length_squared) * interpolation
			)

	state.progress_segment_index = best_segment_index
	state.progress_distance = clampf(best_progress_distance, 0.0, _track_length)


func _reject_crossing(state: ParticipantRaceState) -> void:
	state.rejected_crossings += 1


func _mark_participant_finished(state: ParticipantRaceState) -> void:
	if state.finished:
		return
	state.finished = true
	_finish_order.append(state.car)
	participant_finished.emit(state.car)


func _sort_participants_by_progress(a: PlayerCarController, b: PlayerCarController) -> bool:
	return _get_race_distance_score(a) > _get_race_distance_score(b)


func _get_race_distance_score(car: PlayerCarController) -> float:
	var state: ParticipantRaceState = _get_state(car)
	if state == null:
		return -1.0
	return float(state.completed_laps) * maxf(_track_length, 1.0) + state.progress_distance


func _on_track_checkpoint_crossed(
	car: PlayerCarController,
	checkpoint_index: int,
	is_forward: bool
) -> void:
	register_checkpoint_crossing(car, checkpoint_index, is_forward)


func _on_track_geometry_rebuilt(_revision: int) -> void:
	_refresh_track_contract()
	for participant_id: int in _participant_order:
		var state: ParticipantRaceState = _participant_states.get(participant_id) as ParticipantRaceState
		if state != null and is_instance_valid(state.car):
			_update_participant_projection(state)
