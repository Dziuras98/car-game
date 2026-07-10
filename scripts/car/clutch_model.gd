extends RefCounted
class_name ClutchModel

const LOW_SPEED_FULL_ENGAGEMENT: float = 3.0
const MIN_LAUNCH_ENGAGEMENT: float = 0.28
const ENGAGE_RATE: float = 4.5
const DISENGAGE_RATE: float = 12.0


func update_engagement(
	current_engagement: float,
	current_gear: int,
	forward_speed: float,
	throttle: float,
	shift_timer: float,
	delta: float
) -> float:
	var target: float = get_target_engagement(
		current_gear,
		forward_speed,
		throttle,
		shift_timer
	)
	var rate: float = DISENGAGE_RATE if target < current_engagement else ENGAGE_RATE
	return move_toward(
		clampf(current_engagement, 0.0, 1.0),
		target,
		rate * maxf(delta, 0.0)
	)


func get_target_engagement(
	current_gear: int,
	forward_speed: float,
	throttle: float,
	shift_timer: float
) -> float:
	if current_gear == 0 or shift_timer > 0.0:
		return 0.0
	var speed_ratio: float = clampf(absf(forward_speed) / LOW_SPEED_FULL_ENGAGEMENT, 0.0, 1.0)
	var launch_engagement: float = lerpf(
		MIN_LAUNCH_ENGAGEMENT,
		0.62,
		clampf(throttle, 0.0, 1.0)
	)
	return lerpf(launch_engagement, 1.0, speed_ratio)


func get_transmitted_torque_factor(engagement: float) -> float:
	var safe_engagement: float = clampf(engagement, 0.0, 1.0)
	return safe_engagement * safe_engagement
