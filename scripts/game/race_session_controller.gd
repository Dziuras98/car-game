extends RefCounted
class_name RaceSessionController

const HUD_UPDATE_FRAME_INTERVAL: int = 6

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


func configure(
	car_spawner: CarSpawner,
	race_hud: RaceHud,
	track: GeneratedTrack,
	minimap: Minimap,
	race_lap_count: int,
	opponent_count: int
) -> void:
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


func start_race(current_car: PlayerCarController, scene_tree: SceneTree) -> void:
	if current_car == null or scene_tree == null:
		push_error("RaceSessionController requires a player car and SceneTree.")
		return
	_current_car = current_car
	_spawn_opponents()
	if not _prepare_race_tracking():
		clear_opponents()
		return
	_race_manager.start_race(_current_car, scene_tree)


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


func get_moving_opponent_count_for_test() -> int:
	var moving_count: int = 0
	for opponent: PlayerCarController in _opponents:
		if is_instance_valid(opponent) and absf(opponent.get_forward_speed()) > 0.05:
			moving_count += 1
	return moving_count


func simulate_current_player_finish_for_test(current_car: PlayerCarController) -> void:
	if current_car == null:
		return
	_current_car = current_car
	_on_lap_tracker_participant_finished(current_car)


func are_player_controls_locked() -> bool:
	return _race_manager != null and _race_manager.are_player_controls_locked()


func _spawn_opponents() -> void:
	if _car_spawner == null:
		return
	_opponents = _car_spawner.spawn_opponents(_opponent_count)
	_update_minimap_opponents()


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
		return "Ty"
	if car != null and car.name != "":
		return car.name
	return "Kierowca"


func _update_minimap_opponents() -> void:
	if _minimap != null:
		_minimap.set_opponents(_opponents)
