extends Resource
class_name CarSpecs

const MIN_SUSPENSION_SUPPORT_RESERVE: float = 1.10

enum TransmissionType {
	DIRECT_DRIVE,
	MANUAL,
	AUTOMATIC,
	CVT,
}

@export_group("Identity")
@export var display_name: String = "Car"

@export_group("Driving")
@export var brake_deceleration: float = 34.0
@export var reverse_acceleration: float = 12.0
@export var coast_deceleration: float = 5.0
@export var handbrake_deceleration: float = 18.0
@export var max_forward_speed: float = 30.0
@export var max_reverse_speed: float = 10.0
@export var steering_speed: float = 2.7
@export var wheel_base: float = 2.65
@export var front_axle_track_width: float = 1.55
@export var rear_axle_track_width: float = 1.55
@export var max_steering_angle_degrees: float = 32.0

@export_group("Engine")
@export var idle_rpm: float = 900.0
@export var peak_torque_rpm: float = 4200.0
@export var power_peak_rpm: float = 6200.0
@export var redline_rpm: float = 6500.0
@export var rev_limiter_rpm: float = 6800.0
@export var torque_curve: EngineTorqueCurve
@export var low_rpm_torque_multiplier: float = 0.42
@export var mid_rpm_torque_multiplier: float = 0.82
@export var redline_torque_multiplier: float = 0.72
@export var engine_force: float = 30.0
@export var engine_brake_force: float = 3.0
@export var rpm_response: float = 8.0

@export_group("Audio")
@export var engine_audio_profile: EngineAudioProfile

@export_group("Transmission")
@export_enum("Direct Drive", "Manual", "Automatic", "CVT") var transmission_type: int = TransmissionType.DIRECT_DRIVE
@export var gear_ratios: Array[float] = [3.20, 2.10, 1.50, 1.15, 0.92, 0.75]
@export var reverse_gear_ratio: float = 3.00
@export var final_drive_ratio: float = 3.70
@export var peak_engine_torque: float = 420.0
@export var wheel_radius: float = 0.34
@export var drivetrain_efficiency: float = 0.85
@export var shift_delay: float = 0.28
@export var max_drive_acceleration: float = 100.0

@export_group("Automatic Transmission")
@export var automatic_upshift_rpm: float = 6200.0
@export var automatic_downshift_rpm: float = 2100.0
@export var automatic_kickdown_throttle: float = 0.82
@export var automatic_kickdown_rpm: float = 5200.0
@export var automatic_shift_delay: float = 0.22
@export var torque_converter_stall_rpm: float = 2600.0
@export var torque_converter_coupling_rpm: float = 4200.0
@export var torque_converter_stall_torque_multiplier: float = 1.65

@export_group("Automated Manual / SMG")
@export var smg_enabled: bool = false
@export var smg_auto_mode: bool = true
@export var smg_shift_delay: float = 0.22
@export var smg_launch_full_speed: float = 4.0
@export var smg_upshift_rpm: float = 6100.0
@export var smg_downshift_rpm: float = 1800.0
@export_range(0.0, 1.0, 0.01) var smg_clutch_reengage_point: float = 0.48

@export_group("Continuously Variable Transmission")
@export var cvt_max_ratio: float = 2.50
@export var cvt_target_rpm_min: float = 1800.0
@export var cvt_target_rpm_max: float = 5500.0
@export var cvt_ratio_response: float = 8.0
@export var cvt_clutch_engagement_rpm: float = 1250.0
@export var cvt_clutch_full_rpm: float = 2200.0

@export_group("Resistance")
@export var vehicle_mass: float = 1200.0
@export var drag_coefficient: float = 0.30
@export var frontal_area: float = 2.05
@export var air_density: float = 1.225
@export var rolling_resistance_coefficient: float = 0.015

@export_group("Tires")
@export var front_lateral_grip: float = 10.0
@export var rear_lateral_grip: float = 10.0
@export var front_tire_width_m: float = 0.225
@export var rear_tire_width_m: float = 0.245
@export var longitudinal_grip_coefficient: float = 1.05
@export var longitudinal_peak_slip_ratio: float = 0.12
@export_range(0.0, 1.0, 0.01) var longitudinal_slide_grip_multiplier: float = 0.78
@export var handbrake_lateral_grip_multiplier: float = 0.28
@export var steering_slip_gain: float = 0.85
@export var slip_speed_threshold: float = 2.2
@export var slip_steering_lock_threshold: float = 0.55
@export var slip_steering_same_direction_multiplier: float = 0.12
@export var skid_mark_min_slip: float = 0.45
@export var skid_mark_interval: float = 0.055
@export var skid_mark_lifetime: float = 10.0
@export var skid_mark_width: float = 0.22
@export var skid_mark_length: float = 0.9

@export_group("Grounding")
@export var gravity: float = 30.0
@export var floor_stick_force: float = 0.5
@export var suspension_probe_height: float = 0.42
@export var suspension_rest_length: float = 0.28
@export var suspension_travel: float = 0.18
@export var suspension_stiffness: float = 32.0
@export var suspension_damping: float = 5.0
@export var ground_probe_collision_mask: int = 1
@export_range(0.0, 1.0, 0.01) var minimum_ground_normal_dot: float = 0.35

func is_manual_transmission() -> bool:
	return transmission_type == TransmissionType.MANUAL

func is_automatic_transmission() -> bool:
	return transmission_type == TransmissionType.AUTOMATIC

func is_smg_transmission() -> bool:
	return is_automatic_transmission() and smg_enabled

func is_torque_converter_automatic() -> bool:
	return is_automatic_transmission() and not smg_enabled

func is_cvt_transmission() -> bool:
	return transmission_type == TransmissionType.CVT

func is_self_shifting_transmission() -> bool:
	return is_automatic_transmission() or is_cvt_transmission()

func uses_discrete_gears() -> bool:
	return is_manual_transmission() or is_automatic_transmission()

func uses_geared_transmission() -> bool:
	return uses_discrete_gears() or is_cvt_transmission()

func is_valid() -> bool:
	return validate().is_empty()

func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if display_name.strip_edges().is_empty(): errors.append("display_name must not be empty")
	_append_positive(errors, "brake_deceleration", brake_deceleration)
	_append_non_negative(errors, "reverse_acceleration", reverse_acceleration)
	_append_non_negative(errors, "coast_deceleration", coast_deceleration)
	_append_non_negative(errors, "handbrake_deceleration", handbrake_deceleration)
	_append_positive(errors, "max_forward_speed", max_forward_speed)
	_append_non_negative(errors, "max_reverse_speed", max_reverse_speed)
	_append_positive(errors, "steering_speed", steering_speed)
	_append_positive(errors, "wheel_base", wheel_base)
	_append_positive(errors, "front_axle_track_width", front_axle_track_width)
	_append_positive(errors, "rear_axle_track_width", rear_axle_track_width)
	_append_range(errors, "max_steering_angle_degrees", max_steering_angle_degrees, 0.01, 89.0)

	_append_positive(errors, "idle_rpm", idle_rpm)
	_append_positive(errors, "peak_torque_rpm", peak_torque_rpm)
	_append_positive(errors, "power_peak_rpm", power_peak_rpm)
	_append_positive(errors, "redline_rpm", redline_rpm)
	_append_positive(errors, "rev_limiter_rpm", rev_limiter_rpm)
	if peak_torque_rpm <= idle_rpm: errors.append("peak_torque_rpm must be above idle_rpm")
	if power_peak_rpm < peak_torque_rpm: errors.append("power_peak_rpm must be at or above peak_torque_rpm")
	if power_peak_rpm > redline_rpm: errors.append("power_peak_rpm must not exceed redline_rpm")
	if redline_rpm < peak_torque_rpm: errors.append("redline_rpm must be at or above peak_torque_rpm")
	if rev_limiter_rpm < redline_rpm: errors.append("rev_limiter_rpm must be at or above redline_rpm")
	if torque_curve != null:
		for curve_error: String in torque_curve.validate(): errors.append("torque_curve: %s" % curve_error)
	if engine_audio_profile != null:
		for audio_error: String in engine_audio_profile.validate(): errors.append("engine_audio_profile: %s" % audio_error)
	_append_non_negative(errors, "low_rpm_torque_multiplier", low_rpm_torque_multiplier)
	_append_non_negative(errors, "mid_rpm_torque_multiplier", mid_rpm_torque_multiplier)
	_append_non_negative(errors, "redline_torque_multiplier", redline_torque_multiplier)
	_append_non_negative(errors, "engine_force", engine_force)
	_append_non_negative(errors, "engine_brake_force", engine_brake_force)
	_append_positive(errors, "rpm_response", rpm_response)

	if transmission_type < TransmissionType.DIRECT_DRIVE or transmission_type > TransmissionType.CVT:
		errors.append("transmission_type is invalid")
	if smg_enabled and not is_automatic_transmission():
		errors.append("smg_enabled requires AUTOMATIC transmission_type")
	if uses_discrete_gears() and gear_ratios.is_empty(): errors.append("gear_ratios must contain at least one forward gear")
	for gear_index: int in range(gear_ratios.size()):
		_append_positive(errors, "gear_ratios[%d]" % gear_index, gear_ratios[gear_index])
		if uses_discrete_gears() and gear_index > 0 and gear_ratios[gear_index] >= gear_ratios[gear_index - 1]:
			errors.append("gear_ratios must be strictly descending")
	_append_positive(errors, "reverse_gear_ratio", reverse_gear_ratio)
	_append_positive(errors, "final_drive_ratio", final_drive_ratio)
	_append_positive(errors, "peak_engine_torque", peak_engine_torque)
	_append_positive(errors, "wheel_radius", wheel_radius)
	_append_range(errors, "drivetrain_efficiency", drivetrain_efficiency, 0.0001, 1.0)
	_append_non_negative(errors, "shift_delay", shift_delay)
	_append_positive(errors, "max_drive_acceleration", max_drive_acceleration)
	if uses_discrete_gears() and not gear_ratios.is_empty():
		var highest_gear_ratio: float = gear_ratios[gear_ratios.size() - 1]
		var theoretical_speed: float = rev_limiter_rpm / (highest_gear_ratio * final_drive_ratio) * TAU * wheel_radius / 60.0
		if max_forward_speed > theoretical_speed * 1.05:
			errors.append("max_forward_speed exceeds the rev-limited highest-gear speed")

	if is_automatic_transmission():
		_append_positive(errors, "automatic_upshift_rpm", automatic_upshift_rpm)
		_append_positive(errors, "automatic_downshift_rpm", automatic_downshift_rpm)
		if automatic_downshift_rpm >= automatic_upshift_rpm: errors.append("automatic_downshift_rpm must be below automatic_upshift_rpm")
		if automatic_downshift_rpm < idle_rpm: errors.append("automatic_downshift_rpm must be at or above idle_rpm")
		if automatic_upshift_rpm > redline_rpm: errors.append("automatic_upshift_rpm must not exceed redline_rpm")
		_append_range(errors, "automatic_kickdown_throttle", automatic_kickdown_throttle, 0.0, 1.0)
		_append_positive(errors, "automatic_kickdown_rpm", automatic_kickdown_rpm)
		if automatic_kickdown_rpm < automatic_downshift_rpm or automatic_kickdown_rpm > redline_rpm:
			errors.append("automatic_kickdown_rpm must be between downshift and redline RPM")
		_append_non_negative(errors, "automatic_shift_delay", automatic_shift_delay)
		if is_torque_converter_automatic():
			_append_positive(errors, "torque_converter_stall_rpm", torque_converter_stall_rpm)
			_append_positive(errors, "torque_converter_coupling_rpm", torque_converter_coupling_rpm)
			if torque_converter_stall_rpm < idle_rpm: errors.append("torque_converter_stall_rpm must be at or above idle_rpm")
			if torque_converter_coupling_rpm < torque_converter_stall_rpm: errors.append("torque_converter_coupling_rpm must be at or above stall RPM")
			if torque_converter_coupling_rpm > redline_rpm: errors.append("torque_converter_coupling_rpm must not exceed redline RPM")
			_append_range(errors, "torque_converter_stall_torque_multiplier", torque_converter_stall_torque_multiplier, 1.0, 5.0)
	if smg_enabled:
		_append_positive(errors, "smg_shift_delay", smg_shift_delay)
		_append_positive(errors, "smg_launch_full_speed", smg_launch_full_speed)
		_append_positive(errors, "smg_upshift_rpm", smg_upshift_rpm)
		_append_positive(errors, "smg_downshift_rpm", smg_downshift_rpm)
		if smg_downshift_rpm < idle_rpm: errors.append("smg_downshift_rpm must be at or above idle_rpm")
		if smg_downshift_rpm >= smg_upshift_rpm: errors.append("smg_downshift_rpm must be below smg_upshift_rpm")
		if smg_upshift_rpm > redline_rpm: errors.append("smg_upshift_rpm must not exceed redline_rpm")
		_append_range(errors, "smg_clutch_reengage_point", smg_clutch_reengage_point, 0.05, 0.95)

	if is_cvt_transmission():
		_append_positive(errors, "cvt_max_ratio", cvt_max_ratio)
		_append_positive(errors, "cvt_target_rpm_min", cvt_target_rpm_min)
		_append_positive(errors, "cvt_target_rpm_max", cvt_target_rpm_max)
		if cvt_target_rpm_min < idle_rpm: errors.append("cvt_target_rpm_min must be at or above idle_rpm")
		if cvt_target_rpm_max < cvt_target_rpm_min: errors.append("cvt_target_rpm_max must be at or above cvt_target_rpm_min")
		if cvt_target_rpm_max > redline_rpm: errors.append("cvt_target_rpm_max must not exceed redline_rpm")
		_append_positive(errors, "cvt_ratio_response", cvt_ratio_response)
		_append_positive(errors, "cvt_clutch_engagement_rpm", cvt_clutch_engagement_rpm)
		_append_positive(errors, "cvt_clutch_full_rpm", cvt_clutch_full_rpm)
		if cvt_clutch_engagement_rpm < idle_rpm: errors.append("cvt_clutch_engagement_rpm must be at or above idle_rpm")
		if cvt_clutch_full_rpm <= cvt_clutch_engagement_rpm: errors.append("cvt_clutch_full_rpm must be above cvt_clutch_engagement_rpm")
		if cvt_clutch_full_rpm > redline_rpm: errors.append("cvt_clutch_full_rpm must not exceed redline_rpm")

	_append_positive(errors, "vehicle_mass", vehicle_mass)
	_append_non_negative(errors, "drag_coefficient", drag_coefficient)
	_append_positive(errors, "frontal_area", frontal_area)
	_append_positive(errors, "air_density", air_density)
	_append_non_negative(errors, "rolling_resistance_coefficient", rolling_resistance_coefficient)
	_append_positive(errors, "front_lateral_grip", front_lateral_grip)
	_append_positive(errors, "rear_lateral_grip", rear_lateral_grip)
	_append_positive(errors, "front_tire_width_m", front_tire_width_m)
	_append_positive(errors, "rear_tire_width_m", rear_tire_width_m)
	_append_positive(errors, "longitudinal_grip_coefficient", longitudinal_grip_coefficient)
	_append_positive(errors, "longitudinal_peak_slip_ratio", longitudinal_peak_slip_ratio)
	_append_range(errors, "longitudinal_slide_grip_multiplier", longitudinal_slide_grip_multiplier, 0.0, 1.0)
	_append_range(errors, "handbrake_lateral_grip_multiplier", handbrake_lateral_grip_multiplier, 0.0, 1.0)
	_append_non_negative(errors, "steering_slip_gain", steering_slip_gain)
	_append_positive(errors, "slip_speed_threshold", slip_speed_threshold)
	_append_range(errors, "slip_steering_lock_threshold", slip_steering_lock_threshold, 0.0, 1.0)
	_append_range(errors, "slip_steering_same_direction_multiplier", slip_steering_same_direction_multiplier, 0.0, 1.0)
	_append_range(errors, "skid_mark_min_slip", skid_mark_min_slip, 0.0, 1.0)
	_append_positive(errors, "skid_mark_interval", skid_mark_interval)
	_append_positive(errors, "skid_mark_lifetime", skid_mark_lifetime)
	_append_positive(errors, "skid_mark_width", skid_mark_width)
	_append_positive(errors, "skid_mark_length", skid_mark_length)
	_append_positive(errors, "gravity", gravity)
	_append_non_negative(errors, "floor_stick_force", floor_stick_force)
	_append_non_negative(errors, "suspension_probe_height", suspension_probe_height)
	_append_positive(errors, "suspension_rest_length", suspension_rest_length)
	_append_positive(errors, "suspension_travel", suspension_travel)
	_append_positive(errors, "suspension_stiffness", suspension_stiffness)
	_append_non_negative(errors, "suspension_damping", suspension_damping)
	if suspension_stiffness * float(GroundContactModel.PROBE_COUNT) < gravity * MIN_SUSPENSION_SUPPORT_RESERVE:
		errors.append("suspension_stiffness across all probes must exceed gravity with at least %.0f%% reserve" % ((MIN_SUSPENSION_SUPPORT_RESERVE - 1.0) * 100.0))
	if ground_probe_collision_mask <= 0: errors.append("ground_probe_collision_mask must include at least one physics layer")
	_append_range(errors, "minimum_ground_normal_dot", minimum_ground_normal_dot, 0.0, 1.0)
	return errors

func _append_positive(errors: PackedStringArray, property_name: String, value: float) -> void:
	if not is_finite(value) or value <= 0.0: errors.append("%s must be finite and greater than zero" % property_name)

func _append_non_negative(errors: PackedStringArray, property_name: String, value: float) -> void:
	if not is_finite(value) or value < 0.0: errors.append("%s must be finite and non-negative" % property_name)

func _append_range(errors: PackedStringArray, property_name: String, value: float, minimum: float, maximum: float) -> void:
	if not is_finite(value) or value < minimum or value > maximum:
		errors.append("%s must be finite and between %s and %s" % [property_name, minimum, maximum])
