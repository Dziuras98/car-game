extends RefCounted
class_name GameSessionState

signal phase_changed(phase: Phase)


enum Phase {
	MENU,
	STARTING,
	FREE_DRIVE,
	RACE,
}


enum Result {
	OK,
	INVALID_PHASE,
	UNSUPPORTED_MODE,
	EMPTY_TRACK_ID,
	EMPTY_CAR_VARIANT_ID,
}


var _phase: Phase = Phase.MENU
var _mode_id: StringName = &""
var _track_id: StringName = &""
var _car_variant_id: StringName = &""


static func is_success(result: Result) -> bool:
	return result == Result.OK


func begin_start() -> Result:
	if _phase != Phase.MENU:
		return Result.INVALID_PHASE
	_set_phase(Phase.STARTING)
	return Result.OK


func commit(mode_id: StringName, track_id: StringName, car_variant_id: StringName) -> Result:
	if _phase != Phase.STARTING:
		return Result.INVALID_PHASE
	if not GameModes.is_supported(mode_id):
		return Result.UNSUPPORTED_MODE
	if track_id == &"":
		return Result.EMPTY_TRACK_ID
	if car_variant_id == &"":
		return Result.EMPTY_CAR_VARIANT_ID

	_mode_id = mode_id
	_track_id = track_id
	_car_variant_id = car_variant_id
	_set_phase(Phase.RACE if mode_id == GameModes.RACE else Phase.FREE_DRIVE)
	return Result.OK


func update_free_drive_car_variant(car_variant_id: StringName) -> Result:
	if _phase != Phase.FREE_DRIVE:
		return Result.INVALID_PHASE
	if car_variant_id == &"":
		return Result.EMPTY_CAR_VARIANT_ID
	_car_variant_id = car_variant_id
	return Result.OK


func reset() -> void:
	_mode_id = &""
	_track_id = &""
	_car_variant_id = &""
	_set_phase(Phase.MENU)


func get_phase() -> Phase:
	return _phase


func get_mode_id() -> StringName:
	return _mode_id


func get_track_id() -> StringName:
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


func _set_phase(next_phase: Phase) -> void:
	if _phase == next_phase:
		return
	_phase = next_phase
	phase_changed.emit(_phase)
