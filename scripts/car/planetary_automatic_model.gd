extends RefCounted
class_name PlanetaryAutomaticModel

const MIN_RPM: float = 1.0
const MIN_PHASE_DURATION_S: float = 0.001
const MAX_UPDATE_STEP_S: float = 1.0 / 120.0

var torque_reduction_duration_s: float = 0.045
var handover_duration_s: float = 0.070
var inertia_duration_s: float = 0.090
var reapply_duration_s: float = 0.075
var minimum_torque_factor: float = 0.32
var handover_torque_factor: float = 0.52
var inertia_torque_factor: float = 0.72
var stall_torque_multiplier: float = 1.80
var coupling_speed_ratio: float = 0.90
var lockup_minimum_speed_mps: float = 7.0
var lockup_minimum_gear: int = 2
var lockup_maximum_throttle: float = 0.72
var lockup_engage_rate: float = 4.0
var lockup_release_rate: float = 10.0
var commanded_lockup_slip_rpm: float = 35.0
var maximum_skip_gears: int = 4


func configure(
	target_torque_reduction_duration_s: float,
	target_handover_duration_s: float,
	target_inertia_duration_s: float,
	target_reapply_duration_s: float,
	target_stall_torque_multiplier: float,
	target_coupling_speed_ratio: float,
	target_lockup_minimum_speed_mps: float,
	target_lockup_minimum_gear: int,
	target_lockup_maximum_throttle: float,
	target_lockup_engage_rate: float,
	target_lockup_release_rate: float,
	target_commanded_lockup_slip_rpm: float,
	target_maximum_skip_gears: int
) -> void:
	torque_reduction_duration_s = maxf(target_torque_reduction_duration_s, MIN_PHASE_DURATION_S)
	handover_duration_s = maxf(target_handover_duration_s, MIN_PHASE_DURATION_S)
	inertia_duration_s = maxf(target_inertia_duration_s, MIN_PHASE_DURATION_S)
	reapply_duration_s = maxf(target_reapply_duration_s, MIN_PHASE_DURATION_S)
	stall_torque_multiplier = maxf(target_stall_torque_multiplier, 1.0)
	coupling_speed_ratio = clampf(target_coupling_speed_ratio, 0.05, 1.0)
	lockup_minimum_speed_mps = maxf(target_lockup_minimum_speed_mps, 0.0)
	lockup_minimum_gear = maxi(target_lockup_minimum_gear, 1)
	lockup_maximum_throttle = clampf(target_lockup_maximum_throttle, 0.0, 1.0)
	lockup_engage_rate = maxf(target_lockup_engage_rate, 0.01)
	lockup_release_rate = maxf(target_lockup_release_rate, 0.01)
	commanded_lockup_slip_rpm = maxf(target_commanded_lockup_slip_rpm, 0.0)
	maximum_skip_gears = maxi(target_maximum_skip_gears, 1)


func reset(runtime: PlanetaryAutomaticRuntimeState, initial_gear: int = 1) -> void:
	if runtime == null:
		return
	runtime.reset(initial_gear)


func request_gear(
	runtime: PlanetaryAutomaticRuntimeState,
	requested_gear: int,
	forward_gear_count: int
) -> bool:
	if runtime == null or runtime.is_shifting():
		return false
	var maximum_gear: int = maxi(forward_gear_count, 1)
	var safe_gear: int = clampi(requested_gear, -1, maximum_gear)
	if safe_gear == 0:
		safe_gear = 1
	if safe_gear == runtime.engaged_gear:
		runtime.selected_gear = safe_gear
		return false
	runtime.source_gear = runtime.engaged_gear
	runtime.target_gear = safe_gear
	runtime.selected_gear = safe_gear
	runtime.shift_phase = PlanetaryAutomaticRuntimeState.ShiftPhase.TORQUE_REDUCTION
	runtime.phase_elapsed_s = 0.0
	runtime.shift_progress = 0.0
	runtime.torque_transfer_factor = 1.0
	runtime.lockup_target = 0.0
	return true


func update(
	runtime: PlanetaryAutomaticRuntimeState,
	engine_rpm: float,
	turbine_rpm: float,
	throttle: float,
	vehicle_speed_mps: float,
	delta: float
) -> void:
	if runtime == null:
		return
	var remaining: float = maxf(delta, 0.0)
	while remaining > 0.000001:
		var step: float = minf(remaining, MAX_UPDATE_STEP_S)
		_update_shift(runtime, step)
		_update_converter(runtime, engine_rpm, turbine_rpm, throttle, vehicle_speed_mps, step)
		remaining -= step
	if delta <= 0.0:
		_update_converter(runtime, engine_rpm, turbine_rpm, throttle, vehicle_speed_mps, 0.0)


func choose_kickdown_gear(
	current_gear: int,
	forward_gear_count: int,
	wheel_rpm: float,
	gear_ratios: Array[float],
	final_drive_ratio: float,
	redline_rpm: float
) -> int:
	if current_gear <= 1 or forward_gear_count <= 1 or gear_ratios.is_empty():
		return maxi(current_gear, 1)
	var lowest_allowed: int = maxi(1, current_gear - maximum_skip_gears)
	var safe_redline: float = maxf(redline_rpm, MIN_RPM) * 0.97
	for candidate: int in range(lowest_allowed, current_gear):
		var ratio_index: int = candidate - 1
		if ratio_index < 0 or ratio_index >= gear_ratios.size():
			continue
		var predicted_rpm: float = absf(wheel_rpm * gear_ratios[ratio_index] * final_drive_ratio)
		if predicted_rpm <= safe_redline:
			return candidate
	return current_gear


func _update_shift(runtime: PlanetaryAutomaticRuntimeState, delta: float) -> void:
	if not runtime.is_shifting():
		runtime.shift_progress = 1.0
		runtime.torque_transfer_factor = 1.0
		return
	var phase_duration: float = _get_phase_duration(runtime.shift_phase)
	runtime.phase_elapsed_s += delta
	var phase_progress: float = clampf(runtime.phase_elapsed_s / phase_duration, 0.0, 1.0)
	runtime.torque_transfer_factor = _get_phase_torque_factor(runtime.shift_phase, phase_progress)
	runtime.shift_progress = _get_total_shift_progress(runtime.shift_phase, phase_progress)
	if phase_progress < 1.0:
		return
	_advance_shift_phase(runtime)


func _advance_shift_phase(runtime: PlanetaryAutomaticRuntimeState) -> void:
	runtime.phase_elapsed_s = 0.0
	match runtime.shift_phase:
		PlanetaryAutomaticRuntimeState.ShiftPhase.TORQUE_REDUCTION:
			runtime.shift_phase = PlanetaryAutomaticRuntimeState.ShiftPhase.HANDOVER
		PlanetaryAutomaticRuntimeState.ShiftPhase.HANDOVER:
			runtime.engaged_gear = runtime.target_gear
			runtime.shift_phase = PlanetaryAutomaticRuntimeState.ShiftPhase.INERTIA
		PlanetaryAutomaticRuntimeState.ShiftPhase.INERTIA:
			runtime.shift_phase = PlanetaryAutomaticRuntimeState.ShiftPhase.REAPPLY
		PlanetaryAutomaticRuntimeState.ShiftPhase.REAPPLY:
			runtime.shift_phase = PlanetaryAutomaticRuntimeState.ShiftPhase.IDLE
			runtime.source_gear = runtime.target_gear
			runtime.engaged_gear = runtime.target_gear
			runtime.shift_progress = 1.0
			runtime.torque_transfer_factor = 1.0


func _update_converter(
	runtime: PlanetaryAutomaticRuntimeState,
	engine_rpm: float,
	turbine_rpm: float,
	throttle: float,
	vehicle_speed_mps: float,
	delta: float
) -> void:
	var safe_engine_rpm: float = maxf(absf(engine_rpm), MIN_RPM)
	var safe_turbine_rpm: float = maxf(absf(turbine_rpm), 0.0)
	runtime.converter_speed_ratio = clampf(safe_turbine_rpm / safe_engine_rpm, 0.0, 1.0)
	runtime.converter_slip_rpm = maxf(safe_engine_rpm - safe_turbine_rpm, 0.0)
	var multiplication_progress: float = clampf(
		runtime.converter_speed_ratio / coupling_speed_ratio,
		0.0,
		1.0
	)
	var unlocked_multiplier: float = lerpf(stall_torque_multiplier, 1.0, multiplication_progress)
	var safe_throttle: float = clampf(throttle, 0.0, 1.0)
	var lockup_allowed: bool = (
		not runtime.is_shifting()
		and runtime.engaged_gear >= lockup_minimum_gear
		and absf(vehicle_speed_mps) >= lockup_minimum_speed_mps
		and safe_throttle <= lockup_maximum_throttle
		and runtime.converter_speed_ratio >= coupling_speed_ratio * 0.82
	)
	runtime.lockup_target = 1.0 if lockup_allowed else 0.0
	var rate: float = lockup_engage_rate if runtime.lockup_target > runtime.lockup_engagement else lockup_release_rate
	runtime.lockup_engagement = move_toward(runtime.lockup_engagement, runtime.lockup_target, rate * maxf(delta, 0.0))
	runtime.converter_torque_multiplier = lerpf(unlocked_multiplier, 1.0, runtime.lockup_engagement)
	if runtime.lockup_engagement > 0.0:
		runtime.converter_slip_rpm = lerpf(
			runtime.converter_slip_rpm,
			minf(runtime.converter_slip_rpm, commanded_lockup_slip_rpm),
			runtime.lockup_engagement
		)


func _get_phase_duration(phase: int) -> float:
	match phase:
		PlanetaryAutomaticRuntimeState.ShiftPhase.TORQUE_REDUCTION:
			return torque_reduction_duration_s
		PlanetaryAutomaticRuntimeState.ShiftPhase.HANDOVER:
			return handover_duration_s
		PlanetaryAutomaticRuntimeState.ShiftPhase.INERTIA:
			return inertia_duration_s
		PlanetaryAutomaticRuntimeState.ShiftPhase.REAPPLY:
			return reapply_duration_s
	return MIN_PHASE_DURATION_S


func _get_phase_torque_factor(phase: int, progress: float) -> float:
	match phase:
		PlanetaryAutomaticRuntimeState.ShiftPhase.TORQUE_REDUCTION:
			return lerpf(1.0, minimum_torque_factor, progress)
		PlanetaryAutomaticRuntimeState.ShiftPhase.HANDOVER:
			return lerpf(minimum_torque_factor, handover_torque_factor, progress)
		PlanetaryAutomaticRuntimeState.ShiftPhase.INERTIA:
			return lerpf(handover_torque_factor, inertia_torque_factor, progress)
		PlanetaryAutomaticRuntimeState.ShiftPhase.REAPPLY:
			return lerpf(inertia_torque_factor, 1.0, progress)
	return 1.0


func _get_total_shift_progress(phase: int, phase_progress: float) -> float:
	var phase_index: int = clampi(phase - PlanetaryAutomaticRuntimeState.ShiftPhase.TORQUE_REDUCTION, 0, 3)
	return clampf((float(phase_index) + phase_progress) / 4.0, 0.0, 1.0)
