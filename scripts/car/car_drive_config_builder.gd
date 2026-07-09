extends RefCounted
class_name CarDriveConfigBuilder


static func build_from_specs(car_specs: CarSpecs) -> CarDriveConfig:
	var config: CarDriveConfig = CarDriveConfig.new()
	if car_specs == null:
		config.sanitize()
		return config

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


static func build_from_legacy_exports(controller: PlayerCarController) -> CarDriveConfig:
	var config: CarDriveConfig = CarDriveConfig.new()
	config.acceleration = controller.acceleration
	config.brake_deceleration = controller.brake_deceleration
	config.reverse_acceleration = controller.reverse_acceleration
	config.coast_deceleration = controller.coast_deceleration
	config.handbrake_deceleration = controller.handbrake_deceleration
	config.max_forward_speed = controller.max_forward_speed
	config.max_reverse_speed = controller.max_reverse_speed
	config.steering_speed = controller.steering_speed
	config.wheel_base = controller.wheel_base
	config.max_steering_angle_degrees = controller.max_steering_angle_degrees
	config.idle_rpm = controller.idle_rpm
	config.peak_torque_rpm = controller.peak_torque_rpm
	config.redline_rpm = controller.redline_rpm
	config.rev_limiter_rpm = controller.rev_limiter_rpm
	config.low_rpm_torque_multiplier = controller.low_rpm_torque_multiplier
	config.mid_rpm_torque_multiplier = controller.mid_rpm_torque_multiplier
	config.redline_torque_multiplier = controller.redline_torque_multiplier
	config.engine_force = controller.engine_force
	config.engine_brake_force = controller.engine_brake_force
	config.rpm_response = controller.rpm_response
	config.manual_transmission_enabled = controller.manual_transmission_enabled
	config.automatic_transmission_enabled = controller.automatic_transmission_enabled
	config.gear_ratios = controller.gear_ratios.duplicate()
	config.reverse_gear_ratio = controller.reverse_gear_ratio
	config.final_drive_ratio = controller.final_drive_ratio
	config.peak_engine_torque = controller.peak_engine_torque
	config.wheel_radius = controller.wheel_radius
	config.drivetrain_efficiency = controller.drivetrain_efficiency
	config.shift_delay = controller.shift_delay
	config.automatic_upshift_rpm = controller.automatic_upshift_rpm
	config.automatic_downshift_rpm = controller.automatic_downshift_rpm
	config.automatic_kickdown_throttle = controller.automatic_kickdown_throttle
	config.automatic_kickdown_rpm = controller.automatic_kickdown_rpm
	config.automatic_shift_delay = controller.automatic_shift_delay
	config.torque_converter_stall_rpm = controller.torque_converter_stall_rpm
	config.torque_converter_coupling_rpm = controller.torque_converter_coupling_rpm
	config.torque_converter_stall_torque_multiplier = controller.torque_converter_stall_torque_multiplier
	config.vehicle_mass = controller.vehicle_mass
	config.drag_coefficient = controller.drag_coefficient
	config.frontal_area = controller.frontal_area
	config.air_density = controller.air_density
	config.rolling_resistance_coefficient = controller.rolling_resistance_coefficient
	config.lateral_grip = controller.lateral_grip
	config.handbrake_lateral_grip_multiplier = controller.handbrake_lateral_grip_multiplier
	config.steering_slip_gain = controller.steering_slip_gain
	config.slip_speed_threshold = controller.slip_speed_threshold
	config.slip_steering_lock_threshold = controller.slip_steering_lock_threshold
	config.slip_steering_same_direction_multiplier = controller.slip_steering_same_direction_multiplier
	config.skid_mark_min_slip = controller.skid_mark_min_slip
	config.skid_mark_interval = controller.skid_mark_interval
	config.skid_mark_lifetime = controller.skid_mark_lifetime
	config.skid_mark_width = controller.skid_mark_width
	config.skid_mark_length = controller.skid_mark_length
	config.gravity = controller.gravity
	config.floor_stick_force = controller.floor_stick_force
	config.sanitize()
	return config


static func build_from_specs_or_legacy(car_specs: CarSpecs, controller: PlayerCarController) -> CarDriveConfig:
	if car_specs != null:
		return build_from_specs(car_specs)

	return build_from_legacy_exports(controller)
