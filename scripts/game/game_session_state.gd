extends RefCounted
class_name GameSessionState


enum Phase {
	MENU,
	STARTING,
	FREE_DRIVE,
	RACE,
}


var _phase: Phase = Phase.MENU
var _mode_id: String = ""
var _track_id: String = ""
var _car_variant_id: StringName = &""


func begin_start() -> bool:
	if _phase != Phase.MENU:
		return false
	_phase = Phase.STARTING
	return true


func commit(mode_id: String, track_id: String, car_variant_id: StringName) -> bool:
	if _phase != Phase.STARTING:
		return false
	if not GameModes.is_supported(mode_id) or track_id.is_empty() or car_variant_id == &"":
		return false

	_mode_id = mode_id
	_track_id = track_id
	_car_variant_id = car_variant_id
	_phase = Phase.RACE if mode_id == GameModes.RACE else Phase.FREE_DRIVE
	return true


func reset() -> void:
	_phase = Phase.MENU
	_mode_id = ""
	_track_id = ""
	_car_variant_id = &""


func get_phase() -> Phase:
	return _phase


func get_mode_id() -> String:
	return _mode_id


func get_track_id() -> String:
	return _track_id


func get_car_variant_id() -> StringName:
	return _car_variant_id


func is_menu() -> bool:
	return _phase == Phase.MENU


func is_starting() -> bool:
	return _phase == Phase.STARTING


func is_free_drive() -> bool:
	return _phase == Phase.FREE_DRIVE


func is_race() -> bool:
	return _phase == Phase.RACE
