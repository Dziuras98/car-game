extends RefCounted
class_name OnDemandAwdCouplingModel

const MAX_UPDATE_STEP_S: float = 1.0 / 120.0
const MIN_TORQUE_EPSILON_NM: float = 0.001

var base_front_fraction: float = 0.0
var maximum_front_fraction: float = 0.50
var launch_command: float = 0.55
var throttle_command_gain: float = 0.42
var slip_command_gain: float = 0.018
var stability_command_gain: float = 0.60
var engage_rate_per_s: float = 5.0
var release_rate_per_s: float = 2.5
var maximum_clutch_capacity_nm: float = 900.0
var high_speed_release_start_mps: float = 45.0
var high_speed_release_end_mps: float = 60.0
var ambient_temperature_c: float = 25.0
var thermal_mass_j_per_c: float = 18000.0
var cooling_w_per_c: float = 65.0
var derate_start_c: float = 135.0
var shutdown_temperature_c: float = 180.0


func configure(
	target_base_front_fraction: float,
	target_maximum_front_fraction: float,
	target_launch_command: float,
	target_throttle_command_gain: float,
	target_slip_command_gain: float,
	target_stability_command_gain: float,
	target_engage_rate_per_s: float,
	target_release_rate_per_s: float,
	target_maximum_clutch_capacity_nm: float,
	target_high_speed_release_start_mps: float,
	target_high_speed_release_end_mps: float,
	target_thermal_mass_j_per_c: float,
	target_cooling_w_per_c: float,
	target_derate_start_c: float,
	target_shutdown_temperature_c: float
) -> void:
	base_front_fraction = clampf(target_base_front_fraction, 0.0, 1.0)
	maximum_front_fraction = clampf(target_maximum_front_fraction, base_front_fraction, 1.0)
	launch_command = clampf(target_launch_command, 0.0, 1.0)
	throttle_command_gain = maxf(target_throttle_command_gain, 0.0)
	slip_command_gain = maxf(target_slip_command_gain, 0.0)
	stability_command_gain = maxf(target_stability_command_gain, 0.0)
	engage_rate_per_s = maxf(target_engage_rate_per_s, 0.01)
	release_rate_per_s = maxf(target_release_rate_per_s, 0.01)
	maximum_clutch_capacity_nm = maxf(target_maximum_clutch_capacity_nm, 0.0)
	high_speed_release_start_mps = maxf(target_high_speed_release_start_mps, 0.0)
	high_speed_release_end_mps = maxf(target_high_speed_release_end_mps, high_speed_release_start_mps + 0.01)
	thermal_mass_j_per_c = maxf(target_thermal_mass_j_per_c, 1.0)
	cooling_w_per_c = maxf(target_cooling_w_per_c, 0.0)
	derate_start_c = maxf(target_derate_start_c, ambient_temperature_c)
	shutdown_temperature_c = maxf(target_shutdown_temperature_c, derate_start_c + 0.01)


func reset(state: OnDemandAwdCouplingState) -> void:
	if state == null:
		return
	state.reset(base_front_fraction, ambient_temperature_c)


func update(
	state: OnDemandAwdCouplingState,
	throttle: float,
	vehicle_speed_mps: float,
	front_axle_speed_rad_s: float,
	rear_axle_speed_rad_s: float,
	stability_request: float,
	total_input_torque_nm: float,
	delta: float
) -> void:
	if state == null:
		return
	var remaining: float = maxf(delta, 0.0)
	while remaining > 0.000001:
		var step: float = minf(remaining, MAX_UPDATE_STEP_S)
		_update_step(
			state,
			throttle,
			vehicle_speed_mps,
			front_axle_speed_rad_s,
			rear_axle_speed_rad_s,
			stability_request,
			total_input_torque_nm,
			step
		)
		remaining -= step
	if delta <= 0.0:
		_update_step(
			state,
			throttle,
			vehicle_speed_mps,
			front_axle_speed_rad_s,
			rear_axle_speed_rad_s,
			stability_request,
			total_input_torque_nm,
			0.0
		)


func get_front_torque_nm(state: OnDemandAwdCouplingState, total_input_torque_nm: float) -> float:
	if state == null:
		return 0.0
	return total_input_torque_nm * clampf(state.front_torque_fraction, 0.0, 1.0)


func _update_step(
	state: OnDemandAwdCouplingState,
	throttle: float,
	vehicle_speed_mps: float,
	front_axle_speed_rad_s: float,
	rear_axle_speed_rad_s: float,
	stability_request: float,
	total_input_torque_nm: float,
	delta: float
) -> void:
	var safe_throttle: float = clampf(throttle, 0.0, 1.0)
	var speed: float = absf(vehicle_speed_mps)
	state.axle_speed_difference_rad_s = rear_axle_speed_rad_s - front_axle_speed_rad_s
	var slip_request: float = clampf(maxf(state.axle_speed_difference_rad_s, 0.0) * slip_command_gain, 0.0, 1.0)
	var launch_request: float = launch_command * safe_throttle * (1.0 - clampf(speed / 8.0, 0.0, 1.0))
	var throttle_request: float = safe_throttle * throttle_command_gain
	var stability_component: float = clampf(stability_request, 0.0, 1.0) * stability_command_gain
	var raw_command: float = clampf(
		maxf(launch_request, maxf(throttle_request, maxf(slip_request, stability_component))),
		0.0,
		1.0
	)
	var high_speed_factor: float = 1.0 - clampf(
		(speed - high_speed_release_start_mps)
		/ maxf(high_speed_release_end_mps - high_speed_release_start_mps, 0.01),
		0.0,
		1.0
	)
	state.clutch_command = raw_command * high_speed_factor * state.thermal_capacity_factor
	var rate: float = engage_rate_per_s if state.clutch_command > state.clutch_engagement else release_rate_per_s
	state.clutch_engagement = move_toward(
		state.clutch_engagement,
		state.clutch_command,
		rate * maxf(delta, 0.0)
	)
	state.clutch_capacity_nm = maximum_clutch_capacity_nm * state.clutch_engagement * state.thermal_capacity_factor
	var requested_front_fraction: float = lerpf(
		base_front_fraction,
		maximum_front_fraction,
		state.clutch_engagement
	)
	var requested_front_torque_nm: float = absf(total_input_torque_nm) * requested_front_fraction
	var capacity_limited_torque_nm: float = minf(requested_front_torque_nm, state.clutch_capacity_nm)
	state.transferred_torque_nm = signf(total_input_torque_nm) * capacity_limited_torque_nm
	state.front_torque_fraction = (
		capacity_limited_torque_nm / absf(total_input_torque_nm)
		if absf(total_input_torque_nm) > MIN_TORQUE_EPSILON_NM
		else base_front_fraction
	)
	_update_temperature(state, delta)


func _update_temperature(state: OnDemandAwdCouplingState, delta: float) -> void:
	var slip_power_w: float = absf(
		state.transferred_torque_nm * state.axle_speed_difference_rad_s
	)
	var cooling_w: float = maxf(state.temperature_c - ambient_temperature_c, 0.0) * cooling_w_per_c
	state.thermal_energy_j = maxf(
		state.thermal_energy_j + (slip_power_w - cooling_w) * maxf(delta, 0.0),
		0.0
	)
	state.temperature_c = ambient_temperature_c + state.thermal_energy_j / thermal_mass_j_per_c
	state.thermal_capacity_factor = 1.0 - clampf(
		(state.temperature_c - derate_start_c)
		/ maxf(shutdown_temperature_c - derate_start_c, 0.01),
		0.0,
		1.0
	)
