extends RefCounted
class_name CarRuntimeState

const FREE_ROLLING_STRAIGHT_YAW_THRESHOLD_RAD_S: float = 0.05
const FREE_ROLLING_STRAIGHT_LATERAL_THRESHOLD_MPS: float = 0.25
const FREE_ROLLING_STRAIGHT_STEERING_THRESHOLD_RAD: float = 0.02
const FREE_ROLLING_DISCONTINUITY_THRESHOLD_MPS: float = 0.25

var start_transform: Transform3D
var forward_speed: float = 0.0
var lateral_speed: float = 0.0
var yaw_rate_rad_s: float = 0.0
var yaw_acceleration_rad_s2: float = 0.0
var longitudinal_acceleration_mps2: float = 0.0
var lateral_acceleration_mps2: float = 0.0
var yaw_moment_nm: float = 0.0
var steering_input_state: float = 0.0
var body_pitch_angle_rad: float = 0.0
var body_roll_angle_rad: float = 0.0
var engine_rpm: float = 900.0
var current_gear: int = 1
var shift_timer: float = 0.0
var clutch_engagement: float = 1.0
var throttle_input: float = 0.0
var brake_input: float = 0.0
var lateral_slip_intensity: float = 0.0
var longitudinal_slip_ratio: float = 0.0
var longitudinal_slip_intensity: float = 0.0
var tire_slip_intensity: float = 0.0
var surface_grip_multiplier: float = 1.0
var ground_contact_count: int = 0
var ground_normal: Vector3 = Vector3.UP
var suspension_acceleration: float = 0.0
var suspension_acceleration_vector: Vector3 = Vector3.ZERO
var wheel_states: Array[WheelTireState] = []


func _init() -> void:
	ensure_wheel_states()


func ensure_wheel_states() -> void:
	while wheel_states.size() < WheelTireState.WHEEL_COUNT:
		wheel_states.append(WheelTireState.new(wheel_states.size()))
	if wheel_states.size() > WheelTireState.WHEEL_COUNT:
		wheel_states.resize(WheelTireState.WHEEL_COUNT)
	for index: int in range(wheel_states.size()):
		if wheel_states[index] == null:
			wheel_states[index] = WheelTireState.new(index)
		else:
			wheel_states[index].wheel_index = index


func get_wheel_state(wheel_index: int) -> WheelTireState:
	ensure_wheel_states()
	if wheel_index < 0 or wheel_index >= wheel_states.size():
		return null
	return wheel_states[wheel_index]


func get_wheel_contact_count() -> int:
	ensure_wheel_states()
	var contact_count: int = 0
	for wheel: WheelTireState in wheel_states:
		if wheel.has_contact:
			contact_count += 1
	return contact_count


func configure_wheel_rotation(config: CarDriveConfig, preserve_angular_velocity: bool = true) -> void:
	ensure_wheel_states()
	if config == null:
		return
	for wheel: WheelTireState in wheel_states:
		var preserved_velocity: float = wheel.angular_velocity_rad_s
		wheel.configure_rotation(
			config.wheel_radius,
			config.get_wheel_inertia_kg_m2(wheel.wheel_index)
		)
		if preserve_angular_velocity:
			wheel.angular_velocity_rad_s = preserved_velocity
		else:
			wheel.set_rolling_speed(forward_speed)
	if preserve_angular_velocity:
		_synchronize_free_rolling_wheels(config)


func _synchronize_free_rolling_wheels(config: CarDriveConfig) -> void:
	var free_wheels: Array[WheelTireState] = []
	for wheel: WheelTireState in wheel_states:
		if _should_prepare_free_rolling_wheel(wheel, config):
			free_wheels.append(wheel)
	if free_wheels.is_empty():
		return

	if _is_near_straight_free_rolling(free_wheels):
		_synchronize_straight_free_rolling_wheels(free_wheels, config)
		return

	# During a turn each contact patch has a different longitudinal road speed.
	# Synchronizing every wheel to the center speed repeatedly removes yaw and
	# lateral kinetic energy. Match each wheel to its own velocity along the
	# steered wheel plane instead, without applying a fictitious center impulse.
	for wheel: WheelTireState in free_wheels:
		wheel.set_rolling_speed(get_wheel_longitudinal_road_speed(wheel, config))
		wheel.angular_acceleration_rad_s2 = 0.0


func _synchronize_straight_free_rolling_wheels(
	free_wheels: Array[WheelTireState],
	config: CarDriveConfig
) -> void:
	var maximum_speed_delta: float = 0.0
	for wheel: WheelTireState in free_wheels:
		maximum_speed_delta = maxf(
			maximum_speed_delta,
			absf(wheel.get_circumferential_speed_mps() - forward_speed)
		)

	# A large mismatch indicates an authoritative state jump such as a reset,
	# teleport, test setup or direction hand-off. It is not a physical acceleration
	# step, so synchronize wheel state without applying an impulse to the chassis.
	if maximum_speed_delta > FREE_ROLLING_DISCONTINUITY_THRESHOLD_MPS:
		for wheel: WheelTireState in free_wheels:
			wheel.set_rolling_speed(forward_speed)
			wheel.angular_acceleration_rad_s2 = 0.0
		return

	var equivalent_mass: float = maxf(config.vehicle_mass, 1.0)
	var generalized_momentum: float = equivalent_mass * forward_speed
	for wheel: WheelTireState in free_wheels:
		var radius: float = maxf(wheel.wheel_radius_m, 0.01)
		var rotational_equivalent_mass: float = (
			maxf(wheel.moment_of_inertia_kg_m2, 0.01)
			/ (radius * radius)
		)
		equivalent_mass += rotational_equivalent_mass
		generalized_momentum += (
			rotational_equivalent_mass
			* wheel.get_circumferential_speed_mps()
		)

	# Enforce no-slip rolling without creating rotational energy for free. The
	# translational vehicle mass and the I/r^2 equivalent masses of all unloaded
	# wheels share one coupled speed, preserving generalized longitudinal momentum.
	var coupled_speed: float = generalized_momentum / maxf(equivalent_mass, 0.01)
	forward_speed = coupled_speed
	for wheel: WheelTireState in free_wheels:
		wheel.set_rolling_speed(coupled_speed)
		wheel.angular_acceleration_rad_s2 = 0.0


func _is_near_straight_free_rolling(free_wheels: Array[WheelTireState]) -> bool:
	if absf(yaw_rate_rad_s) > FREE_ROLLING_STRAIGHT_YAW_THRESHOLD_RAD_S:
		return false
	if absf(lateral_speed) > FREE_ROLLING_STRAIGHT_LATERAL_THRESHOLD_MPS:
		return false
	for wheel: WheelTireState in free_wheels:
		if absf(wheel.steering_angle_rad) > FREE_ROLLING_STRAIGHT_STEERING_THRESHOLD_RAD:
			return false
	return true


func get_wheel_longitudinal_road_speed(
	wheel: WheelTireState,
	config: CarDriveConfig
) -> float:
	var is_front: bool = wheel.is_front()
	var forward_offset: float = (
		maxf(config.wheel_base, 0.10) * (1.0 - config.front_static_load_fraction)
		if is_front
		else -maxf(config.wheel_base, 0.10) * config.front_static_load_fraction
	)
	var track_width: float = (
		config.front_axle_track_width if is_front else config.rear_axle_track_width
	)
	var lateral_offset: float = (
		-1.0 if wheel.is_left() else 1.0
	) * maxf(track_width, 0.10) * 0.5
	var wheel_forward_speed: float = forward_speed - yaw_rate_rad_s * lateral_offset
	var wheel_lateral_speed: float = lateral_speed + yaw_rate_rad_s * forward_offset
	var steering_cosine: float = cos(wheel.steering_angle_rad)
	var steering_sine: float = sin(wheel.steering_angle_rad)
	return (
		wheel_forward_speed * steering_cosine
		+ wheel_lateral_speed * steering_sine
	)


func _should_prepare_free_rolling_wheel(
	wheel: WheelTireState,
	config: CarDriveConfig
) -> bool:
	return (
		wheel.has_contact
		and config.get_drive_torque_fraction(wheel.wheel_index) <= 0.0
		and absf(wheel.drive_torque_nm) <= WheelRotationalDynamicsModel.TORQUE_EPSILON_NM
		and wheel.brake_torque_nm <= WheelRotationalDynamicsModel.TORQUE_EPSILON_NM
	)


func get_average_driven_wheel_angular_velocity(config: CarDriveConfig) -> float:
	ensure_wheel_states()
	if config == null:
		return 0.0
	var weighted_velocity: float = 0.0
	var total_fraction: float = 0.0
	for wheel: WheelTireState in wheel_states:
		var fraction: float = config.get_drive_torque_fraction(wheel.wheel_index)
		if fraction <= 0.0:
			continue
		weighted_velocity += wheel.angular_velocity_rad_s * fraction
		total_fraction += fraction
	if total_fraction <= 0.0:
		return 0.0
	return weighted_velocity / total_fraction


func get_wheel_angular_velocities() -> PackedFloat32Array:
	ensure_wheel_states()
	var velocities := PackedFloat32Array()
	for wheel: WheelTireState in wheel_states:
		velocities.append(wheel.angular_velocity_rad_s)
	return velocities


func get_wheel_angular_positions() -> PackedFloat32Array:
	ensure_wheel_states()
	var positions := PackedFloat32Array()
	for wheel: WheelTireState in wheel_states:
		positions.append(wheel.angular_position_rad)
	return positions


func get_wheel_steering_angles() -> PackedFloat32Array:
	ensure_wheel_states()
	var angles := PackedFloat32Array()
	for wheel: WheelTireState in wheel_states:
		angles.append(wheel.steering_angle_rad)
	return angles


func synchronize_wheel_contacts_from_aggregate() -> void:
	ensure_wheel_states()
	var target_contact_count: int = clampi(
		ground_contact_count,
		0,
		WheelTireState.WHEEL_COUNT
	)
	if get_wheel_contact_count() == target_contact_count:
		return

	for wheel: WheelTireState in wheel_states:
		wheel.reset_contact()
		wheel.reset_tire_dynamics()

	if target_contact_count <= 0:
		return

	var support_per_wheel: float = suspension_acceleration / float(target_contact_count)
	for wheel_index: int in range(target_contact_count):
		var wheel: WheelTireState = wheel_states[wheel_index]
		wheel.set_contact(
			surface_grip_multiplier,
			ground_normal,
			support_per_wheel
		)
		wheel.road_longitudinal_speed_mps = forward_speed
		# Aggregate contact is used by deterministic simulations that may seed body
		# speed directly. Initialize a previously stationary wheel to road speed before
		# slip is resolved, preventing a one-step fictitious braking impulse.
		if (
			absf(wheel.angular_velocity_rad_s)
			<= WheelRotationalDynamicsModel.ANGULAR_STOP_THRESHOLD_RAD_S
			and absf(forward_speed)
			>= WheelRotationalDynamicsModel.MIN_REFERENCE_SPEED_MPS
		):
			wheel.set_rolling_speed(forward_speed)
		wheel.lateral_slip_intensity = lateral_slip_intensity
		wheel.longitudinal_slip_ratio = longitudinal_slip_ratio
		wheel.longitudinal_slip_intensity = longitudinal_slip_intensity
		wheel.tire_slip_intensity = tire_slip_intensity


func update_wheel_load_shares(
	config: CarDriveConfig,
	longitudinal_acceleration: float,
	lateral_acceleration: float
) -> void:
	ensure_wheel_states()
	if config == null:
		return
	var analytic_shares: PackedFloat32Array = PackedFloat32Array()
	analytic_shares.resize(WheelTireState.WHEEL_COUNT)
	var suspension_sum: float = 0.0
	var contact_count: int = 0
	for wheel: WheelTireState in wheel_states:
		if wheel.has_contact:
			contact_count += 1
			suspension_sum += maxf(wheel.suspension_acceleration, 0.0)
	var analytic_sum: float = 0.0
	for wheel: WheelTireState in wheel_states:
		if not wheel.has_contact:
			wheel.normal_load_share = 0.0
			analytic_shares[wheel.wheel_index] = 0.0
			continue
		var base_share: float = config.get_wheel_load_share(
			wheel.wheel_index,
			longitudinal_acceleration
		)
		var axle_fraction: float = base_share * 2.0
		var track_width: float = (
			config.front_axle_track_width if wheel.is_front() else config.rear_axle_track_width
		)
		var requested_transfer: float = (
			absf(lateral_acceleration)
			* config.center_of_mass_height_m
			/ maxf(TireModel.STANDARD_GRAVITY * track_width, 0.01)
			* axle_fraction
			* 0.5
		)
		var transfer: float = minf(requested_transfer, maxf(base_share - 0.001, 0.0))
		var outside_sign: float = signf(lateral_acceleration)
		var wheel_sign: float = 1.0 if wheel.is_left() else -1.0
		var analytic_share: float = maxf(base_share + outside_sign * wheel_sign * transfer, 0.0)
		analytic_shares[wheel.wheel_index] = analytic_share
		analytic_sum += analytic_share
	if contact_count <= 0:
		return
	var blended_sum: float = 0.0
	for wheel: WheelTireState in wheel_states:
		if not wheel.has_contact:
			continue
		var analytic_share: float = (
			analytic_shares[wheel.wheel_index] / analytic_sum
			if analytic_sum > 0.000001
			else 1.0 / float(contact_count)
		)
		var suspension_share: float = (
			maxf(wheel.suspension_acceleration, 0.0) / suspension_sum
			if suspension_sum > 0.000001
			else 1.0 / float(contact_count)
		)
		wheel.normal_load_share = lerpf(
			analytic_share,
			suspension_share,
			clampf(config.suspension_load_blend, 0.0, 1.0)
		)
		blended_sum += wheel.normal_load_share
	if blended_sum <= 0.000001:
		return
	for wheel: WheelTireState in wheel_states:
		if wheel.has_contact:
			wheel.normal_load_share /= blended_sum


func update_contact_aggregates() -> void:
	ensure_wheel_states()
	var contact_count: int = 0
	var normal_sum: Vector3 = Vector3.ZERO
	var grip_sum: float = 0.0
	var support_sum: float = 0.0
	var support_vector_sum: Vector3 = Vector3.ZERO
	for wheel: WheelTireState in wheel_states:
		if not wheel.has_contact:
			continue
		contact_count += 1
		normal_sum += wheel.contact_normal
		grip_sum += wheel.surface_grip_multiplier
		support_sum += wheel.suspension_acceleration
		support_vector_sum += wheel.contact_normal * wheel.suspension_acceleration

	ground_contact_count = contact_count
	suspension_acceleration = support_sum
	suspension_acceleration_vector = support_vector_sum
	if contact_count <= 0:
		ground_normal = Vector3.UP
		surface_grip_multiplier = 1.0
		suspension_acceleration_vector = Vector3.ZERO
		return
	ground_normal = normal_sum.normalized() if normal_sum.length_squared() > 0.000001 else Vector3.UP
	surface_grip_multiplier = clampf(grip_sum / float(contact_count), 0.05, 2.0)


func update_slip_aggregates() -> void:
	ensure_wheel_states()
	lateral_slip_intensity = 0.0
	longitudinal_slip_ratio = 0.0
	longitudinal_slip_intensity = 0.0
	tire_slip_intensity = 0.0
	for wheel: WheelTireState in wheel_states:
		lateral_slip_intensity = maxf(
			lateral_slip_intensity,
			wheel.lateral_slip_intensity
		)
		if absf(wheel.longitudinal_slip_ratio) > absf(longitudinal_slip_ratio):
			longitudinal_slip_ratio = wheel.longitudinal_slip_ratio
		longitudinal_slip_intensity = maxf(
			longitudinal_slip_intensity,
			wheel.longitudinal_slip_intensity
		)
		tire_slip_intensity = maxf(
			tire_slip_intensity,
			wheel.tire_slip_intensity
		)


func clear_wheel_tire_dynamics() -> void:
	ensure_wheel_states()
	for wheel: WheelTireState in wheel_states:
		wheel.reset_tire_dynamics()
	update_slip_aggregates()


func reset_drive_state(idle_rpm: float) -> void:
	forward_speed = 0.0
	lateral_speed = 0.0
	yaw_rate_rad_s = 0.0
	yaw_acceleration_rad_s2 = 0.0
	longitudinal_acceleration_mps2 = 0.0
	lateral_acceleration_mps2 = 0.0
	yaw_moment_nm = 0.0
	steering_input_state = 0.0
	body_pitch_angle_rad = 0.0
	body_roll_angle_rad = 0.0
	engine_rpm = idle_rpm
	current_gear = 1
	shift_timer = 0.0
	clutch_engagement = 0.0
	throttle_input = 0.0
	brake_input = 0.0
	lateral_slip_intensity = 0.0
	longitudinal_slip_ratio = 0.0
	longitudinal_slip_intensity = 0.0
	tire_slip_intensity = 0.0
	surface_grip_multiplier = 1.0
	ground_contact_count = 0
	ground_normal = Vector3.UP
	suspension_acceleration = 0.0
	suspension_acceleration_vector = Vector3.ZERO
	ensure_wheel_states()
	for wheel: WheelTireState in wheel_states:
		wheel.reset()


func reset_input_snapshot() -> void:
	throttle_input = 0.0
	brake_input = 0.0


func set_drive_input_snapshot(throttle: float, brake: float) -> void:
	throttle_input = clampf(throttle, 0.0, 1.0)
	brake_input = clampf(brake, 0.0, 1.0)
