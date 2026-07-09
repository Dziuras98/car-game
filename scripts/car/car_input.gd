extends RefCounted
class_name CarInput

var throttle: float = 0.0
var brake: float = 0.0
var steering: float = 0.0
var handbrake_active: bool = false

var _player_input_enabled: bool = true
var _external_input_enabled: bool = false
var _external_throttle: float = 0.0
var _external_brake: float = 0.0
var _external_steering: float = 0.0
var _external_handbrake: bool = false


func set_player_input_enabled(enabled: bool) -> void:
	_player_input_enabled = enabled
	if not enabled:
		throttle = 0.0
		brake = 0.0


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
	return not _external_input_enabled and _player_input_enabled and Input.is_action_just_pressed("reset-car")


func read_drive_input() -> void:
	throttle = 0.0
	brake = 0.0
	steering = 0.0
	handbrake_active = false

	if _external_input_enabled:
		throttle = _external_throttle
		brake = _external_brake
		steering = _external_steering
		handbrake_active = _external_handbrake
		return

	if _player_input_enabled:
		throttle = Input.get_action_strength("accelerate")
		brake = Input.get_action_strength("brake")
		steering = Input.get_action_strength("steer-right") - Input.get_action_strength("steer-left")
		handbrake_active = Input.is_action_pressed("handbrake")
