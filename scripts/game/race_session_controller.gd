extends RefCounted
class_name RaceSessionController

signal runtime_fault(message: String)


func configure(
	_car_spawner: CarSpawner,
	_race_hud: RaceHud,
	_track: GeneratedTrack,
	_minimap: Minimap,
	_race_lap_count: int,
	_opponent_count: int
) -> bool:
	return false


func is_configured() -> bool:
	return false


func start_race(_current_car: PlayerCarController, _scene_tree: SceneTree) -> bool:
	push_error("Race mode has been removed.")
	return false


func update_physics() -> void:
	pass


func reset_to_menu_state() -> void:
	_reset_runtime_state(true)


func hide_countdown() -> void:
	pass


func hide_lap_ui() -> void:
	pass


func hide_results() -> void:
	pass


func get_opponents() -> Array[PlayerCarController]:
	var empty: Array[PlayerCarController] = []
	return empty


func get_participants() -> Array[RaceParticipant]:
	var empty: Array[RaceParticipant] = []
	return empty


func get_race_state() -> RaceManager.State:
	return RaceManager.State.IDLE


func get_player_current_lap() -> int:
	return 0


func get_player_race_position() -> int:
	return 0


func get_participant_count() -> int:
	return 0


func are_player_controls_locked() -> bool:
	return false


func _build_participants() -> bool:
	return false


func _abort_race_start() -> void:
	_reset_runtime_state(false)


func _reset_runtime_state(_hide_result_screen: bool) -> void:
	pass
