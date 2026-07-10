extends CharacterBody3D
class_name PlayerCarController

var _car_specs: CarSpecs

@export_group("Specs")
@export var car_specs: CarSpecs:
	set(value):
		_car_specs = value
		if is_inside_tree():
			_reconfigure_drive_runtime(true)
	get:
		return _car_specs

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


func _exit_tree() -> void:
	if _skid_mark_emitter != null:
		_skid_mark_emitter.dispose()


func get_forward_speed() -> float:
	return _runtime_state.forward_speed


func get_speed_kmh() -> float:
	return _runtime_state.forward_speed * 3.6


func get_engine_rpm() -> float:
	return _runtime_state.engine_rpm


func get_throttle_input() -> float:
	return _runtime_state.throttle_input


func get_engine_load() -> float:
	if _drive_config == null:
		return 0.0
	return _powertrain_controller.get_engine_load(_runtime_state)


func get_tire_slip_intensity() -> float:
	return _runtime_state.tire_slip_intensity


func get_gear_text() -> String:
	if _drive_config == null:
		return "N"
	return _powertrain_controller.get_gear_text(_runtime_state)


func get_current_gear() -> int:
	return _runtime_state.current_gear


func get_lateral_speed() -> float:
	return _runtime_state.lateral_speed


func set_player_input_enabled(enabled: bool) -> void:
	_car_input.set_player_input_enabled(enabled)
	if not enabled:
		_runtime_state.reset_input_snapshot()


func set_external_input_enabled(enabled: bool) -> void:
	_car_input.set_external_input_enabled(enabled)


func set_external_drive_inputs(throttle: float, brake: float, steering: float, handbrake_active: bool = false) -> void:
	_car_input.set_external_drive_inputs(throttle, brake, steering, handbrake_active)


func set_touch_drive_inputs(throttle: float, brake: float, steering: float, handbrake_active: bool = false) -> void:
	_car_input.set_touch_drive_inputs(throttle, brake, steering, handbrake_active)


func request_touch_gear_up() -> void:
	_car_input.request_touch_gear_up()


func request_touch_gear_down() -> void:
	_car_input.request_touch_gear_down()


func request_touch_reset() -> void:
	_car_input.request_touch_reset()


func clear_touch_input() -> void:
	_car_input.clear_touch_input()


func _physics_process(delta: float) -> void:
	if _drive_config == null:
		return

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
	_chassis_controller.update_tires(_runtime_state, steering, handbrake_active, self, _skid_mark_emitter, delta)
	_chassis_controller.update_steering(_runtime_state, steering, self, delta)
	_chassis_controller.apply_velocity(_runtime_state, self, delta)


func _reconfigure_drive_runtime(preserve_motion_state: bool = true) -> void:
	if car_specs == null:
		_drive_config = null
		set_physics_process(false)
		push_error("PlayerCarController requires a non-null CarSpecs resource.")
		return

	_drive_config = CarDriveConfigBuilder.build_from_specs(car_specs)
	if _drive_config == null:
		set_physics_process(false)
		return

	set_physics_process(true)
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
	if _drive_config == null:
		return

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
