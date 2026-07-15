extends RefCounted
class_name TireModel

const STANDARD_GRAVITY: float = 9.80665
const MIN_ACCELERATION_CAPACITY: float = 0.0001
const FULL_SLIDE_DEMAND_RATIO: float = 2.5


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


func resolve_longitudinal_acceleration(
	requested_acceleration: float,
	lateral_grip_usage: float,
	surface_grip_multiplier: float,
	contact_factor: float,
	longitudinal_grip_coefficient: float,
	peak_slip_ratio: float,
	slide_grip_multiplier: float
) -> Vector2:
	var safe_contact_factor: float = clampf(contact_factor, 0.0, 1.0)
	if safe_contact_factor <= 0.0 or is_zero_approx(requested_acceleration):
		return Vector2.ZERO

	var peak_capacity: float = get_longitudinal_acceleration_capacity(
		lateral_grip_usage,
		surface_grip_multiplier,
		safe_contact_factor,
		longitudinal_grip_coefficient
	)
	if peak_capacity <= MIN_ACCELERATION_CAPACITY:
		return Vector2(0.0, signf(requested_acceleration) * maxf(peak_slip_ratio, 0.001))

	var requested_magnitude: float = absf(requested_acceleration)
	var demand_ratio: float = requested_magnitude / peak_capacity
	var safe_peak_slip_ratio: float = maxf(peak_slip_ratio, 0.001)
	var signed_slip_ratio: float = signf(requested_acceleration) * safe_peak_slip_ratio * demand_ratio
	if demand_ratio <= 1.0:
		return Vector2(requested_acceleration, signed_slip_ratio)

	var sliding_capacity_multiplier: float = _get_post_peak_capacity_multiplier(
		demand_ratio,
		slide_grip_multiplier
	)
	var applied_magnitude: float = minf(requested_magnitude, peak_capacity * sliding_capacity_multiplier)
	return Vector2(signf(requested_acceleration) * applied_magnitude, signed_slip_ratio)


func resolve_longitudinal_acceleration_from_slip(
	slip_ratio: float,
	lateral_grip_usage: float,
	surface_grip_multiplier: float,
	contact_factor: float,
	longitudinal_grip_coefficient: float,
	peak_slip_ratio: float,
	slide_grip_multiplier: float
) -> float:
	var safe_contact_factor: float = clampf(contact_factor, 0.0, 1.0)
	if safe_contact_factor <= 0.0 or is_zero_approx(slip_ratio):
		return 0.0
	var peak_capacity: float = get_longitudinal_acceleration_capacity(
		lateral_grip_usage,
		surface_grip_multiplier,
		safe_contact_factor,
		longitudinal_grip_coefficient
	)
	if peak_capacity <= MIN_ACCELERATION_CAPACITY:
		return 0.0
	var normalized_slip: float = absf(slip_ratio) / maxf(peak_slip_ratio, 0.001)
	var capacity_multiplier: float = normalized_slip
	if normalized_slip > 1.0:
		capacity_multiplier = _get_post_peak_capacity_multiplier(
			normalized_slip,
			slide_grip_multiplier
		)
	return signf(slip_ratio) * peak_capacity * clampf(capacity_multiplier, 0.0, 1.0)


func get_longitudinal_acceleration_capacity(
	lateral_grip_usage: float,
	surface_grip_multiplier: float,
	contact_factor: float,
	longitudinal_grip_coefficient: float
) -> float:
	return (
		STANDARD_GRAVITY
		* maxf(longitudinal_grip_coefficient, 0.0)
		* get_longitudinal_grip_factor(lateral_grip_usage, surface_grip_multiplier)
		* clampf(contact_factor, 0.0, 1.0)
	)


func calculate_longitudinal_slip_intensity(slip_ratio: float, peak_slip_ratio: float) -> float:
	# This value participates in the lateral/longitudinal friction circle, so it
	# represents physical grip usage rather than a delayed visual-only onset.
	return clampf(
		absf(slip_ratio) / maxf(peak_slip_ratio, 0.001),
		0.0,
		1.0
	)


func calculate_longitudinal_grip_usage(
	slip_ratio: float,
	peak_slip_ratio: float,
	slide_grip_multiplier: float
) -> float:
	var normalized_slip: float = absf(slip_ratio) / maxf(peak_slip_ratio, 0.001)
	if normalized_slip <= 1.0:
		return clampf(normalized_slip, 0.0, 1.0)
	return clampf(
		_get_post_peak_capacity_multiplier(normalized_slip, slide_grip_multiplier),
		0.0,
		1.0
	)


func calculate_combined_slip_intensity(lateral_intensity: float, longitudinal_intensity: float) -> float:
	var lateral: float = clampf(lateral_intensity, 0.0, 1.0)
	var longitudinal: float = clampf(longitudinal_intensity, 0.0, 1.0)
	return clampf(sqrt(lateral * lateral + longitudinal * longitudinal), 0.0, 1.0)


func get_longitudinal_grip_factor(
	lateral_grip_usage: float,
	surface_grip_multiplier: float
) -> float:
	var lateral_usage: float = clampf(lateral_grip_usage, 0.0, 1.0)
	var friction_circle_factor: float = sqrt(maxf(1.0 - lateral_usage * lateral_usage, 0.0))
	return friction_circle_factor * clampf(surface_grip_multiplier, 0.05, 2.0)


func _get_post_peak_capacity_multiplier(
	normalized_demand_or_slip: float,
	slide_grip_multiplier: float
) -> float:
	var slide_progress: float = _smoothstep(
		clampf(
			(normalized_demand_or_slip - 1.0) / maxf(FULL_SLIDE_DEMAND_RATIO - 1.0, 0.001),
			0.0,
			1.0
		)
	)
	return lerpf(
		1.0,
		clampf(slide_grip_multiplier, 0.0, 1.0),
		slide_progress
	)


func _smoothstep(value: float) -> float:
	var clamped_value: float = clampf(value, 0.0, 1.0)
	return clamped_value * clamped_value * (3.0 - 2.0 * clamped_value)
