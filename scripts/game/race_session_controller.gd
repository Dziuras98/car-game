extends RefCounted
class_name RaceSessionController

signal runtime_fault(message: String)

const HUD_UPDATE_FRAME_INTERVAL: int = 6

var _race_manager: RaceManager
var _lap_tracker: LapTracker
var _opponents: Array[PlayerCarController] = []
var _participants: Array[RaceParticipant] = []
var _participants_by_car_id: Dictionary = {}
var _current_car: PlayerCarController
var _car_spawner: CarSpawner
var _race_hud: RaceHud
var _track: GeneratedTrack
var _minimap: Minimap
var _race_lap_count: int = 1
var _opponent_count: int = 0
var _hud_update_frames_remaining: int = 0
var _configured: bool = false
var _runtime_fault_active: bool = false


func configure(
	car_spawner: CarSpawner,
	race_hud: RaceHud,
	track: GeneratedTrack,
	minimap: Minimap,
	race_lap_count: int,
	opponent_count: int
) -> bool:
	_configured = false
	if car_spawner == null or not car_spawner.is_configured():
		push_error("RaceSessionController requires a configured CarSpawner.")
		return false
	if race_hud == null:
		push_error("RaceSessionController requires a RaceHud.")
		return false
	if not is_instance_valid(track) or not track.has_committed_generation():
		push_error("RaceSessionController requires a committed GeneratedTrack.")
		return false
	if not is_instance_valid(minimap):
		push_error("RaceSessionController requires a Minimap.")
		return false
	if race_lap_count <= 0:
		push_error("RaceSessionController race_lap_count must be positive.")
		return false
	if opponent_count < 0:
		push_error("RaceSessionController opponent_count must be non-negative.")
		return false
	var spawn_validation_errors: PackedStringArray = car_spawner.validate_opponent_spawn_request(opponent_count)
	if not spawn_validation_errors.is_empty():
		push_error(
			"RaceSessionController rejected the configured opponent grid: %s"
			% "; ".join(spawn_validation_errors)
		)
		return false

	_car_spawner = car_spawner
	_race_hud = race_hud
	_track = track
	_minimap = minimap
	_race_lap_count = race_lap_count
	_opponent_count = opponent_count
	_runtime_fault_active = false

	_lap_tracker = LapTracker.new()
	_lap_tracker.participant_finished.connect(_on_lap_tracker_participant_finished)
	_lap_tracker.runtime_contract_failed.connect(_on_lap_tracker_runtime_contract_failed)

	_race_manager = RaceManager.new()
	_race_manager.countdown_changed.connect(_show_countdown)
	_race_manager.countdown_hidden.connect(hide_countdown)
	_race_manager.player_input_enabled_changed.connect(_set_player_input_enabled)
	_race_manager.ai_enabled_changed.connect(_set_ai_enabled)
	_race_manager.opponent_should_stop.connect(_stop_participant_car)
	_race_manager.race_finished.connect(_on_race_finished)
	_car_spawner.driver_fault.connect(_on_ai_driver_fault)
	_configured = true
	return true


func is_configured() -> bool:
	return _configured


func start_race(current_car: PlayerCarController, scene_tree: SceneTree) -> bool:
	if not _configured:
		push_error("RaceSessionController must be configured before starting a race.")
		return false
	if not is_instance_valid(current_car) or scene_tree == null:
		push_error("RaceSessionController requires a player car and SceneTree.")
		return false
	if _race_manager == null or _race_manager.get_state() != RaceManager.State.IDLE:
		push_error("RaceSessionController can start a race only from the IDLE state.")
		return false

	_current_car = current_car
	if not _spawn_opponents():
		_abort_race_start()
		return false
	if not _build_participants():
		push_error("RaceSessionController could not create the typed participant set.")
		_abort_race_start()
		return false
	if not _prepare_race_tracking():
		push_error("RaceSessionController could not prepare race tracking for the complete participant set.")
		_abort_race_start()
		return false
	var start_result: RaceManager.Result = _race_manager.start_race(_current_car, scene_tree)
	if not RaceManager.is_success(start_result):
		push_error(RaceManager.get_failure_message(start_result))
		_abort_race_start()
		return false
	return true


func update_physics() -> void:
	if _race_manager == null or not _race_manager.should_update_race_positions() or _lap_tracker == null:
		return

	_lap_tracker.update_positions()
	if _runtime_fault_active:
		return
	if _hud_update_frames_remaining > 0:
		_hud_update_frames_remaining -= 1
		return

	_hud_update_frames_remaining = HUD_UPDATE_FRAME_INTERVAL - 1
	_update_lap_ui()


func reset_to_menu_state() -> void:
	_reset_runtime_state(true)
	_runtime_fault_active = false


func hide_countdown() -> void:
	if _race_hud != null:
		_race_hud.hide_countdown()


func hide_lap_ui() -> void:
	if _race_hud != null:
		_race_hud.hide_lap()


func hide_results() -> void:
	if _race_hud != null:
		_race_hud.hide_results()


func get_opponents() -> Array[PlayerCarController]:
	return _opponents.duplicate()


func get_participants() -> Array[RaceParticipant]:
	return _participants.duplicate()


func get_race_state() -> RaceManager.State:
	return _race_manager.get_state() if _race_manager != null else RaceManager.State.IDLE


func get_player_current_lap() -> int:
	if _lap_tracker == null or not _lap_tracker.has_participant(_current_car):
		return 0
	return _lap_tracker.get_current_lap(_current_car)


func get_player_race_position() -> int:
	if _lap_tracker == null or not _lap_tracker.has_participant(_current_car):
		return 0
	return _lap_tracker.get_race_position(_current_car)


func get_participant_count() -> int:
	return _lap_tracker.get_participant_count() if _lap_tracker != null else 0


func are_player_controls_locked() -> bool:
	return _race_manager != null and _race_manager.are_player_controls_locked()


func _spawn_opponents() -> bool:
	if _car_spawner == null:
		return false
	_opponents = _car_spawner.spawn_opponents(_opponent_count)
	if _opponents.size() != _opponent_count:
		push_error(
			"RaceSessionController requested %d opponents but received %d."
			% [_opponent_count, _opponents.size()]
		)
		return false
	_update_minimap_opponents()
	return true


func _build_participants() -> bool:
	_clear_participants()
	if not _register_participant(RaceParticipant.create_player(_current_car)):
		return false
	for opponent_index: int in range(_opponents.size()):
		if not _register_participant(
			RaceParticipant.create_opponent(_opponents[opponent_index], opponent_index + 1)
		):
			_clear_participants()
			return false
	return _participants.size() == _opponents.size() + 1


func _register_participant(participant: RaceParticipant) -> bool:
	if participant == null or not participant.is_valid():
		return false
	for existing: RaceParticipant in _participants:
		if existing.get_participant_id() == participant.get_participant_id():
			return false
	var participant_car: PlayerCarController = participant.get_car()
	var car_instance_id: int = participant_car.get_instance_id()
	if _participants_by_car_id.has(car_instance_id):
		return false
	_participants.append(participant)
	_participants_by_car_id[car_instance_id] = participant
	return true


func _get_participant_for_car(car: PlayerCarController) -> RaceParticipant:
	if not is_instance_valid(car):
		return null
	return _participants_by_car_id.get(car.get_instance_id()) as RaceParticipant


func _clear_participants() -> void:
	_participants.clear()
	_participants_by_car_id.clear()


func _set_ai_enabled(enabled: bool) -> void:
	if _car_spawner != null:
		_car_spawner.set_ai_enabled(enabled)


func _set_player_input_enabled(enabled: bool) -> void:
	if is_instance_valid(_current_car):
		_current_car.set_player_input_enabled(enabled)


func _stop_participant_car(car: PlayerCarController) -> void:
	if not is_instance_valid(car):
		return
	if car.get_current_gear() < 0 or car.get_speed_kmh() < 0.0:
		car.set_external_drive_inputs(1.0, 0.0, 0.0)
	else:
		car.set_external_drive_inputs(0.0, 0.85, 0.0)


func _show_countdown(text: String) -> void:
	if _race_hud != null:
		_race_hud.show_countdown(text)


func _show_lap_ui() -> void:
	if _race_hud != null:
		_race_hud.show_lap()
	_hud_update_frames_remaining = HUD_UPDATE_FRAME_INTERVAL - 1
	_update_lap_ui()


func _update_lap_ui() -> void:
	if not is_instance_valid(_current_car) or _lap_tracker == null or _race_hud == null:
		_report_runtime_fault("RaceSessionController lost a required lap-HUD dependency.")
		return
	if not _lap_tracker.has_participant(_current_car):
		_report_runtime_fault("RaceSessionController player car is not registered in LapTracker.")
		return
	var current_lap: int = _lap_tracker.get_current_lap(_current_car)
	var race_position: int = _lap_tracker.get_race_position(_current_car)
	var participant_count: int = _lap_tracker.get_participant_count()
	if current_lap <= 0 or race_position <= 0 or participant_count <= 0:
		_report_runtime_fault("RaceSessionController received invalid player race telemetry.")
		return
	_race_hud.update_lap(
		current_lap,
		_race_lap_count,
		race_position,
		participant_count
	)


func _prepare_race_tracking() -> bool:
	if _lap_tracker == null or _track == null:
		return false
	var prepared: bool = _lap_tracker.prepare(_track, _race_lap_count, _current_car, _opponents)
	if prepared and _lap_tracker.has_participant(_current_car):
		_show_lap_ui()
		return not _runtime_fault_active
	return false


func _abort_race_start() -> void:
	_reset_runtime_state(false)


func _reset_runtime_state(hide_result_screen: bool) -> void:
	if hide_result_screen:
		hide_results()
	hide_lap_ui()
	hide_countdown()
	if _race_manager != null:
		_race_manager.reset_to_idle()
	_clear_tracking()
	_clear_opponent_runtime()
	_clear_participants()
	_current_car = null
	_hud_update_frames_remaining = 0


func _clear_tracking() -> void:
	if _lap_tracker != null:
		_lap_tracker.clear()


func _clear_opponent_runtime() -> void:
	if _car_spawner != null:
		_car_spawner.clear_opponents()
	_opponents.clear()
	_update_minimap_opponents()


func _on_lap_tracker_participant_finished(car: PlayerCarController) -> void:
	var participant: RaceParticipant = _get_participant_for_car(car)
	if participant == null:
		_report_runtime_fault("LapTracker finished an unknown race participant.")
		return
	if participant.is_player():
		_finish_race()
	else:
		_stop_participant_car(participant.get_car())


func _finish_race() -> void:
	if _race_manager == null:
		_report_runtime_fault("RaceSessionController lost RaceManager while finishing.")
		return
	var finish_result: RaceManager.Result = _race_manager.finish_race(_current_car, _opponents)
	if not RaceManager.is_success(finish_result):
		_report_runtime_fault(RaceManager.get_failure_message(finish_result))


func _on_race_finished() -> void:
	hide_lap_ui()
	_show_results()


func _show_results() -> void:
	if _lap_tracker == null or _race_hud == null:
		_report_runtime_fault("RaceSessionController lost result-screen dependencies.")
		return

	var result_labels: Array[String] = []
	for car: PlayerCarController in _lap_tracker.get_result_order():
		var participant: RaceParticipant = _get_participant_for_car(car)
		if participant == null:
			_report_runtime_fault("Race result order contains an unknown participant.")
			return
		result_labels.append(participant.get_display_label())
	_race_hud.show_results(result_labels)


func _update_minimap_opponents() -> void:
	if _minimap != null:
		_minimap.set_opponents(_opponents)


func _on_ai_driver_fault(message: String) -> void:
	_report_runtime_fault("AI driver fault: %s" % message)


func _on_lap_tracker_runtime_contract_failed(message: String) -> void:
	_report_runtime_fault(message)


func _report_runtime_fault(message: String) -> void:
	if _runtime_fault_active:
		return
	_runtime_fault_active = true
	push_error(message)
	_reset_runtime_state(true)
	runtime_fault.emit(message)
