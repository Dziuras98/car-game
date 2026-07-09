extends CharacterBody3D
class_name PlayerCarController

const DEFAULT_CAR_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_6mt_specs.tres")

var _car_specs: CarSpecs = DEFAULT_CAR_SPECS

@export_group("Specs")
@export var car_specs: CarSpecs = DEFAULT_CAR_SPECS:
	set(value):
		_car_specs = value
		if is_inside_tree():
			_reconfigure_drive_runtime(true)
	get:
		return _car_specs

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

var _drive_config: CarDriveConfig
var _runtime_state: CarRuntimeState = CarRuntimeState.new()
var _powertrain_controller: CarPowertrainController = CarPowertrainController.new()
var _chassis_controller: CarChassisController = CarChassisController.new()
var _reset_controller: CarResetController = CarResetController.new()
var _car_input: CarInput = CarInput.new()
var _skid_mark_emitter: SkidMarkEmitter


func _ready() -> void:
	_reconfigure_drive_runtime(false)
	_reset_controller.capture_start_transform(_runtime_state, global_transform)


func get_forward_speed() -> float:
	return _runtime_state.forward_speed


func get_speed_kmh() -> float:
	return _runtime_state.forward_speed * 3.6


func get_engine_rpm() -> float:
	return _runtime_state.engine_rpm


func get_throttle_input() -> float:
	return _runtime_state.throttle_input


func get_engine_load() -> float:
	return _powertrain_controller.get_engine_load(_runtime_state)


func get_tire_slip_intensity() -> float:
	return _runtime_state.tire_slip_intensity


func get_gear_text() -> String:
	return _powertrain_controller.get_gear_text(_runtime_state)


func get_current_gear_for_test() -> int:
	return _runtime_state.current_gear


func get_lateral_speed_for_test() -> float:
	return _runtime_state.lateral_speed


func set_player_input_enabled(enabled: bool) -> void:
	_car_input.set_player_input_enabled(enabled)
	if not enabled:
		_runtime_state.reset_input_snapshot()


func set_external_input_enabled(enabled: bool) -> void:
	_car_input.set_external_input_enabled(enabled)


func set_external_drive_inputs(throttle: float, brake: float, steering: float, handbrake_active: bool = false) -> void:
	_car_input.set_external_drive_inputs(throttle, brake, steering, handbrake_active)


func _physics_process(delta: float) -> void:
	if _car_input.should_reset_car():
		_reset_to_start()
		return

	_car_input.read_drive_input()

	var throttle: float = _car_input.throttle
	var brake: float = _car_input.brake
	var steering: float = _car_input.steering
	var handbrake_active: bool = _car_input.handbrake_active

	_runtime_state.set_drive_input_snapshot(throttle, brake)
	_powertrain_controller.update(
		_runtime_state,
		throttle,
		brake,
		handbrake_active,
		_car_input.gear_up_pressed,
		_car_input.gear_down_pressed,
		delta
	)
	_chassis_controller.update_steering(_runtime_state, steering, self, delta)
	_chassis_controller.update_tires(_runtime_state, steering, handbrake_active, self, _skid_mark_emitter, delta)
	_chassis_controller.apply_velocity(_runtime_state, self, delta)


func _reconfigure_drive_runtime(preserve_motion_state: bool = true) -> void:
	_drive_config = CarDriveConfigBuilder.build_from_specs_or_legacy(car_specs, self)
	_drive_config.sanitize()
	_powertrain_controller.configure(_drive_config)
	_chassis_controller.configure(_drive_config)
	_configure_skid_mark_emitter()

	if preserve_motion_state:
		_clamp_runtime_gear_to_config()
		return

	_runtime_state.reset_drive_state(_drive_config.idle_rpm)
	_powertrain_controller.reset(_runtime_state)


func _clamp_runtime_gear_to_config() -> void:
	if _drive_config == null or not _drive_config.uses_geared_transmission():
		return

	var max_forward_gear: int = maxi(_drive_config.gear_ratios.size(), 1)
	if _runtime_state.current_gear > max_forward_gear:
		_runtime_state.current_gear = max_forward_gear
	if _runtime_state.current_gear < -1:
		_runtime_state.current_gear = -1


func _reset_to_start() -> void:
	_reset_controller.reset_to_start(
		self,
		_runtime_state,
		_drive_config,
		_powertrain_controller,
		_skid_mark_emitter
	)


func _configure_skid_mark_emitter() -> void:
	if _drive_config == null:
		return

	if _skid_mark_emitter == null:
		_skid_mark_emitter = SkidMarkEmitter.new()

	_skid_mark_emitter.configure(
		self,
		_drive_config.skid_mark_min_slip,
		_drive_config.skid_mark_interval,
		_drive_config.skid_mark_lifetime,
		_drive_config.skid_mark_width,
		_drive_config.skid_mark_length
	)


func _apply_car_specs() -> void:
	_reconfigure_drive_runtime(true)
