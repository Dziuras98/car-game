extends RefCounted
class_name RaceSessionController

const HUD_UPDATE_FRAME_INTERVAL: int = 6
const OPPONENT_NODE_PREFIX: String = "Opponent"

var _race_manager: RaceManager
var _lap_tracker: LapTracker
var _opponents: Array[PlayerCarController] = []
var _current_car: PlayerCarController
var _car_spawner: CarSpawner
var _race_hud: RaceHud
var _track: GeneratedTrack
var _minimap: Minimap
var _race_lap_count: int = 1
var _opponent_count: int = 0
var _hud_update_frames_remaining: int = 0
var _configured: bool = false


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
	if opponent_count > 0 and not car_spawner.has_ai_eligible_cars():
		push_error("RaceSessionController requires an AI-eligible car variant when opponents are enabled.")
		return false

	_car_spawner = car_spawner
	_race_hud = race_hud
	_track = track
	_minimap = minimap
	_race_lap_count = maxi(race_lap_count, 1)
	_opponent_count = maxi(opponent_count, 0)

	_lap_tracker = LapTracker.new()
	_lap_tracker.participant_finished.connect(_on_lap_tracker_participant_finished)

	_race_manager = RaceManager.new()
	_race_manager.countdown_changed.connect(_show_countdown)
	_race_manager.countdown_hidden.connect(hide_countdown)
	_race_manager.player_input_enabled_changed.connect(_set_player_input_enabled)
	_race_manager.ai_enabled_changed.connect(_set_ai_enabled)
	_race_manager.opponent_should_stop.connect(_stop_participant_car)
	_race_manager.race_finished.connect(_on_race_finished)
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

	_current_car = current_car
	if not _spawn_opponents():
		_abort_race_start()
		return false
	if not _prepare_race_tracking():
		push_error("RaceSessionController could not prepare race tracking for the complete participant set.")
		_abort_race_start()
		return false
	_race_manager.start_race(_current_car, scene_tree)
	return true


func update_physics() -> void:
	if _race_manager == null or not _race_manager.should_update_race_positions() or _lap_tracker == null:
		return

	_lap_tracker.update_positions()
	if _hud_update_frames_remaining > 0:
		_hud_update_frames_remaining -= 1
		return

	_hud_update_frames_remaining = HUD_UPDATE_FRAME_INTERVAL - 1
	_update_lap_ui()


func reset_to_menu_state() -> void:
	hide_results()
	hide_lap_ui()
	hide_countdown()
	clear_opponents()
	clear_tracking()
	_current_car = null
	_hud_update_frames_remaining = 0


func clear_opponents() -> void:
	if _race_manager != null:
		_race_manager.reset_to_idle()
	if _car_spawner != null:
		_car_spawner.clear_opponents()
	_opponents.clear()
	_update_minimap_opponents()


func clear_tracking() -> void:
	if _lap_tracker != null:
		_lap_tracker.clear()


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


func get_lap_tracker() -> LapTracker:
	return _lap_tracker


func get_race_manager() -> RaceManager:
	return _race_manager


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


func _set_ai_enabled(enabled: bool) -> void:
	if _car_spawner != null:
		_car_spawner.set_ai_enabled(enabled)


func _set_player_input_enabled(enabled: bool) -> void:
	if is_instance_valid(_current_car):
		_current_car.set_player_input_enabled(enabled)


func _stop_participant_car(car: PlayerCarController) -> void:
	if is_instance_valid(car):
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
	if _current_car == null or _lap_tracker == null or _race_hud == null:
		return
	_race_hud.update_lap(
		_lap_tracker.get_current_lap(_current_car),
		_race_lap_count,
		_lap_tracker.get_race_position(_current_car),
		maxi(_lap_tracker.get_participant_count(), 1)
	)


func _prepare_race_tracking() -> bool:
	if _lap_tracker == null or _track == null:
		return false
	var prepared: bool = _lap_tracker.prepare(_track, _race_lap_count, _current_car, _opponents)
	if prepared:
		_show_lap_ui()
	return prepared


func _abort_race_start() -> void:
	hide_lap_ui()
	hide_countdown()
	clear_tracking()
	if _car_spawner != null:
		_car_spawner.clear_opponents()
	_opponents.clear()
	_update_minimap_opponents()
	_current_car = null
	_hud_update_frames_remaining = 0
	if _race_manager != null:
		_race_manager.reset_to_idle()


func _on_lap_tracker_participant_finished(car: PlayerCarController) -> void:
	if car == _current_car:
		_finish_race()
	elif is_instance_valid(car):
		_stop_participant_car(car)


func _finish_race() -> void:
	if _race_manager != null:
		_race_manager.finish_race(_current_car, _opponents)


func _on_race_finished() -> void:
	hide_lap_ui()
	_show_results()


func _show_results() -> void:
	if _lap_tracker == null or _race_hud == null:
		return

	var result_labels: Array[String] = []
	for car: PlayerCarController in _lap_tracker.get_result_order():
		result_labels.append(_get_participant_label(car))
	_race_hud.show_results(result_labels)


func _get_participant_label(car: PlayerCarController) -> String:
	if car == _current_car:
		return tr("Ty")
	if car != null:
		var opponent_number: int = _get_standard_opponent_number(str(car.name))
		if opponent_number > 0:
			return tr("Kierowca %d") % opponent_number
		if not str(car.name).is_empty():
			return str(car.name)
	return tr("Kierowca")


func _get_standard_opponent_number(node_name: String) -> int:
	if not node_name.begins_with(OPPONENT_NODE_PREFIX):
		return -1
	var suffix: String = node_name.trim_prefix(OPPONENT_NODE_PREFIX)
	return suffix.to_int() if suffix.is_valid_int() else -1


func _update_minimap_opponents() -> void:
	if _minimap != null:
		_minimap.set_opponents(_opponents)
