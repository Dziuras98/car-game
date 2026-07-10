extends RefCounted
class_name CarDriveConfigBuilder


static func build_from_specs(car_specs: CarSpecs) -> CarDriveConfig:
	if car_specs == null:
		push_error("CarDriveConfigBuilder requires a non-null CarSpecs resource.")
		return null

	var config: CarDriveConfig = CarDriveConfig.new()
	config.acceleration = car_specs.acceleration
	config.brake_deceleration = car_specs.brake_deceleration
	config.reverse_acceleration = car_specs.reverse_acceleration
	config.coast_deceleration = car_specs.coast_deceleration
	config.handbrake_deceleration = car_specs.handbrake_deceleration
	config.max_forward_speed = car_specs.max_forward_speed
	config.max_reverse_speed = car_specs.max_reverse_speed
	config.steering_speed = car_specs.steering_speed
	config.wheel_base = car_specs.wheel_base
	config.max_steering_angle_degrees = car_specs.max_steering_angle_degrees
	config.idle_rpm = car_specs.idle_rpm
	config.peak_torque_rpm = car_specs.peak_torque_rpm
	config.redline_rpm = car_specs.redline_rpm
	config.rev_limiter_rpm = car_specs.rev_limiter_rpm
	config.low_rpm_torque_multiplier = car_specs.low_rpm_torque_multiplier
	config.mid_rpm_torque_multiplier = car_specs.mid_rpm_torque_multiplier
	config.redline_torque_multiplier = car_specs.redline_torque_multiplier
	config.engine_force = car_specs.engine_force
	config.engine_brake_force = car_specs.engine_brake_force
	config.rpm_response = car_specs.rpm_response
	config.manual_transmission_enabled = car_specs.manual_transmission_enabled
	config.automatic_transmission_enabled = car_specs.automatic_transmission_enabled
	config.gear_ratios = car_specs.gear_ratios.duplicate()
	config.reverse_gear_ratio = car_specs.reverse_gear_ratio
	config.final_drive_ratio = car_specs.final_drive_ratio
	config.peak_engine_torque = car_specs.peak_engine_torque
	config.wheel_radius = car_specs.wheel_radius
	config.drivetrain_efficiency = car_specs.drivetrain_efficiency
	config.shift_delay = car_specs.shift_delay
	config.automatic_upshift_rpm = car_specs.automatic_upshift_rpm
	config.automatic_downshift_rpm = car_specs.automatic_downshift_rpm
	config.automatic_kickdown_throttle = car_specs.automatic_kickdown_throttle
	config.automatic_kickdown_rpm = car_specs.automatic_kickdown_rpm
	config.automatic_shift_delay = car_specs.automatic_shift_delay
	config.torque_converter_stall_rpm = car_specs.torque_converter_stall_rpm
	config.torque_converter_coupling_rpm = car_specs.torque_converter_coupling_rpm
	config.torque_converter_stall_torque_multiplier = car_specs.torque_converter_stall_torque_multiplier
	config.vehicle_mass = car_specs.vehicle_mass
	config.drag_coefficient = car_specs.drag_coefficient
	config.frontal_area = car_specs.frontal_area
	config.air_density = car_specs.air_density
	config.rolling_resistance_coefficient = car_specs.rolling_resistance_coefficient
	config.lateral_grip = car_specs.lateral_grip
	config.handbrake_lateral_grip_multiplier = car_specs.handbrake_lateral_grip_multiplier
	config.steering_slip_gain = car_specs.steering_slip_gain
	config.slip_speed_threshold = car_specs.slip_speed_threshold
	config.slip_steering_lock_threshold = car_specs.slip_steering_lock_threshold
	config.slip_steering_same_direction_multiplier = car_specs.slip_steering_same_direction_multiplier
	config.skid_mark_min_slip = car_specs.skid_mark_min_slip
	config.skid_mark_interval = car_specs.skid_mark_interval
	config.skid_mark_lifetime = car_specs.skid_mark_lifetime
	config.skid_mark_width = car_specs.skid_mark_width
	config.skid_mark_length = car_specs.skid_mark_length
	config.gravity = car_specs.gravity
	config.floor_stick_force = car_specs.floor_stick_force
	config.sanitize()
	return config
