extends RefCounted
class_name LateralTireDynamicsModel

const MIN_REFERENCE_SPEED_MPS: float = 0.25
const MAX_STEERING_ANGLE_RAD: float = PI * 0.305555556
const MAX_SLIP_ANGLE_RAD: float = PI * 0.49
const FULL_SLIDE_SLIP_RATIO: float = 3.0
const DEFAULT_LATERAL_SLIDE_GRIP_MULTIPLIER: float = 0.92


func get_ackermann_steering_angles(
	steering_input: float,
	max_steering_angle_degrees: float,
	wheel_base_m: float,
	front_track_width_m: float
) -> Vector2:
	var safe_input: float = clampf(steering_input, -1.0, 1.0)
	if absf(safe_input) <= 0.0001:
		return Vector2.ZERO
	var center_angle: float = clampf(
		deg_to_rad(maxf(max_steering_angle_degrees, 0.01)) * safe_input,
		-MAX_STEERING_ANGLE_RAD,
		MAX_STEERING_ANGLE_RAD
	)
	var safe_wheel_base: float = maxf(wheel_base_m, 0.10)
	var half_track: float = maxf(front_track_width_m, 0.10) * 0.5
	var turn_radius: float = safe_wheel_base / maxf(tan(absf(center_angle)), 0.0001)
	var inner_angle: float = atan(safe_wheel_base / maxf(turn_radius - half_track, 0.05))
	var outer_angle: float = atan(safe_wheel_base / maxf(turn_radius + half_track, 0.05))
	if center_angle > 0.0:
		return Vector2(outer_angle, inner_angle)
	return Vector2(-inner_angle, -outer_angle)


func get_wheel_forward_offset_m(config: CarDriveConfig, wheel_index: int) -> float:
	var safe_wheel_base: float = maxf(config.wheel_base, 0.10)
	if wheel_index == WheelTireState.Position.FRONT_LEFT or wheel_index == WheelTireState.Position.FRONT_RIGHT:
		return safe_wheel_base * (1.0 - config.front_static_load_fraction)
	return -safe_wheel_base * config.front_static_load_fraction


func get_wheel_lateral_offset_m(config: CarDriveConfig, wheel_index: int) -> float:
	var track_width: float = (
		config.front_axle_track_width
		if wheel_index == WheelTireState.Position.FRONT_LEFT or wheel_index == WheelTireState.Position.FRONT_RIGHT
		else config.rear_axle_track_width
	)
	var side: float = -1.0 if wheel_index == WheelTireState.Position.FRONT_LEFT or wheel_index == WheelTireState.Position.REAR_LEFT else 1.0
	return side * maxf(track_width, 0.10) * 0.5


func get_wheel_local_velocity(
	forward_speed_mps: float,
	lateral_speed_mps: float,
	yaw_rate_rad_s: float,
	forward_offset_m: float,
	lateral_offset_m: float
) -> Vector2:
	return Vector2(
		forward_speed_mps - yaw_rate_rad_s * lateral_offset_m,
		lateral_speed_mps + yaw_rate_rad_s * forward_offset_m
	)


func calculate_slip_angle_rad(
	wheel_forward_speed_mps: float,
	wheel_lateral_speed_mps: float,
	steering_angle_rad: float
) -> float:
	var wheel_speed_mps: float = Vector2(
		wheel_forward_speed_mps,
		wheel_lateral_speed_mps
	).length()
	if wheel_speed_mps <= MIN_REFERENCE_SPEED_MPS:
		return 0.0
	var travel_direction: float = 1.0 if wheel_forward_speed_mps >= 0.0 else -1.0
	var velocity_angle: float = atan2(
		wheel_lateral_speed_mps,
		maxf(absf(wheel_forward_speed_mps), MIN_REFERENCE_SPEED_MPS)
	)
	return clampf(
		velocity_angle - steering_angle_rad * travel_direction,
		-MAX_SLIP_ANGLE_RAD,
		MAX_SLIP_ANGLE_RAD
	)


func get_peak_slip_angle_rad(
	lateral_grip_mps2: float,
	tire_width_m: float,
	steering_response_gain: float
) -> float:
	var width_factor: float = clampf(0.205 / maxf(tire_width_m, 0.10), 0.80, 1.25)
	var grip_factor: float = clampf(9.0 / maxf(lateral_grip_mps2, 1.0), 0.80, 1.20)
	var response_factor: float = 1.0 / clampf(steering_response_gain, 0.65, 1.35)
	var peak_degrees: float = clampf(
		6.5 * width_factor * grip_factor * response_factor,
		4.0,
		10.0
	)
	return deg_to_rad(peak_degrees)


func resolve_lateral_acceleration(
	slip_angle_rad: float,
	wheel_forward_speed_mps: float,
	load_share: float,
	lateral_grip_mps2: float,
	surface_grip_multiplier: float,
	longitudinal_slip_intensity: float,
	peak_slip_angle_rad: float,
	handbrake_grip_multiplier: float = 1.0
) -> float:
	if is_zero_approx(slip_angle_rad) or load_share <= 0.0:
		return 0.0
	var forward_speed_factor: float = absf(wheel_forward_speed_mps) / (
		absf(wheel_forward_speed_mps) + MIN_REFERENCE_SPEED_MPS
	)
	# Near a perpendicular slide the forward component can approach zero even
	# while the tire contact patch is moving quickly. Preserve lateral recovery
	# from the slip angle instead of treating that state as almost stationary.
	var sideways_motion_factor: float = absf(sin(slip_angle_rad))
	var speed_factor: float = maxf(forward_speed_factor, sideways_motion_factor)
	if speed_factor <= 0.0:
		return 0.0
	var combined_grip_factor: float = sqrt(
		maxf(1.0 - pow(clampf(longitudinal_slip_intensity, 0.0, 1.0), 2.0), 0.0)
	)
	var maximum_acceleration: float = (
		maxf(lateral_grip_mps2, 0.01)
		* clampf(surface_grip_multiplier, 0.05, 2.0)
		* clampf(load_share, 0.0, 1.0)
		* clampf(handbrake_grip_multiplier, 0.0, 1.0)
		* combined_grip_factor
		* speed_factor
	)
	var normalized_slip: float = absf(slip_angle_rad) / maxf(peak_slip_angle_rad, 0.001)
	var force_multiplier: float = normalized_slip
	if normalized_slip > 1.0:
		var slide_progress: float = _smoothstep(
			clampf(
				(normalized_slip - 1.0) / maxf(FULL_SLIDE_SLIP_RATIO - 1.0, 0.001),
				0.0,
				1.0
			)
		)
		force_multiplier = lerpf(
			1.0,
			DEFAULT_LATERAL_SLIDE_GRIP_MULTIPLIER,
			slide_progress
		)
	return -signf(slip_angle_rad) * maximum_acceleration * clampf(force_multiplier, 0.0, 1.0)


func calculate_lateral_slip_intensity(
	slip_angle_rad: float,
	peak_slip_angle_rad: float
) -> float:
	return clampf(
		absf(slip_angle_rad) / maxf(peak_slip_angle_rad * 1.5, 0.001),
		0.0,
		1.0
	)


func estimate_yaw_inertia_kg_m2(config: CarDriveConfig) -> float:
	var average_track: float = (
		maxf(config.front_axle_track_width, 0.10)
		+ maxf(config.rear_axle_track_width, 0.10)
	) * 0.5
	return maxf(
		config.vehicle_mass
		* (
			0.22 * config.wheel_base * config.wheel_base
			+ 0.05 * average_track * average_track
		),
		1.0
	)


func _smoothstep(value: float) -> float:
	var clamped_value: float = clampf(value, 0.0, 1.0)
	return clamped_value * clamped_value * (3.0 - 2.0 * clamped_value)
