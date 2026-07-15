extends CarPowertrainController
class_name BmwE46PowertrainController

var _torque_converter_automatic_model: AutomaticTransmissionModel = AutomaticTransmissionModel.new()
var _smg_transmission_model: SmgTransmissionModel = SmgTransmissionModel.new()


func reset(state: CarRuntimeState) -> void:
	super.reset(state)
	if _config != null and _config.is_smg_transmission():
		state.clutch_engagement = 0.0


func get_engine_load(state: CarRuntimeState) -> float:
	if _config != null and _config.is_smg_transmission():
		if state.current_gear == 0 or state.shift_timer > 0.0 or state.clutch_engagement <= 0.05:
			return 0.0
		if state.current_gear < 0:
			return state.brake_input
		return state.throttle_input
	return super.get_engine_load(state)


func get_gear_text(state: CarRuntimeState) -> String:
	if _config != null and _config.is_smg_transmission():
		if state.current_gear < 0:
			return "R"
		if state.current_gear == 0:
			return "N"
		return "S%d" % state.current_gear
	return super.get_gear_text(state)


func _update_transmission_input(state: CarRuntimeState, throttle: float, brake: float, gear_up_pressed: bool, gear_down_pressed: bool) -> void:
	if _config == null:
		return
	if _config.is_torque_converter_automatic():
		_update_torque_converter_automatic_transmission(state, throttle, brake)
		return
	if not _config.is_smg_transmission():
		super._update_transmission_input(state, throttle, brake, gear_up_pressed, gear_down_pressed)
		return
	var lower_gear_rpm: float = _config.idle_rpm
	if state.current_gear > 1:
		lower_gear_rpm = _get_coupled_engine_rpm_for_gear(state, state.current_gear - 1)
	var requested_gear: int = _smg_transmission_model.get_requested_gear(
		state.current_gear,
		_config.gear_ratios.size(),
		state.forward_speed,
		state.engine_rpm,
		throttle,
		brake,
		state.shift_timer,
		_config.redline_rpm,
		_config.smg_upshift_rpm,
		_config.smg_downshift_rpm,
		lower_gear_rpm,
		_config.smg_auto_mode,
		gear_up_pressed,
		gear_down_pressed
	)
	if requested_gear != state.current_gear:
		_set_transmission_gear(state, requested_gear)


func _update_torque_converter_automatic_transmission(state: CarRuntimeState, throttle: float, brake: float) -> void:
	var lower_gear_rpm: float = _config.idle_rpm
	if state.current_gear > 1:
		lower_gear_rpm = _get_coupled_engine_rpm_for_gear(state, state.current_gear - 1)
	var requested_gear: int = _torque_converter_automatic_model.get_requested_gear(
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


func _set_transmission_gear(state: CarRuntimeState, next_gear: int) -> void:
	if _config == null or not _config.is_smg_transmission():
		super._set_transmission_gear(state, next_gear)
		return
	if next_gear == state.current_gear:
		return
	var previous_gear: int = state.current_gear
	state.current_gear = next_gear
	state.shift_timer = _config.smg_shift_delay
	state.clutch_engagement = 0.0
	_start_manual_shift_assist(state, previous_gear, next_gear)


func _get_assisted_throttle(state: CarRuntimeState, requested_throttle: float) -> float:
	if _config == null or not _config.is_smg_transmission():
		return super._get_assisted_throttle(state, requested_throttle)
	var safe_throttle: float = clampf(requested_throttle, 0.0, 1.0)
	if state.shift_timer <= 0.0:
		return safe_throttle
	if _manual_shift_assist_mode == ManualShiftAssistMode.UPSHIFT_CUT:
		return 0.0
	if _manual_shift_assist_mode != ManualShiftAssistMode.DOWNSHIFT_BLIP:
		return safe_throttle
	if state.engine_rpm >= _manual_shift_target_rpm - 25.0:
		return safe_throttle
	var usable_rpm_range: float = maxf(_config.rev_limiter_rpm - _config.idle_rpm, 1.0)
	var blip_throttle: float = clampf((_manual_shift_target_rpm - _config.idle_rpm) / usable_rpm_range, 0.0, 1.0)
	return maxf(safe_throttle, blip_throttle)


func _update_clutch(state: CarRuntimeState, throttle: float, delta: float) -> void:
	if _config == null or not _config.is_smg_transmission():
		super._update_clutch(state, throttle, delta)
		return
	state.clutch_engagement = _smg_transmission_model.get_clutch_engagement(
		state.current_gear,
		state.forward_speed,
		throttle,
		state.shift_timer,
		_config.smg_shift_delay,
		_config.smg_launch_full_speed,
		_config.smg_clutch_reengage_point
	)


func _get_wheel_driven_rpm(state: CarRuntimeState) -> float:
	if _config == null or not _config.is_smg_transmission():
		return super._get_wheel_driven_rpm(state)
	if state.current_gear == 0:
		return _config.idle_rpm
	return _get_coupled_engine_rpm_for_gear(state, state.current_gear)


func _get_engine_free_rev_blend(state: CarRuntimeState) -> float:
	if _config != null and _config.is_smg_transmission():
		if state.current_gear == 0:
			return 1.0
		return 1.0 - clampf(state.clutch_engagement, 0.0, 1.0)
	return super._get_engine_free_rev_blend(state)


func _get_transmission_drive_acceleration(state: CarRuntimeState, throttle: float) -> float:
	var acceleration: float = super._get_transmission_drive_acceleration(state, throttle)
	if _config != null and _config.is_smg_transmission():
		acceleration *= _clutch_model.get_transmitted_torque_factor(state.clutch_engagement)
	return acceleration


func _get_torque_converter_torque_multiplier(drive_input: float) -> float:
	if _config != null and _config.is_smg_transmission():
		return 1.0
	return super._get_torque_converter_torque_multiplier(drive_input)
