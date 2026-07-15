extends RefCounted
class_name CarPowertrainController

const MAX_FRAME_DELTA: float = 0.10
const MAX_SIMULATION_SUBSTEP: float = 1.0 / 120.0
const PER_WHEEL_LOAD_SHARE: float = 1.0 / 4.0

enum ManualShiftAssistMode {
	NONE,
	UPSHIFT_CUT,
	DOWNSHIFT_BLIP,
}

var _manual_transmission_model: ManualTransmissionModel = ManualTransmissionModel.new()
var _automatic_transmission_model: AutomaticTransmissionModel = AutomaticTransmissionModel.new()
var _cvt_transmission_model: CvtTransmissionModel = CvtTransmissionModel.new()
var _shift_timer_model: ShiftTimerModel = ShiftTimerModel.new()
var _clutch_model: ClutchModel = ClutchModel.new()
var _engine_model: EngineModel = EngineModel.new()
var _resistance_model: ResistanceModel = ResistanceModel.new()
var _drivetrain_model: DrivetrainModel = DrivetrainModel.new()
var _torque_converter_model: TorqueConverterModel = TorqueConverterModel.new()
var _tire_model: TireModel = TireModel.new()
var _wheel_rotational_dynamics_model: WheelRotationalDynamicsModel = WheelRotationalDynamicsModel.new()
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
	_cvt_transmission_model.configure(
		_config.idle_rpm,
		_config.cvt_max_ratio,
		_config.reverse_gear_ratio,
		_config.final_drive_ratio,
		_config.wheel_radius,
		_config.peak_engine_torque,
		_config.drivetrain_efficiency,
		_config.vehicle_mass,
		_config.cvt_target_rpm_min,
		_config.cvt_target_rpm_max,
		_config.cvt_ratio_response,
		_config.cvt_clutch_engagement_rpm,
		_config.cvt_clutch_full_rpm
	)

	if _runtime_state != null:
		_runtime_state.configure_wheel_rotation(_config, true)
		_runtime_state.engine_rpm = _engine_model.set_rpm(preserved_engine_rpm)
		if _config.is_manual_transmission():
			_runtime_state.clutch_engagement = clampf(_runtime_state.clutch_engagement, 0.0, 1.0)
		elif _config.is_cvt_transmission():
			_runtime_state.clutch_engagement = _cvt_transmission_model.get_clutch_factor(_runtime_state.engine_rpm)
		else:
			_runtime_state.clutch_engagement = 1.0


func reset(state: CarRuntimeState) -> void:
	_runtime_state = state
	_reset_manual_shift_assist()
	_cvt_transmission_model.reset()
	state.configure_wheel_rotation(_config, false)
	state.engine_rpm = _engine_model.reset()
	if _config != null and _config.is_manual_transmission():
		state.clutch_engagement = 0.0
	elif _config != null and _config.is_cvt_transmission():
		state.clutch_engagement = _cvt_transmission_model.get_clutch_factor(state.engine_rpm)
	else:
		state.clutch_engagement = 1.0


func update(state: CarRuntimeState, throttle: float, brake: float, handbrake_active: bool, gear_up_pressed: bool, gear_down_pressed: bool, delta: float) -> void:
	if _config == null:
		return
	_runtime_state = state
	state.configure_wheel_rotation(_config, true)
	var safe_delta: float = clampf(delta, 0.0, MAX_FRAME_DELTA)
	var safe_throttle: float = clampf(throttle, 0.0, 1.0)
	var safe_brake: float = clampf(brake, 0.0, 1.0)
	_update_shift_timer(state, safe_delta)
	_update_transmission_input(state, safe_throttle, safe_brake, gear_up_pressed, gear_down_pressed)
	var assisted_throttle: float = _get_assisted_throttle(state, safe_throttle)
	state.throttle_input = assisted_throttle
	if safe_delta <= 0.0:
		_update_cvt_ratio(state, assisted_throttle, 0.0)
		_update_clutch(state, assisted_throttle, 0.0)
		_update_engine(state, assisted_throttle, 0.0)
		return
	var remaining_delta: float = safe_delta
	while remaining_delta > 0.000001:
		var step: float = minf(remaining_delta, MAX_SIMULATION_SUBSTEP)
		_update_cvt_ratio(state, assisted_throttle, step)
		_update_clutch(state, assisted_throttle, step)
		_update_engine(state, assisted_throttle, step)
		_update_clutch(state, assisted_throttle, 0.0)
		_update_speed_step(state, assisted_throttle, safe_brake, handbrake_active, step)
		remaining_delta -= step


func get_engine_load(state: CarRuntimeState) -> float:
	if _config == null:
		return 0.0
	if _config.uses_discrete_gears() and (state.current_gear == 0 or state.shift_timer > 0.0):
		return 0.0
	if _config.is_manual_transmission() and state.clutch_engagement <= 0.05:
		return 0.0
	if _config.is_self_shifting_transmission() and state.current_gear < 0:
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
	if _config.is_cvt_transmission():
		return "R" if state.current_gear < 0 else "D"
	if state.forward_speed < -0.25:
		return "R"
	if state.forward_speed > 0.25:
		return "D"
	return "N"


func get_torque_multiplier() -> float:
	return _engine_model.get_torque_multiplier()


func get_rev_limiter_multiplier() -> float:
	return _engine_model.get_rev_limiter_multiplier()


func get_cvt_ratio() -> float:
	return _cvt_transmission_model.get_current_ratio() if _config != null and _config.is_cvt_transmission() else 0.0


func _update_transmission_input(state: CarRuntimeState, throttle: float, brake: float, gear_up_pressed: bool, gear_down_pressed: bool) -> void:
	if _config.is_manual_transmission():
		var requested_gear: int = _manual_transmission_model.get_requested_gear(
			state.current_gear,
			_config.gear_ratios.size(),
			gear_up_pressed,
			gear_down_pressed
		)
		if requested_gear != state.current_gear:
			var requested_gear_rpm: float = (
				_get_coupled_engine_rpm_for_gear(state, requested_gear)
				if requested_gear > 0
				else _config.idle_rpm
			)
			if _manual_transmission_model.is_shift_safe(
				requested_gear,
				state.forward_speed,
				requested_gear_rpm,
				_config.rev_limiter_rpm
			):
				_set_transmission_gear(state, requested_gear)
		return
	if _config.is_automatic_transmission():
		_update_automatic_transmission(state, throttle, brake)
		return
	if _config.is_cvt_transmission():
		_update_cvt_transmission(state, throttle, brake)


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


func _update_cvt_transmission(state: CarRuntimeState, throttle: float, brake: float) -> void:
	if state.shift_timer > 0.0:
		return
	var threshold: float = CvtTransmissionModel.DIRECTION_CHANGE_SPEED_THRESHOLD
	if state.current_gear < 0:
		if throttle > 0.05 and brake <= 0.05 and state.forward_speed >= -threshold:
			_set_transmission_gear(state, 1)
		return
	if brake > 0.05 and throttle <= 0.05 and state.forward_speed <= threshold:
		_set_transmission_gear(state, -1)
	elif state.current_gear <= 0:
		_set_transmission_gear(state, 1)


func _update_shift_timer(state: CarRuntimeState, delta: float) -> void:
	state.shift_timer = _shift_timer_model.update_timer(state.shift_timer, delta)
	if state.shift_timer <= 0.0:
		_reset_manual_shift_assist()


func _set_transmission_gear(state: CarRuntimeState, next_gear: int) -> void:
	if next_gear == state.current_gear:
		return
	var previous_gear: int = state.current_gear
	state.current_gear = next_gear
	state.shift_timer = _shift_timer_model.get_shift_delay(_config.is_self_shifting_transmission(), _config.automatic_shift_delay, _config.shift_delay)
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


func _update_cvt_ratio(state: CarRuntimeState, throttle: float, delta: float) -> void:
	if not _config.is_cvt_transmission() or state.current_gear < 0:
		return
	_cvt_transmission_model.update_ratio(_get_driven_wheel_surface_speed(state), throttle, delta)


func _update_clutch(state: CarRuntimeState, throttle: float, delta: float) -> void:
	if _config.is_cvt_transmission():
		state.clutch_engagement = _cvt_transmission_model.get_clutch_factor(state.engine_rpm)
		return
	if not _config.is_manual_transmission():
		state.clutch_engagement = 1.0
		return
	state.clutch_engagement = _clutch_model.update_engagement(state.clutch_engagement, state.current_gear, state.forward_speed, throttle, state.shift_timer, delta)


func _update_engine(state: CarRuntimeState, throttle: float, delta: float) -> void:
	state.engine_rpm = _engine_model.update(throttle, _get_wheel_driven_rpm(state), delta, _get_engine_free_rev_blend(state))


func _update_speed_step(state: CarRuntimeState, throttle: float, brake: float, handbrake_active: bool, delta: float) -> void:
	_reset_longitudinal_slip(state)
	var requested_drive_acceleration: float = 0.0
	var service_brake_deceleration: float = 0.0
	var engine_brake_deceleration: float = 0.0
	var handbrake_deceleration: float = _config.handbrake_deceleration if handbrake_active else 0.0
	var effective_throttle: float = throttle if brake <= 0.0 else 0.0

	if effective_throttle > 0.0:
		if _config.uses_geared_transmission():
			var direction_threshold: float = AutomaticTransmissionModel.DIRECTION_CHANGE_SPEED_THRESHOLD
			if (
				_config.is_self_shifting_transmission()
				and (state.current_gear < 1 or state.forward_speed < -direction_threshold)
			):
				service_brake_deceleration = _config.brake_deceleration * effective_throttle
			else:
				requested_drive_acceleration = _get_transmission_drive_acceleration(state, effective_throttle)
		else:
			requested_drive_acceleration = (
				effective_throttle
				* _config.engine_force
				* get_torque_multiplier()
				* get_rev_limiter_multiplier()
			)
	elif brake > 0.0:
		if _config.is_manual_transmission():
			service_brake_deceleration = _config.brake_deceleration * brake
		elif _config.is_self_shifting_transmission():
			if state.current_gear < 0 and state.forward_speed <= AutomaticTransmissionModel.DIRECTION_CHANGE_SPEED_THRESHOLD:
				requested_drive_acceleration = _get_transmission_drive_acceleration(state, brake)
			else:
				service_brake_deceleration = _config.brake_deceleration * brake
		elif state.forward_speed > 0.25:
			service_brake_deceleration = _config.brake_deceleration * brake
		else:
			requested_drive_acceleration = -_config.reverse_acceleration * brake
	else:
		var ground_factor: float = _get_ground_contact_factor(state)
		state.forward_speed = move_toward(
			state.forward_speed,
			0.0,
			_config.coast_deceleration * ground_factor * delta
		)
		if absf(state.forward_speed) > 0.0 and (not _config.is_manual_transmission() or state.clutch_engagement > 0.1):
			engine_brake_deceleration = _config.engine_brake_force * state.clutch_engagement

	_simulate_wheel_dynamics(
		state,
		requested_drive_acceleration,
		service_brake_deceleration,
		engine_brake_deceleration,
		handbrake_deceleration,
		delta
	)
	state.forward_speed = _resistance_model.apply(state.forward_speed, delta, state.ground_contact_count > 0)
	state.forward_speed = clampf(state.forward_speed, -_config.max_reverse_speed, _config.max_forward_speed)
	_update_combined_slip(state)


func _simulate_wheel_dynamics(
	state: CarRuntimeState,
	requested_drive_acceleration: float,
	service_brake_deceleration: float,
	engine_brake_deceleration: float,
	handbrake_deceleration: float,
	delta: float
) -> void:
	state.synchronize_wheel_contacts_from_aggregate()
	state.configure_wheel_rotation(_config, true)
	_initialize_external_motion_wheel_state(state)
	var mass: float = maxf(_config.vehicle_mass, 1.0)
	var radius: float = maxf(_config.wheel_radius, 0.01)
	var total_drive_torque_nm: float = requested_drive_acceleration * mass * radius
	var total_service_brake_torque_nm: float = maxf(service_brake_deceleration, 0.0) * mass * radius
	var total_engine_brake_torque_nm: float = maxf(engine_brake_deceleration, 0.0) * mass * radius
	var total_handbrake_torque_nm: float = maxf(handbrake_deceleration, 0.0) * mass * radius
	var vehicle_acceleration: float = 0.0
	var braking_direction: float = -signf(state.forward_speed)
	if braking_direction == 0.0:
		braking_direction = -signf(state.get_average_driven_wheel_angular_velocity(_config))
	var estimated_longitudinal_acceleration: float = (
		requested_drive_acceleration
		+ braking_direction
		* (service_brake_deceleration + engine_brake_deceleration + handbrake_deceleration)
	)

	for wheel: WheelTireState in state.wheel_states:
		var drive_fraction: float = _config.get_drive_torque_fraction(wheel.wheel_index)
		var brake_fraction: float = _config.get_service_brake_fraction(wheel.wheel_index)
		var handbrake_fraction: float = _config.get_handbrake_fraction(wheel.wheel_index)
		var load_share: float = _config.get_wheel_load_share(
			wheel.wheel_index,
			estimated_longitudinal_acceleration
		)
		var drive_torque_nm: float = total_drive_torque_nm * drive_fraction
		var brake_torque_nm: float = (
			total_service_brake_torque_nm * brake_fraction
			+ total_engine_brake_torque_nm * drive_fraction
			+ total_handbrake_torque_nm * handbrake_fraction
		)
		var requested_wheel_acceleration: float = (
			requested_drive_acceleration * drive_fraction
			+ braking_direction
			* (
				service_brake_deceleration * brake_fraction
				+ engine_brake_deceleration * drive_fraction
				+ handbrake_deceleration * handbrake_fraction
			)
		)
		var tire_acceleration: float = 0.0
		var slip_ratio: float = 0.0
		if wheel.has_contact:
			slip_ratio = _wheel_rotational_dynamics_model.calculate_slip_ratio(
				wheel.angular_velocity_rad_s,
				wheel.wheel_radius_m,
				state.forward_speed,
				_config.wheel_slip_reference_speed_mps
			)
			tire_acceleration = _tire_model.resolve_longitudinal_acceleration_from_slip(
				slip_ratio,
				wheel.lateral_slip_intensity,
				wheel.surface_grip_multiplier,
				load_share,
				_config.longitudinal_grip_coefficient,
				_config.longitudinal_peak_slip_ratio,
				_config.longitudinal_slide_grip_multiplier
			)
			vehicle_acceleration += tire_acceleration
		_record_longitudinal_slip(
			wheel,
			requested_wheel_acceleration,
			tire_acceleration,
			slip_ratio
		)
		_wheel_rotational_dynamics_model.integrate_wheel(
			wheel,
			drive_torque_nm,
			brake_torque_nm,
			tire_acceleration,
			mass,
			_config.wheel_angular_damping_nm_per_rad_s,
			state.forward_speed,
			delta,
			_get_effective_wheel_inertia(state, wheel, drive_fraction)
		)
		_clamp_driven_wheel_to_engine_limit(state, wheel, drive_fraction)

	state.forward_speed += vehicle_acceleration * delta
	state.update_slip_aggregates()


func _initialize_external_motion_wheel_state(state: CarRuntimeState) -> void:
	if absf(state.forward_speed) < WheelRotationalDynamicsModel.MIN_REFERENCE_SPEED_MPS:
		return
	for wheel: WheelTireState in state.wheel_states:
		if (
			absf(wheel.angular_velocity_rad_s) > 0.0001
			or absf(wheel.angular_position_rad) > 0.0001
			or absf(wheel.drive_torque_nm) > 0.0001
			or absf(wheel.brake_torque_nm) > 0.0001
			or absf(wheel.tire_torque_nm) > 0.0001
		):
			return
	for wheel: WheelTireState in state.wheel_states:
		wheel.set_rolling_speed(state.forward_speed)


func _get_effective_wheel_inertia(
	state: CarRuntimeState,
	wheel: WheelTireState,
	drive_fraction: float
) -> float:
	var base_inertia: float = maxf(wheel.moment_of_inertia_kg_m2, 0.01)
	if drive_fraction <= 0.0 or state.current_gear == 0:
		return base_inertia
	var active_ratio: float = _get_active_drivetrain_ratio(state)
	if active_ratio <= 0.0:
		return base_inertia
	var coupling: float = 1.0
	if _config.is_manual_transmission() or _config.is_cvt_transmission() or _config.is_smg_transmission():
		coupling = sqrt(clampf(state.clutch_engagement, 0.0, 1.0))
	elif _config.is_torque_converter_automatic():
		coupling = 0.65
	if state.shift_timer > 0.0:
		coupling = 0.0
	var engine_side_inertia: float = clampf(
		0.08 + _config.peak_engine_torque * 0.00028,
		0.10,
		0.24
	)
	var reflected_inertia: float = (
		engine_side_inertia
		* active_ratio
		* active_ratio
		* drive_fraction
		* coupling
	)
	return base_inertia + reflected_inertia


func _get_active_drivetrain_ratio(state: CarRuntimeState) -> float:
	if not _config.uses_geared_transmission() or state.current_gear == 0:
		return 1.0
	var transmission_ratio: float
	if _config.is_cvt_transmission():
		transmission_ratio = _cvt_transmission_model.get_current_ratio()
	elif state.current_gear < 0:
		transmission_ratio = _config.reverse_gear_ratio
	else:
		var gear_index: int = clampi(state.current_gear - 1, 0, _config.gear_ratios.size() - 1)
		transmission_ratio = _config.gear_ratios[gear_index]
	return absf(transmission_ratio * _config.final_drive_ratio)


func _clamp_driven_wheel_to_engine_limit(
	state: CarRuntimeState,
	wheel: WheelTireState,
	drive_fraction: float
) -> void:
	if drive_fraction <= 0.0 or not _config.uses_geared_transmission() or state.current_gear == 0:
		return
	var coupling: float = 1.0
	if _config.is_manual_transmission() or _config.is_cvt_transmission() or _config.is_smg_transmission():
		coupling = clampf(state.clutch_engagement, 0.0, 1.0)
	if coupling < 0.10 or state.shift_timer > 0.0:
		return
	var active_ratio: float = _get_active_drivetrain_ratio(state)
	if active_ratio <= 0.0:
		return
	var maximum_wheel_speed: float = _config.rev_limiter_rpm * TAU / 60.0 / active_ratio
	if state.current_gear < 0:
		wheel.angular_velocity_rad_s = clampf(wheel.angular_velocity_rad_s, -maximum_wheel_speed, 0.0)
	else:
		wheel.angular_velocity_rad_s = clampf(wheel.angular_velocity_rad_s, 0.0, maximum_wheel_speed)


func _apply_throttle(state: CarRuntimeState, throttle: float, delta: float) -> void:
	var requested_acceleration: float
	if _config.uses_geared_transmission():
		requested_acceleration = _get_transmission_drive_acceleration(state, throttle)
	else:
		requested_acceleration = throttle * _config.engine_force * get_torque_multiplier() * get_rev_limiter_multiplier()
	_simulate_wheel_dynamics(state, requested_acceleration, 0.0, 0.0, 0.0, delta)


func _apply_brake_or_reverse(state: CarRuntimeState, brake: float, delta: float) -> void:
	if _config.is_self_shifting_transmission() and state.current_gear < 0 and state.forward_speed <= AutomaticTransmissionModel.DIRECTION_CHANGE_SPEED_THRESHOLD:
		_simulate_wheel_dynamics(state, _get_transmission_drive_acceleration(state, brake), 0.0, 0.0, 0.0, delta)
		return
	if not _config.uses_geared_transmission() and state.forward_speed <= 0.25:
		_simulate_wheel_dynamics(state, -_config.reverse_acceleration * brake, 0.0, 0.0, 0.0, delta)
		return
	_simulate_wheel_dynamics(state, 0.0, _config.brake_deceleration * brake, 0.0, 0.0, delta)


func _apply_braking_acceleration(state: CarRuntimeState, deceleration: float, delta: float) -> void:
	_simulate_wheel_dynamics(state, 0.0, maxf(deceleration, 0.0), 0.0, 0.0, delta)


func _apply_longitudinal_acceleration(state: CarRuntimeState, requested_acceleration: float, delta: float) -> void:
	_simulate_wheel_dynamics(state, requested_acceleration, 0.0, 0.0, 0.0, delta)


func _resolve_longitudinal_acceleration(state: CarRuntimeState, requested_acceleration: float) -> float:
	state.synchronize_wheel_contacts_from_aggregate()
	var active_wheel_count: int = 0
	var total_peak_capacity: float = 0.0
	for wheel: WheelTireState in state.wheel_states:
		if not wheel.has_contact:
			continue
		active_wheel_count += 1
		total_peak_capacity += _get_wheel_longitudinal_capacity(wheel)

	if active_wheel_count <= 0 or is_zero_approx(requested_acceleration):
		return 0.0

	var applied_acceleration: float = 0.0
	for wheel: WheelTireState in state.wheel_states:
		if not wheel.has_contact:
			continue
		var wheel_capacity: float = _get_wheel_longitudinal_capacity(wheel)
		var requested_wheel_acceleration: float
		if total_peak_capacity > TireModel.MIN_ACCELERATION_CAPACITY:
			requested_wheel_acceleration = requested_acceleration * wheel_capacity / total_peak_capacity
		else:
			requested_wheel_acceleration = requested_acceleration / float(active_wheel_count)
		var response: Vector2 = _tire_model.resolve_longitudinal_acceleration(
			requested_wheel_acceleration,
			wheel.lateral_slip_intensity,
			wheel.surface_grip_multiplier,
			PER_WHEEL_LOAD_SHARE,
			_config.longitudinal_grip_coefficient,
			_config.longitudinal_peak_slip_ratio,
			_config.longitudinal_slide_grip_multiplier
		)
		_record_longitudinal_slip(wheel, requested_wheel_acceleration, response.x, response.y)
		applied_acceleration += response.x
	return applied_acceleration


func _get_wheel_longitudinal_capacity(wheel: WheelTireState) -> float:
	return _tire_model.get_longitudinal_acceleration_capacity(
		wheel.lateral_slip_intensity,
		wheel.surface_grip_multiplier,
		PER_WHEEL_LOAD_SHARE,
		_config.longitudinal_grip_coefficient
	)


func _record_longitudinal_slip(
	wheel: WheelTireState,
	requested_acceleration: float,
	applied_acceleration: float,
	slip_ratio: float
) -> void:
	wheel.requested_longitudinal_acceleration += requested_acceleration
	wheel.applied_longitudinal_acceleration += applied_acceleration
	if absf(slip_ratio) > absf(wheel.longitudinal_slip_ratio):
		wheel.longitudinal_slip_ratio = slip_ratio
	wheel.longitudinal_slip_intensity = maxf(
		wheel.longitudinal_slip_intensity,
		_tire_model.calculate_longitudinal_slip_intensity(
			slip_ratio,
			_config.longitudinal_peak_slip_ratio
		)
	)


func _reset_longitudinal_slip(state: CarRuntimeState) -> void:
	state.synchronize_wheel_contacts_from_aggregate()
	for wheel: WheelTireState in state.wheel_states:
		wheel.reset_longitudinal_dynamics()
	state.update_slip_aggregates()


func _update_combined_slip(state: CarRuntimeState) -> void:
	for wheel: WheelTireState in state.wheel_states:
		if not wheel.has_contact:
			wheel.longitudinal_slip_ratio = 0.0
			wheel.longitudinal_slip_intensity = 0.0
			wheel.tire_slip_intensity = 0.0
			continue
		wheel.tire_slip_intensity = _tire_model.calculate_combined_slip_intensity(
			wheel.lateral_slip_intensity,
			wheel.longitudinal_slip_intensity
		)
	state.update_slip_aggregates()


func _get_wheel_driven_rpm(state: CarRuntimeState) -> float:
	var driven_surface_speed: float = _get_driven_wheel_surface_speed(state)
	if not _config.uses_geared_transmission():
		var speed_ratio: float = clampf(absf(driven_surface_speed) / _config.max_forward_speed, 0.0, 1.0)
		return lerpf(_config.idle_rpm, _config.redline_rpm, speed_ratio)
	if state.current_gear == 0:
		return _config.idle_rpm
	if _config.is_cvt_transmission():
		return _cvt_transmission_model.get_coupled_engine_rpm(driven_surface_speed, state.current_gear)
	var coupled_rpm: float = _get_coupled_engine_rpm_for_gear(state, state.current_gear)
	if _config.is_automatic_transmission():
		return _get_torque_converter_rpm(state, coupled_rpm)
	return coupled_rpm


func _get_engine_free_rev_blend(state: CarRuntimeState) -> float:
	if not _config.uses_geared_transmission() or state.current_gear == 0:
		return 1.0
	if _config.is_manual_transmission() or _config.is_cvt_transmission():
		return 1.0 - clampf(state.clutch_engagement, 0.0, 1.0)
	return 0.0


func _get_coupled_engine_rpm_for_gear(state: CarRuntimeState, gear: int) -> float:
	return _drivetrain_model.get_coupled_engine_rpm_for_gear(gear, _get_driven_wheel_surface_speed(state))


func _get_driven_wheel_surface_speed(state: CarRuntimeState) -> float:
	return state.get_average_driven_wheel_angular_velocity(_config) * _config.wheel_radius


func _get_torque_converter_rpm(state: CarRuntimeState, coupled_rpm: float) -> float:
	var drive_input: float = state.brake_input if state.current_gear < 0 else state.throttle_input
	return _torque_converter_model.get_coupled_rpm(coupled_rpm, drive_input)


func _get_transmission_drive_acceleration(state: CarRuntimeState, throttle: float) -> float:
	var acceleration: float
	if _config.is_cvt_transmission():
		acceleration = _cvt_transmission_model.get_drive_acceleration(
			throttle,
			state.current_gear,
			state.shift_timer > 0.0,
			state.engine_rpm,
			get_torque_multiplier(),
			get_rev_limiter_multiplier()
		)
	else:
		acceleration = _drivetrain_model.get_drive_acceleration(
			throttle,
			state.current_gear,
			_config.uses_discrete_gears() and state.shift_timer > 0.0,
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
	return acceleration


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
