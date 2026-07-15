extends RefCounted
class_name CarChassisController

const PROBE_END_MARGIN: float = 0.05
const REFERENCE_FRONT_TIRE_WIDTH_M: float = 0.225
const REFERENCE_REAR_TIRE_WIDTH_M: float = 0.245
const DEFAULT_SURFACE_GRIP_MULTIPLIER: float = 1.0
const PER_WHEEL_LATERAL_SHARE: float = 1.0 / 4.0

var _tire_model: TireModel = TireModel.new()
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
	state.update_contact_aggregates()
	if _config == null or _probe_local_positions.is_empty() or not car.is_inside_tree() or car.get_world_3d() == null:
		return

	var car_rid: RID = car.get_rid()
	if _excluded_car_rid != car_rid:
		_excluded_car_rid = car_rid
		_ray_query.exclude = [_excluded_car_rid]
	_ray_query.collision_mask = _config.ground_probe_collision_mask

	var ray_direction: Vector3 = -car.global_transform.basis.y.normalized()
	var maximum_probe_length: float = _config.suspension_rest_length + _config.suspension_travel + PROBE_END_MARGIN
	var direct_space_state: PhysicsDirectSpaceState3D = car.get_world_3d().direct_space_state

	for wheel_index: int in range(_probe_local_positions.size()):
		if wheel_index >= state.wheel_states.size():
			break
		var local_probe_position: Vector3 = _probe_local_positions[wheel_index]
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
		state.wheel_states[wheel_index].set_contact(
			_get_surface_grip_multiplier(collider),
			hit_normal,
			support_acceleration
		)

	state.update_contact_aggregates()


func update_tire_dynamics(state: CarRuntimeState, steering: float, handbrake_active: bool, delta: float) -> void:
	state.synchronize_wheel_contacts_from_aggregate()
	if state.ground_contact_count <= 0:
		state.clear_wheel_tire_dynamics()
		return

	for wheel: WheelTireState in state.wheel_states:
		if not wheel.has_contact:
			continue
		var wheel_handbrake_active: bool = handbrake_active and wheel.is_rear()
		state.lateral_speed = _tire_model.recover_lateral_speed(
			state.lateral_speed,
			_get_wheel_effective_lateral_grip(wheel.wheel_index) * PER_WHEEL_LATERAL_SHARE,
			_config.handbrake_lateral_grip_multiplier,
			wheel_handbrake_active,
			delta,
			wheel.surface_grip_multiplier
		)

	for wheel: WheelTireState in state.wheel_states:
		if not wheel.has_contact:
			wheel.reset_tire_dynamics()
			continue
		var wheel_steering: float = steering if wheel.is_front() else 0.0
		var wheel_handbrake_active: bool = handbrake_active and wheel.is_rear()
		wheel.lateral_slip_intensity = _tire_model.calculate_slip_intensity(
			state.lateral_speed,
			state.forward_speed,
			wheel_steering,
			_config.steering_slip_gain,
			_config.slip_speed_threshold,
			_config.max_forward_speed,
			wheel_handbrake_active
		)
		wheel.tire_slip_intensity = _tire_model.calculate_combined_slip_intensity(
			wheel.lateral_slip_intensity,
			wheel.longitudinal_slip_intensity
		)

	state.update_slip_aggregates()


func update_skid_marks(state: CarRuntimeState, car: CharacterBody3D, skid_mark_emitter: SkidMarkEmitter, delta: float) -> void:
	if skid_mark_emitter != null:
		skid_mark_emitter.update(delta, state.tire_slip_intensity, car.global_transform)


func update_tires(state: CarRuntimeState, steering: float, handbrake_active: bool, car: CharacterBody3D, skid_mark_emitter: SkidMarkEmitter, delta: float) -> void:
	sample_ground_contact(state, car)
	update_tire_dynamics(state, steering, handbrake_active, delta)
	update_skid_marks(state, car, skid_mark_emitter, delta)


func update_steering(state: CarRuntimeState, steering: float, car: CharacterBody3D, delta: float) -> void:
	var contact_factor: float = _get_ground_contact_factor(state)
	if contact_factor <= 0.0:
		return
	var steering_amount: float = _get_slip_limited_steering(state, steering)
	var absolute_forward_speed: float = absf(state.forward_speed)
	if absf(steering_amount) < 0.01 or absolute_forward_speed < 0.35:
		return
	var horizontal_velocity: Vector3 = get_horizontal_velocity_vector(state, car.global_transform)
	var speed_ratio: float = clampf(absolute_forward_speed / maxf(_config.max_forward_speed, 0.1), 0.0, 1.0)
	var high_speed_steering_limit: float = lerpf(1.0, 0.42, _smoothstep(speed_ratio))
	var steer_angle: float = deg_to_rad(_config.max_steering_angle_degrees) * steering_amount * high_speed_steering_limit
	var grip_factor: float = lerpf(1.0, 0.38, state.tire_slip_intensity) * contact_factor
	var axle_balance: float = _get_front_axle_yaw_factor()
	var yaw_rate: float = tan(steer_angle) * state.forward_speed / maxf(_config.wheel_base, 0.1) * grip_factor * axle_balance
	yaw_rate = clampf(yaw_rate, -_config.steering_speed, _config.steering_speed)
	car.rotate_y(-yaw_rate * delta)
	set_local_speeds_from_horizontal_velocity(state, car.global_transform, horizontal_velocity)


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


func _get_front_axle_yaw_factor() -> float:
	var front_effective: float = _config.front_lateral_grip * sqrt(_config.front_tire_width_m / REFERENCE_FRONT_TIRE_WIDTH_M)
	var rear_effective: float = _config.rear_lateral_grip * sqrt(_config.rear_tire_width_m / REFERENCE_REAR_TIRE_WIDTH_M)
	var total: float = maxf(front_effective + rear_effective, 0.01)
	return clampf(front_effective / total * 2.0, 0.72, 1.18)


func _get_ground_contact_factor(state: CarRuntimeState) -> float:
	return clampf(
		float(state.ground_contact_count) / float(GroundContactModel.PROBE_COUNT),
		0.0,
		1.0
	)


func _smoothstep(value: float) -> float:
	var clamped_value: float = clampf(value, 0.0, 1.0)
	return clamped_value * clamped_value * (3.0 - 2.0 * clamped_value)


func _get_slip_limited_steering(state: CarRuntimeState, steering: float) -> float:
	var steering_amount: float = clampf(steering, -1.0, 1.0)
	var lateral_slip_ratio: float = absf(state.lateral_speed) / maxf(_config.slip_speed_threshold, 0.1)
	if lateral_slip_ratio < _config.slip_steering_lock_threshold:
		return steering_amount
	var slip_direction: float = signf(state.lateral_speed)
	if signf(steering_amount) != slip_direction:
		return steering_amount
	var lock_range: float = maxf(1.0 - _config.slip_steering_lock_threshold, 0.01)
	var lock_amount: float = clampf((lateral_slip_ratio - _config.slip_steering_lock_threshold) / lock_range, 0.0, 1.0)
	var same_direction_multiplier: float = clampf(_config.slip_steering_same_direction_multiplier, 0.0, 1.0)
	var steering_multiplier: float = lerpf(1.0, same_direction_multiplier, lock_amount)
	return steering_amount * steering_multiplier
