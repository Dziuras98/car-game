extends RefCounted
class_name CarChassisController

const PROBE_END_MARGIN: float = 0.05
const REFERENCE_FRONT_TIRE_WIDTH_M: float = 0.225
const REFERENCE_REAR_TIRE_WIDTH_M: float = 0.245
const DEFAULT_SURFACE_GRIP_MULTIPLIER: float = 1.0
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
var _predicted_transform: Transform3D = Transform3D.IDENTITY
var _prediction_active: bool = false


func configure(config: CarDriveConfig) -> void:
	_config = config.duplicate_config()
	_config.sanitize()
	_probe_local_positions = _ground_contact_model.get_probe_local_positions(
		_config.wheel_base,
		_config.front_axle_track_width,
		_config.rear_axle_track_width,
		_config.suspension_probe_height,
		_config.front_static_load_fraction
	)
	_excluded_car_rid = RID()
	_ray_query.exclude = []
	_ray_query.collide_with_areas = false
	_ray_query.collide_with_bodies = true
	_prediction_active = false


func begin_simulation_frame(car: CharacterBody3D) -> void:
	_predicted_transform = car.global_transform
	_prediction_active = true


func advance_simulation_prediction(state: CarRuntimeState, car: CharacterBody3D, delta: float) -> void:
	if not _prediction_active:
		return
	var safe_delta: float = maxf(delta, 0.0)
	if safe_delta <= 0.0:
		return
	var normal: Vector3 = state.ground_normal if state.ground_contact_count > 0 else Vector3.UP
	var velocity: Vector3 = _vehicle_motion_model.get_velocity_vector(
		_predicted_transform,
		state.forward_speed,
		state.lateral_speed,
		normal
	)
	velocity += normal * car.velocity.dot(normal)
	_predicted_transform.origin += velocity * safe_delta
	var yaw_step: float = state.yaw_rate_rad_s * safe_delta
	if absf(yaw_step) > 0.000001:
		_predicted_transform.basis = _predicted_transform.basis.rotated(Vector3.UP, -yaw_step)


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

	var sampling_transform: Transform3D = _predicted_transform if _prediction_active else car.global_transform
	var ray_direction: Vector3 = -sampling_transform.basis.y.normalized()
	var maximum_probe_length: float = _config.suspension_rest_length + _config.suspension_travel + PROBE_END_MARGIN
	var direct_space_state: PhysicsDirectSpaceState3D = car.get_world_3d().direct_space_state

	for wheel_index: int in range(mini(_probe_local_positions.size(), state.wheel_states.size())):
		var ray_start: Vector3 = sampling_transform * _probe_local_positions[wheel_index]
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
			support_acceleration,
			hit_position
		)
	state.update_contact_aggregates()


func update_tire_dynamics(state: CarRuntimeState, steering: float, handbrake_active: bool, delta: float) -> void:
	state.synchronize_wheel_contacts_from_aggregate()
	_update_steering_input_state(state, steering, delta)
	_set_wheel_steering_angles(state, state.steering_input_state)
	_update_wheel_road_speeds(state)
	state.update_wheel_load_shares(
		_config,
		state.longitudinal_acceleration_mps2,
		state.lateral_acceleration_mps2
	)
	state.longitudinal_acceleration_mps2 = 0.0
	state.lateral_acceleration_mps2 = 0.0
	state.yaw_acceleration_rad_s2 = 0.0
	state.yaw_moment_nm = 0.0
	if state.ground_contact_count <= 0:
		for wheel: WheelTireState in state.wheel_states:
			wheel.reset_lateral_dynamics()
			wheel.lateral_grip_usage = 0.0
			wheel.tire_slip_intensity = wheel.longitudinal_slip_intensity
		state.update_slip_aggregates()
		_update_body_attitude(state, delta)
		return

	var safe_delta: float = maxf(delta, 0.0)
	var maximum_speed: float = Vector2(state.forward_speed, state.lateral_speed).length()
	_apply_lateral_force_solution(state, handbrake_active, safe_delta, false)
	if safe_delta > 0.0:
		_limit_lateral_tire_energy(state, maximum_speed)
		_apply_yaw_damping(state, state.steering_input_state, safe_delta)
		state.yaw_rate_rad_s = clampf(
			state.yaw_rate_rad_s,
			-_config.max_yaw_rate_rad_s,
			_config.max_yaw_rate_rad_s
		)
		_rotate_local_velocity_for_yaw(state, state.yaw_rate_rad_s * safe_delta)
		_apply_low_speed_lateral_friction(state, state.steering_input_state, safe_delta)
	_update_body_attitude(state, safe_delta)
	state.update_slip_aggregates()


func correct_combined_tire_forces(state: CarRuntimeState, handbrake_active: bool, delta: float) -> void:
	if _config == null or state.ground_contact_count <= 0:
		return
	state.update_wheel_load_shares(
		_config,
		state.longitudinal_acceleration_mps2,
		state.lateral_acceleration_mps2
	)
	_apply_lateral_force_solution(state, handbrake_active, maxf(delta, 0.0), true)
	_update_body_attitude(state, delta)
	state.update_slip_aggregates()


func _apply_lateral_force_solution(
	state: CarRuntimeState,
	handbrake_active: bool,
	delta: float,
	correction_only: bool
) -> void:
	var mass: float = maxf(_config.vehicle_mass, 1.0)
	var total_body_force: Vector2 = Vector2.ZERO
	var total_yaw_moment: float = 0.0
	for wheel: WheelTireState in state.wheel_states:
		if not wheel.has_contact:
			wheel.reset_lateral_dynamics()
			wheel.lateral_grip_usage = 0.0
			continue
		var forward_offset: float = _lateral_tire_model.get_wheel_forward_offset_m(_config, wheel.wheel_index)
		var lateral_offset: float = _lateral_tire_model.get_wheel_lateral_offset_m(_config, wheel.wheel_index)
		var wheel_velocity: Vector2 = _lateral_tire_model.get_wheel_local_velocity(
			state.forward_speed,
			state.lateral_speed,
			state.yaw_rate_rad_s,
			forward_offset,
			lateral_offset
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
		var handbrake_multiplier: float = (
			_config.handbrake_lateral_grip_multiplier
			if handbrake_active and wheel.is_rear()
			else 1.0
		)
		var lateral_acceleration: float = _lateral_tire_model.resolve_lateral_acceleration(
			wheel.lateral_slip_angle_rad,
			wheel_velocity.x,
			wheel.normal_load_share,
			lateral_grip,
			wheel.surface_grip_multiplier,
			wheel.longitudinal_grip_usage,
			peak_slip_angle,
			handbrake_multiplier,
			_config.lateral_slide_grip_multiplier
		)
		var next_lateral_force: float = lateral_acceleration * mass
		var applied_lateral_force: float = (
			next_lateral_force - wheel.lateral_force_n if correction_only else next_lateral_force
		)
		wheel.lateral_force_n = next_lateral_force
		wheel.lateral_grip_usage = _lateral_tire_model.calculate_lateral_grip_usage(
			wheel.lateral_slip_angle_rad,
			peak_slip_angle,
			_config.lateral_slide_grip_multiplier
		)
		wheel.lateral_slip_intensity = _lateral_tire_model.calculate_lateral_slip_intensity(
			wheel.lateral_slip_angle_rad,
			peak_slip_angle
		)
		var body_force: Vector2 = _rotate_wheel_force_to_body(
			Vector2(0.0, applied_lateral_force),
			wheel.steering_angle_rad
		)
		wheel.body_force_local_n += body_force
		total_body_force += body_force
		total_yaw_moment += forward_offset * body_force.y - lateral_offset * body_force.x
		wheel.tire_slip_intensity = _tire_model.calculate_combined_slip_intensity(
			wheel.lateral_slip_intensity,
			wheel.longitudinal_slip_intensity
		)
	if delta <= 0.0:
		state.lateral_acceleration_mps2 += total_body_force.y / mass
		state.yaw_moment_nm += total_yaw_moment
		state.yaw_acceleration_rad_s2 += total_yaw_moment / _lateral_tire_model.estimate_yaw_inertia_kg_m2(_config)
		return
	var acceleration: Vector2 = total_body_force / mass
	state.forward_speed += acceleration.x * delta
	state.lateral_speed += acceleration.y * delta
	state.longitudinal_acceleration_mps2 += acceleration.x
	state.lateral_acceleration_mps2 += acceleration.y
	state.yaw_moment_nm += total_yaw_moment
	var yaw_acceleration: float = total_yaw_moment / _lateral_tire_model.estimate_yaw_inertia_kg_m2(_config)
	state.yaw_acceleration_rad_s2 += yaw_acceleration
	state.yaw_rate_rad_s += yaw_acceleration * delta


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
	var normal: Vector3 = state.ground_normal if state.ground_contact_count > 0 else Vector3.UP
	var tangent_velocity: Vector3 = _vehicle_motion_model.get_velocity_vector(
		car.global_transform,
		state.forward_speed,
		state.lateral_speed,
		normal
	)
	var normal_velocity: float = car.velocity.dot(normal)
	car.velocity = tangent_velocity + normal * normal_velocity
	var safe_delta: float = clampf(delta, 0.0, CarPowertrainController.MAX_SIMULATION_SUBSTEP)
	if safe_delta <= 0.0:
		return
	car.velocity += Vector3.DOWN * _config.gravity * safe_delta
	if state.ground_contact_count > 0:
		car.velocity += state.suspension_acceleration_vector * safe_delta
	elif car.is_on_floor():
		car.velocity.y = minf(car.velocity.y, -_config.floor_stick_force)


func resolve_velocity(state: CarRuntimeState, car: CharacterBody3D) -> void:
	var requested_velocity: Vector3 = car.velocity
	car.move_and_slide()
	_apply_collision_yaw(state, car, requested_velocity, car.velocity)
	var normal: Vector3 = state.ground_normal if state.ground_contact_count > 0 else Vector3.UP
	set_local_speeds_from_velocity(state, car.global_transform, car.velocity, normal)
	_prediction_active = false


func apply_velocity(state: CarRuntimeState, car: CharacterBody3D, delta: float) -> void:
	begin_simulation_frame(car)
	var remaining_delta: float = clampf(delta, 0.0, CarPowertrainController.MAX_FRAME_DELTA)
	while remaining_delta > 0.000001:
		var step: float = minf(remaining_delta, CarPowertrainController.MAX_SIMULATION_SUBSTEP)
		integrate_velocity(state, car, step)
		advance_simulation_prediction(state, car, step)
		remaining_delta -= step
	resolve_velocity(state, car)


func get_horizontal_velocity_vector(state: CarRuntimeState, car_transform: Transform3D) -> Vector3:
	var normal: Vector3 = state.ground_normal if state.ground_contact_count > 0 else Vector3.UP
	return _vehicle_motion_model.get_velocity_vector(car_transform, state.forward_speed, state.lateral_speed, normal)


func set_local_speeds_from_horizontal_velocity(state: CarRuntimeState, car_transform: Transform3D, horizontal_velocity: Vector3) -> void:
	set_local_speeds_from_velocity(state, car_transform, horizontal_velocity, Vector3.UP)


func set_local_speeds_from_velocity(
	state: CarRuntimeState,
	car_transform: Transform3D,
	velocity: Vector3,
	ground_normal: Vector3
) -> void:
	var local_speeds: Vector2 = _vehicle_motion_model.get_local_speeds_from_velocity(
		car_transform,
		velocity,
		ground_normal
	)
	state.forward_speed = local_speeds.x
	state.lateral_speed = local_speeds.y


func _update_steering_input_state(state: CarRuntimeState, steering: float, delta: float) -> void:
	var target: float = clampf(steering, -1.0, 1.0)
	if delta <= 0.0:
		state.steering_input_state = target
		return
	var blend: float = 1.0 - exp(-_config.steering_response_rate * delta)
	state.steering_input_state = lerpf(state.steering_input_state, target, blend)


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


func _update_wheel_road_speeds(state: CarRuntimeState) -> void:
	for wheel: WheelTireState in state.wheel_states:
		wheel.road_longitudinal_speed_mps = state.get_wheel_longitudinal_road_speed(wheel, _config)


func _rotate_wheel_force_to_body(wheel_force: Vector2, steering_angle: float) -> Vector2:
	var cosine: float = cos(steering_angle)
	var sine: float = sin(steering_angle)
	return Vector2(
		wheel_force.x * cosine - wheel_force.y * sine,
		wheel_force.x * sine + wheel_force.y * cosine
	)


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
	var low_speed_factor: float = 1.0 - clampf(horizontal_speed / LOW_SPEED_YAW_REFERENCE_MPS, 0.0, 1.0)
	var released_steering_factor: float = 1.0 - absf(clampf(steering, -1.0, 1.0))
	var damping_rate: float = (
		_config.yaw_damping_per_second
		+ _config.released_steering_yaw_damping_per_second * released_steering_factor
		+ _config.low_speed_yaw_damping_per_second * low_speed_factor
	)
	state.yaw_rate_rad_s *= exp(-damping_rate * _get_ground_contact_factor(state) * maxf(delta, 0.0))
	if absf(state.yaw_rate_rad_s) <= YAW_STOP_THRESHOLD_RAD_S and absf(state.yaw_acceleration_rad_s2) <= YAW_STOP_THRESHOLD_RAD_S:
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
	var low_speed_factor: float = 1.0 - clampf(horizontal_speed / LOW_SPEED_LATERAL_FRICTION_REFERENCE_MPS, 0.0, 1.0)
	if low_speed_factor <= 0.0:
		return
	var lateral_deceleration: float = (
		maxf(_config.front_lateral_grip, _config.rear_lateral_grip)
		* state.surface_grip_multiplier
		* _get_ground_contact_factor(state)
		* low_speed_factor
	)
	state.lateral_speed = move_toward(state.lateral_speed, 0.0, lateral_deceleration * maxf(delta, 0.0))
	if absf(state.lateral_speed) <= LATERAL_STOP_THRESHOLD_MPS:
		state.lateral_speed = 0.0


func _update_body_attitude(state: CarRuntimeState, delta: float) -> void:
	var gravity_reference: float = maxf(TireModel.STANDARD_GRAVITY, 0.01)
	var pitch_limit: float = deg_to_rad(_config.max_body_pitch_degrees)
	var roll_limit: float = deg_to_rad(_config.max_body_roll_degrees)
	var target_pitch: float = clampf(
		-state.longitudinal_acceleration_mps2 / gravity_reference * pitch_limit,
		-pitch_limit,
		pitch_limit
	)
	var target_roll: float = clampf(
		-state.lateral_acceleration_mps2 / gravity_reference * roll_limit,
		-roll_limit,
		roll_limit
	)
	if delta <= 0.0:
		state.body_pitch_angle_rad = target_pitch
		state.body_roll_angle_rad = target_roll
		return
	var pitch_blend: float = 1.0 - exp(-_config.body_pitch_response * delta)
	var roll_blend: float = 1.0 - exp(-_config.body_roll_response * delta)
	state.body_pitch_angle_rad = lerpf(state.body_pitch_angle_rad, target_pitch, pitch_blend)
	state.body_roll_angle_rad = lerpf(state.body_roll_angle_rad, target_roll, roll_blend)


func _apply_collision_yaw(
	state: CarRuntimeState,
	car: CharacterBody3D,
	requested_velocity: Vector3,
	resolved_velocity: Vector3
) -> void:
	if _config.collision_yaw_response <= 0.0 or car.get_slide_collision_count() <= 0:
		return
	var delta_momentum: Vector3 = (resolved_velocity - requested_velocity) * _config.vehicle_mass
	if delta_momentum.length_squared() <= 0.000001:
		return
	var up_axis: Vector3 = car.global_transform.basis.y.normalized()
	var yaw_impulse: float = 0.0
	var wall_collision_count: int = 0
	for collision_index: int in range(car.get_slide_collision_count()):
		var collision: KinematicCollision3D = car.get_slide_collision(collision_index)
		if collision == null:
			continue
		var normal: Vector3 = collision.get_normal()
		if absf(normal.dot(Vector3.UP)) >= _config.minimum_ground_normal_dot:
			continue
		var lever: Vector3 = collision.get_position() - car.global_position
		yaw_impulse += lever.cross(delta_momentum).dot(up_axis)
		wall_collision_count += 1
	if wall_collision_count <= 0:
		return
	var yaw_inertia: float = _lateral_tire_model.estimate_yaw_inertia_kg_m2(_config)
	state.yaw_rate_rad_s += (
		yaw_impulse
		/ float(wall_collision_count)
		/ maxf(yaw_inertia, 1.0)
		* _config.collision_yaw_response
	)
	state.yaw_rate_rad_s = clampf(state.yaw_rate_rad_s, -_config.max_yaw_rate_rad_s, _config.max_yaw_rate_rad_s)


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
			_config.front_lateral_grip * sqrt(_config.front_tire_width_m / REFERENCE_FRONT_TIRE_WIDTH_M),
			0.01
		)
	return maxf(
		_config.rear_lateral_grip * sqrt(_config.rear_tire_width_m / REFERENCE_REAR_TIRE_WIDTH_M),
		0.01
	)


func _get_ground_contact_factor(state: CarRuntimeState) -> float:
	return clampf(float(state.ground_contact_count) / float(GroundContactModel.PROBE_COUNT), 0.0, 1.0)
