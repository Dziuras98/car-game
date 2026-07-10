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
var axle_track_width: float = 1.55
var max_steering_angle_degrees: float = 32.0

var idle_rpm: float = 900.0
var peak_torque_rpm: float = 4200.0
var redline_rpm: float = 6500.0
var rev_limiter_rpm: float = 6800.0
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

var automatic_upshift_rpm: float = 6200.0
var automatic_downshift_rpm: float = 2100.0
var automatic_kickdown_throttle: float = 0.82
var automatic_kickdown_rpm: float = 5200.0
var automatic_shift_delay: float = 0.22
var torque_converter_stall_rpm: float = 2600.0
var torque_converter_coupling_rpm: float = 4200.0
var torque_converter_stall_torque_multiplier: float = 1.65

var vehicle_mass: float = 1200.0
var drag_coefficient: float = 0.30
var frontal_area: float = 2.05
var air_density: float = 1.225
var rolling_resistance_coefficient: float = 0.015

var lateral_grip: float = 10.0
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

var gravity: float = 30.0
var floor_stick_force: float = 0.5
var suspension_probe_height: float = 0.42
var suspension_rest_length: float = 0.28
var suspension_travel: float = 0.18
var suspension_stiffness: float = 32.0
var suspension_damping: float = 5.0


func is_manual_transmission() -> bool:
	return transmission_type == CarSpecs.TransmissionType.MANUAL


func is_automatic_transmission() -> bool:
	return transmission_type == CarSpecs.TransmissionType.AUTOMATIC


func uses_geared_transmission() -> bool:
	return is_manual_transmission() or is_automatic_transmission()


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
	axle_track_width = maxf(axle_track_width, 0.1)
	vehicle_mass = maxf(vehicle_mass, 1.0)
	wheel_radius = maxf(wheel_radius, 0.01)
	drivetrain_efficiency = clampf(drivetrain_efficiency, 0.0001, 1.0)
	suspension_probe_height = maxf(suspension_probe_height, 0.0)
	suspension_rest_length = maxf(suspension_rest_length, 0.01)
	suspension_travel = maxf(suspension_travel, 0.01)
	suspension_stiffness = maxf(suspension_stiffness, 0.0)
	suspension_damping = maxf(suspension_damping, 0.0)
	if transmission_type < CarSpecs.TransmissionType.DIRECT_DRIVE or transmission_type > CarSpecs.TransmissionType.AUTOMATIC:
		transmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE
	if uses_geared_transmission() and gear_ratios.is_empty():
		gear_ratios = [1.0]
