extends RefCounted
class_name WheelRotationalDynamicsModel

const MIN_REFERENCE_SPEED_MPS: float = 0.25
const MAX_ABSOLUTE_SLIP_RATIO: float = 4.0
const MAX_ANGULAR_SPEED_RAD_S: float = 2500.0
const ANGULAR_STOP_THRESHOLD_RAD_S: float = 0.05
const TORQUE_EPSILON_NM: float = 0.01


func calculate_slip_ratio(
	angular_velocity_rad_s: float,
	wheel_radius_m: float,
	vehicle_forward_speed_mps: float,
	reference_speed_mps: float
) -> float:
	var circumferential_speed: float = angular_velocity_rad_s * maxf(wheel_radius_m, 0.01)
	var denominator: float = maxf(
		absf(vehicle_forward_speed_mps),
		maxf(reference_speed_mps, MIN_REFERENCE_SPEED_MPS)
	)
	return clampf(
		(circumferential_speed - vehicle_forward_speed_mps) / denominator,
		-MAX_ABSOLUTE_SLIP_RATIO,
		MAX_ABSOLUTE_SLIP_RATIO
	)


func integrate_wheel(
	wheel: WheelTireState,
	drive_torque_nm: float,
	brake_torque_nm: float,
	tire_acceleration_mps2: float,
	vehicle_mass_kg: float,
	angular_damping_nm_per_rad_s: float,
	vehicle_forward_speed_mps: float,
	delta: float,
	effective_inertia_kg_m2: float = -1.0
) -> void:
	if wheel == null:
		return
	var safe_delta: float = maxf(delta, 0.0)
	var safe_mass: float = maxf(vehicle_mass_kg, 1.0)
	var safe_radius: float = maxf(wheel.wheel_radius_m, 0.01)
	var selected_inertia: float = (
		effective_inertia_kg_m2
		if effective_inertia_kg_m2 > 0.0
		else wheel.moment_of_inertia_kg_m2
	)
	var safe_inertia: float = maxf(selected_inertia, 0.01)
	var tire_force_n: float = tire_acceleration_mps2 * safe_mass
	var tire_torque_nm: float = -tire_force_n * safe_radius
	var damping_torque_nm: float = -wheel.angular_velocity_rad_s * maxf(
		angular_damping_nm_per_rad_s,
		0.0
	)
	var torque_without_brake: float = drive_torque_nm + tire_torque_nm + damping_torque_nm
	var reference_direction: float = _get_rotation_direction(
		wheel.angular_velocity_rad_s,
		torque_without_brake,
		vehicle_forward_speed_mps
	)
	var safe_brake_torque: float = maxf(brake_torque_nm, 0.0)
	var signed_brake_torque: float = -reference_direction * safe_brake_torque
	var net_torque_nm: float = torque_without_brake + signed_brake_torque
	var angular_acceleration: float = net_torque_nm / safe_inertia
	var next_angular_velocity: float = wheel.angular_velocity_rad_s + angular_acceleration * safe_delta

	if (
		safe_brake_torque > 0.0
		and reference_direction != 0.0
		and signf(next_angular_velocity) != reference_direction
		and absf(drive_torque_nm) <= safe_brake_torque + TORQUE_EPSILON_NM
	):
		next_angular_velocity = 0.0
		angular_acceleration = 0.0 if safe_delta <= 0.0 else -wheel.angular_velocity_rad_s / safe_delta

	wheel.drive_torque_nm = drive_torque_nm
	wheel.brake_torque_nm = safe_brake_torque
	wheel.tire_torque_nm = tire_torque_nm
	wheel.angular_acceleration_rad_s2 = angular_acceleration
	wheel.angular_velocity_rad_s = clampf(
		next_angular_velocity,
		-MAX_ANGULAR_SPEED_RAD_S,
		MAX_ANGULAR_SPEED_RAD_S
	)
	if absf(wheel.angular_velocity_rad_s) < ANGULAR_STOP_THRESHOLD_RAD_S and absf(net_torque_nm) < TORQUE_EPSILON_NM:
		wheel.angular_velocity_rad_s = 0.0
	wheel.integrate_rotation(safe_delta)


func _get_rotation_direction(
	angular_velocity_rad_s: float,
	torque_without_brake_nm: float,
	vehicle_forward_speed_mps: float
) -> float:
	if absf(angular_velocity_rad_s) >= ANGULAR_STOP_THRESHOLD_RAD_S:
		return signf(angular_velocity_rad_s)
	if absf(torque_without_brake_nm) >= TORQUE_EPSILON_NM:
		return signf(torque_without_brake_nm)
	if absf(vehicle_forward_speed_mps) >= MIN_REFERENCE_SPEED_MPS:
		return signf(vehicle_forward_speed_mps)
	return 0.0
