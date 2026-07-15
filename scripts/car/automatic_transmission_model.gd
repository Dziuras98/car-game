extends RefCounted
class_name AutomaticTransmissionModel

const DIRECTION_CHANGE_SPEED_THRESHOLD: float = 0.25
const UPSHIFT_HOLD_SPEED_GAIN_MPS: float = 2.0
const UPSHIFT_HOLD_THROTTLE_RELEASE_FACTOR: float = 0.75

var _upshift_hold_gear: int = 0
var _upshift_hold_start_speed: float = 0.0


func is_direction_change_safe(forward_speed: float) -> bool:
	return absf(forward_speed) <= DIRECTION_CHANGE_SPEED_THRESHOLD


func get_requested_gear(
	current_gear: int,
	forward_gear_count: int,
	forward_speed: float,
	engine_rpm: float,
	throttle: float,
	brake: float,
	shift_timer: float,
	redline_rpm: float,
	upshift_base_rpm: float,
	downshift_base_rpm: float,
	kickdown_throttle: float,
	kickdown_rpm: float,
	lower_gear_rpm: float
) -> int:
	if forward_gear_count <= 0 or shift_timer > 0.0:
		return current_gear

	var throttle_ratio: float = clampf(throttle, 0.0, 1.0)
	var brake_ratio: float = clampf(brake, 0.0, 1.0)
	var safe_lower_gear_rpm: float = lower_gear_rpm
	var downshift_inhibited: bool = _is_downshift_inhibited(
		current_gear,
		forward_speed,
		engine_rpm,
		throttle_ratio,
		brake_ratio,
		downshift_base_rpm,
		kickdown_throttle
	)

	if brake_ratio > 0.0 and throttle_ratio <= 0.0:
		if current_gear < 0:
			return current_gear
		if is_direction_change_safe(forward_speed):
			return -1
		if current_gear > 1 and safe_lower_gear_rpm < redline_rpm * 0.97:
			return current_gear - 1
		return current_gear

	var next_gear: int = current_gear
	if throttle_ratio > 0.0 and next_gear < 1:
		if is_direction_change_safe(forward_speed):
			next_gear = 1
		else:
			return current_gear

	if next_gear < 1:
		return next_gear

	if (
		not downshift_inhibited
		and throttle_ratio >= kickdown_throttle
		and next_gear > 1
		and engine_rpm < kickdown_rpm
	):
		if safe_lower_gear_rpm < redline_rpm * 0.97:
			return next_gear - 1

	var upshift_rpm: float = lerpf(upshift_base_rpm, redline_rpm * 0.98, throttle_ratio)
	if engine_rpm >= upshift_rpm and next_gear < forward_gear_count:
		var target_gear: int = next_gear + 1
		if throttle_ratio >= kickdown_throttle:
			_start_upshift_hold(target_gear, forward_speed)
		return target_gear

	var downshift_rpm: float = downshift_base_rpm + throttle_ratio * 900.0
	if not downshift_inhibited and engine_rpm <= downshift_rpm and next_gear > 1:
		if safe_lower_gear_rpm < redline_rpm * 0.97:
			return next_gear - 1

	return next_gear


func _start_upshift_hold(target_gear: int, forward_speed: float) -> void:
	_upshift_hold_gear = target_gear
	_upshift_hold_start_speed = absf(forward_speed)


func _is_downshift_inhibited(
	current_gear: int,
	forward_speed: float,
	engine_rpm: float,
	throttle: float,
	brake: float,
	downshift_base_rpm: float,
	kickdown_throttle: float
) -> bool:
	if _upshift_hold_gear <= 0:
		return false
	if current_gear != _upshift_hold_gear:
		_clear_upshift_hold()
		return false

	var throttle_release_threshold: float = (
		kickdown_throttle
		* UPSHIFT_HOLD_THROTTLE_RELEASE_FACTOR
	)
	if (
		brake > 0.0
		or throttle < throttle_release_threshold
		or engine_rpm <= downshift_base_rpm
		or absf(forward_speed) >= _upshift_hold_start_speed + UPSHIFT_HOLD_SPEED_GAIN_MPS
	):
		_clear_upshift_hold()
		return false

	return true


func _clear_upshift_hold() -> void:
	_upshift_hold_gear = 0
	_upshift_hold_start_speed = 0.0
