extends CharacterBody3D
class_name PlayerCarController

const DEFAULT_CAR_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_6mt_specs.tres")

@export_group("Specs")
@export var car_specs: CarSpecs = DEFAULT_CAR_SPECS

@export_group("Driving")
@export var acceleration: float = 22.0
@export var brake_deceleration: float = 34.0
@export var reverse_acceleration: float = 12.0
@export var coast_deceleration: float = 5.0
@export var handbrake_deceleration: float = 18.0
@export var max_forward_speed: float = 30.0
@export var max_reverse_speed: float = 10.0
@export var steering_speed: float = 2.7
@export var wheel_base: float = 2.65
@export var max_steering_angle_degrees: float = 32.0

@export_group("Engine")
@export var idle_rpm: float = 900.0
@export var peak_torque_rpm: float = 4200.0
@export var redline_rpm: float = 6500.0
@export var rev_limiter_rpm: float = 6800.0
@export var low_rpm_torque_multiplier: float = 0.42
@export var mid_rpm_torque_multiplier: float = 0.82
@export var redline_torque_multiplier: float = 0.72
@export var engine_force: float = 30.0
@export var engine_brake_force: float = 3.0
@export var rpm_response: float = 8.0

@export_group("Transmission")
@export var manual_transmission_enabled: bool = false
@export var automatic_transmission_enabled: bool = false
@export var gear_ratios: Array[float] = [3.20, 2.10, 1.50, 1.15, 0.92, 0.75]
@export var reverse_gear_ratio: float = 3.00
@export var final_drive_ratio: float = 3.70
@export var peak_engine_torque: float = 420.0
@export var wheel_radius: float = 0.34
@export var drivetrain_efficiency: float = 0.85
@export var shift_delay: float = 0.28

@export_group("Automatic Transmission")
@export var automatic_upshift_rpm: float = 6200.0
@export var automatic_downshift_rpm: float = 2100.0
@export var automatic_kickdown_throttle: float = 0.82
@export var automatic_kickdown_rpm: float = 5200.0
@export var automatic_shift_delay: float = 0.22
@export var torque_converter_stall_rpm: float = 2600.0
@export var torque_converter_coupling_rpm: float = 4200.0
@export var torque_converter_stall_torque_multiplier: float = 1.65

@export_group("Resistance")
@export var vehicle_mass: float = 1200.0
@export var drag_coefficient: float = 0.30
@export var frontal_area: float = 2.05
@export var air_density: float = 1.225
@export var rolling_resistance_coefficient: float = 0.015

@export_group("Tires")
@export var lateral_grip: float = 10.0
@export var handbrake_lateral_grip_multiplier: float = 0.28
@export var steering_slip_gain: float = 0.85
@export var slip_speed_threshold: float = 2.2
@export var slip_steering_lock_threshold: float = 0.55
@export var slip_steering_same_direction_multiplier: float = 0.12
@export var skid_mark_min_slip: float = 0.45
@export var skid_mark_interval: float = 0.055
@export var skid_mark_lifetime: float = 10.0
@export var skid_mark_width: float = 0.22
@export var skid_mark_length: float = 0.9

@export_group("Grounding")
@export var gravity: float = 30.0
@export var floor_stick_force: float = 0.5

var _start_transform: Transform3D
var _forward_speed: float = 0.0
var _lateral_speed: float = 0.0
var _engine_rpm: float = 900.0
var _current_gear: int = 1
var _shift_timer: float = 0.0
var _throttle_input: float = 0.0
var _brake_input: float = 0.0
var _tire_slip_intensity: float = 0.0
var _car_input: CarInput = CarInput.new()
var _manual_transmission_model: ManualTransmissionModel = ManualTransmissionModel.new()
var _automatic_transmission_model: AutomaticTransmissionModel = AutomaticTransmissionModel.new()
var _shift_timer_model: ShiftTimerModel = ShiftTimerModel.new()
var _engine_model: EngineModel = EngineModel.new()
var _resistance_model: ResistanceModel = ResistanceModel.new()
var _drivetrain_model: DrivetrainModel = DrivetrainModel.new()
var _torque_converter_model: TorqueConverterModel = TorqueConverterModel.new()
var _tire_model: TireModel = TireModel.new()
var _vehicle_motion_model: VehicleMotionModel = VehicleMotionModel.new()
var _skid_mark_emitter: SkidMarkEmitter


func _ready() -> void:
	_apply_car_specs()
	_start_transform = global_transform
	_prepare_engine_model()
	_prepare_resistance_model()
	_prepare_drivetrain_model()
	_prepare_torque_converter_model()
	_prepare_skid_marks()


func get_forward_speed() -> float:
	return _forward_speed


func get_speed_kmh() -> float:
	return _forward_speed * 3.6


func get_engine_rpm() -> float:
	return _engine_rpm


func get_throttle_input() -> float:
	return _throttle_input


func get_engine_load() -> float:
	if _uses_geared_transmission() and _current_gear == 0:
		return 0.0

	if manual_transmission_enabled and _shift_timer > 0.0:
		return 0.0

	if automatic_transmission_enabled and _current_gear < 0:
		return _brake_input

	return _throttle_input


func get_tire_slip_intensity() -> float:
	return _tire_slip_intensity


func get_gear_text() -> String:
	if manual_transmission_enabled:
		if _current_gear < 0:
			return "R"
		if _current_gear == 0:
			return "N"
		return str(_current_gear)

	if automatic_transmission_enabled:
		if _current_gear < 0:
			return "R"
		return "D%d" % clampi(_current_gear, 1, maxi(gear_ratios.size(), 1))

	if _forward_speed < -0.25:
		return "R"
	if _forward_speed > 0.25:
		return "D"
	return "N"


func set_player_input_enabled(enabled: bool) -> void:
	_car_input.set_player_input_enabled(enabled)
	if not enabled:
		_throttle_input = 0.0
		_brake_input = 0.0


func set_external_input_enabled(enabled: bool) -> void:
	_car_input.set_external_input_enabled(enabled)


func set_external_drive_inputs(throttle: float, brake: float, steering: float, handbrake_active: bool = false) -> void:
	_car_input.set_external_drive_inputs(throttle, brake, steering, handbrake_active)


func _physics_process(delta: float) -> void:
	if _car_input.should_reset_car():
		_reset_to_start()
		return

	_update_shift_timer(delta)
	_car_input.read_drive_input()

	var throttle: float = _car_input.throttle
	var brake: float = _car_input.brake
	var steering: float = _car_input.steering
	var handbrake_active: bool = _car_input.handbrake_active
	_throttle_input = throttle
	_brake_input = brake

	_update_transmission_input(throttle, brake)
	_update_engine(throttle, delta)
	_update_speed(throttle, brake, handbrake_active, delta)
	_update_steering(steering, delta)
	_update_tire_model(steering, handbrake_active, delta)
	_apply_velocity(delta)


func _update_transmission_input(throttle: float, brake: float) -> void:
	if manual_transmission_enabled:
		var requested_gear: int = _manual_transmission_model.get_requested_gear(_current_gear, gear_ratios.size())
		if requested_gear != _current_gear:
			_set_transmission_gear(requested_gear)
		return

	if automatic_transmission_enabled:
		_update_automatic_transmission(throttle, brake)


func _update_automatic_transmission(throttle: float, brake: float) -> void:
	var lower_gear_rpm: float = idle_rpm
	if _current_gear > 1:
		lower_gear_rpm = _get_coupled_engine_rpm_for_gear(_current_gear - 1)

	var requested_gear: int = _automatic_transmission_model.get_requested_gear(
		_current_gear,
		gear_ratios.size(),
		_forward_speed,
		_engine_rpm,
		throttle,
		brake,
		_shift_timer,
		redline_rpm,
		automatic_upshift_rpm,
		automatic_downshift_rpm,
		automatic_kickdown_throttle,
		automatic_kickdown_rpm,
		lower_gear_rpm
	)

	if requested_gear != _current_gear:
		_set_transmission_gear(requested_gear)


func _update_shift_timer(delta: float) -> void:
	_shift_timer = _shift_timer_model.update_timer(_shift_timer, delta)


func _set_transmission_gear(next_gear: int) -> void:
	if next_gear == _current_gear:
		return

	_current_gear = next_gear
	_shift_timer = _shift_timer_model.get_shift_delay(automatic_transmission_enabled, automatic_shift_delay, shift_delay)


func _update_engine(throttle: float, delta: float) -> void:
	var wheel_rpm: float = _get_wheel_driven_rpm()
	_engine_rpm = _engine_model.update(throttle, wheel_rpm, delta)


func _update_speed(throttle: float, brake: float, handbrake_active: bool, delta: float) -> void:
	if throttle > 0.0:
		if _uses_geared_transmission():
			if automatic_transmission_enabled and _current_gear < 1:
				_set_transmission_gear(1)

			_forward_speed += _get_transmission_drive_acceleration(throttle) * delta
		else:
			var torque_multiplier: float = _get_torque_multiplier()
			var limiter_multiplier: float = _get_rev_limiter_multiplier()
			_forward_speed += throttle * engine_force * torque_multiplier * limiter_multiplier * delta

	if brake > 0.0:
		if manual_transmission_enabled:
			_forward_speed = move_toward(_forward_speed, 0.0, brake_deceleration * brake * delta)
		elif automatic_transmission_enabled:
			if _forward_speed > 0.25 or throttle > 0.0:
				_forward_speed = move_toward(_forward_speed, 0.0, brake_deceleration * brake * delta)
			else:
				if _current_gear >= 0:
					_set_transmission_gear(-1)

				_forward_speed += _get_transmission_drive_acceleration(brake) * delta
		elif _forward_speed > 0.25:
			_forward_speed = move_toward(_forward_speed, 0.0, brake_deceleration * brake * delta)
		else:
			_forward_speed -= reverse_acceleration * brake * delta

	if throttle == 0.0 and brake == 0.0:
		_forward_speed = move_toward(_forward_speed, 0.0, coast_deceleration * delta)

	if throttle == 0.0 and _forward_speed > 0.0:
		_forward_speed = move_toward(_forward_speed, 0.0, engine_brake_force * delta)

	if handbrake_active:
		_forward_speed = move_toward(_forward_speed, 0.0, handbrake_deceleration * delta)

	_apply_resistance(delta)
	_forward_speed = clampf(_forward_speed, -max_reverse_speed, max_forward_speed)


func _update_tire_model(steering: float, handbrake_active: bool, delta: float) -> void:
	_lateral_speed = _tire_model.recover_lateral_speed(
		_lateral_speed,
		lateral_grip,
		handbrake_lateral_grip_multiplier,
		handbrake_active,
		delta
	)
	_tire_slip_intensity = _tire_model.calculate_slip_intensity(
		_lateral_speed,
		_forward_speed,
		steering,
		steering_slip_gain,
		slip_speed_threshold,
		max_forward_speed,
		handbrake_active
	)

	if not is_on_floor():
		_tire_slip_intensity = 0.0
		return

	_update_skid_marks(delta)


func _update_skid_marks(delta: float) -> void:
	if _skid_mark_emitter != null:
		_skid_mark_emitter.update(delta, _tire_slip_intensity, global_transform)


func _apply_resistance(delta: float) -> void:
	_forward_speed = _resistance_model.apply(_forward_speed, delta)


func _get_wheel_driven_rpm() -> float:
	if not _uses_geared_transmission():
		var speed_ratio: float = clampf(absf(_forward_speed) / max_forward_speed, 0.0, 1.0)
		return lerpf(idle_rpm, redline_rpm, speed_ratio)

	if _current_gear == 0:
		return idle_rpm

	var coupled_rpm: float = _get_coupled_engine_rpm_for_gear(_current_gear)
	if automatic_transmission_enabled:
		return _get_torque_converter_rpm(coupled_rpm)

	return coupled_rpm


func _get_coupled_engine_rpm_for_gear(gear: int) -> float:
	return _drivetrain_model.get_coupled_engine_rpm_for_gear(gear, _forward_speed)


func _get_torque_converter_rpm(coupled_rpm: float) -> float:
	var drive_input: float = _brake_input if _current_gear < 0 else _throttle_input
	return _torque_converter_model.get_coupled_rpm(coupled_rpm, drive_input)


func _get_transmission_drive_acceleration(throttle: float) -> float:
	return _drivetrain_model.get_drive_acceleration(
		throttle,
		_current_gear,
		manual_transmission_enabled and _shift_timer > 0.0,
		_get_torque_multiplier(),
		_get_rev_limiter_multiplier(),
		_get_torque_converter_torque_multiplier(throttle)
	)


func _get_torque_converter_torque_multiplier(drive_input: float) -> float:
	if not automatic_transmission_enabled:
		return 1.0

	return _torque_converter_model.get_torque_multiplier(_engine_rpm, drive_input)


func _get_current_gear_ratio() -> float:
	return _get_gear_ratio_for_gear(_current_gear)


func _get_gear_ratio_for_gear(gear: int) -> float:
	return _drivetrain_model.get_gear_ratio_for_gear(gear)


func _uses_geared_transmission() -> bool:
	return manual_transmission_enabled or automatic_transmission_enabled


func _get_torque_multiplier() -> float:
	return _engine_model.get_torque_multiplier()


func _get_rev_limiter_multiplier() -> float:
	return _engine_model.get_rev_limiter_multiplier()


func _smoothstep(value: float) -> float:
	var clamped_value: float = clampf(value, 0.0, 1.0)
	return clamped_value * clamped_value * (3.0 - 2.0 * clamped_value)


func _update_steering(steering: float, delta: float) -> void:
	var steering_amount: float = _get_slip_limited_steering(steering)
	var absolute_forward_speed: float = absf(_forward_speed)
	if absf(steering_amount) < 0.01 or absolute_forward_speed < 0.35:
		return

	var horizontal_velocity: Vector3 = _get_horizontal_velocity_vector()
	var speed_ratio: float = clampf(absolute_forward_speed / maxf(max_forward_speed, 0.1), 0.0, 1.0)
	var high_speed_steering_limit: float = lerpf(1.0, 0.42, _smoothstep(speed_ratio))
	var steer_angle: float = deg_to_rad(max_steering_angle_degrees) * steering_amount * high_speed_steering_limit
	var grip_factor: float = lerpf(1.0, 0.38, _tire_slip_intensity)
	var yaw_rate: float = tan(steer_angle) * _forward_speed / maxf(wheel_base, 0.1) * grip_factor
	yaw_rate = clampf(yaw_rate, -steering_speed, steering_speed)

	rotate_y(-yaw_rate * delta)
	_set_local_speeds_from_horizontal_velocity(horizontal_velocity)


func _get_slip_limited_steering(steering: float) -> float:
	var steering_amount: float = clampf(steering, -1.0, 1.0)
	var lateral_slip_ratio: float = absf(_lateral_speed) / maxf(slip_speed_threshold, 0.1)
	if lateral_slip_ratio < slip_steering_lock_threshold:
		return steering_amount

	var slip_direction: float = signf(_lateral_speed)
	if signf(steering_amount) != slip_direction:
		return steering_amount

	var lock_range: float = maxf(1.0 - slip_steering_lock_threshold, 0.01)
	var lock_amount: float = clampf((lateral_slip_ratio - slip_steering_lock_threshold) / lock_range, 0.0, 1.0)
	var same_direction_multiplier: float = clampf(slip_steering_same_direction_multiplier, 0.0, 1.0)
	var steering_multiplier: float = lerpf(1.0, same_direction_multiplier, lock_amount)
	return steering_amount * steering_multiplier


func _apply_velocity(delta: float) -> void:
	var horizontal_velocity: Vector3 = _get_horizontal_velocity_vector()
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z

	if is_on_floor():
		velocity.y = -floor_stick_force
	else:
		velocity.y -= gravity * delta

	move_and_slide()


func _get_horizontal_velocity_vector() -> Vector3:
	return _vehicle_motion_model.get_horizontal_velocity_vector(global_transform, _forward_speed, _lateral_speed)


func _set_local_speeds_from_horizontal_velocity(horizontal_velocity: Vector3) -> void:
	var local_speeds: Vector2 = _vehicle_motion_model.get_local_speeds_from_horizontal_velocity(global_transform, horizontal_velocity)
	_forward_speed = local_speeds.x
	_lateral_speed = local_speeds.y


func _reset_to_start() -> void:
	global_transform = _start_transform
	velocity = Vector3.ZERO
	_forward_speed = 0.0
	_lateral_speed = 0.0
	_engine_rpm = _engine_model.reset()
	_current_gear = 1
	_shift_timer = 0.0
	_throttle_input = 0.0
	_brake_input = 0.0
	_tire_slip_intensity = 0.0
	if _skid_mark_emitter != null:
		_skid_mark_emitter.reset_timer()


func _apply_car_specs() -> void:
	if car_specs == null:
		return

	acceleration = car_specs.acceleration
	brake_deceleration = car_specs.brake_deceleration
	reverse_acceleration = car_specs.reverse_acceleration
	coast_deceleration = car_specs.coast_deceleration
	handbrake_deceleration = car_specs.handbrake_deceleration
	max_forward_speed = car_specs.max_forward_speed
	max_reverse_speed = car_specs.max_reverse_speed
	steering_speed = car_specs.steering_speed
	wheel_base = car_specs.wheel_base
	max_steering_angle_degrees = car_specs.max_steering_angle_degrees
	idle_rpm = car_specs.idle_rpm
	peak_torque_rpm = car_specs.peak_torque_rpm
	redline_rpm = car_specs.redline_rpm
	rev_limiter_rpm = car_specs.rev_limiter_rpm
	low_rpm_torque_multiplier = car_specs.low_rpm_torque_multiplier
	mid_rpm_torque_multiplier = car_specs.mid_rpm_torque_multiplier
	redline_torque_multiplier = car_specs.redline_torque_multiplier
	engine_force = car_specs.engine_force
	engine_brake_force = car_specs.engine_brake_force
	rpm_response = car_specs.rpm_response
	manual_transmission_enabled = car_specs.manual_transmission_enabled
	automatic_transmission_enabled = car_specs.automatic_transmission_enabled
	gear_ratios = car_specs.gear_ratios.duplicate()
	reverse_gear_ratio = car_specs.reverse_gear_ratio
	final_drive_ratio = car_specs.final_drive_ratio
	peak_engine_torque = car_specs.peak_engine_torque
	wheel_radius = car_specs.wheel_radius
	drivetrain_efficiency = car_specs.drivetrain_efficiency
	shift_delay = car_specs.shift_delay
	automatic_upshift_rpm = car_specs.automatic_upshift_rpm
	automatic_downshift_rpm = car_specs.automatic_downshift_rpm
	automatic_kickdown_throttle = car_specs.automatic_kickdown_throttle
	automatic_kickdown_rpm = car_specs.automatic_kickdown_rpm
	automatic_shift_delay = car_specs.automatic_shift_delay
	torque_converter_stall_rpm = car_specs.torque_converter_stall_rpm
	torque_converter_coupling_rpm = car_specs.torque_converter_coupling_rpm
	torque_converter_stall_torque_multiplier = car_specs.torque_converter_stall_torque_multiplier
	vehicle_mass = car_specs.vehicle_mass
	drag_coefficient = car_specs.drag_coefficient
	frontal_area = car_specs.frontal_area
	air_density = car_specs.air_density
	rolling_resistance_coefficient = car_specs.rolling_resistance_coefficient
	lateral_grip = car_specs.lateral_grip
	handbrake_lateral_grip_multiplier = car_specs.handbrake_lateral_grip_multiplier
	steering_slip_gain = car_specs.steering_slip_gain
	slip_speed_threshold = car_specs.slip_speed_threshold
	slip_steering_lock_threshold = car_specs.slip_steering_lock_threshold
	slip_steering_same_direction_multiplier = car_specs.slip_steering_same_direction_multiplier
	skid_mark_min_slip = car_specs.skid_mark_min_slip
	skid_mark_interval = car_specs.skid_mark_interval
	skid_mark_lifetime = car_specs.skid_mark_lifetime
	skid_mark_width = car_specs.skid_mark_width
	skid_mark_length = car_specs.skid_mark_length
	gravity = car_specs.gravity
	floor_stick_force = car_specs.floor_stick_force


func _prepare_engine_model() -> void:
	_engine_model.configure(
		idle_rpm,
		peak_torque_rpm,
		redline_rpm,
		rev_limiter_rpm,
		low_rpm_torque_multiplier,
		mid_rpm_torque_multiplier,
		redline_torque_multiplier,
		rpm_response
	)
	_engine_rpm = _engine_model.get_rpm()


func _prepare_resistance_model() -> void:
	_resistance_model.configure(
		vehicle_mass,
		drag_coefficient,
		frontal_area,
		air_density,
		rolling_resistance_coefficient
	)


func _prepare_drivetrain_model() -> void:
	_drivetrain_model.configure(
		idle_rpm,
		gear_ratios,
		reverse_gear_ratio,
		final_drive_ratio,
		peak_engine_torque,
		wheel_radius,
		drivetrain_efficiency,
		vehicle_mass
	)


func _prepare_torque_converter_model() -> void:
	_torque_converter_model.configure(
		idle_rpm,
		torque_converter_stall_rpm,
		torque_converter_coupling_rpm,
		torque_converter_stall_torque_multiplier
	)


func _prepare_skid_marks() -> void:
	_skid_mark_emitter = SkidMarkEmitter.new()
	_skid_mark_emitter.configure(
		self,
		skid_mark_min_slip,
		skid_mark_interval,
		skid_mark_lifetime,
		skid_mark_width,
		skid_mark_length
	)
