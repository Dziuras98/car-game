extends Node
class_name AiRaceDriver

signal driver_fault(message: String)

enum DriverState {
	FOLLOW_LINE,
	RECOVERY_BRAKE_TO_STOP,
	RECOVERY_ENGAGE_REVERSE,
	RECOVERY_REVERSE_UNTIL_CLEAR,
	RECOVERY_RETURN_TO_FORWARD,
}

var _car: PlayerCarController


func configure(
	car: PlayerCarController,
	_track: GeneratedTrack,
	_profile: AiDriverProfile
) -> bool:
	_car = car
	_neutralize_car()
	return false


func _ready() -> void:
	set_physics_process(false)
	_neutralize_car()


func _exit_tree() -> void:
	_neutralize_car()


func set_driver_enabled(_enabled: bool) -> void:
	set_physics_process(false)
	_neutralize_car()


func is_configured() -> bool:
	return false


func get_profile() -> AiDriverProfile:
	return null


func get_last_search_check_count() -> int:
	return 0


func get_point_revision() -> int:
	return 0


func get_cached_point_count() -> int:
	return 0


func get_driver_state() -> DriverState:
	return DriverState.FOLLOW_LINE


func _update_manual_transmission(_throttle: float, _brake: float) -> void:
	pass


func _request_manual_gear(_target_gear: int) -> void:
	pass


func _set_reverse_recovery_inputs(_steering: float) -> void:
	pass


func _set_return_to_forward_inputs(
	_signed_speed_kmh: float,
	_stop_speed: float,
	_steering: float
) -> void:
	pass


func _neutralize_car() -> void:
	if not is_instance_valid(_car):
		return
	_car.clear_external_gear_requests()
	_car.set_external_drive_inputs(0.0, 0.0, 0.0, false)
	_car.set_external_input_enabled(false)
