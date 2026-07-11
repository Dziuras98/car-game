extends RefCounted
class_name CarInput

var throttle: float = 0.0
var brake: float = 0.0
var steering: float = 0.0
var handbrake_active: bool = false
var gear_up_pressed: bool = false
var gear_down_pressed: bool = false

var _player_input_enabled: bool = true
var _external_input_enabled: bool = false
var _external_throttle: float = 0.0
var _external_brake: float = 0.0
var _external_steering: float = 0.0
var _external_handbrake: bool = false


func set_player_input_enabled(enabled: bool) -> void:
	_player_input_enabled = enabled
	if not enabled:
		_clear_drive_input()


func set_external_input_enabled(enabled: bool) -> void:
	_external_input_enabled = enabled
	if not enabled:
		set_external_drive_inputs(0.0, 0.0, 0.0, false)


func set_external_drive_inputs(target_throttle: float, target_brake: float, target_steering: float, target_handbrake_active: bool = false) -> void:
	_external_throttle = clampf(target_throttle, 0.0, 1.0)
	_external_brake = clampf(target_brake, 0.0, 1.0)
	_external_steering = clampf(target_steering, -1.0, 1.0)
	_external_handbrake = target_handbrake_active


func should_reset_car() -> bool:
	if _external_input_enabled or not _player_input_enabled:
		return false
	return Input.is_action_just_pressed(GameInputActions.RESET_CAR)


func read_drive_input() -> void:
	_clear_drive_input()

	if _external_input_enabled:
		throttle = _external_throttle
		brake = _external_brake
		steering = _external_steering
		handbrake_active = _external_handbrake
		return

	if not _player_input_enabled:
		return

	throttle = Input.get_action_strength(GameInputActions.ACCELERATE)
	brake = Input.get_action_strength(GameInputActions.BRAKE)
	steering = clampf(
		Input.get_action_strength(GameInputActions.STEER_RIGHT)
		- Input.get_action_strength(GameInputActions.STEER_LEFT),
		-1.0,
		1.0
	)
	handbrake_active = Input.is_action_pressed(GameInputActions.HANDBRAKE)
	gear_up_pressed = Input.is_action_just_pressed(GameInputActions.GEAR_UP)
	gear_down_pressed = Input.is_action_just_pressed(GameInputActions.GEAR_DOWN)


func _clear_drive_input() -> void:
	throttle = 0.0
	brake = 0.0
	steering = 0.0
	handbrake_active = false
	gear_up_pressed = false
	gear_down_pressed = false
