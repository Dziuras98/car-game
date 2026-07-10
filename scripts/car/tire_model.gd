extends RefCounted
class_name TireModel


func recover_lateral_speed(
	lateral_speed: float,
	lateral_grip: float,
	handbrake_lateral_grip_multiplier: float,
	handbrake_active: bool,
	delta: float,
	surface_grip_multiplier: float = 1.0
) -> float:
	var handbrake_multiplier: float = handbrake_lateral_grip_multiplier if handbrake_active else 1.0
	var active_lateral_grip: float = maxf(
		lateral_grip * handbrake_multiplier * clampf(surface_grip_multiplier, 0.05, 2.0),
		0.1
	)
	return move_toward(lateral_speed, 0.0, active_lateral_grip * maxf(delta, 0.0))


func calculate_slip_intensity(
	lateral_speed: float,
	forward_speed: float,
	steering: float,
	steering_slip_gain: float,
	slip_speed_threshold: float,
	max_forward_speed: float,
	handbrake_active: bool
) -> float:
	var absolute_forward_speed: float = absf(forward_speed)
	var lateral_ratio: float = absf(lateral_speed) / maxf(slip_speed_threshold, 0.1)
	var steering_load: float = absf(steering) * absolute_forward_speed * steering_slip_gain / maxf(max_forward_speed, 1.0)
	var handbrake_bonus: float = 0.35 if handbrake_active and absolute_forward_speed > 4.0 else 0.0
	return clampf(lateral_ratio + steering_load + handbrake_bonus, 0.0, 1.0)


func get_longitudinal_grip_factor(
	slip_intensity: float,
	surface_grip_multiplier: float
) -> float:
	var lateral_usage: float = clampf(slip_intensity, 0.0, 1.0)
	var friction_circle_factor: float = sqrt(maxf(1.0 - lateral_usage * lateral_usage, 0.0))
	return friction_circle_factor * clampf(surface_grip_multiplier, 0.05, 2.0)
