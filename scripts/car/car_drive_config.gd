extends RefCounted
class_name CarDriveConfig

var acceleration: float = 22.0
var brake_deceleration: float = 34.0
var reverse_acceleration: float = 12.0
var coast_deceleration: float = 5.0
var handbrake_deceleration: float = 18.0
var max_forward_speed: float = 30.0
var max_reverse_speed: float = 10.0
var steering_speed: float = 2.7
var wheel_base: float = 2.65
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

var manual_transmission_enabled: bool = false
var automatic_transmission_enabled: bool = false
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


func uses_geared_transmission() -> bool:
	return manual_transmission_enabled or automatic_transmission_enabled


func duplicate_config() -> CarDriveConfig:
	var config: CarDriveConfig = CarDriveConfig.new()
	config.acceleration = acceleration
	config.brake_deceleration = brake_deceleration
	config.reverse_acceleration = reverse_acceleration
	config.coast_deceleration = coast_deceleration
	config.handbrake_deceleration = handbrake_deceleration
	config.max_forward_speed = max_forward_speed
	config.max_reverse_speed = max_reverse_speed
	config.steering_speed = steering_speed
	config.wheel_base = wheel_base
	config.max_steering_angle_degrees = max_steering_angle_degrees
	config.idle_rpm = idle_rpm
	config.peak_torque_rpm = peak_torque_rpm
	config.redline_rpm = redline_rpm
	config.rev_limiter_rpm = rev_limiter_rpm
	config.low_rpm_torque_multiplier = low_rpm_torque_multiplier
	config.mid_rpm_torque_multiplier = mid_rpm_torque_multiplier
	config.redline_torque_multiplier = redline_torque_multiplier
	config.engine_force = engine_force
	config.engine_brake_force = engine_brake_force
	config.rpm_response = rpm_response
	config.manual_transmission_enabled = manual_transmission_enabled
	config.automatic_transmission_enabled = automatic_transmission_enabled
	config.gear_ratios = gear_ratios.duplicate()
	config.reverse_gear_ratio = reverse_gear_ratio
	config.final_drive_ratio = final_drive_ratio
	config.peak_engine_torque = peak_engine_torque
	config.wheel_radius = wheel_radius
	config.drivetrain_efficiency = drivetrain_efficiency
	config.shift_delay = shift_delay
	config.automatic_upshift_rpm = automatic_upshift_rpm
	config.automatic_downshift_rpm = automatic_downshift_rpm
	config.automatic_kickdown_throttle = automatic_kickdown_throttle
	config.automatic_kickdown_rpm = automatic_kickdown_rpm
	config.automatic_shift_delay = automatic_shift_delay
	config.torque_converter_stall_rpm = torque_converter_stall_rpm
	config.torque_converter_coupling_rpm = torque_converter_coupling_rpm
	config.torque_converter_stall_torque_multiplier = torque_converter_stall_torque_multiplier
	config.vehicle_mass = vehicle_mass
	config.drag_coefficient = drag_coefficient
	config.frontal_area = frontal_area
	config.air_density = air_density
	config.rolling_resistance_coefficient = rolling_resistance_coefficient
	config.lateral_grip = lateral_grip
	config.handbrake_lateral_grip_multiplier = handbrake_lateral_grip_multiplier
	config.steering_slip_gain = steering_slip_gain
	config.slip_speed_threshold = slip_speed_threshold
	config.slip_steering_lock_threshold = slip_steering_lock_threshold
	config.slip_steering_same_direction_multiplier = slip_steering_same_direction_multiplier
	config.skid_mark_min_slip = skid_mark_min_slip
	config.skid_mark_interval = skid_mark_interval
	config.skid_mark_lifetime = skid_mark_lifetime
	config.skid_mark_width = skid_mark_width
	config.skid_mark_length = skid_mark_length
	config.gravity = gravity
	config.floor_stick_force = floor_stick_force
	return config


func sanitize() -> void:
	max_forward_speed = maxf(max_forward_speed, 0.1)
	max_reverse_speed = maxf(max_reverse_speed, 0.0)
	wheel_base = maxf(wheel_base, 0.1)
	vehicle_mass = maxf(vehicle_mass, 1.0)
	wheel_radius = maxf(wheel_radius, 0.01)
	if uses_geared_transmission() and gear_ratios.is_empty():
		gear_ratios = [1.0]
