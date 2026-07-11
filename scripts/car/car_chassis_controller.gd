extends RefCounted
class_name CarChassisController

const PROBE_END_MARGIN: float = 0.05

var _tire_model: TireModel = TireModel.new()
var _vehicle_motion_model: VehicleMotionModel = VehicleMotionModel.new()
var _ground_contact_model: GroundContactModel = GroundContactModel.new()
var _config: CarDriveConfig


func configure(config: CarDriveConfig) -> void:
	_config = config.duplicate_config()
	_config.sanitize()


func update_tires(
	state: CarRuntimeState,
	steering: float,
	handbrake_active: bool,
	car: CharacterBody3D,
	skid_mark_emitter: SkidMarkEmitter,
	delta: float
) -> void:
	_update_ground_contact(state, car)
	if state.ground_contact_count <= 0:
		state.tire_slip_intensity = 0.0
		_update_skid_marks(state, car, skid_mark_emitter, delta)
		return

	state.lateral_speed = _tire_model.recover_lateral_speed(
		state.lateral_speed,
		_config.lateral_grip,
		_config.handbrake_lateral_grip_multiplier,
		handbrake_active,
		delta,
		state.surface_grip_multiplier
	)
	state.tire_slip_intensity = _tire_model.calculate_slip_intensity(
		state.lateral_speed,
		state.forward_speed,
		steering,
		_config.steering_slip_gain,
		_config.slip_speed_threshold,
		_config.max_forward_speed,
		handbrake_active
	)

	_update_skid_marks(state, car, skid_mark_emitter, delta)


func update_steering(state: CarRuntimeState, steering: float, car: CharacterBody3D, delta: float) -> void:
	if state.ground_contact_count <= 0:
		return
	var steering_amount: float = _get_slip_limited_steering(state, steering)
	var absolute_forward_speed: float = absf(state.forward_speed)
	if absf(steering_amount) < 0.01 or absolute_forward_speed < 0.35:
		return

	var horizontal_velocity: Vector3 = get_horizontal_velocity_vector(state, car.global_transform)
	var speed_ratio: float = clampf(absolute_forward_speed / maxf(_config.max_forward_speed, 0.1), 0.0, 1.0)
	var high_speed_steering_limit: float = lerpf(1.0, 0.42, _smoothstep(speed_ratio))
	var steer_angle: float = deg_to_rad(_config.max_steering_angle_degrees) * steering_amount * high_speed_steering_limit
	var grip_factor: float = lerpf(1.0, 0.38, state.tire_slip_intensity)
	var yaw_rate: float = tan(steer_angle) * state.forward_speed / maxf(_config.wheel_base, 0.1) * grip_factor
	yaw_rate = clampf(yaw_rate, -_config.steering_speed, _config.steering_speed)

	car.rotate_y(-yaw_rate * delta)
	set_local_speeds_from_horizontal_velocity(state, car.global_transform, horizontal_velocity)


func apply_velocity(state: CarRuntimeState, car: CharacterBody3D, delta: float) -> void:
	var horizontal_velocity: Vector3 = get_horizontal_velocity_vector(state, car.global_transform)
	car.velocity.x = horizontal_velocity.x
	car.velocity.z = horizontal_velocity.z

	var remaining_delta: float = clampf(delta, 0.0, CarPowertrainController.MAX_FRAME_DELTA)
	while remaining_delta > 0.000001:
		var step: float = minf(remaining_delta, CarPowertrainController.MAX_SIMULATION_SUBSTEP)
		car.velocity.y -= _config.gravity * step
		if state.ground_contact_count > 0:
			car.velocity += state.ground_normal * state.suspension_acceleration * step
		elif car.is_on_floor():
			car.velocity.y = minf(car.velocity.y, -_config.floor_stick_force)
		remaining_delta -= step

	car.move_and_slide()

	var resolved_horizontal_velocity: Vector3 = Vector3(car.velocity.x, 0.0, car.velocity.z)
	set_local_speeds_from_horizontal_velocity(state, car.global_transform, resolved_horizontal_velocity)


func get_horizontal_velocity_vector(state: CarRuntimeState, car_transform: Transform3D) -> Vector3:
	return _vehicle_motion_model.get_horizontal_velocity_vector(
		car_transform,
		state.forward_speed,
		state.lateral_speed
	)


func set_local_speeds_from_horizontal_velocity(
	state: CarRuntimeState,
	car_transform: Transform3D,
	horizontal_velocity: Vector3
) -> void:
	var local_speeds: Vector2 = _vehicle_motion_model.get_local_speeds_from_horizontal_velocity(
		car_transform,
		horizontal_velocity
	)
	state.forward_speed = local_speeds.x
	state.lateral_speed = local_speeds.y


func _update_ground_contact(state: CarRuntimeState, car: CharacterBody3D) -> void:
	state.ground_contact_count = 0
	state.ground_normal = Vector3.UP
	state.surface_grip_multiplier = 1.0
	state.suspension_acceleration = 0.0
	if _config == null or not car.is_inside_tree() or car.get_world_3d() == null:
		return

	var probe_positions: Array[Vector3] = _ground_contact_model.get_probe_local_positions(
		_config.wheel_base,
		_config.axle_track_width,
		_config.suspension_probe_height
	)
	var ray_direction: Vector3 = -car.global_transform.basis.y.normalized()
	var maximum_probe_length: float = (
		_config.suspension_rest_length
		+ _config.suspension_travel
		+ PROBE_END_MARGIN
	)
	var normals: Array[Vector3] = []
	var grip_values: Array[float] = []
	var support_acceleration: float = 0.0
	var direct_space_state: PhysicsDirectSpaceState3D = car.get_world_3d().direct_space_state

	for local_probe_position: Vector3 in probe_positions:
		var ray_start: Vector3 = car.global_transform * local_probe_position
		var ray_end: Vector3 = ray_start + ray_direction * maximum_probe_length
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			ray_start,
			ray_end,
			car.collision_mask,
			[car.get_rid()]
		)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var hit: Dictionary = direct_space_state.intersect_ray(query)
		if hit.is_empty():
			continue

		var hit_position: Vector3 = hit.get("position", ray_end)
		var hit_normal: Vector3 = hit.get("normal", Vector3.UP)
		if hit_normal.length_squared() <= 0.000001:
			hit_normal = Vector3.UP
		else:
			hit_normal = hit_normal.normalized()
		var normal_velocity: float = car.velocity.dot(hit_normal)
		support_acceleration += _ground_contact_model.calculate_spring_acceleration(
			ray_start.distance_to(hit_position),
			_config.suspension_rest_length,
			_config.suspension_travel,
			normal_velocity,
			_config.suspension_stiffness,
			_config.suspension_damping
		)
		normals.append(hit_normal)
		grip_values.append(_get_surface_grip(hit.get("collider")))

	state.ground_contact_count = normals.size()
	if state.ground_contact_count <= 0:
		return
	state.ground_normal = _ground_contact_model.calculate_average_normal(normals)
	state.surface_grip_multiplier = _ground_contact_model.calculate_average_grip(grip_values)
	state.suspension_acceleration = support_acceleration


func _get_surface_grip(collider_value: Variant) -> float:
	var surface: TrackSurfaceBody = collider_value as TrackSurfaceBody
	return surface.get_grip_multiplier() if surface != null else 1.0


func _update_skid_marks(
	state: CarRuntimeState,
	car: CharacterBody3D,
	skid_mark_emitter: SkidMarkEmitter,
	delta: float
) -> void:
	if skid_mark_emitter != null:
		skid_mark_emitter.update(delta, state.tire_slip_intensity, car.global_transform)


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
