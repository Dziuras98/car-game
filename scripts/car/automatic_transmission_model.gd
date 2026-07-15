extends RefCounted
class_name AutomaticTransmissionModel

const DIRECTION_CHANGE_SPEED_THRESHOLD: float = 0.25
const UPSHIFT_HOLD_THROTTLE_RELEASE_FACTOR: float = 0.75

var _upshift_hold_gear: int = 0


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
		throttle_ratio,
		brake_ratio,
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
			_start_upshift_hold(target_gear)
		return target_gear

	var downshift_rpm: float = downshift_base_rpm + throttle_ratio * 900.0
	if not downshift_inhibited and engine_rpm <= downshift_rpm and next_gear > 1:
		if safe_lower_gear_rpm < redline_rpm * 0.97:
			return next_gear - 1

	return next_gear


func _start_upshift_hold(target_gear: int) -> void:
	_upshift_hold_gear = target_gear


func _is_downshift_inhibited(
	current_gear: int,
	throttle: float,
	brake: float,
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
	if brake > 0.0 or throttle < throttle_release_threshold:
		_clear_upshift_hold()
		return false

	# A high-throttle upshift may sharply reduce coupled RPM while driven wheels
	# are spinning. Keep the selected gear latched until driver demand changes;
	# releasing it from RPM or a small vehicle-speed gain recreates a 1-2-1 or
	# multi-gear hunting loop under sustained wheelspin.
	return true


func _clear_upshift_hold() -> void:
	_upshift_hold_gear = 0
