extends RefCounted
class_name ManualTransmissionModel

const DIRECTION_CHANGE_SPEED_THRESHOLD: float = 0.5


func get_requested_gear(
	current_gear: int,
	forward_gear_count: int,
	gear_up_pressed: bool,
	gear_down_pressed: bool
) -> int:
	var next_gear: int = current_gear

	if gear_up_pressed:
		next_gear = mini(next_gear + 1, forward_gear_count)

	if gear_down_pressed:
		next_gear = maxi(next_gear - 1, -1)

	return next_gear


func is_shift_safe(
	requested_gear: int,
	forward_speed: float,
	requested_gear_rpm: float,
	rev_limiter_rpm: float
) -> bool:
	if requested_gear < 0:
		return forward_speed <= DIRECTION_CHANGE_SPEED_THRESHOLD
	if requested_gear > 0:
		if forward_speed < -DIRECTION_CHANGE_SPEED_THRESHOLD:
			return false
		return requested_gear_rpm <= maxf(rev_limiter_rpm, 0.0)
	return true
