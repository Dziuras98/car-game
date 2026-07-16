extends CarPowertrainController
class_name TrafficRiderPowertrainController

var _definition: TrafficRiderPowertrainDefinition
var _definition_errors := PackedStringArray()
var _planetary_automatic_active: bool = false
var _on_demand_awd_active: bool = false
var _planetary_model := PlanetaryAutomaticModel.new()
var _planetary_state := PlanetaryAutomaticRuntimeState.new()
var _awd_model := OnDemandAwdCouplingModel.new()
var _awd_state := OnDemandAwdCouplingState.new()


func set_powertrain_definition(definition: TrafficRiderPowertrainDefinition) -> void:
	_definition = definition


func get_powertrain_definition_errors() -> PackedStringArray:
	return _definition_errors.duplicate()


func has_valid_powertrain_definition() -> bool:
	return _definition != null and _definition_errors.is_empty()


func configure(config: CarDriveConfig) -> void:
	super.configure(config)
	_definition_errors = PackedStringArray(["Traffic Rider vehicle requires an explicit powertrain definition"])
	_planetary_automatic_active = false
	_on_demand_awd_active = false
	if _definition == null:
		return
	_definition_errors = _definition.validate_for(_config)
	if not _definition_errors.is_empty():
		return
	_planetary_automatic_active = _definition.planetary_automatic_enabled
	_on_demand_awd_active = _definition.on_demand_awd_enabled
	_configure_planetary_automatic()
	_configure_on_demand_awd()
	if _runtime_state != null:
		_reset_advanced_runtime(_runtime_state)


func reset(state: CarRuntimeState) -> void:
	super.reset(state)
	_reset_advanced_runtime(state)


func update(
	state: CarRuntimeState,
	throttle: float,
	brake: float,
	handbrake_active: bool,
	gear_up_pressed: bool,
	gear_down_pressed: bool,
	delta: float
) -> void:
	if _planetary_automatic_active:
		_advance_planetary_automatic(state, throttle, brake, delta)
	super.update(
		state,
		throttle,
		brake,
		handbrake_active,
		gear_up_pressed,
		gear_down_pressed,
		delta
	)
	if _planetary_automatic_active:
		_synchronize_planetary_runtime(state)


func get_engine_load(state: CarRuntimeState) -> float:
	if not _planetary_automatic_active:
		return super.get_engine_load(state)
	if state.current_gear == 0:
		return 0.0
	var drive_input: float = state.brake_input if state.current_gear < 0 else state.throttle_input
	return clampf(
		drive_input * lerpf(0.35, 1.0, _planetary_state.torque_transfer_factor),
		0.0,
		1.0
	)


func get_gear_text(state: CarRuntimeState) -> String:
	if not _planetary_automatic_active:
		return super.get_gear_text(state)
	if _planetary_state.is_shifting():
		return "%s→%s" % [
			_format_automatic_gear(_planetary_state.source_gear),
			_format_automatic_gear(_planetary_state.target_gear),
		]
	return _format_automatic_gear(_planetary_state.engaged_gear)


func get_selected_gear() -> int:
	return _planetary_state.selected_gear if _planetary_automatic_active else 0


func get_engaged_gear() -> int:
	return _planetary_state.engaged_gear if _planetary_automatic_active else 0


func get_shift_phase() -> int:
	return _planetary_state.shift_phase if _planetary_automatic_active else PlanetaryAutomaticRuntimeState.ShiftPhase.IDLE


func get_shift_progress() -> float:
	return _planetary_state.shift_progress if _planetary_automatic_active else 1.0


func get_converter_speed_ratio() -> float:
	return _planetary_state.converter_speed_ratio if _planetary_automatic_active else 1.0


func get_converter_slip_rpm() -> float:
	return _planetary_state.converter_slip_rpm if _planetary_automatic_active else 0.0


func get_lockup_engagement() -> float:
	return _planetary_state.lockup_engagement if _planetary_automatic_active else 0.0


func get_dynamic_front_torque_fraction() -> float:
	return _awd_state.front_torque_fraction if _on_demand_awd_active else (_config.awd_front_torque_fraction if _config != null else 0.0)


func get_transfer_clutch_temperature_c() -> float:
	return _awd_state.temperature_c if _on_demand_awd_active else 0.0


func _configure_planetary_automatic() -> void:
	if not _planetary_automatic_active:
		return
	_planetary_model.configure(
		_definition.torque_reduction_duration_s,
		_definition.handover_duration_s,
		_definition.inertia_duration_s,
		_definition.reapply_duration_s,
		_definition.stall_torque_multiplier,
		_definition.coupling_speed_ratio,
		_definition.lockup_minimum_speed_mps,
		_definition.lockup_minimum_gear,
		_definition.lockup_maximum_throttle,
		_definition.lockup_engage_rate_per_s,
		_definition.lockup_release_rate_per_s,
		_definition.commanded_lockup_slip_rpm,
		_definition.maximum_skip_gears
	)
	_planetary_model.minimum_torque_factor = _definition.minimum_torque_factor
	_planetary_model.handover_torque_factor = _definition.handover_torque_factor
	_planetary_model.inertia_torque_factor = _definition.inertia_torque_factor


func _configure_on_demand_awd() -> void:
	if not _on_demand_awd_active:
		return
	_awd_model.configure(
		_definition.base_front_torque_fraction,
		_definition.maximum_front_torque_fraction,
		_definition.launch_clutch_command,
		_definition.throttle_command_gain,
		_definition.slip_command_gain,
		_definition.stability_command_gain,
		_definition.clutch_engage_rate_per_s,
		_definition.clutch_release_rate_per_s,
		_definition.maximum_transfer_clutch_capacity_nm,
		_definition.high_speed_release_start_mps,
		_definition.high_speed_release_end_mps,
		_definition.transfer_clutch_thermal_mass_j_per_c,
		_definition.transfer_clutch_cooling_w_per_c,
		_definition.transfer_clutch_derate_start_c,
		_definition.transfer_clutch_shutdown_c
	)
	_config.awd_front_torque_fraction = _definition.base_front_torque_fraction


func _reset_advanced_runtime(state: CarRuntimeState) -> void:
	if state == null:
		return
	if _planetary_automatic_active:
		_planetary_model.reset(_planetary_state, state.current_gear)
		state.shift_timer = 0.0
	if _on_demand_awd_active:
		_awd_model.reset(_awd_state)
		_config.awd_front_torque_fraction = _definition.base_front_torque_fraction


func _advance_planetary_automatic(
	state: CarRuntimeState,
	throttle: float,
	brake: float,
	delta: float
) -> void:
	var turbine_rpm: float = _get_coupled_engine_rpm_for_gear(
		state,
		_planetary_state.engaged_gear
	)
	var drive_input: float = brake if _planetary_state.engaged_gear < 0 else throttle
	_planetary_model.update(
		_planetary_state,
		state.engine_rpm,
		turbine_rpm,
		drive_input,
		state.forward_speed,
		clampf(delta, 0.0, MAX_FRAME_DELTA)
	)
	_synchronize_planetary_runtime(state)


func _synchronize_planetary_runtime(state: CarRuntimeState) -> void:
	state.current_gear = _planetary_state.engaged_gear
	state.shift_timer = _planetary_model.get_remaining_shift_time(_planetary_state)


func _update_shift_timer(state: CarRuntimeState, delta: float) -> void:
	if not _planetary_automatic_active:
		super._update_shift_timer(state, delta)
		return
	state.shift_timer = _planetary_model.get_remaining_shift_time(_planetary_state)


func _update_automatic_transmission(state: CarRuntimeState, throttle: float, brake: float) -> void:
	if not _planetary_automatic_active:
		super._update_automatic_transmission(state, throttle, brake)
		return
	if _planetary_state.is_shifting():
		return
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
	if (
		state.current_gear > 1
		and throttle >= _config.automatic_kickdown_throttle
		and state.engine_rpm <= _config.automatic_kickdown_rpm
	):
		requested_gear = _planetary_model.choose_kickdown_gear(
			state.current_gear,
			_config.gear_ratios.size(),
			_get_driven_wheel_rpm(state),
			_config.gear_ratios,
			_config.final_drive_ratio,
			_config.redline_rpm
		)
	if requested_gear != state.current_gear:
		_set_transmission_gear(state, requested_gear)


func _set_transmission_gear(state: CarRuntimeState, next_gear: int) -> void:
	if not _planetary_automatic_active:
		super._set_transmission_gear(state, next_gear)
		return
	if _planetary_model.request_gear(
		_planetary_state,
		next_gear,
		_config.gear_ratios.size()
	):
		state.shift_timer = _planetary_model.get_remaining_shift_time(_planetary_state)


func _get_torque_converter_rpm(state: CarRuntimeState, coupled_rpm: float) -> float:
	if not _planetary_automatic_active:
		return super._get_torque_converter_rpm(state, coupled_rpm)
	var drive_input: float = state.brake_input if state.current_gear < 0 else state.throttle_input
	return _planetary_model.get_pump_rpm(
		_planetary_state,
		coupled_rpm,
		drive_input,
		_config.idle_rpm,
		_config.torque_converter_stall_rpm
	)


func _get_torque_converter_torque_multiplier(drive_input: float) -> float:
	if not _planetary_automatic_active:
		return super._get_torque_converter_torque_multiplier(drive_input)
	return _planetary_state.converter_torque_multiplier


func _get_transmission_drive_acceleration(state: CarRuntimeState, throttle: float) -> float:
	if not _planetary_automatic_active:
		return super._get_transmission_drive_acceleration(state, throttle)
	var acceleration: float = _drivetrain_model.get_drive_acceleration(
		throttle,
		_planetary_state.engaged_gear,
		false,
		get_torque_multiplier(),
		get_rev_limiter_multiplier(),
		_planetary_state.converter_torque_multiplier
	)
	acceleration *= _planetary_state.torque_transfer_factor
	return clampf(
		acceleration,
		-_config.max_drive_acceleration,
		_config.max_drive_acceleration
	)


func _update_speed_step(
	state: CarRuntimeState,
	throttle: float,
	brake: float,
	handbrake_active: bool,
	delta: float
) -> void:
	if _on_demand_awd_active:
		_update_on_demand_awd(state, throttle, brake, delta)
	super._update_speed_step(state, throttle, brake, handbrake_active, delta)


func _update_on_demand_awd(
	state: CarRuntimeState,
	throttle: float,
	brake: float,
	delta: float
) -> void:
	var drive_input: float = brake if state.current_gear < 0 else throttle
	var input_torque_nm: float = _estimate_transmission_output_torque_nm(
		state,
		drive_input
	)
	_awd_model.update(
		_awd_state,
		drive_input,
		state.forward_speed,
		_get_front_axle_speed_rad_s(state),
		_get_rear_axle_speed_rad_s(state),
		maxf(state.lateral_slip_intensity, state.tire_slip_intensity),
		input_torque_nm,
		delta
	)
	_config.awd_front_torque_fraction = _awd_state.front_torque_fraction


func _estimate_transmission_output_torque_nm(
	state: CarRuntimeState,
	drive_input: float
) -> float:
	if is_zero_approx(drive_input) or state.current_gear == 0:
		return 0.0
	var ratio: float = _get_ratio_for_gear(state.current_gear)
	var engine_torque_nm: float = (
		_config.peak_engine_torque
		* get_torque_multiplier()
		* get_rev_limiter_multiplier()
		* clampf(drive_input, 0.0, 1.0)
	)
	if _planetary_automatic_active:
		engine_torque_nm *= (
			_planetary_state.converter_torque_multiplier
			* _planetary_state.torque_transfer_factor
		)
	elif _config.is_manual_transmission() or _config.is_smg_transmission():
		engine_torque_nm *= clampf(state.clutch_engagement, 0.0, 1.0)
	return (
		engine_torque_nm
		* ratio
		* _config.final_drive_ratio
		* _config.drivetrain_efficiency
		* signf(float(state.current_gear))
	)


func _get_ratio_for_gear(gear: int) -> float:
	if gear < 0:
		return _config.reverse_gear_ratio
	var index: int = clampi(gear - 1, 0, maxi(_config.gear_ratios.size() - 1, 0))
	return _config.gear_ratios[index] if not _config.gear_ratios.is_empty() else 1.0


func _get_front_axle_speed_rad_s(state: CarRuntimeState) -> float:
	return _get_axle_speed_rad_s(
		state,
		WheelTireState.Position.FRONT_LEFT,
		WheelTireState.Position.FRONT_RIGHT
	)


func _get_rear_axle_speed_rad_s(state: CarRuntimeState) -> float:
	return _get_axle_speed_rad_s(
		state,
		WheelTireState.Position.REAR_LEFT,
		WheelTireState.Position.REAR_RIGHT
	)


func _get_axle_speed_rad_s(state: CarRuntimeState, first_index: int, second_index: int) -> float:
	var first: WheelTireState = state.get_wheel_state(first_index)
	var second: WheelTireState = state.get_wheel_state(second_index)
	if first == null or second == null:
		return 0.0
	return (first.angular_velocity_rad_s + second.angular_velocity_rad_s) * 0.5


func _get_driven_wheel_rpm(state: CarRuntimeState) -> float:
	return absf(state.get_average_driven_wheel_angular_velocity(_config)) * 60.0 / TAU


func _format_automatic_gear(gear: int) -> String:
	if gear < 0:
		return "R"
	if gear == 0:
		return "N"
	return "D%d" % gear
