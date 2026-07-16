extends RefCounted
class_name DifferentialModel

const MIN_DELTA: float = 1.0 / 10000.0
const MAX_COUPLING_ACCELERATION_RAD_S2: float = 900.0


func distribute_drive_torque(
	state: CarRuntimeState,
	config: CarDriveConfig,
	total_drive_torque_nm: float,
	delta: float
) -> PackedFloat32Array:
	var torques := PackedFloat32Array()
	torques.resize(WheelTireState.WHEEL_COUNT)
	torques.fill(0.0)
	if state == null or config == null:
		return torques
	state.ensure_wheel_states()
	for wheel: WheelTireState in state.wheel_states:
		torques[wheel.wheel_index] = total_drive_torque_nm * config.get_drive_torque_fraction(wheel.wheel_index)

	var safe_delta: float = maxf(delta, MIN_DELTA)
	_apply_axle_lock(
		torques,
		state,
		WheelTireState.Position.FRONT_LEFT,
		WheelTireState.Position.FRONT_RIGHT,
		config.front_differential_lock,
		safe_delta
	)
	_apply_axle_lock(
		torques,
		state,
		WheelTireState.Position.REAR_LEFT,
		WheelTireState.Position.REAR_RIGHT,
		config.rear_differential_lock,
		safe_delta
	)
	if config.is_all_wheel_drive():
		_apply_center_lock(torques, state, config.center_differential_lock, safe_delta)
	return torques


func _apply_axle_lock(
	torques: PackedFloat32Array,
	state: CarRuntimeState,
	left_index: int,
	right_index: int,
	lock_strength: float,
	delta: float
) -> void:
	var strength: float = clampf(lock_strength, 0.0, 1.0)
	if strength <= 0.0:
		return
	var left: WheelTireState = state.get_wheel_state(left_index)
	var right: WheelTireState = state.get_wheel_state(right_index)
	if left == null or right == null:
		return
	var relative_speed: float = right.angular_velocity_rad_s - left.angular_velocity_rad_s
	var effective_inertia: float = maxf(
		0.5 * (left.moment_of_inertia_kg_m2 + right.moment_of_inertia_kg_m2),
		0.01
	)
	var requested_coupling: float = (
		relative_speed
		* effective_inertia
		/ delta
		* strength
		* 0.5
	)
	var maximum_coupling: float = effective_inertia * MAX_COUPLING_ACCELERATION_RAD_S2 * strength
	var coupling: float = clampf(requested_coupling, -maximum_coupling, maximum_coupling)
	torques[left_index] += coupling
	torques[right_index] -= coupling


func _apply_center_lock(
	torques: PackedFloat32Array,
	state: CarRuntimeState,
	lock_strength: float,
	delta: float
) -> void:
	var strength: float = clampf(lock_strength, 0.0, 1.0)
	if strength <= 0.0:
		return
	var front_left: WheelTireState = state.get_wheel_state(WheelTireState.Position.FRONT_LEFT)
	var front_right: WheelTireState = state.get_wheel_state(WheelTireState.Position.FRONT_RIGHT)
	var rear_left: WheelTireState = state.get_wheel_state(WheelTireState.Position.REAR_LEFT)
	var rear_right: WheelTireState = state.get_wheel_state(WheelTireState.Position.REAR_RIGHT)
	if front_left == null or front_right == null or rear_left == null or rear_right == null:
		return
	var front_speed: float = 0.5 * (front_left.angular_velocity_rad_s + front_right.angular_velocity_rad_s)
	var rear_speed: float = 0.5 * (rear_left.angular_velocity_rad_s + rear_right.angular_velocity_rad_s)
	var average_inertia: float = maxf(
		0.25 * (
			front_left.moment_of_inertia_kg_m2
			+ front_right.moment_of_inertia_kg_m2
			+ rear_left.moment_of_inertia_kg_m2
			+ rear_right.moment_of_inertia_kg_m2
		),
		0.01
	)
	var requested_coupling: float = (
		(rear_speed - front_speed)
		* average_inertia
		/ delta
		* strength
		* 0.5
	)
	var maximum_coupling: float = average_inertia * MAX_COUPLING_ACCELERATION_RAD_S2 * strength
	var coupling: float = clampf(requested_coupling, -maximum_coupling, maximum_coupling)
	torques[WheelTireState.Position.FRONT_LEFT] += coupling * 0.5
	torques[WheelTireState.Position.FRONT_RIGHT] += coupling * 0.5
	torques[WheelTireState.Position.REAR_LEFT] -= coupling * 0.5
	torques[WheelTireState.Position.REAR_RIGHT] -= coupling * 0.5
