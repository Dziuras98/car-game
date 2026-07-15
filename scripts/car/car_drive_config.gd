extends RefCounted
class_name CarDriveConfig

var brake_deceleration: float = 34.0
var reverse_acceleration: float = 12.0
var coast_deceleration: float = 5.0
var handbrake_deceleration: float = 18.0
var max_forward_speed: float = 30.0
var max_reverse_speed: float = 10.0
var steering_speed: float = 2.7
var wheel_base: float = 2.65
var front_axle_track_width: float = 1.55
var rear_axle_track_width: float = 1.55
var max_steering_angle_degrees: float = 32.0

var idle_rpm: float = 900.0
var peak_torque_rpm: float = 4200.0
var power_peak_rpm: float = 6200.0
var redline_rpm: float = 6500.0
var rev_limiter_rpm: float = 6800.0
var torque_curve: EngineTorqueCurve
var low_rpm_torque_multiplier: float = 0.42
var mid_rpm_torque_multiplier: float = 0.82
var redline_torque_multiplier: float = 0.72
var engine_force: float = 30.0
var engine_brake_force: float = 3.0
var rpm_response: float = 8.0

var transmission_type: int = CarSpecs.TransmissionType.DIRECT_DRIVE
var gear_ratios: Array[float] = [3.20, 2.10, 1.50, 1.15, 0.92, 0.75]
var reverse_gear_ratio: float = 3.00
var final_drive_ratio: float = 3.70
var peak_engine_torque: float = 420.0
var wheel_radius: float = 0.34
var drivetrain_efficiency: float = 0.85
var shift_delay: float = 0.28
var max_drive_acceleration: float = 100.0
var drive_layout: int = CarSpecs.DriveLayout.REAR_WHEEL_DRIVE
var awd_front_torque_fraction: float = 0.40

var automatic_upshift_rpm: float = 6200.0
var automatic_downshift_rpm: float = 2100.0
var automatic_kickdown_throttle: float = 0.82
var automatic_kickdown_rpm: float = 5200.0
var automatic_shift_delay: float = 0.22
var torque_converter_stall_rpm: float = 2600.0
var torque_converter_coupling_rpm: float = 4200.0
var torque_converter_stall_torque_multiplier: float = 1.65

var smg_enabled: bool = false
var smg_auto_mode: bool = true
var smg_shift_delay: float = 0.22
var smg_launch_full_speed: float = 4.0
var smg_upshift_rpm: float = 6100.0
var smg_downshift_rpm: float = 1800.0
var smg_clutch_reengage_point: float = 0.48

var cvt_max_ratio: float = 2.50
var cvt_target_rpm_min: float = 1800.0
var cvt_target_rpm_max: float = 5500.0
var cvt_ratio_response: float = 8.0
var cvt_clutch_engagement_rpm: float = 1250.0
var cvt_clutch_full_rpm: float = 2200.0

var vehicle_mass: float = 1200.0
var drag_coefficient: float = 0.30
var frontal_area: float = 2.05
var air_density: float = 1.225
var rolling_resistance_coefficient: float = 0.015
var front_static_load_fraction: float = 0.0
var center_of_mass_height_m: float = 0.55

var front_lateral_grip: float = 10.0
var rear_lateral_grip: float = 10.0
var front_tire_width_m: float = 0.225
var rear_tire_width_m: float = 0.245
var longitudinal_grip_coefficient: float = 1.05
var longitudinal_peak_slip_ratio: float = 0.12
var longitudinal_slide_grip_multiplier: float = 0.78
var handbrake_lateral_grip_multiplier: float = 0.28
var steering_slip_gain: float = 0.85
var slip_speed_threshold: float = 2.2
var slip_steering_lock_threshold: float = 0.55
var slip_steering_same_direction_multiplier: float = 0.12
var skid_mark_min_slip: float = 0.45
var skid_mark_interval: float = 0.055
var skid_mark_lifetime: float = 10.0
var skid_mark_width: float = 0.22
var skid_mark_length: float = 0.9
var front_brake_bias: float = 0.62
var front_wheel_inertia_kg_m2: float = 0.0
var rear_wheel_inertia_kg_m2: float = 0.0
var wheel_angular_damping_nm_per_rad_s: float = 0.08
var wheel_slip_reference_speed_mps: float = 1.0

var gravity: float = 30.0
var floor_stick_force: float = 0.5
var suspension_probe_height: float = 0.42
var suspension_rest_length: float = 0.28
var suspension_travel: float = 0.18
var suspension_stiffness: float = 32.0
var suspension_damping: float = 5.0
var ground_probe_collision_mask: int = 1
var minimum_ground_normal_dot: float = 0.35


func is_manual_transmission() -> bool:
	return transmission_type == CarSpecs.TransmissionType.MANUAL


func is_automatic_transmission() -> bool:
	return transmission_type == CarSpecs.TransmissionType.AUTOMATIC


func is_smg_transmission() -> bool:
	return is_automatic_transmission() and smg_enabled


func is_torque_converter_automatic() -> bool:
	return is_automatic_transmission() and not smg_enabled


func is_cvt_transmission() -> bool:
	return transmission_type == CarSpecs.TransmissionType.CVT


func is_self_shifting_transmission() -> bool:
	return is_automatic_transmission() or is_cvt_transmission()


func uses_discrete_gears() -> bool:
	return is_manual_transmission() or is_automatic_transmission()


func uses_geared_transmission() -> bool:
	return uses_discrete_gears() or is_cvt_transmission()


func is_front_wheel_drive() -> bool:
	return drive_layout == CarSpecs.DriveLayout.FRONT_WHEEL_DRIVE


func is_rear_wheel_drive() -> bool:
	return drive_layout == CarSpecs.DriveLayout.REAR_WHEEL_DRIVE


func is_all_wheel_drive() -> bool:
	return drive_layout == CarSpecs.DriveLayout.ALL_WHEEL_DRIVE


func get_drive_torque_fraction(wheel_index: int) -> float:
	var is_front: bool = wheel_index == WheelTireState.Position.FRONT_LEFT or wheel_index == WheelTireState.Position.FRONT_RIGHT
	if is_front_wheel_drive():
		return 0.5 if is_front else 0.0
	if is_rear_wheel_drive():
		return 0.0 if is_front else 0.5
	var axle_fraction: float = awd_front_torque_fraction if is_front else 1.0 - awd_front_torque_fraction
	return axle_fraction * 0.5


func get_service_brake_fraction(wheel_index: int) -> float:
	var is_front: bool = wheel_index == WheelTireState.Position.FRONT_LEFT or wheel_index == WheelTireState.Position.FRONT_RIGHT
	return (front_brake_bias if is_front else 1.0 - front_brake_bias) * 0.5


func get_handbrake_fraction(wheel_index: int) -> float:
	return 0.5 if wheel_index == WheelTireState.Position.REAR_LEFT or wheel_index == WheelTireState.Position.REAR_RIGHT else 0.0


func get_wheel_inertia_kg_m2(wheel_index: int) -> float:
	return front_wheel_inertia_kg_m2 if wheel_index == WheelTireState.Position.FRONT_LEFT or wheel_index == WheelTireState.Position.FRONT_RIGHT else rear_wheel_inertia_kg_m2


func get_wheel_load_share(wheel_index: int, longitudinal_acceleration_mps2: float) -> float:
	var transfer_fraction: float = (
		longitudinal_acceleration_mps2
		* center_of_mass_height_m
		/ maxf(TireModel.STANDARD_GRAVITY * wheel_base, 0.01)
	)
	var dynamic_front_fraction: float = clampf(
		front_static_load_fraction - transfer_fraction,
		0.10,
		0.90
	)
	var is_front: bool = wheel_index == WheelTireState.Position.FRONT_LEFT or wheel_index == WheelTireState.Position.FRONT_RIGHT
	return (dynamic_front_fraction if is_front else 1.0 - dynamic_front_fraction) * 0.5


func duplicate_config() -> CarDriveConfig:
	var config: CarDriveConfig = CarDriveConfig.new()
	for property: Dictionary in get_property_list():
		var property_name: StringName = property.get("name", &"")
		if property_name == &"" or property_name in [&"script", &"RefCounted"]:
			continue
		var usage: int = int(property.get("usage", 0))
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		var value: Variant = get(property_name)
		if value is Array:
			value = value.duplicate(true)
		config.set(property_name, value)
	config.sanitize()
	return config


func sanitize() -> void:
	max_forward_speed = maxf(max_forward_speed, 0.1)
	max_reverse_speed = maxf(max_reverse_speed, 0.0)
	wheel_base = maxf(wheel_base, 0.1)
	front_axle_track_width = maxf(front_axle_track_width, 0.1)
	rear_axle_track_width = maxf(rear_axle_track_width, 0.1)
	vehicle_mass = maxf(vehicle_mass, 1.0)
	wheel_radius = maxf(wheel_radius, 0.01)
	drivetrain_efficiency = clampf(drivetrain_efficiency, 0.0001, 1.0)
	max_drive_acceleration = maxf(max_drive_acceleration, 0.01)
	if drive_layout < CarSpecs.DriveLayout.FRONT_WHEEL_DRIVE or drive_layout > CarSpecs.DriveLayout.ALL_WHEEL_DRIVE:
		drive_layout = CarSpecs.DriveLayout.REAR_WHEEL_DRIVE
	awd_front_torque_fraction = clampf(awd_front_torque_fraction, 0.0, 1.0)
	if front_static_load_fraction <= 0.0:
		front_static_load_fraction = 0.62 if is_front_wheel_drive() else 0.50 if is_all_wheel_drive() else 0.53
	front_static_load_fraction = clampf(front_static_load_fraction, 0.10, 0.90)
	center_of_mass_height_m = maxf(center_of_mass_height_m, 0.05)
	front_lateral_grip = maxf(front_lateral_grip, 0.01)
	rear_lateral_grip = maxf(rear_lateral_grip, 0.01)
	front_tire_width_m = maxf(front_tire_width_m, 0.01)
	rear_tire_width_m = maxf(rear_tire_width_m, 0.01)
	longitudinal_grip_coefficient = maxf(longitudinal_grip_coefficient, 0.01)
	longitudinal_peak_slip_ratio = maxf(longitudinal_peak_slip_ratio, 0.001)
	longitudinal_slide_grip_multiplier = clampf(longitudinal_slide_grip_multiplier, 0.0, 1.0)
	front_brake_bias = clampf(front_brake_bias, 0.0, 1.0)
	wheel_angular_damping_nm_per_rad_s = maxf(wheel_angular_damping_nm_per_rad_s, 0.0)
	wheel_slip_reference_speed_mps = maxf(wheel_slip_reference_speed_mps, WheelRotationalDynamicsModel.MIN_REFERENCE_SPEED_MPS)
	if front_wheel_inertia_kg_m2 <= 0.0:
		front_wheel_inertia_kg_m2 = _estimate_wheel_inertia(front_tire_width_m)
	if rear_wheel_inertia_kg_m2 <= 0.0:
		rear_wheel_inertia_kg_m2 = _estimate_wheel_inertia(rear_tire_width_m)
	front_wheel_inertia_kg_m2 = maxf(front_wheel_inertia_kg_m2, 0.01)
	rear_wheel_inertia_kg_m2 = maxf(rear_wheel_inertia_kg_m2, 0.01)
	suspension_probe_height = maxf(suspension_probe_height, 0.0)
	suspension_rest_length = maxf(suspension_rest_length, 0.01)
	suspension_travel = maxf(suspension_travel, 0.01)
	suspension_stiffness = maxf(suspension_stiffness, 0.0)
	suspension_damping = maxf(suspension_damping, 0.0)
	ground_probe_collision_mask = maxi(ground_probe_collision_mask, 1)
	minimum_ground_normal_dot = clampf(minimum_ground_normal_dot, 0.0, 1.0)
	cvt_max_ratio = maxf(cvt_max_ratio, CvtTransmissionModel.MIN_DYNAMIC_RATIO)
	cvt_target_rpm_min = maxf(cvt_target_rpm_min, idle_rpm)
	cvt_target_rpm_max = maxf(cvt_target_rpm_max, cvt_target_rpm_min)
	cvt_ratio_response = maxf(cvt_ratio_response, 0.01)
	cvt_clutch_engagement_rpm = maxf(cvt_clutch_engagement_rpm, idle_rpm)
	cvt_clutch_full_rpm = maxf(cvt_clutch_full_rpm, cvt_clutch_engagement_rpm + 1.0)
	smg_shift_delay = maxf(smg_shift_delay, 0.01)
	smg_launch_full_speed = maxf(smg_launch_full_speed, 0.25)
	smg_upshift_rpm = clampf(smg_upshift_rpm, idle_rpm + 1.0, redline_rpm)
	smg_downshift_rpm = clampf(smg_downshift_rpm, idle_rpm, smg_upshift_rpm - 1.0)
	smg_clutch_reengage_point = clampf(smg_clutch_reengage_point, 0.05, 0.95)
	if transmission_type < CarSpecs.TransmissionType.DIRECT_DRIVE or transmission_type > CarSpecs.TransmissionType.CVT:
		transmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE
	if smg_enabled and not is_automatic_transmission():
		smg_enabled = false
	if uses_discrete_gears() and gear_ratios.is_empty():
		gear_ratios = [1.0]


func _estimate_wheel_inertia(tire_width_m: float) -> float:
	var effective_rotating_mass_kg: float = clampf(
		11.0 + tire_width_m * 45.0 + wheel_radius * 8.0,
		12.0,
		34.0
	)
	return effective_rotating_mass_kg * wheel_radius * wheel_radius * 0.65
