extends RefCounted
class_name CarChassisController

const PROBE_END_MARGIN: float = 0.05
const REFERENCE_FRONT_TIRE_WIDTH_M: float = 0.225
const REFERENCE_REAR_TIRE_WIDTH_M: float = 0.245
const DEFAULT_SURFACE_GRIP_MULTIPLIER: float = 1.0
const MIN_WHEEL_LOAD_SHARE: float = 0.01
const BASE_YAW_DAMPING_PER_SECOND: float = 0.35
const RELEASED_STEERING_YAW_DAMPING_PER_SECOND: float = 0.90
const LOW_SPEED_YAW_DAMPING_PER_SECOND: float = 3.50
const LOW_SPEED_YAW_REFERENCE_MPS: float = 5.0
const YAW_STOP_THRESHOLD_RAD_S: float = 0.0005
const HORIZONTAL_SPEED_EPSILON_MPS: float = 0.0001
const LOW_SPEED_LATERAL_FRICTION_REFERENCE_MPS: float = 1.0
const LATERAL_STOP_THRESHOLD_MPS: float = 0.001
const RELEASED_STEERING_THRESHOLD: float = 0.05

var _tire_model: TireModel = TireModel.new()
var _lateral_tire_model: LateralTireDynamicsModel = LateralTireDynamicsModel.new()
var _vehicle_motion_model: VehicleMotionModel = VehicleMotionModel.new()
var _ground_contact_model: GroundContactModel = GroundContactModel.new()
var _config: CarDriveConfig
var _probe_local_positions: Array[Vector3] = []
var _ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
var _excluded_car_rid: RID = RID()


func configure(config: CarDriveConfig) -> void:
	_config = config.duplicate_config()
	_config.sanitize()
	_probe_local_positions = _ground_contact_model.get_probe_local_positions(
		_config.wheel_base,
		_config.front_axle_track_width,
		_config.rear_axle_track_width,
		_config.suspension_probe_height
	)
	_excluded_car_rid = RID()
	_ray_query.exclude = []
	_ray_query.collide_with_areas = false
	_ray_query.collide_with_bodies = true


func sample_ground_contact(state: CarRuntimeState, car: CharacterBody3D) -> void:
	state.ensure_wheel_states()
	for wheel: WheelTireState in state.wheel_states:
		wheel.reset_contact()
	state.ground_contact_count = 0
	state.ground_normal = Vector3.UP
	state.surface_grip_multiplier = 1.0
	state.suspension_acceleration = 0.0
	if _config == null or _probe_local_positions.is_empty() or not car.is_inside_tree() or car.get_world_3d() == null:
		return

	var car_rid: RID = car.get_rid()
	if _excluded_car_rid != car_rid:
		_excluded_car_rid = car_rid
		_ray_query.exclude = [_excluded_car_rid]
	_ray_query.collision_mask = _config.ground_probe_collision_mask

	var ray_direction: Vector3 = -car.global_transform.basis.y.normalized()
	var maximum_probe_length: float = _config.suspension_rest_length + _config.suspension_travel + PROBE_END_MARGIN
	var contact_count: int = 0
	var normal_sum: Vector3 = Vector3.ZERO
	var grip_sum: float = 0.0
	var support_acceleration_sum: float = 0.0
	var wheel_index: int = 0
	var direct_space_state: PhysicsDirectSpaceState3D = car.get_world_3d().direct_space_state

	for local_probe_position: Vector3 in _probe_local_positions:
		if wheel_index >= state.wheel_states.size():
			break
		var current_wheel_index: int = wheel_index
		wheel_index += 1
		var ray_start: Vector3 = car.global_transform * local_probe_position
		var ray_end: Vector3 = ray_start + ray_direction * maximum_probe_length
		_ray_query.from = ray_start
		_ray_query.to = ray_end
		var hit: Dictionary = direct_space_state.intersect_ray(_ray_query)
		if hit.is_empty():
			continue
		var collider: CollisionObject3D = hit.get("collider") as CollisionObject3D
		if collider == null:
			continue
		var hit_position: Vector3 = hit.get("position", ray_end)
		var hit_normal: Vector3 = hit.get("normal", Vector3.UP)
		if hit_normal.length_squared() <= 0.000001:
			continue
		hit_normal = hit_normal.normalized()
		if hit_normal.dot(Vector3.UP) < _config.minimum_ground_normal_dot:
			continue
		var normal_velocity: float = car.velocity.dot(hit_normal)
		var support_acceleration: float = _ground_contact_model.calculate_spring_acceleration(
			ray_start.distance_to(hit_position),
			_config.suspension_rest_length,
			_config.suspension_travel,
			normal_velocity,
			_config.suspension_stiffness,
			_config.suspension_damping
		)
		var surface_grip: float = _get_surface_grip_multiplier(collider)
		state.wheel_states[current_wheel_index].set_contact(
			surface_grip,
			hit_normal,
			support_acceleration
		)
		contact_count += 1
		normal_sum += hit_normal
		grip_sum += surface_grip
		support_acceleration_sum += support_acceleration

	state.ground_contact_count = contact_count
	state.suspension_acceleration = support_acceleration_sum
	if contact_count <= 0:
		return
	state.ground_normal = normal_sum.normalized() if normal_sum.length_squared() > 0.000001 else Vector3.UP
	state.surface_grip_multiplier = clampf(grip_sum / float(contact_count), 0.05, 2.0)


func update_tire_dynamics(state: CarRuntimeState, steering: float, handbrake_active: bool, delta: float) -> void:
	state.synchronize_wheel_contacts_from_aggregate()
	_set_wheel_steering_angles(state, steering)
	var mass: float = maxf(_config.vehicle_mass, 1.0)
	var previous_lateral_acceleration: float = _get_previous_lateral_tire_acceleration(
		state,
		mass
	)
	state.lateral_acceleration_mps2 = 0.0
	state.yaw_acceleration_rad_s2 = 0.0
	state.yaw_moment_nm = 0.0
	if state.ground_contact_count <= 0:
		for wheel: WheelTireState in state.wheel_states:
			wheel.reset_lateral_dynamics()
			wheel.tire_slip_intensity = wheel.longitudinal_slip_intensity
		state.update_slip_aggregates()
		return

	var safe_delta: float = maxf(delta, 0.0)
	var horizontal_speed_before: float = Vector2(state.forward_speed, state.lateral_speed).length()
	var total_lateral_force_n: float = 0.0
	var total_yaw_moment_nm: float = 0.0
	var longitudinal_acceleration: float = _get_previous_longitudinal_acceleration(state)

	for wheel: WheelTireState in state.wheel_states:
		if not wheel.has_contact:
			wheel.reset_lateral_dynamics()
			wheel.tire_slip_intensity = wheel.longitudinal_slip_intensity
			continue
		var forward_offset_m: float = _lateral_tire_model.get_wheel_forward_offset_m(
			_config,
			wheel.wheel_index
		)
		var lateral_offset_m: float = _lateral_tire_model.get_wheel_lateral_offset_m(
			_config,
			wheel.wheel_index
		)
		var wheel_velocity: Vector2 = _lateral_tire_model.get_wheel_local_velocity(
			state.forward_speed,
			state.lateral_speed,
			state.yaw_rate_rad_s,
			forward_offset_m,
			lateral_offset_m
		)
		var lateral_grip: float = _get_wheel_effective_lateral_grip(wheel.wheel_index)
		var tire_width: float = _config.front_tire_width_m if wheel.is_front() else _config.rear_tire_width_m
		var peak_slip_angle: float = _lateral_tire_model.get_peak_slip_angle_rad(
			lateral_grip,
			tire_width,
			_config.steering_slip_gain
		)
		wheel.lateral_slip_angle_rad = _lateral_tire_model.calculate_slip_angle_rad(
			wheel_velocity.x,
			wheel_velocity.y,
			wheel.steering_angle_rad
		)
		var load_share: float = _get_dynamic_wheel_load_share(
			wheel,
			longitudinal_acceleration,
			previous_lateral_acceleration
		)
		var handbrake_multiplier: float = (
			_config.handbrake_lateral_grip_multiplier
			if handbrake_active and wheel.is_rear()
			else 1.0
		)
		var lateral_acceleration_contribution: float = _lateral_tire_model.resolve_lateral_acceleration(
			wheel.lateral_slip_angle_rad,
			wheel_velocity.x,
			load_share,
			lateral_grip,
			wheel.surface_grip_multiplier,
			wheel.longitudinal_slip_intensity,
			peak_slip_angle,
			handbrake_multiplier
		)
		wheel.lateral_force_n = lateral_acceleration_contribution * mass
		wheel.lateral_slip_intensity = _lateral_tire_model.calculate_lateral_slip_intensity(
			wheel.lateral_slip_angle_rad,
			peak_slip_angle
		)
		wheel.tire_slip_intensity = _tire_model.calculate_combined_slip_intensity(
			wheel.lateral_slip_intensity,
			wheel.longitudinal_slip_intensity
		)
		total_lateral_force_n += wheel.lateral_force_n
		total_yaw_moment_nm += wheel.lateral_force_n * forward_offset_m

	state.yaw_moment_nm = total_yaw_moment_nm
	state.lateral_acceleration_mps2 = total_lateral_force_n / mass
	state.yaw_acceleration_rad_s2 = total_yaw_moment_nm / _lateral_tire_model.estimate_yaw_inertia_kg_m2(_config)
	if safe_delta > 0.0:
		state.lateral_speed += state.lateral_acceleration_mps2 * safe_delta
		_limit_lateral_tire_energy(state, horizontal_speed_before)
		state.yaw_rate_rad_s += state.yaw_acceleration_rad_s2 * safe_delta
		_apply_yaw_damping(state, steering, safe_delta)
		state.yaw_rate_rad_s = clampf(
			state.yaw_rate_rad_s,
			-_config.steering_speed,
			_config.steering_speed
		)
		_rotate_local_velocity_for_yaw(state, state.yaw_rate_rad_s * safe_delta)
		_apply_low_speed_lateral_friction(state, steering, safe_delta)
	state.update_slip_aggregates()


func update_skid_marks(state: CarRuntimeState, car: CharacterBody3D, skid_mark_emitter: SkidMarkEmitter, delta: float) -> void:
	if skid_mark_emitter != null:
		skid_mark_emitter.update(delta, state.tire_slip_intensity, car.global_transform)


func update_tires(state: CarRuntimeState, steering: float, handbrake_active: bool, car: CharacterBody3D, skid_mark_emitter: SkidMarkEmitter, delta: float) -> void:
	sample_ground_contact(state, car)
	update_tire_dynamics(state, steering, handbrake_active, delta)
	update_skid_marks(state, car, skid_mark_emitter, delta)


func update_steering(state: CarRuntimeState, _steering: float, car: CharacterBody3D, delta: float) -> void:
	var yaw_step: float = state.yaw_rate_rad_s * maxf(delta, 0.0)
	if absf(yaw_step) <= 0.000001:
		return
	car.rotate_y(-yaw_step)


func integrate_velocity(state: CarRuntimeState, car: CharacterBody3D, delta: float) -> void:
	var horizontal_velocity: Vector3 = get_horizontal_velocity_vector(state, car.global_transform)
	car.velocity.x = horizontal_velocity.x
	car.velocity.z = horizontal_velocity.z
	var safe_delta: float = clampf(delta, 0.0, CarPowertrainController.MAX_SIMULATION_SUBSTEP)
	if safe_delta <= 0.0:
		return
	car.velocity.y -= _config.gravity * safe_delta
	if state.ground_contact_count > 0:
		car.velocity += state.ground_normal * state.suspension_acceleration * safe_delta
	elif car.is_on_floor():
		car.velocity.y = minf(car.velocity.y, -_config.floor_stick_force)


func resolve_velocity(state: CarRuntimeState, car: CharacterBody3D) -> void:
	car.move_and_slide()
	var resolved_horizontal_velocity: Vector3 = Vector3(car.velocity.x, 0.0, car.velocity.z)
	set_local_speeds_from_horizontal_velocity(state, car.global_transform, resolved_horizontal_velocity)


func apply_velocity(state: CarRuntimeState, car: CharacterBody3D, delta: float) -> void:
	var remaining_delta: float = clampf(delta, 0.0, CarPowertrainController.MAX_FRAME_DELTA)
	while remaining_delta > 0.000001:
		var step: float = minf(remaining_delta, CarPowertrainController.MAX_SIMULATION_SUBSTEP)
		integrate_velocity(state, car, step)
		remaining_delta -= step
	resolve_velocity(state, car)


func get_horizontal_velocity_vector(state: CarRuntimeState, car_transform: Transform3D) -> Vector3:
	return _vehicle_motion_model.get_horizontal_velocity_vector(car_transform, state.forward_speed, state.lateral_speed)


func set_local_speeds_from_horizontal_velocity(state: CarRuntimeState, car_transform: Transform3D, horizontal_velocity: Vector3) -> void:
	var local_speeds: Vector2 = _vehicle_motion_model.get_local_speeds_from_horizontal_velocity(car_transform, horizontal_velocity)
	state.forward_speed = local_speeds.x
	state.lateral_speed = local_speeds.y


func _set_wheel_steering_angles(state: CarRuntimeState, steering: float) -> void:
	var front_angles: Vector2 = _lateral_tire_model.get_ackermann_steering_angles(
		steering,
		_config.max_steering_angle_degrees,
		_config.wheel_base,
		_config.front_axle_track_width
	)
	state.wheel_states[WheelTireState.Position.FRONT_LEFT].steering_angle_rad = front_angles.x
	state.wheel_states[WheelTireState.Position.FRONT_RIGHT].steering_angle_rad = front_angles.y
	state.wheel_states[WheelTireState.Position.REAR_LEFT].steering_angle_rad = 0.0
	state.wheel_states[WheelTireState.Position.REAR_RIGHT].steering_angle_rad = 0.0


func _limit_lateral_tire_energy(state: CarRuntimeState, maximum_speed: float) -> void:
	var current_speed: float = Vector2(state.forward_speed, state.lateral_speed).length()
	if current_speed <= maximum_speed + HORIZONTAL_SPEED_EPSILON_MPS:
		return
	if current_speed <= HORIZONTAL_SPEED_EPSILON_MPS or maximum_speed <= HORIZONTAL_SPEED_EPSILON_MPS:
		state.forward_speed = 0.0
		state.lateral_speed = 0.0
		return
	var scale: float = maximum_speed / current_speed
	state.forward_speed *= scale
	state.lateral_speed *= scale


func _apply_yaw_damping(state: CarRuntimeState, steering: float, delta: float) -> void:
	var horizontal_speed: float = Vector2(state.forward_speed, state.lateral_speed).length()
	var low_speed_factor: float = 1.0 - clampf(
		horizontal_speed / LOW_SPEED_YAW_REFERENCE_MPS,
		0.0,
		1.0
	)
	var released_steering_factor: float = 1.0 - absf(clampf(steering, -1.0, 1.0))
	var damping_rate: float = (
		BASE_YAW_DAMPING_PER_SECOND
		+ RELEASED_STEERING_YAW_DAMPING_PER_SECOND * released_steering_factor
		+ LOW_SPEED_YAW_DAMPING_PER_SECOND * low_speed_factor
	)
	state.yaw_rate_rad_s *= exp(-damping_rate * _get_ground_contact_factor(state) * maxf(delta, 0.0))
	if (
		absf(state.yaw_rate_rad_s) <= YAW_STOP_THRESHOLD_RAD_S
		and absf(state.yaw_acceleration_rad_s2) <= YAW_STOP_THRESHOLD_RAD_S
	):
		state.yaw_rate_rad_s = 0.0


func _rotate_local_velocity_for_yaw(state: CarRuntimeState, yaw_step: float) -> void:
	if absf(yaw_step) <= 0.000001:
		return
	var forward_speed: float = state.forward_speed
	var lateral_speed: float = state.lateral_speed
	var cosine: float = cos(yaw_step)
	var sine: float = sin(yaw_step)
	state.forward_speed = forward_speed * cosine + lateral_speed * sine
	state.lateral_speed = lateral_speed * cosine - forward_speed * sine


func _apply_low_speed_lateral_friction(state: CarRuntimeState, steering: float, delta: float) -> void:
	if absf(steering) > RELEASED_STEERING_THRESHOLD:
		return
	var horizontal_speed: float = Vector2(state.forward_speed, state.lateral_speed).length()
	var low_speed_factor: float = 1.0 - clampf(
		horizontal_speed / LOW_SPEED_LATERAL_FRICTION_REFERENCE_MPS,
		0.0,
		1.0
	)
	if low_speed_factor <= 0.0:
		return
	var lateral_deceleration: float = (
		maxf(_config.front_lateral_grip, _config.rear_lateral_grip)
		* state.surface_grip_multiplier
		* _get_ground_contact_factor(state)
		* low_speed_factor
	)
	state.lateral_speed = move_toward(
		state.lateral_speed,
		0.0,
		lateral_deceleration * maxf(delta, 0.0)
	)
	if absf(state.lateral_speed) <= LATERAL_STOP_THRESHOLD_MPS:
		state.lateral_speed = 0.0


func _get_previous_longitudinal_acceleration(state: CarRuntimeState) -> float:
	var acceleration: float = 0.0
	for wheel: WheelTireState in state.wheel_states:
		if not wheel.has_contact:
			continue
		acceleration += wheel.applied_longitudinal_acceleration
	return acceleration


func _get_previous_lateral_tire_acceleration(
	state: CarRuntimeState,
	vehicle_mass: float
) -> float:
	var total_lateral_force_n: float = 0.0
	for wheel: WheelTireState in state.wheel_states:
		if not wheel.has_contact:
			continue
		total_lateral_force_n += wheel.lateral_force_n
	return total_lateral_force_n / maxf(vehicle_mass, 1.0)


func _get_dynamic_wheel_load_share(
	wheel: WheelTireState,
	longitudinal_acceleration: float,
	lateral_acceleration: float
) -> float:
	var base_share: float = _config.get_wheel_load_share(
		wheel.wheel_index,
		longitudinal_acceleration
	)
	var dynamic_axle_fraction: float = base_share * 2.0
	var track_width: float = _config.front_axle_track_width if wheel.is_front() else _config.rear_axle_track_width
	var requested_transfer_per_wheel: float = (
		absf(lateral_acceleration)
		* _config.center_of_mass_height_m
		/ maxf(TireModel.STANDARD_GRAVITY * track_width, 0.01)
		* dynamic_axle_fraction
		* 0.5
	)
	var transfer_per_wheel: float = minf(
		requested_transfer_per_wheel,
		maxf(base_share - MIN_WHEEL_LOAD_SHARE, 0.0)
	)
	var outside_sign: float = signf(lateral_acceleration)
	var wheel_sign: float = 1.0 if wheel.is_left() else -1.0
	return base_share + outside_sign * wheel_sign * transfer_per_wheel


func _get_surface_grip_multiplier(collider: CollisionObject3D) -> float:
	if collider is TrackSurfaceBody:
		return (collider as TrackSurfaceBody).get_grip_multiplier()
	if collider.has_meta("surface_grip_multiplier"):
		var metadata_value: Variant = collider.get_meta("surface_grip_multiplier")
		if metadata_value is float or metadata_value is int:
			return clampf(float(metadata_value), 0.05, 2.0)
	return DEFAULT_SURFACE_GRIP_MULTIPLIER


func _get_wheel_effective_lateral_grip(wheel_index: int) -> float:
	if wheel_index == WheelTireState.Position.FRONT_LEFT or wheel_index == WheelTireState.Position.FRONT_RIGHT:
		return maxf(
			_config.front_lateral_grip
			* sqrt(_config.front_tire_width_m / REFERENCE_FRONT_TIRE_WIDTH_M),
			0.01
		)
	return maxf(
		_config.rear_lateral_grip
		* sqrt(_config.rear_tire_width_m / REFERENCE_REAR_TIRE_WIDTH_M),
		0.01
	)


func _get_ground_contact_factor(state: CarRuntimeState) -> float:
	return clampf(
		float(state.ground_contact_count) / float(GroundContactModel.PROBE_COUNT),
		0.0,
		1.0
	)
