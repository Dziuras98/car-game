extends RefCounted
class_name CarPerformanceIndexCalculator

const INDEX_SCALE: float = 1000.0
const STEP_METERS: float = 1.0
const MIN_SPEED_SUM: float = 0.000001
const MIN_CVT_RATIO: float = 0.01

# Frozen DPI v1 normalization. These are the three benchmark times produced by
# the reference 2016 Nissan 370Z 7AT configuration when the model was defined.
const REFERENCE_TECHNICAL_TIME: float = 87.923473
const REFERENCE_MIXED_TIME: float = 117.032444
const REFERENCE_FAST_TIME: float = 128.254370

const TECHNICAL_WEIGHT: float = 0.35
const MIXED_WEIGHT: float = 0.40
const FAST_WEIGHT: float = 0.25

# Vector2(length_metres, corner_radius_metres). A zero radius denotes a straight.
const TECHNICAL_COURSE := [
	Vector2(120.0, 0.0),
	Vector2(75.0, 30.0),
	Vector2(90.0, 0.0),
	Vector2(110.0, 45.0),
	Vector2(65.0, 22.0),
	Vector2(160.0, 0.0),
	Vector2(95.0, 38.0),
	Vector2(70.0, 26.0),
	Vector2(210.0, 0.0),
	Vector2(130.0, 55.0),
	Vector2(85.0, 32.0),
	Vector2(180.0, 0.0),
	Vector2(70.0, 24.0),
	Vector2(120.0, 42.0),
	Vector2(260.0, 0.0),
]

const MIXED_COURSE := [
	Vector2(260.0, 0.0),
	Vector2(140.0, 80.0),
	Vector2(320.0, 0.0),
	Vector2(110.0, 48.0),
	Vector2(220.0, 0.0),
	Vector2(190.0, 110.0),
	Vector2(420.0, 0.0),
	Vector2(95.0, 42.0),
	Vector2(180.0, 0.0),
	Vector2(240.0, 140.0),
	Vector2(520.0, 0.0),
	Vector2(125.0, 62.0),
	Vector2(300.0, 0.0),
	Vector2(180.0, 95.0),
	Vector2(650.0, 0.0),
]

const FAST_COURSE := [
	Vector2(700.0, 0.0),
	Vector2(230.0, 180.0),
	Vector2(950.0, 0.0),
	Vector2(160.0, 95.0),
	Vector2(1200.0, 0.0),
	Vector2(300.0, 240.0),
	Vector2(850.0, 0.0),
	Vector2(180.0, 120.0),
	Vector2(1500.0, 0.0),
]


static func calculate(specs: CarSpecs) -> int:
	if specs == null or not specs.is_valid():
		return 0

	var technical_time: float = _calculate_course_time(specs, TECHNICAL_COURSE)
	var mixed_time: float = _calculate_course_time(specs, MIXED_COURSE)
	var fast_time: float = _calculate_course_time(specs, FAST_COURSE)
	if (
		not is_finite(technical_time)
		or not is_finite(mixed_time)
		or not is_finite(fast_time)
		or technical_time <= 0.0
		or mixed_time <= 0.0
		or fast_time <= 0.0
	):
		return 0

	var combined_ratio: float = (
		pow(REFERENCE_TECHNICAL_TIME / technical_time, TECHNICAL_WEIGHT)
		* pow(REFERENCE_MIXED_TIME / mixed_time, MIXED_WEIGHT)
		* pow(REFERENCE_FAST_TIME / fast_time, FAST_WEIGHT)
	)
	if not is_finite(combined_ratio) or combined_ratio <= 0.0:
		return 0
	return maxi(roundi(INDEX_SCALE * combined_ratio), 1)


static func _calculate_course_time(specs: CarSpecs, segments: Array) -> float:
	var samples: Dictionary = _build_course_samples(specs, segments)
	var speed_limits: PackedFloat64Array = samples["speed_limits"]
	var radii: PackedFloat64Array = samples["radii"]
	if speed_limits.size() < 2 or speed_limits.size() != radii.size():
		return INF

	var speed_profile: PackedFloat64Array = speed_limits.duplicate()
	var longitudinal_capacity: float = specs.longitudinal_grip_coefficient * specs.gravity
	for sample_index: int in range(speed_profile.size() - 2, -1, -1):
		var current_speed: float = minf(speed_profile[sample_index], specs.max_forward_speed)
		var friction_factor: float = _get_remaining_longitudinal_factor(
			specs,
			current_speed,
			radii[sample_index]
		)
		var braking_deceleration: float = (
			minf(specs.brake_deceleration, longitudinal_capacity) * friction_factor
			+ _get_resistance_acceleration(specs, current_speed)
		)
		var reachable_speed: float = sqrt(maxf(
			0.0,
			speed_profile[sample_index + 1] * speed_profile[sample_index + 1]
			+ 2.0 * braking_deceleration * STEP_METERS
		))
		speed_profile[sample_index] = minf(speed_profile[sample_index], reachable_speed)

	var elapsed_time: float = 0.0
	var previous_gear: int = 0
	for sample_index: int in range(speed_profile.size() - 1):
		var current_speed: float = speed_profile[sample_index]
		var drive_state: Vector2 = _get_best_drive_state(specs, current_speed)
		var selected_gear: int = roundi(drive_state.y)
		var friction_factor: float = _get_remaining_longitudinal_factor(
			specs,
			current_speed,
			radii[sample_index]
		)
		var resistance_acceleration: float = _get_resistance_acceleration(specs, current_speed)
		var traction_limited_acceleration: float = (
			longitudinal_capacity * friction_factor - resistance_acceleration
		)
		var net_acceleration: float = maxf(
			0.0,
			minf(drive_state.x - resistance_acceleration, traction_limited_acceleration)
		)
		var reachable_speed: float = sqrt(maxf(
			0.0,
			current_speed * current_speed + 2.0 * net_acceleration * STEP_METERS
		))
		speed_profile[sample_index + 1] = minf(
			speed_profile[sample_index + 1],
			reachable_speed
		)

		var next_speed: float = speed_profile[sample_index + 1]
		var speed_sum: float = current_speed + next_speed
		if speed_sum <= MIN_SPEED_SUM:
			return INF
		elapsed_time += 2.0 * STEP_METERS / speed_sum
		if previous_gear > 0 and selected_gear > previous_gear:
			elapsed_time += _get_shift_delay(specs)
		previous_gear = selected_gear

	return elapsed_time


static func _build_course_samples(specs: CarSpecs, segments: Array) -> Dictionary:
	var speed_limits: PackedFloat64Array = PackedFloat64Array([0.0])
	var radii: PackedFloat64Array = PackedFloat64Array([0.0])
	var lateral_capacity: float = _get_lateral_capacity(specs)
	for segment_value: Variant in segments:
		var segment: Vector2 = segment_value as Vector2
		var sample_count: int = maxi(ceili(segment.x / STEP_METERS), 1)
		var speed_limit: float = specs.max_forward_speed
		if segment.y > 0.0:
			speed_limit = minf(speed_limit, sqrt(lateral_capacity * segment.y))
		for _sample_index: int in range(sample_count):
			speed_limits.append(speed_limit)
			radii.append(segment.y)
	if not speed_limits.is_empty():
		speed_limits[speed_limits.size() - 1] = 0.0
	return {
		"speed_limits": speed_limits,
		"radii": radii,
	}


static func _get_best_drive_state(specs: CarSpecs, speed: float) -> Vector2:
	if specs.is_cvt_transmission():
		return Vector2(_get_cvt_drive_acceleration(specs, speed), 0.0)
	if not specs.uses_discrete_gears():
		return Vector2(minf(specs.engine_force, specs.max_drive_acceleration), 0.0)

	var best_acceleration: float = 0.0
	var best_gear: int = 1
	var wheel_rpm: float = _get_wheel_rpm(specs, speed)
	for gear_index: int in range(specs.gear_ratios.size()):
		var gear_ratio: float = specs.gear_ratios[gear_index]
		var engine_rpm: float = maxf(
			specs.idle_rpm,
			wheel_rpm * gear_ratio * specs.final_drive_ratio
		)
		if engine_rpm > specs.rev_limiter_rpm:
			continue
		var torque_multiplier: float = _sample_torque_multiplier(specs, engine_rpm)
		var converter_multiplier: float = _get_torque_converter_multiplier(specs, engine_rpm)
		var engine_torque: float = (
			specs.peak_engine_torque
			* torque_multiplier
			* _get_rev_limiter_multiplier(specs, engine_rpm)
			* converter_multiplier
		)
		var wheel_force: float = (
			engine_torque
			* gear_ratio
			* specs.final_drive_ratio
			* specs.drivetrain_efficiency
			/ specs.wheel_radius
		)
		var acceleration: float = minf(
			wheel_force / specs.vehicle_mass,
			specs.max_drive_acceleration
		)
		if acceleration > best_acceleration:
			best_acceleration = acceleration
			best_gear = gear_index + 1
	return Vector2(best_acceleration, float(best_gear))


static func _get_cvt_drive_acceleration(specs: CarSpecs, speed: float) -> float:
	var wheel_rpm: float = _get_wheel_rpm(specs, speed)
	var target_rpm: float = specs.cvt_target_rpm_max
	var ratio: float = specs.cvt_max_ratio
	if wheel_rpm > 0.01:
		ratio = target_rpm / (wheel_rpm * specs.final_drive_ratio)
	ratio = clampf(ratio, MIN_CVT_RATIO, specs.cvt_max_ratio)
	var engine_rpm: float = maxf(
		specs.idle_rpm,
		maxf(target_rpm, wheel_rpm * ratio * specs.final_drive_ratio)
	)
	var clutch_span: float = maxf(
		specs.cvt_clutch_full_rpm - specs.cvt_clutch_engagement_rpm,
		1.0
	)
	var clutch_normalized: float = clampf(
		(engine_rpm - specs.cvt_clutch_engagement_rpm) / clutch_span,
		0.0,
		1.0
	)
	var clutch_factor: float = (
		clutch_normalized * clutch_normalized * (3.0 - 2.0 * clutch_normalized)
	)
	var engine_torque: float = (
		specs.peak_engine_torque
		* _sample_torque_multiplier(specs, engine_rpm)
		* _get_rev_limiter_multiplier(specs, engine_rpm)
		* clutch_factor
	)
	var wheel_force: float = (
		engine_torque
		* ratio
		* specs.final_drive_ratio
		* specs.drivetrain_efficiency
		/ specs.wheel_radius
	)
	return minf(wheel_force / specs.vehicle_mass, specs.max_drive_acceleration)


static func _get_remaining_longitudinal_factor(
	specs: CarSpecs,
	speed: float,
	corner_radius: float
) -> float:
	if corner_radius <= 0.0:
		return 1.0
	var lateral_capacity: float = _get_lateral_capacity(specs)
	var lateral_acceleration: float = speed * speed / corner_radius
	var lateral_use: float = clampf(lateral_acceleration / lateral_capacity, 0.0, 1.0)
	return sqrt(maxf(0.0, 1.0 - lateral_use * lateral_use))


static func _get_lateral_capacity(specs: CarSpecs) -> float:
	return maxf(minf(specs.front_lateral_grip, specs.rear_lateral_grip), 0.01)


static func _get_resistance_acceleration(specs: CarSpecs, speed: float) -> float:
	var aerodynamic_drag: float = (
		0.5
		* specs.air_density
		* specs.drag_coefficient
		* specs.frontal_area
		* speed
		* speed
		/ specs.vehicle_mass
	)
	var rolling_resistance: float = specs.rolling_resistance_coefficient * specs.gravity
	return aerodynamic_drag + rolling_resistance


static func _get_wheel_rpm(specs: CarSpecs, speed: float) -> float:
	return absf(speed) / (TAU * specs.wheel_radius) * 60.0


static func _sample_torque_multiplier(specs: CarSpecs, rpm: float) -> float:
	if specs.torque_curve != null:
		return specs.torque_curve.sample(rpm)
	var rpm_range: float = maxf(specs.redline_rpm - specs.idle_rpm, 1.0)
	var normalized_rpm: float = clampf((rpm - specs.idle_rpm) / rpm_range, 0.0, 1.0)
	var peak_rpm_ratio: float = clampf(
		(specs.peak_torque_rpm - specs.idle_rpm) / rpm_range,
		0.01,
		0.99
	)
	if normalized_rpm <= peak_rpm_ratio:
		var low_rpm_ratio: float = 0.34
		if normalized_rpm <= low_rpm_ratio:
			return lerpf(
				specs.low_rpm_torque_multiplier,
				specs.mid_rpm_torque_multiplier,
				_smoothstep(normalized_rpm / low_rpm_ratio)
			)
		return lerpf(
			specs.mid_rpm_torque_multiplier,
			1.0,
			_smoothstep((normalized_rpm - low_rpm_ratio) / (peak_rpm_ratio - low_rpm_ratio))
		)
	return lerpf(
		1.0,
		specs.redline_torque_multiplier,
		_smoothstep((normalized_rpm - peak_rpm_ratio) / (1.0 - peak_rpm_ratio))
	)


static func _get_rev_limiter_multiplier(specs: CarSpecs, rpm: float) -> float:
	if rpm < specs.redline_rpm:
		return 1.0
	var limiter_range: float = specs.rev_limiter_rpm - specs.redline_rpm
	if limiter_range <= 0.0:
		return 0.0
	return 1.0 - clampf((rpm - specs.redline_rpm) / limiter_range, 0.0, 1.0)


static func _get_torque_converter_multiplier(specs: CarSpecs, rpm: float) -> float:
	if not specs.is_automatic_transmission() or rpm >= specs.torque_converter_coupling_rpm:
		return 1.0
	var coupling_span: float = maxf(
		specs.torque_converter_coupling_rpm - specs.torque_converter_stall_rpm,
		1.0
	)
	var coupling: float = clampf(
		(rpm - specs.torque_converter_stall_rpm) / coupling_span,
		0.0,
		1.0
	)
	return lerpf(specs.torque_converter_stall_torque_multiplier, 1.0, coupling)


static func _get_shift_delay(specs: CarSpecs) -> float:
	return specs.automatic_shift_delay if specs.is_automatic_transmission() else specs.shift_delay


static func _smoothstep(value: float) -> float:
	var clamped_value: float = clampf(value, 0.0, 1.0)
	return clamped_value * clamped_value * (3.0 - 2.0 * clamped_value)
