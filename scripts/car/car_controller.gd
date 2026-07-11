extends CharacterBody3D
class_name PlayerCarController


enum SpecsApplyResult {
	OK,
	NULL_SPECS,
	INVALID_SPECS,
}

var _car_specs: CarSpecs

@export_group("Specs")
@export var car_specs: CarSpecs:
	set(value):
		if not is_inside_tree():
			_car_specs = value
			return
		try_apply_car_specs(value)
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
	var result: SpecsApplyResult = _initialize_drive_runtime()
	if result != SpecsApplyResult.OK:
		set_physics_process(false)
		return
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


func get_telemetry_snapshot() -> CarTelemetrySnapshot:
	return CarTelemetrySnapshot.capture(_runtime_state)


func capture_current_transform_as_start() -> void:
	_reset_controller.capture_start_transform(_runtime_state, global_transform)


func set_player_input_enabled(enabled: bool) -> void:
	_car_input.set_player_input_enabled(enabled)
	if not enabled:
		_runtime_state.reset_input_snapshot()


func set_external_input_enabled(enabled: bool) -> void:
	_car_input.set_external_input_enabled(enabled)


func set_external_drive_inputs(throttle: float, brake: float, steering: float, handbrake_active: bool = false) -> void:
	_car_input.set_external_drive_inputs(throttle, brake, steering, handbrake_active)


func try_apply_car_specs(next_specs: CarSpecs) -> SpecsApplyResult:
	if next_specs == null:
		push_error("PlayerCarController rejected null CarSpecs; keeping the active runtime configuration.")
		return SpecsApplyResult.NULL_SPECS
	var next_config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(next_specs)
	if next_config == null:
		push_error("PlayerCarController rejected invalid CarSpecs; keeping the active runtime configuration.")
		return SpecsApplyResult.INVALID_SPECS
	_car_specs = next_specs
	_apply_drive_config(next_config, true)
	return SpecsApplyResult.OK


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
	var gear_up_pressed: bool = _car_input.gear_up_pressed
	var gear_down_pressed: bool = _car_input.gear_down_pressed
	var safe_delta: float = clampf(delta, 0.0, CarPowertrainController.MAX_FRAME_DELTA)

	_runtime_state.set_drive_input_snapshot(throttle, brake)
	_chassis_controller.sample_ground_contact(_runtime_state, self)
	if safe_delta <= 0.0:
		_chassis_controller.update_tire_dynamics(
			_runtime_state,
			steering,
			handbrake_active,
			0.0
		)
		_powertrain_controller.update(
			_runtime_state,
			throttle,
			brake,
			handbrake_active,
			gear_up_pressed,
			gear_down_pressed,
			0.0
		)
		_chassis_controller.update_skid_marks(
			_runtime_state,
			self,
			_skid_mark_emitter,
			0.0
		)
		return

	var remaining_delta: float = safe_delta
	var apply_shift_input: bool = true
	while remaining_delta > 0.000001:
		var step: float = minf(remaining_delta, CarPowertrainController.MAX_SIMULATION_SUBSTEP)
		_chassis_controller.update_tire_dynamics(
			_runtime_state,
			steering,
			handbrake_active,
			step
		)
		_powertrain_controller.update(
			_runtime_state,
			throttle,
			brake,
			handbrake_active,
			gear_up_pressed if apply_shift_input else false,
			gear_down_pressed if apply_shift_input else false,
			step
		)
		_chassis_controller.update_steering(_runtime_state, steering, self, step)
		apply_shift_input = false
		remaining_delta -= step

	_chassis_controller.apply_velocity(_runtime_state, self, safe_delta)
	_chassis_controller.update_skid_marks(
		_runtime_state,
		self,
		_skid_mark_emitter,
		safe_delta
	)


func _initialize_drive_runtime() -> SpecsApplyResult:
	if _car_specs == null:
		push_error("PlayerCarController requires a non-null CarSpecs resource.")
		return SpecsApplyResult.NULL_SPECS
	var initial_config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(_car_specs)
	if initial_config == null:
		return SpecsApplyResult.INVALID_SPECS
	_apply_drive_config(initial_config, false)
	return SpecsApplyResult.OK


func _apply_drive_config(next_config: CarDriveConfig, preserve_motion_state: bool) -> void:
	_drive_config = next_config
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
