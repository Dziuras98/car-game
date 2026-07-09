extends RefCounted
class_name CarChassisController

var _tire_model: TireModel = TireModel.new()
var _vehicle_motion_model: VehicleMotionModel = VehicleMotionModel.new()
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
	state.lateral_speed = _tire_model.recover_lateral_speed(
		state.lateral_speed,
		_config.lateral_grip,
		_config.handbrake_lateral_grip_multiplier,
		handbrake_active,
		delta
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

	if not car.is_on_floor():
		state.tire_slip_intensity = 0.0
		return

	_update_skid_marks(state, car, skid_mark_emitter, delta)


func update_steering(state: CarRuntimeState, steering: float, car: CharacterBody3D, delta: float) -> void:
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

	if car.is_on_floor():
		car.velocity.y = -_config.floor_stick_force
	else:
		car.velocity.y -= _config.gravity * delta

	car.move_and_slide()


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
