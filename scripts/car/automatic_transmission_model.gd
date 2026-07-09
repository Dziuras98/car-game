extends RefCounted
class_name AutomaticTransmissionModel


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

	if brake > 0.0 and throttle <= 0.0 and forward_speed < 0.25:
		return -1

	var next_gear: int = current_gear
	if throttle > 0.0 and next_gear < 1:
		next_gear = 1

	if next_gear < 1 or shift_timer > 0.0:
		return next_gear

	var throttle_ratio: float = clampf(throttle, 0.0, 1.0)
	var safe_lower_gear_rpm: float = lower_gear_rpm

	if brake > 0.0 and throttle_ratio <= 0.0 and forward_speed > 0.25 and next_gear > 1:
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
