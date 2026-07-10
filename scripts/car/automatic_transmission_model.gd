extends RefCounted
class_name AutomaticTransmissionModel

const DIRECTION_CHANGE_SPEED_THRESHOLD: float = 0.25


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
	if forward_gear_count <= 0:
		return current_gear

	if brake > 0.0 and throttle <= 0.0 and current_gear >= 0:
		if is_direction_change_safe(forward_speed):
			return -1
		return current_gear

	var next_gear: int = current_gear
	if throttle > 0.0 and next_gear < 1:
		if is_direction_change_safe(forward_speed):
			next_gear = 1
		else:
			return current_gear

	if next_gear < 1 or shift_timer > 0.0:
		return next_gear

	var throttle_ratio: float = clampf(throttle, 0.0, 1.0)
	var safe_lower_gear_rpm: float = lower_gear_rpm

	if brake > 0.0 and throttle_ratio <= 0.0 and forward_speed > DIRECTION_CHANGE_SPEED_THRESHOLD and next_gear > 1:
		if safe_lower_gear_rpm < redline_rpm * 0.97:
			return next_gear - 1

	if throttle_ratio >= kickdown_throttle and next_gear > 1 and engine_rpm < kickdown_rpm:
		if safe_lower_gear_rpm < redline_rpm * 0.97:
			return next_gear - 1

	var upshift_rpm: float = lerpf(upshift_base_rpm, redline_rpm * 0.98, throttle_ratio)
	if engine_rpm >= upshift_rpm and next_gear < forward_gear_count:
		return next_gear + 1

	var downshift_rpm: float = downshift_base_rpm + throttle_ratio * 900.0
	if engine_rpm <= downshift_rpm and next_gear > 1:
		if safe_lower_gear_rpm < redline_rpm * 0.97:
			return next_gear - 1

	return next_gear