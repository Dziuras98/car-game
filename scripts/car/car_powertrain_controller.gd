extends RefCounted
class_name CarPowertrainController

const MAX_FRAME_DELTA: float = 0.10
const MAX_SIMULATION_SUBSTEP: float = 1.0 / 120.0

enum ManualShiftAssistMode {
	NONE,
	UPSHIFT_CUT,
	DOWNSHIFT_BLIP,
}

var _manual_transmission_model: ManualTransmissionModel = ManualTransmissionModel.new()
var _automatic_transmission_model: AutomaticTransmissionModel = AutomaticTransmissionModel.new()
var _shift_timer_model: ShiftTimerModel = ShiftTimerModel.new()
var _clutch_model: ClutchModel = ClutchModel.new()
var _engine_model: EngineModel = EngineModel.new()
var _resistance_model: ResistanceModel = ResistanceModel.new()
var _drivetrain_model: DrivetrainModel = DrivetrainModel.new()
var _torque_converter_model: TorqueConverterModel = TorqueConverterModel.new()
var _tire_model: TireModel = TireModel.new()
var _config: CarDriveConfig
var _runtime_state: CarRuntimeState
var _manual_shift_assist_mode: int = ManualShiftAssistMode.NONE
var _manual_shift_target_rpm: float = 0.0


func configure(config: CarDriveConfig) -> void:
	var preserved_engine_rpm: float = _engine_model.get_rpm()
	if _runtime_state != null:
		preserved_engine_rpm = _runtime_state.engine_rpm

	_reset_manual_shift_assist()
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
		_config.rpm_response,
		_config.torque_curve
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
		_runtime_state.clutch_engagement = clampf(_runtime_state.clutch_engagement, 0.0, 1.0) if _config.is_manual_transmission() else 1.0


func reset(state: CarRuntimeState) -> void:
	_runtime_state = state
	_reset_manual_shift_assist()
	state.engine_rpm = _engine_model.reset()
	state.clutch_engagement = 0.0 if _config != null and _config.is_manual_transmission() else 1.0


func update(state: CarRuntimeState, throttle: float, brake: float, handbrake_active: bool, gear_up_pressed: bool, gear_down_pressed: bool, delta: float) -> void:
	if _config == null:
		return
	_runtime_state = state
	var safe_delta: float = clampf(delta, 0.0, MAX_FRAME_DELTA)
	var safe_throttle: float = clampf(throttle, 0.0, 1.0)
	var safe_brake: float = clampf(brake, 0.0, 1.0)
	_update_shift_timer(state, safe_delta)
	_update_transmission_input(state, safe_throttle, safe_brake, gear_up_pressed, gear_down_pressed)
	var assisted_throttle: float = _get_assisted_throttle(state, safe_throttle)
	state.throttle_input = assisted_throttle
	if safe_delta <= 0.0:
		_update_engine(state, assisted_throttle, 0.0)
		return
	var remaining_delta: float = safe_delta
	while remaining_delta > 0.000001:
		var step: float = minf(remaining_delta, MAX_SIMULATION_SUBSTEP)
		_update_clutch(state, assisted_throttle, step)
		_update_engine(state, assisted_throttle, step)
		_update_speed_step(state, assisted_throttle, safe_brake, handbrake_active, step)
		remaining_delta -= step


func get_engine_load(state: CarRuntimeState) -> float:
	if _config == null:
		return 0.0
	if _config.uses_geared_transmission() and (state.current_gear == 0 or state.shift_timer > 0.0):
		return 0.0
	if _config.is_manual_transmission() and state.clutch_engagement <= 0.05:
		return 0.0
	if _config.is_automatic_transmission() and state.current_gear < 0:
		return state.brake_input
	return state.throttle_input


func get_gear_text(state: CarRuntimeState) -> String:
	if _config == null:
		return "N"
	if _config.is_manual_transmission():
		if state.current_gear < 0:
			return "R"
		if state.current_gear == 0:
			return "N"
		return str(state.current_gear)
	if _config.is_automatic_transmission():
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


func _update_transmission_input(state: CarRuntimeState, throttle: float, brake: float, gear_up_pressed: bool, gear_down_pressed: bool) -> void:
	if _config.is_manual_transmission():
		var requested_gear: int = _manual_transmission_model.get_requested_gear(state.current_gear, _config.gear_ratios.size(), gear_up_pressed, gear_down_pressed)
		if requested_gear != state.current_gear:
			_set_transmission_gear(state, requested_gear)
		return
	if _config.is_automatic_transmission():
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
	if state.shift_timer <= 0.0:
		_reset_manual_shift_assist()


func _set_transmission_gear(state: CarRuntimeState, next_gear: int) -> void:
	if next_gear == state.current_gear:
		return
	var previous_gear: int = state.current_gear
	state.current_gear = next_gear
	state.shift_timer = _shift_timer_model.get_shift_delay(_config.is_automatic_transmission(), _config.automatic_shift_delay, _config.shift_delay)
	if _config.is_manual_transmission():
		state.clutch_engagement = 0.0
		_start_manual_shift_assist(state, previous_gear, next_gear)


func _start_manual_shift_assist(state: CarRuntimeState, previous_gear: int, next_gear: int) -> void:
	_reset_manual_shift_assist()
	if state.shift_timer <= 0.0 or previous_gear <= 0 or next_gear <= 0:
		return
	if next_gear > previous_gear:
		_manual_shift_assist_mode = ManualShiftAssistMode.UPSHIFT_CUT
		return
	if next_gear >= previous_gear:
		return

	var coupled_rpm: float = _get_coupled_engine_rpm_for_gear(state, next_gear)
	_manual_shift_target_rpm = clampf(coupled_rpm, _config.idle_rpm, _config.redline_rpm)
	if _manual_shift_target_rpm <= state.engine_rpm + 25.0:
		_manual_shift_target_rpm = 0.0
		return
	_manual_shift_assist_mode = ManualShiftAssistMode.DOWNSHIFT_BLIP


func _get_assisted_throttle(state: CarRuntimeState, requested_throttle: float) -> float:
	var safe_throttle: float = clampf(requested_throttle, 0.0, 1.0)
	if not _config.is_manual_transmission() or state.shift_timer <= 0.0:
		return safe_throttle
	if _manual_shift_assist_mode == ManualShiftAssistMode.UPSHIFT_CUT:
		return 0.0
	if _manual_shift_assist_mode != ManualShiftAssistMode.DOWNSHIFT_BLIP:
		return safe_throttle
	if state.engine_rpm >= _manual_shift_target_rpm - 25.0:
		return safe_throttle

	var usable_rpm_range: float = maxf(_config.rev_limiter_rpm - _config.idle_rpm, 1.0)
	var blip_throttle: float = clampf(
		(_manual_shift_target_rpm - _config.idle_rpm) / usable_rpm_range,
		0.0,
		1.0
	)
	return maxf(safe_throttle, blip_throttle)


func _reset_manual_shift_assist() -> void:
	_manual_shift_assist_mode = ManualShiftAssistMode.NONE
	_manual_shift_target_rpm = 0.0


func _update_clutch(state: CarRuntimeState, throttle: float, delta: float) -> void:
	if not _config.is_manual_transmission():
		state.clutch_engagement = 1.0
		return
	state.clutch_engagement = _clutch_model.update_engagement(state.clutch_engagement, state.current_gear, state.forward_speed, throttle, state.shift_timer, delta)


func _update_engine(state: CarRuntimeState, throttle: float, delta: float) -> void:
	state.engine_rpm = _engine_model.update(throttle, _get_wheel_driven_rpm(state), delta, _get_engine_free_rev_blend(state))


func _update_speed_step(state: CarRuntimeState, throttle: float, brake: float, handbrake_active: bool, delta: float) -> void:
	var effective_throttle: float = throttle if brake <= 0.0 else 0.0
	if effective_throttle > 0.0:
		_apply_throttle(state, effective_throttle, delta)
	elif brake > 0.0:
		_apply_brake_or_reverse(state, brake, delta)
	else:
		var ground_factor: float = _get_ground_contact_factor(state)
		var passive_deceleration: float = _config.coast_deceleration * ground_factor
		if absf(state.forward_speed) > 0.0 and (not _config.is_manual_transmission() or state.clutch_engagement > 0.1):
			passive_deceleration += _config.engine_brake_force * state.clutch_engagement * ground_factor
		state.forward_speed = move_toward(state.forward_speed, 0.0, passive_deceleration * delta)
	if handbrake_active:
		state.forward_speed = move_toward(state.forward_speed, 0.0, _config.handbrake_deceleration * _get_longitudinal_grip_factor(state) * delta)
	state.forward_speed = _resistance_model.apply(state.forward_speed, delta, state.ground_contact_count > 0)
	state.forward_speed = clampf(state.forward_speed, -_config.max_reverse_speed, _config.max_forward_speed)


func _apply_throttle(state: CarRuntimeState, throttle: float, delta: float) -> void:
	if _config.uses_geared_transmission():
		var direction_threshold: float = AutomaticTransmissionModel.DIRECTION_CHANGE_SPEED_THRESHOLD
		if (
			_config.is_automatic_transmission()
			and (
				state.current_gear < 1
				or state.forward_speed < -direction_threshold
			)
		):
			state.forward_speed = move_toward(state.forward_speed, 0.0, _config.brake_deceleration * throttle * _get_longitudinal_grip_factor(state) * delta)
		else:
			state.forward_speed += _get_transmission_drive_acceleration(state, throttle) * delta
		return
	state.forward_speed += throttle * _config.engine_force * get_torque_multiplier() * get_rev_limiter_multiplier() * _get_longitudinal_grip_factor(state) * delta


func _apply_brake_or_reverse(state: CarRuntimeState, brake: float, delta: float) -> void:
	var brake_delta: float = _config.brake_deceleration * brake * _get_longitudinal_grip_factor(state) * delta
	if _config.is_manual_transmission():
		state.forward_speed = move_toward(state.forward_speed, 0.0, brake_delta)
		return
	if _config.is_automatic_transmission():
		if state.current_gear < 0:
			if state.forward_speed > AutomaticTransmissionModel.DIRECTION_CHANGE_SPEED_THRESHOLD:
				state.forward_speed = move_toward(state.forward_speed, 0.0, brake_delta)
			else:
				state.forward_speed += _get_transmission_drive_acceleration(state, brake) * delta
		else:
			state.forward_speed = move_toward(state.forward_speed, 0.0, brake_delta)
		return
	if state.forward_speed > 0.25:
		state.forward_speed = move_toward(state.forward_speed, 0.0, brake_delta)
	else:
		state.forward_speed -= _config.reverse_acceleration * brake * _get_longitudinal_grip_factor(state) * delta


func _get_wheel_driven_rpm(state: CarRuntimeState) -> float:
	if not _config.uses_geared_transmission():
		var speed_ratio: float = clampf(absf(state.forward_speed) / _config.max_forward_speed, 0.0, 1.0)
		return lerpf(_config.idle_rpm, _config.redline_rpm, speed_ratio)
	if state.current_gear == 0:
		return _config.idle_rpm
	var coupled_rpm: float = _get_coupled_engine_rpm_for_gear(state, state.current_gear)
	if _config.is_automatic_transmission():
		return _get_torque_converter_rpm(state, coupled_rpm)
	return coupled_rpm


func _get_engine_free_rev_blend(state: CarRuntimeState) -> float:
	if not _config.uses_geared_transmission() or state.current_gear == 0:
		return 1.0
	if state.ground_contact_count <= 0:
		return 1.0
	if _config.is_manual_transmission():
		return 1.0 - clampf(state.clutch_engagement, 0.0, 1.0)
	return 0.0


func _get_coupled_engine_rpm_for_gear(state: CarRuntimeState, gear: int) -> float:
	return _drivetrain_model.get_coupled_engine_rpm_for_gear(gear, state.forward_speed)


func _get_torque_converter_rpm(state: CarRuntimeState, coupled_rpm: float) -> float:
	var drive_input: float = state.brake_input if state.current_gear < 0 else state.throttle_input
	return _torque_converter_model.get_coupled_rpm(coupled_rpm, drive_input)


func _get_transmission_drive_acceleration(state: CarRuntimeState, throttle: float) -> float:
	var acceleration: float = _drivetrain_model.get_drive_acceleration(
		throttle,
		state.current_gear,
		_config.uses_geared_transmission() and state.shift_timer > 0.0,
		get_torque_multiplier(),
		get_rev_limiter_multiplier(),
		_get_torque_converter_torque_multiplier(throttle)
	)
	acceleration = clampf(
		acceleration,
		-_config.max_drive_acceleration,
		_config.max_drive_acceleration
	)
	if _config.is_manual_transmission():
		acceleration *= _clutch_model.get_transmitted_torque_factor(state.clutch_engagement)
	return acceleration * _get_longitudinal_grip_factor(state)


func _get_torque_converter_torque_multiplier(drive_input: float) -> float:
	if not _config.is_automatic_transmission():
		return 1.0
	return _torque_converter_model.get_torque_multiplier(_engine_model.get_rpm(), drive_input)


func _get_ground_contact_factor(state: CarRuntimeState) -> float:
	return clampf(
		float(state.ground_contact_count) / float(GroundContactModel.PROBE_COUNT),
		0.0,
		1.0
	)
