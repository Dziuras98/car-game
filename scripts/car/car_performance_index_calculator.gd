extends RefCounted
class_name CarPerformanceIndexCalculator

const INDEX_SCALE: float = 1000.0
const STEP_METERS: float = 1.0
const MIN_SPEED_SUM: float = 0.000001
const MIN_CVT_RATIO: float = 0.01
const ROLLING_RESISTANCE_GRAVITY: float = 9.81
const MIN_DYNAMIC_AXLE_LOAD_FRACTION: float = 0.10
const MAX_DYNAMIC_AXLE_LOAD_FRACTION: float = 0.90
const REFERENCE_FRONT_TIRE_WIDTH_M: float = 0.225
const REFERENCE_REAR_TIRE_WIDTH_M: float = 0.245
const REFERENCE_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")

static var _reference_course_times: Vector3 = Vector3.ZERO

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
	var course_times: Vector3 = calculate_course_times(specs)
	var reference_times: Vector3 = _get_reference_course_times()
	if not _are_valid_course_times(course_times) or not _are_valid_course_times(reference_times):
		return 0

	var combined_ratio: float = (
		pow(reference_times.x / course_times.x, TECHNICAL_WEIGHT)
		* pow(reference_times.y / course_times.y, MIXED_WEIGHT)
		* pow(reference_times.z / course_times.z, FAST_WEIGHT)
	)
	if not is_finite(combined_ratio) or combined_ratio <= 0.0:
		return 0
	return maxi(roundi(INDEX_SCALE * combined_ratio), 1)


static func calculate_course_times(specs: CarSpecs) -> Vector3:
	if specs == null or not specs.is_valid():
		return Vector3(INF, INF, INF)
	return Vector3(
		_calculate_course_time(specs, TECHNICAL_COURSE),
		_calculate_course_time(specs, MIXED_COURSE),
		_calculate_course_time(specs, FAST_COURSE)
	)


static func _get_reference_course_times() -> Vector3:
	if not _are_valid_course_times(_reference_course_times):
		_reference_course_times = calculate_course_times(REFERENCE_SPECS)
	return _reference_course_times


static func _are_valid_course_times(course_times: Vector3) -> bool:
	return (
		is_finite(course_times.x)
		and is_finite(course_times.y)
		and is_finite(course_times.z)
		and course_times.x > 0.0
		and course_times.y > 0.0
		and course_times.z > 0.0
	)


static func _calculate_course_time(specs: CarSpecs, segments: Array) -> float:
	var samples: Dictionary = _build_course_samples(specs, segments)
	var speed_limits: PackedFloat64Array = samples["speed_limits"]
	var radii: PackedFloat64Array = samples["radii"]
	if speed_limits.size() < 2 or speed_limits.size() != radii.size():
		return INF

	var speed_profile: PackedFloat64Array = speed_limits.duplicate()
	for sample_index: int in range(speed_profile.size() - 2, -1, -1):
		var current_speed: float = minf(speed_profile[sample_index], specs.max_forward_speed)
		var friction_factor: float = _get_remaining_longitudinal_factor(
			specs,
			current_speed,
			radii[sample_index]
		)
		var braking_deceleration: float = (
			_get_braking_acceleration(specs, specs.brake_deceleration, friction_factor)
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
		var drive_state: Vector3 = _get_best_drive_state(specs, current_speed)
		var selected_gear: int = roundi(drive_state.y)
		var friction_factor: float = _get_remaining_longitudinal_factor(
			specs,
			current_speed,
			radii[sample_index]
		)
		var resistance_acceleration: float = _get_resistance_acceleration(specs, current_speed)
		var traction_acceleration: float = _get_drive_traction_acceleration(
			specs,
			drive_state.z,
			friction_factor
		)
		var net_acceleration: float = maxf(
			0.0,
			minf(
				drive_state.x - resistance_acceleration,
				traction_acceleration - resistance_acceleration
			)
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


# Vector3(actual acceleration after rotating inertia, selected gear, requested
# chassis acceleration used by the runtime for torque split and load transfer).
static func _get_best_drive_state(specs: CarSpecs, speed: float) -> Vector3:
	if specs.is_cvt_transmission():
		var cvt_state: Vector2 = _get_cvt_drive_acceleration(specs, speed)
		return Vector3(cvt_state.x, 0.0, cvt_state.y)
	if not specs.uses_discrete_gears():
		var nominal_acceleration: float = minf(specs.engine_force, specs.max_drive_acceleration)
		return Vector3(
			_apply_rotational_inertia(specs, nominal_acceleration, 0.0, false),
			0.0,
			nominal_acceleration
		)

	var best_acceleration: float = 0.0
	var best_nominal_acceleration: float = 0.0
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
		var nominal_acceleration: float = minf(
			wheel_force / specs.vehicle_mass,
			specs.max_drive_acceleration
		)
		var acceleration: float = _apply_rotational_inertia(
			specs,
			nominal_acceleration,
			gear_ratio,
			true
		)
		if acceleration > best_acceleration:
			best_acceleration = acceleration
			best_nominal_acceleration = nominal_acceleration
			best_gear = gear_index + 1
	return Vector3(best_acceleration, float(best_gear), best_nominal_acceleration)


# Vector2(actual acceleration after rotating inertia, requested chassis acceleration).
static func _get_cvt_drive_acceleration(specs: CarSpecs, speed: float) -> Vector2:
	var wheel_rpm: float = _get_wheel_rpm(specs, speed)
	var target_rpm: float = specs.cvt_target_rpm_max
	var ratio: float = specs.cvt_max_ratio
	if wheel_rpm > 0.01:
		ratio = target_rpm / (wheel_rpm * specs.final_drive_ratio)
	var effective_min_ratio: float = specs.cvt_min_ratio if specs.cvt_min_ratio > 0.0 else MIN_CVT_RATIO
	ratio = clampf(ratio, effective_min_ratio, specs.cvt_max_ratio)
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
	var nominal_acceleration: float = minf(
		wheel_force / specs.vehicle_mass,
		specs.max_drive_acceleration
	)
	return Vector2(
		_apply_rotational_inertia(specs, nominal_acceleration, ratio, true),
		nominal_acceleration
	)


static func _get_drive_traction_acceleration(
	specs: CarSpecs,
	requested_acceleration: float,
	friction_factor: float
) -> float:
	if requested_acceleration <= 0.0:
		return 0.0
	var drive_fractions: Vector2 = _get_drive_axle_fractions(specs)
	var axle_capacity_scale: float = (
		TireModel.STANDARD_GRAVITY
		* specs.longitudinal_grip_coefficient
		* clampf(friction_factor, 0.0, 1.0)
	)
	var acceleration_estimate: float = requested_acceleration
	var resolved_acceleration: float = 0.0
	for _pass_index: int in range(2):
		var dynamic_front_fraction: float = _get_dynamic_front_load_fraction(
			specs,
			acceleration_estimate
		)
		resolved_acceleration = (
			_resolve_axle_longitudinal_acceleration(
				requested_acceleration * drive_fractions.x,
				axle_capacity_scale * dynamic_front_fraction,
				specs.longitudinal_slide_grip_multiplier,
				specs.traction_control_strength
			)
			+ _resolve_axle_longitudinal_acceleration(
				requested_acceleration * drive_fractions.y,
				axle_capacity_scale * (1.0 - dynamic_front_fraction),
				specs.longitudinal_slide_grip_multiplier,
				specs.traction_control_strength
			)
		)
		acceleration_estimate = resolved_acceleration
	return resolved_acceleration


static func _get_braking_acceleration(
	specs: CarSpecs,
	requested_deceleration: float,
	friction_factor: float
) -> float:
	if requested_deceleration <= 0.0:
		return 0.0
	var front_brake_fraction: float = clampf(specs.front_brake_bias, 0.0, 1.0)
	var axle_capacity_scale: float = (
		TireModel.STANDARD_GRAVITY
		* specs.longitudinal_grip_coefficient
		* clampf(friction_factor, 0.0, 1.0)
	)
	var deceleration_estimate: float = requested_deceleration
	var resolved_deceleration: float = 0.0
	for _pass_index: int in range(2):
		var dynamic_front_fraction: float = _get_dynamic_front_load_fraction(
			specs,
			-deceleration_estimate
		)
		resolved_deceleration = (
			_resolve_axle_longitudinal_acceleration(
				requested_deceleration * front_brake_fraction,
				axle_capacity_scale * dynamic_front_fraction,
				specs.longitudinal_slide_grip_multiplier,
				specs.abs_strength
			)
			+ _resolve_axle_longitudinal_acceleration(
				requested_deceleration * (1.0 - front_brake_fraction),
				axle_capacity_scale * (1.0 - dynamic_front_fraction),
				specs.longitudinal_slide_grip_multiplier,
				specs.abs_strength
			)
		)
		deceleration_estimate = resolved_deceleration
	return resolved_deceleration


static func _resolve_axle_longitudinal_acceleration(
	requested_acceleration: float,
	peak_capacity: float,
	slide_grip_multiplier: float,
	driver_aid_strength: float
) -> float:
	if requested_acceleration <= 0.0 or peak_capacity <= TireModel.MIN_ACCELERATION_CAPACITY:
		return 0.0
	var demand_ratio: float = requested_acceleration / peak_capacity
	if demand_ratio <= 1.0:
		return requested_acceleration
	var controlled_demand_ratio: float = lerpf(
		demand_ratio,
		1.0,
		clampf(driver_aid_strength, 0.0, 1.0)
	)
	var slide_progress: float = _smoothstep(
		(controlled_demand_ratio - 1.0)
		/ maxf(TireModel.FULL_SLIDE_DEMAND_RATIO - 1.0, 0.001)
	)
	var capacity_multiplier: float = lerpf(
		1.0,
		clampf(slide_grip_multiplier, 0.0, 1.0),
		slide_progress
	)
	return minf(requested_acceleration, peak_capacity * capacity_multiplier)


static func _get_drive_axle_fractions(specs: CarSpecs) -> Vector2:
	if specs.drive_layout == CarSpecs.DriveLayout.FRONT_WHEEL_DRIVE:
		return Vector2(1.0, 0.0)
	if specs.drive_layout == CarSpecs.DriveLayout.ALL_WHEEL_DRIVE:
		var front_fraction: float = clampf(specs.awd_front_torque_fraction, 0.0, 1.0)
		return Vector2(front_fraction, 1.0 - front_fraction)
	return Vector2(0.0, 1.0)


static func _get_dynamic_front_load_fraction(
	specs: CarSpecs,
	longitudinal_acceleration: float
) -> float:
	var transfer_fraction: float = (
		longitudinal_acceleration
		* specs.center_of_mass_height_m
		/ maxf(TireModel.STANDARD_GRAVITY * specs.wheel_base, 0.01)
	)
	return clampf(
		_get_front_static_load_fraction(specs) - transfer_fraction,
		MIN_DYNAMIC_AXLE_LOAD_FRACTION,
		MAX_DYNAMIC_AXLE_LOAD_FRACTION
	)


static func _get_front_static_load_fraction(specs: CarSpecs) -> float:
	var front_fraction: float = specs.front_static_load_fraction
	if front_fraction <= 0.0:
		if specs.drive_layout == CarSpecs.DriveLayout.FRONT_WHEEL_DRIVE:
			front_fraction = 0.62
		elif specs.drive_layout == CarSpecs.DriveLayout.ALL_WHEEL_DRIVE:
			front_fraction = 0.50
		else:
			front_fraction = 0.53
	return clampf(
		front_fraction,
		MIN_DYNAMIC_AXLE_LOAD_FRACTION,
		MAX_DYNAMIC_AXLE_LOAD_FRACTION
	)


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
	var front_grip: float = (
		specs.front_lateral_grip
		* sqrt(specs.front_tire_width_m / REFERENCE_FRONT_TIRE_WIDTH_M)
	)
	var rear_grip: float = (
		specs.rear_lateral_grip
		* sqrt(specs.rear_tire_width_m / REFERENCE_REAR_TIRE_WIDTH_M)
	)
	var front_fraction: float = _get_front_static_load_fraction(specs)
	return maxf(
		front_grip * front_fraction + rear_grip * (1.0 - front_fraction),
		0.01
	)


static func _apply_rotational_inertia(
	specs: CarSpecs,
	nominal_acceleration: float,
	transmission_ratio: float,
	include_engine_inertia: bool
) -> float:
	var effective_mass: float = _get_effective_vehicle_mass(
		specs,
		transmission_ratio,
		include_engine_inertia
	)
	return nominal_acceleration * specs.vehicle_mass / effective_mass


static func _get_effective_vehicle_mass(
	specs: CarSpecs,
	transmission_ratio: float,
	include_engine_inertia: bool
) -> float:
	var radius_squared: float = maxf(specs.wheel_radius * specs.wheel_radius, 0.0001)
	var front_inertia: float = _get_wheel_inertia(
		specs,
		specs.front_wheel_inertia_kg_m2,
		specs.front_tire_width_m
	)
	var rear_inertia: float = _get_wheel_inertia(
		specs,
		specs.rear_wheel_inertia_kg_m2,
		specs.rear_tire_width_m
	)
	var rotating_equivalent_mass: float = (
		2.0 * (front_inertia + rear_inertia) / radius_squared
	)
	if include_engine_inertia and transmission_ratio > 0.0:
		var engine_side_inertia: float = specs.engine_inertia_kg_m2
		if engine_side_inertia <= 0.0:
			engine_side_inertia = clampf(
				0.08 + specs.peak_engine_torque * 0.00028,
				0.10,
				0.24
			)
		var coupling: float = 0.65 if specs.is_torque_converter_automatic() else 1.0
		var active_ratio: float = transmission_ratio * specs.final_drive_ratio
		rotating_equivalent_mass += (
			engine_side_inertia
			* active_ratio
			* active_ratio
			* coupling
			/ radius_squared
		)
	return maxf(specs.vehicle_mass + rotating_equivalent_mass, 1.0)


static func _get_wheel_inertia(
	specs: CarSpecs,
	configured_inertia: float,
	tire_width_m: float
) -> float:
	if configured_inertia > 0.0:
		return configured_inertia
	var effective_rotating_mass_kg: float = clampf(
		11.0 + tire_width_m * 45.0 + specs.wheel_radius * 8.0,
		12.0,
		34.0
	)
	return effective_rotating_mass_kg * specs.wheel_radius * specs.wheel_radius * 0.65


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
	var rolling_resistance: float = (
		specs.rolling_resistance_coefficient * ROLLING_RESISTANCE_GRAVITY
	)
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
	if not specs.is_torque_converter_automatic() or rpm >= specs.torque_converter_coupling_rpm:
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
