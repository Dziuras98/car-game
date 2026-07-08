extends RefCounted
class_name RaceManager

signal countdown_changed(text: String)
signal countdown_hidden()
signal player_input_enabled_changed(enabled: bool)
signal ai_enabled_changed(enabled: bool)
signal opponent_should_stop(car: PlayerCarController)
signal race_finished()

var _race_in_progress: bool = false
var _race_completed: bool = false
var _player_controls_locked: bool = false
var _countdown_sequence: int = 0


func start_race(player_car: PlayerCarController, scene_tree: SceneTree) -> void:
	_countdown_sequence += 1
	var sequence: int = _countdown_sequence

	_race_completed = false
	_race_in_progress = false
	_player_controls_locked = true
	player_input_enabled_changed.emit(false)
	ai_enabled_changed.emit(false)

	countdown_changed.emit("3")
	await scene_tree.create_timer(1.0).timeout
	if _should_cancel_countdown(sequence):
		return

	countdown_changed.emit("2")
	await scene_tree.create_timer(1.0).timeout
	if _should_cancel_countdown(sequence):
		return

	countdown_changed.emit("1")
	await scene_tree.create_timer(1.0).timeout
	if _should_cancel_countdown(sequence):
		return

	countdown_changed.emit("START")
	_player_controls_locked = false
	_race_in_progress = true
	if player_car != null:
		player_input_enabled_changed.emit(true)
	ai_enabled_changed.emit(true)

	await scene_tree.create_timer(0.8).timeout
	if _should_cancel_countdown(sequence):
		return

	countdown_hidden.emit()


func finish_race(player_car: PlayerCarController, opponents: Array[PlayerCarController]) -> void:
	if _race_completed:
		return

	_countdown_sequence += 1
	_race_completed = true
	_race_in_progress = false
	_player_controls_locked = true

	if player_car != null:
		player_input_enabled_changed.emit(false)
	ai_enabled_changed.emit(false)
	for opponent: PlayerCarController in opponents:
		if is_instance_valid(opponent):
			opponent_should_stop.emit(opponent)

	countdown_hidden.emit()
	race_finished.emit()


func reset_to_idle() -> void:
	_countdown_sequence += 1
	_race_completed = false
	_race_in_progress = false
	_player_controls_locked = false
	countdown_hidden.emit()


func should_update_race_positions() -> bool:
	return _race_in_progress and not _race_completed


func is_race_in_progress() -> bool:
	return _race_in_progress


func is_race_completed() -> bool:
	return _race_completed


func are_player_controls_locked() -> bool:
	return _player_controls_locked


func _should_cancel_countdown(sequence: int) -> bool:
	return _race_completed or sequence != _countdown_sequence
