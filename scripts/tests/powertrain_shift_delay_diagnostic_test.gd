extends SceneTree


func _initialize() -> void:
	_test_direction_selection_state()
	_test_upshift_torque_cut_state()
	quit(0)


func _test_direction_selection_state() -> void:
	var config: CarDriveConfig = _build_automatic_config()
	var state: CarRuntimeState = _build_state(config)
	var powertrain: CarPowertrainController = _build_powertrain(config, state)

	powertrain.update(state, 0.0, 1.0, false, false, false, 0.0)
	for _step: int in range(4):
		powertrain.update(state, 0.0, 1.0, false, false, false, 0.10)
	print("[SHIFT_DELAY_DIAGNOSTIC] reverse_complete speed=%.9f gear=%d timer=%.9f wheels=%s" % [
		state.forward_speed,
		state.current_gear,
		state.shift_timer,
		str(state.get_wheel_angular_velocities()),
	])

	state.forward_speed = 0.0
	state.shift_timer = 0.0
	print("[SHIFT_DELAY_DIAGNOSTIC] drive_before speed=%.9f gear=%d timer=%.9f wheels=%s" % [
		state.forward_speed,
		state.current_gear,
		state.shift_timer,
		str(state.get_wheel_angular_velocities()),
	])
	powertrain.update(state, 1.0, 0.0, false, false, false, 0.0)
	print("[SHIFT_DELAY_DIAGNOSTIC] drive_after speed=%.9f gear=%d timer=%.9f wheels=%s" % [
		state.forward_speed,
		state.current_gear,
		state.shift_timer,
		str(state.get_wheel_angular_velocities()),
	])


func _test_upshift_torque_cut_state() -> void:
	var config: CarDriveConfig = _build_automatic_config()
	var state: CarRuntimeState = _build_state(config)
	var powertrain: CarPowertrainController = _build_powertrain(config, state)

	state.current_gear = 1
	state.engine_rpm = config.redline_rpm
	state.forward_speed = 20.0
	print("[SHIFT_DELAY_DIAGNOSTIC] upshift_before speed=%.9f gear=%d timer=%.9f wheels=%s" % [
		state.forward_speed,
		state.current_gear,
		state.shift_timer,
		str(state.get_wheel_angular_velocities()),
	])
	powertrain.update(state, 0.0, 0.0, false, false, false, 0.0)
	var speed_before_shift: float = state.forward_speed
	print("[SHIFT_DELAY_DIAGNOSTIC] upshift_selected speed=%.9f gear=%d timer=%.9f wheels=%s" % [
		state.forward_speed,
		state.current_gear,
		state.shift_timer,
		str(state.get_wheel_angular_velocities()),
	])
	powertrain.update(state, 0.5, 0.0, false, false, false, 0.10)
	print("[SHIFT_DELAY_DIAGNOSTIC] upshift_during speed=%.9f delta=%.9f gear=%d timer=%.9f wheels=%s" % [
		state.forward_speed,
		state.forward_speed - speed_before_shift,
		state.current_gear,
		state.shift_timer,
		str(state.get_wheel_angular_velocities()),
	])


func _build_state(config: CarDriveConfig) -> CarRuntimeState:
	var state: CarRuntimeState = CarRuntimeState.new()
	state.reset_drive_state(config.idle_rpm)
	state.ground_contact_count = WheelTireState.WHEEL_COUNT
	return state


func _build_powertrain(config: CarDriveConfig, state: CarRuntimeState) -> CarPowertrainController:
	var powertrain: CarPowertrainController = CarPowertrainController.new()
	powertrain.configure(config)
	powertrain.reset(state)
	return powertrain


func _build_automatic_config() -> CarDriveConfig:
	var config: CarDriveConfig = CarDriveConfig.new()
	config.transmission_type = CarSpecs.TransmissionType.AUTOMATIC
	config.gear_ratios = [3.0, 2.0, 1.4]
	config.reverse_gear_ratio = 3.2
	config.final_drive_ratio = 3.5
	config.peak_engine_torque = 420.0
	config.wheel_radius = 0.34
	config.drivetrain_efficiency = 0.85
	config.vehicle_mass = 1200.0
	config.idle_rpm = 900.0
	config.peak_torque_rpm = 4200.0
	config.redline_rpm = 6500.0
	config.rev_limiter_rpm = 6800.0
	config.low_rpm_torque_multiplier = 0.42
	config.mid_rpm_torque_multiplier = 0.82
	config.redline_torque_multiplier = 0.72
	config.engine_force = 30.0
	config.engine_brake_force = 0.0
	config.rpm_response = 8.0
	config.shift_delay = 0.28
	config.automatic_upshift_rpm = 6200.0
	config.automatic_downshift_rpm = 2100.0
	config.automatic_kickdown_throttle = 0.82
	config.automatic_kickdown_rpm = 5200.0
	config.automatic_shift_delay = 0.22
	config.torque_converter_stall_rpm = 2600.0
	config.torque_converter_coupling_rpm = 4200.0
	config.torque_converter_stall_torque_multiplier = 1.65
	config.brake_deceleration = 34.0
	config.reverse_acceleration = 12.0
	config.coast_deceleration = 0.0
	config.handbrake_deceleration = 18.0
	config.max_forward_speed = 30.0
	config.max_reverse_speed = 10.0
	config.drag_coefficient = 0.0
	config.frontal_area = 2.05
	config.air_density = 1.225
	config.rolling_resistance_coefficient = 0.0
	config.wheel_angular_damping_nm_per_rad_s = 0.0
	config.sanitize()
	return config
