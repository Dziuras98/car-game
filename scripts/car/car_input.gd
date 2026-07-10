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

var _touch_throttle: float = 0.0
var _touch_brake: float = 0.0
var _touch_steering: float = 0.0
var _touch_handbrake: bool = false
var _touch_gear_up_requested: bool = false
var _touch_gear_down_requested: bool = false
var _touch_reset_requested: bool = false


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


func set_touch_drive_inputs(target_throttle: float, target_brake: float, target_steering: float, target_handbrake_active: bool = false) -> void:
	_touch_throttle = clampf(target_throttle, 0.0, 1.0)
	_touch_brake = clampf(target_brake, 0.0, 1.0)
	_touch_steering = clampf(target_steering, -1.0, 1.0)
	_touch_handbrake = target_handbrake_active


func request_touch_gear_up() -> void:
	_touch_gear_up_requested = true


func request_touch_gear_down() -> void:
	_touch_gear_down_requested = true


func request_touch_reset() -> void:
	_touch_reset_requested = true


func clear_touch_input() -> void:
	set_touch_drive_inputs(0.0, 0.0, 0.0, false)
	_touch_gear_up_requested = false
	_touch_gear_down_requested = false
	_touch_reset_requested = false


func should_reset_car() -> bool:
	if _external_input_enabled or not _player_input_enabled:
		_touch_reset_requested = false
		return false
	var requested: bool = Input.is_action_just_pressed("reset-car") or _touch_reset_requested
	_touch_reset_requested = false
	return requested


func read_drive_input() -> void:
	_clear_drive_input()

	if _external_input_enabled:
		throttle = _external_throttle
		brake = _external_brake
		steering = _external_steering
		handbrake_active = _external_handbrake
		return

	if not _player_input_enabled:
		_touch_gear_up_requested = false
		_touch_gear_down_requested = false
		return

	throttle = maxf(Input.get_action_strength("accelerate"), _touch_throttle)
	brake = maxf(Input.get_action_strength("brake"), _touch_brake)
	var physical_steering: float = Input.get_action_strength("steer-right") - Input.get_action_strength("steer-left")
	steering = clampf(physical_steering + _touch_steering, -1.0, 1.0)
	handbrake_active = Input.is_action_pressed("handbrake") or _touch_handbrake
	gear_up_pressed = Input.is_action_just_pressed("gear-up") or _touch_gear_up_requested
	gear_down_pressed = Input.is_action_just_pressed("gear-down") or _touch_gear_down_requested
	_touch_gear_up_requested = false
	_touch_gear_down_requested = false


func _clear_drive_input() -> void:
	throttle = 0.0
	brake = 0.0
	steering = 0.0
	handbrake_active = false
	gear_up_pressed = false
	gear_down_pressed = false
