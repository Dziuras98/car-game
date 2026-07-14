extends RefCounted
class_name SmgTransmissionModel

const DIRECTION_CHANGE_SPEED_THRESHOLD: float = 0.25

func get_requested_gear(
	current_gear: int,
	forward_gear_count: int,
	forward_speed: float,
	engine_rpm: float,
	throttle: float,
	brake: float,
	shift_timer: float,
	redline_rpm: float,
	upshift_rpm: float,
	downshift_rpm: float,
	lower_gear_rpm: float,
	auto_mode: bool,
	gear_up_pressed: bool,
	gear_down_pressed: bool
) -> int:
	if forward_gear_count <= 0 or shift_timer > 0.0:
		return current_gear
	if gear_up_pressed:
		return mini(current_gear + 1, forward_gear_count)
	if gear_down_pressed:
		var requested: int = maxi(current_gear - 1, -1)
		if requested < 0 and absf(forward_speed) > DIRECTION_CHANGE_SPEED_THRESHOLD:
			return current_gear
		if requested > 0 and lower_gear_rpm >= redline_rpm * 0.985:
			return current_gear
		return requested
	if not auto_mode:
		return current_gear

	var safe_throttle: float = clampf(throttle, 0.0, 1.0)
	var safe_brake: float = clampf(brake, 0.0, 1.0)
	if safe_brake > 0.05 and safe_throttle <= 0.02:
		if current_gear < 0:
			return current_gear
		if absf(forward_speed) <= DIRECTION_CHANGE_SPEED_THRESHOLD:
			return -1
		if current_gear > 1 and lower_gear_rpm < redline_rpm * 0.985:
			return current_gear - 1
		return current_gear
	if safe_throttle > 0.02 and current_gear < 1:
		return 1 if absf(forward_speed) <= DIRECTION_CHANGE_SPEED_THRESHOLD else current_gear
	if current_gear < 1:
		return current_gear

	var dynamic_upshift: float = lerpf(upshift_rpm * 0.72, minf(redline_rpm * 0.985, upshift_rpm), safe_throttle)
	if engine_rpm >= dynamic_upshift and current_gear < forward_gear_count:
		return current_gear + 1
	var dynamic_downshift: float = downshift_rpm + safe_throttle * 750.0
	if engine_rpm <= dynamic_downshift and current_gear > 1 and lower_gear_rpm < redline_rpm * 0.985:
		return current_gear - 1
	return current_gear

func get_clutch_engagement(
	current_gear: int,
	forward_speed: float,
	throttle: float,
	shift_timer: float,
	shift_delay: float,
	launch_full_speed: float,
	reengage_point: float
) -> float:
	if current_gear == 0:
		return 0.0
	if shift_timer > 0.0:
		var progress: float = 1.0 - clampf(shift_timer / maxf(shift_delay, 0.001), 0.0, 1.0)
		if progress <= reengage_point:
			return 0.0
		var blend: float = inverse_lerp(reengage_point, 1.0, progress)
		return smoothstep(0.0, 1.0, blend)
	if current_gear < 0:
		return clampf(absf(forward_speed) / maxf(launch_full_speed, 0.25) + throttle * 0.25, 0.18, 1.0)
	var launch_speed_ratio: float = clampf(absf(forward_speed) / maxf(launch_full_speed, 0.25), 0.0, 1.0)
	var launch_throttle_bias: float = clampf(throttle, 0.0, 1.0) * 0.22
	return clampf(maxf(launch_speed_ratio, launch_throttle_bias), 0.16, 1.0)
