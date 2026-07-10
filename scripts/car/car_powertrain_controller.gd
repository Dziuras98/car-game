extends RefCounted
class_name CarPowertrainController

var _manual_transmission_model: ManualTransmissionModel = ManualTransmissionModel.new()
var _automatic_transmission_model: AutomaticTransmissionModel = AutomaticTransmissionModel.new()
var _shift_timer_model: ShiftTimerModel = ShiftTimerModel.new()
var _engine_model: EngineModel = EngineModel.new()
var _resistance_model: ResistanceModel = ResistanceModel.new()
var _drivetrain_model: DrivetrainModel = DrivetrainModel.new()
var _torque_converter_model: TorqueConverterModel = TorqueConverterModel.new()
var _config: CarDriveConfig
var _runtime_state: CarRuntimeState


func configure(config: CarDriveConfig) -> void:
	var preserved_engine_rpm: float = _engine_model.get_rpm()
	if _runtime_state != null:
		preserved_engine_rpm = _runtime_state.engine_rpm

	_config = config.duplicate_config()
	_config.sanitize()
	_engine_model.configure(
		_config.idle_rpm,
		_config.peak_torque_rpm,
		_config.redline_rpm,
		_config.rev_limiter_rpm,
		_config.low_rpm_torque_multiplier,
		_config.mid_rpm_torque_multiplier,
		_config.redline_torque_multiplier,
		_config.rpm_response
	)
	_resistance_model.configure(
		_config.vehicle_mass,
		_config.drag_coefficient,
		_config.frontal_area,
		_config.air_density,
		_config.rolling_resistance_coefficient
	)
	_drivetrain_model.configure(
		_config.idle_rpm,
		_config.gear_ratios,
		_config.reverse_gear_ratio,
		_config.final_drive_ratio,
		_config.peak_engine_torque,
		_config.wheel_radius,
		_config.drivetrain_efficiency,
		_config.vehicle_mass
	)
	_torque_converter_model.configure(
		_config.idle_rpm,
		_config.torque_converter_stall_rpm,
		_config.torque_converter_coupling_rpm,
		_config.torque_converter_stall_torque_multiplier
	)

	if _runtime_state != null:
		_runtime_state.engine_rpm = _engine_model.set_rpm(preserved_engine_rpm)


func reset(state: CarRuntimeState) -> void:
	_runtime_state = state
	state.engine_rpm = _engine_model.reset()


func update(
	state: CarRuntimeState,
	throttle: float,
	brake: float,
	handbrake_active: bool,
	gear_up_pressed: bool,
	gear_down_pressed: bool,
	delta: float
) -> void:
	_runtime_state = state
	_update_shift_timer(state, delta)
	_update_transmission_input(state, throttle, brake, gear_up_pressed, gear_down_pressed)
	_update_engine(state, throttle, delta)
	_update_speed(state, throttle, brake, handbrake_active, delta)


func get_engine_load(state: CarRuntimeState) -> float:
	if _config.uses_geared_transmission() and state.current_gear == 0:
		return 0.0

	if _config.manual_transmission_enabled and state.shift_timer > 0.0:
		return 0.0

	if _config.automatic_transmission_enabled and state.current_gear < 0:
		return state.brake_input

	return state.throttle_input


func get_gear_text(state: CarRuntimeState) -> String:
	if _config.manual_transmission_enabled:
		if state.current_gear < 0:
			return "R"
		if state.current_gear == 0:
			return "N"
		return str(state.current_gear)

	if _config.automatic_transmission_enabled:
		if state.current_gear < 0:
			return "R"
		return "D%d" % clampi(state.current_gear, 1, maxi(_config.gear_ratios.size(), 1))

	if state.forward_speed < -0.25:
		return "R"
	if state.forward_speed > 0.25:
		return "D"
	return "N"


func get_torque_multiplier() -> float:
	return _engine_model.get_torque_multiplier()


func get_rev_limiter_multiplier() -> float:
	return _engine_model.get_rev_limiter_multiplier()


func _update_transmission_input(
	state: CarRuntimeState,
	throttle: float,
	brake: float,
	gear_up_pressed: bool,
	gear_down_pressed: bool
) -> void:
	if _config.manual_transmission_enabled:
		var requested_gear: int = _manual_transmission_model.get_requested_gear(
			state.current_gear,
			_config.gear_ratios.size(),
			gear_up_pressed,
			gear_down_pressed
		)
		if requested_gear != state.current_gear:
			_set_transmission_gear(state, requested_gear)
		return

	if _config.automatic_transmission_enabled:
		_update_automatic_transmission(state, throttle, brake)


func _update_automatic_transmission(state: CarRuntimeState, throttle: float, brake: float) -> void:
	var lower_gear_rpm: float = _config.idle_rpm
	if state.current_gear > 1:
		lower_gear_rpm = _get_coupled_engine_rpm_for_gear(state, state.current_gear - 1)

	var requested_gear: int = _automatic_transmission_model.get_requested_gear(
		state.current_gear,
		_config.gear_ratios.size(),
		state.forward_speed,
		state.engine_rpm,
		throttle,
		brake,
		state.shift_timer,
		_config.redline_rpm,
		_config.automatic_upshift_rpm,
		_config.automatic_downshift_rpm,
		_config.automatic_kickdown_throttle,
		_config.automatic_kickdown_rpm,
		lower_gear_rpm
	)

	if requested_gear != state.current_gear:
		_set_transmission_gear(state, requested_gear)


func _update_shift_timer(state: CarRuntimeState, delta: float) -> void:
	state.shift_timer = _shift_timer_model.update_timer(state.shift_timer, delta)


func _set_transmission_gear(state: CarRuntimeState, next_gear: int) -> void:
	if next_gear == state.current_gear:
		return

	state.current_gear = next_gear
	state.shift_timer = _shift_timer_model.get_shift_delay(
		_config.automatic_transmission_enabled,
		_config.automatic_shift_delay,
		_config.shift_delay
	)


func _update_engine(state: CarRuntimeState, throttle: float, delta: float) -> void:
	var wheel_rpm: float = _get_wheel_driven_rpm(state)
	state.engine_rpm = _engine_model.update(throttle, wheel_rpm, delta)


func _update_speed(
	state: CarRuntimeState,
	throttle: float,
	brake: float,
	handbrake_active: bool,
	delta: float
) -> void:
	if throttle > 0.0:
		if _config.uses_geared_transmission():
			if _config.automatic_transmission_enabled and state.current_gear < 1:
				state.forward_speed = move_toward(
					state.forward_speed,
					0.0,
					_config.brake_deceleration * throttle * delta
				)
			else:
				state.forward_speed += _get_transmission_drive_acceleration(state, throttle) * delta
		else:
			var torque_multiplier: float = get_torque_multiplier()
			var limiter_multiplier: float = get_rev_limiter_multiplier()
			state.forward_speed += throttle * _config.engine_force * torque_multiplier * limiter_multiplier * delta

	if brake > 0.0:
		if _config.manual_transmission_enabled:
			state.forward_speed = move_toward(state.forward_speed, 0.0, _config.brake_deceleration * brake * delta)
		elif _config.automatic_transmission_enabled:
			if state.current_gear < 0:
				if state.forward_speed > AutomaticTransmissionModel.DIRECTION_CHANGE_SPEED_THRESHOLD:
					state.forward_speed = move_toward(
						state.forward_speed,
						0.0,
						_config.brake_deceleration * brake * delta
					)
				else:
					state.forward_speed += _get_transmission_drive_acceleration(state, brake) * delta
			else:
				state.forward_speed = move_toward(
					state.forward_speed,
					0.0,
					_config.brake_deceleration * brake * delta
				)
		elif state.forward_speed > 0.25:
			state.forward_speed = move_toward(state.forward_speed, 0.0, _config.brake_deceleration * brake * delta)
		else:
			state.forward_speed -= _config.reverse_acceleration * brake * delta

	if throttle == 0.0 and brake == 0.0:
		state.forward_speed = move_toward(state.forward_speed, 0.0, _config.coast_deceleration * delta)

	if throttle == 0.0 and state.forward_speed > 0.0:
		state.forward_speed = move_toward(state.forward_speed, 0.0, _config.engine_brake_force * delta)

	if handbrake_active:
		state.forward_speed = move_toward(state.forward_speed, 0.0, _config.handbrake_deceleration * delta)

	_apply_resistance(state, delta)
	state.forward_speed = clampf(state.forward_speed, -_config.max_reverse_speed, _config.max_forward_speed)


func _apply_resistance(state: CarRuntimeState, delta: float) -> void:
	state.forward_speed = _resistance_model.apply(state.forward_speed, delta)


func _get_wheel_driven_rpm(state: CarRuntimeState) -> float:
	if not _config.uses_geared_transmission():
		var speed_ratio: float = clampf(absf(state.forward_speed) / _config.max_forward_speed, 0.0, 1.0)
		return lerpf(_config.idle_rpm, _config.redline_rpm, speed_ratio)

	if state.current_gear == 0:
		return _config.idle_rpm

	var coupled_rpm: float = _get_coupled_engine_rpm_for_gear(state, state.current_gear)
	if _config.automatic_transmission_enabled:
		return _get_torque_converter_rpm(state, coupled_rpm)

	return coupled_rpm


func _get_coupled_engine_rpm_for_gear(state: CarRuntimeState, gear: int) -> float:
	return _drivetrain_model.get_coupled_engine_rpm_for_gear(gear, state.forward_speed)


func _get_torque_converter_rpm(state: CarRuntimeState, coupled_rpm: float) -> float:
	var drive_input: float = state.brake_input if state.current_gear < 0 else state.throttle_input
	return _torque_converter_model.get_coupled_rpm(coupled_rpm, drive_input)


func _get_transmission_drive_acceleration(state: CarRuntimeState, throttle: float) -> float:
	return _drivetrain_model.get_drive_acceleration(
		throttle,
		state.current_gear,
		_config.manual_transmission_enabled and state.shift_timer > 0.0,
		get_torque_multiplier(),
		get_rev_limiter_multiplier(),
		_get_torque_converter_torque_multiplier(throttle)
	)


func _get_torque_converter_torque_multiplier(drive_input: float) -> float:
	if not _config.automatic_transmission_enabled:
		return 1.0

	return _torque_converter_model.get_torque_multiplier(_engine_model.get_rpm(), drive_input)


func _get_current_gear_ratio(state: CarRuntimeState) -> float:
	return _get_gear_ratio_for_gear(state.current_gear)


func _get_gear_ratio_for_gear(gear: int) -> float:
	return _drivetrain_model.get_gear_ratio_for_gear(gear)