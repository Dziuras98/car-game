extends RefCounted
class_name RaceManager

signal state_changed(state: State)
signal countdown_changed(text: String)
signal countdown_hidden()
signal player_input_enabled_changed(enabled: bool)
signal ai_enabled_changed(enabled: bool)
signal opponent_should_stop(car: PlayerCarController)
signal race_finished()

enum State {
	IDLE,
	COUNTDOWN,
	RUNNING,
	FINISHED,
}

enum Result {
	OK,
	INVALID_STATE,
	INVALID_PLAYER,
	INVALID_SCENE_TREE,
}

var _state: State = State.IDLE
var _countdown_sequence: int = 0
var _countdown_step_duration: float = 1.0
var _start_banner_duration: float = 0.8


static func is_success(result: Result) -> bool:
	return result == Result.OK


static func get_failure_message(result: Result) -> String:
	match result:
		Result.INVALID_STATE:
			return "Race lifecycle rejected the operation from the current state."
		Result.INVALID_PLAYER:
			return "Race lifecycle requires a valid player car."
		Result.INVALID_SCENE_TREE:
			return "Race lifecycle requires a SceneTree for countdown timing."
		_:
			return ""


func configure(countdown_step_duration: float = 1.0, start_banner_duration: float = 0.8) -> void:
	_countdown_step_duration = maxf(countdown_step_duration, 0.001)
	_start_banner_duration = maxf(start_banner_duration, 0.001)


func start_race(player_car: PlayerCarController, scene_tree: SceneTree) -> Result:
	if _state != State.IDLE:
		return Result.INVALID_STATE
	if not is_instance_valid(player_car):
		return Result.INVALID_PLAYER
	if scene_tree == null:
		return Result.INVALID_SCENE_TREE

	_countdown_sequence += 1
	var sequence: int = _countdown_sequence
	_transition_to(State.COUNTDOWN)
	player_input_enabled_changed.emit(false)
	ai_enabled_changed.emit(false)
	_run_countdown(player_car, scene_tree, sequence)
	return Result.OK


func finish_race(player_car: PlayerCarController, opponents: Array[PlayerCarController]) -> Result:
	if _state != State.RUNNING:
		return Result.INVALID_STATE
	if not is_instance_valid(player_car):
		return Result.INVALID_PLAYER

	_countdown_sequence += 1
	_transition_to(State.FINISHED)
	player_input_enabled_changed.emit(false)
	ai_enabled_changed.emit(false)
	for opponent: PlayerCarController in opponents:
		if is_instance_valid(opponent):
			opponent_should_stop.emit(opponent)

	countdown_hidden.emit()
	race_finished.emit()
	return Result.OK


func reset_to_idle() -> Result:
	_countdown_sequence += 1
	_transition_to(State.IDLE)
	player_input_enabled_changed.emit(true)
	ai_enabled_changed.emit(false)
	countdown_hidden.emit()
	return Result.OK


func get_state() -> State:
	return _state


func should_update_race_positions() -> bool:
	return _state == State.RUNNING


func is_race_in_progress() -> bool:
	return _state == State.RUNNING


func is_race_completed() -> bool:
	return _state == State.FINISHED


func are_player_controls_locked() -> bool:
	return _state == State.COUNTDOWN or _state == State.FINISHED


func _run_countdown(player_car: PlayerCarController, scene_tree: SceneTree, sequence: int) -> void:
	for countdown_text: String in ["3", "2", "1"]:
		countdown_changed.emit(countdown_text)
		await scene_tree.create_timer(_countdown_step_duration, false).timeout
		if _should_cancel_countdown(sequence):
			return

	countdown_changed.emit(tr("START"))
	_transition_to(State.RUNNING)
	if is_instance_valid(player_car):
		player_input_enabled_changed.emit(true)
	ai_enabled_changed.emit(true)

	await scene_tree.create_timer(_start_banner_duration, false).timeout
	if _should_cancel_countdown(sequence):
		return
	countdown_hidden.emit()


func _transition_to(next_state: State) -> void:
	if _state == next_state:
		return
	_state = next_state
	state_changed.emit(_state)


func _should_cancel_countdown(sequence: int) -> bool:
	return sequence != _countdown_sequence or (_state != State.COUNTDOWN and _state != State.RUNNING)
