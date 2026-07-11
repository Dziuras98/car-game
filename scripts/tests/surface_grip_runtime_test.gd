extends Node

const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_longitudinal_grip_budget()
	_test_lateral_grip_budget()
	await _test_generated_surface_contract()
	_finish()


func _test_longitudinal_grip_budget() -> void:
	var config: CarDriveConfig = _build_direct_drive_config()
	var dry_state: CarRuntimeState = _make_state(config)
	var grass_state: CarRuntimeState = _make_state(config)
	grass_state.surface_grip_multiplier = 0.5
	var sliding_state: CarRuntimeState = _make_state(config)
	sliding_state.tire_slip_intensity = 0.8

	var dry_powertrain: CarPowertrainController = _make_powertrain(config, dry_state)
	var grass_powertrain: CarPowertrainController = _make_powertrain(config, grass_state)
	var sliding_powertrain: CarPowertrainController = _make_powertrain(config, sliding_state)
	dry_powertrain.update(dry_state, 1.0, 0.0, false, false, false, 0.1)
	grass_powertrain.update(grass_state, 1.0, 0.0, false, false, false, 0.1)
	sliding_powertrain.update(sliding_state, 1.0, 0.0, false, false, false, 0.1)
	_expect(dry_state.forward_speed > grass_state.forward_speed, "lower surface grip reduces drive acceleration")
	_expect(dry_state.forward_speed > sliding_state.forward_speed, "lateral slip consumes longitudinal acceleration budget")

	var dry_brake_state: CarRuntimeState = _make_state(config)
	dry_brake_state.forward_speed = 12.0
	var grass_brake_state: CarRuntimeState = _make_state(config)
	grass_brake_state.forward_speed = 12.0
	grass_brake_state.surface_grip_multiplier = 0.5
	var dry_brakes: CarPowertrainController = _make_powertrain(config, dry_brake_state)
	var grass_brakes: CarPowertrainController = _make_powertrain(config, grass_brake_state)
	dry_brakes.update(dry_brake_state, 0.0, 1.0, false, false, false, 0.1)
	grass_brakes.update(grass_brake_state, 0.0, 1.0, false, false, false, 0.1)
	_expect(dry_brake_state.forward_speed < grass_brake_state.forward_speed, "lower surface grip increases braking distance")


func _test_lateral_grip_budget() -> void:
	var tire_model: TireModel = TireModel.new()
	var dry_recovered: float = tire_model.recover_lateral_speed(5.0, 10.0, 0.3, false, 0.1, 1.0)
	var grass_recovered: float = tire_model.recover_lateral_speed(5.0, 10.0, 0.3, false, 0.1, 0.5)
	var handbrake_recovered: float = tire_model.recover_lateral_speed(5.0, 10.0, 0.3, true, 0.1, 1.0)
	_expect(absf(dry_recovered) < absf(grass_recovered), "low-grip surface slows lateral recovery")
	_expect(absf(dry_recovered) < absf(handbrake_recovered), "handbrake consumes lateral grip")
	_expect(is_equal_approx(tire_model.get_longitudinal_grip_factor(0.0, 1.0), 1.0), "zero slip on asphalt exposes the full longitudinal budget")
	_expect(tire_model.get_longitudinal_grip_factor(1.0, 1.0) <= 0.001, "full lateral slip exhausts the longitudinal friction budget")


func _test_generated_surface_contract() -> void:
	var track: GeneratedTrack = SIMPLE_OVAL_SCENE.instantiate() as GeneratedTrack
	add_child(track)
	await get_tree().process_frame
	var asphalt: TrackSurfaceBody = track.get_node_or_null("GeneratedContent/TrackSurface") as TrackSurfaceBody
	var shoulder: TrackSurfaceBody = track.get_node_or_null("GeneratedContent/RoadsideTerrain") as TrackSurfaceBody
	var grass: TrackSurfaceBody = track.get_node_or_null("GeneratedContent/Grass") as TrackSurfaceBody
	_expect(asphalt != null and is_equal_approx(asphalt.get_grip_multiplier(), TrackSurfaceMeshBuilder.ASPHALT_GRIP), "asphalt publishes its typed runtime grip coefficient")
	_expect(shoulder != null and is_equal_approx(shoulder.get_grip_multiplier(), TrackSurfaceMeshBuilder.SHOULDER_GRIP), "roadside publishes its typed runtime grip coefficient")
	_expect(grass != null and is_equal_approx(grass.get_grip_multiplier(), TrackSurfaceMeshBuilder.GRASS_GRIP), "grass publishes its typed runtime grip coefficient")
	track.queue_free()
	await get_tree().process_frame


func _build_direct_drive_config() -> CarDriveConfig:
	var config: CarDriveConfig = CarDriveConfig.new()
	config.transmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE
	config.engine_force = 30.0
	config.brake_deceleration = 30.0
	config.reverse_acceleration = 10.0
	config.coast_deceleration = 0.0
	config.engine_brake_force = 0.0
	config.handbrake_deceleration = 18.0
	config.max_forward_speed = 40.0
	config.max_reverse_speed = 10.0
	config.vehicle_mass = 1200.0
	config.drag_coefficient = 0.0
	config.frontal_area = 2.0
	config.air_density = 1.225
	config.rolling_resistance_coefficient = 0.0
	config.idle_rpm = 900.0
	config.peak_torque_rpm = 4200.0
	config.redline_rpm = 6500.0
	config.rev_limiter_rpm = 6800.0
	config.rpm_response = 8.0
	config.sanitize()
	return config


func _make_state(config: CarDriveConfig) -> CarRuntimeState:
	var state: CarRuntimeState = CarRuntimeState.new()
	state.reset_drive_state(config.idle_rpm)
	state.ground_contact_count = 4
	return state


func _make_powertrain(config: CarDriveConfig, state: CarRuntimeState) -> CarPowertrainController:
	var controller: CarPowertrainController = CarPowertrainController.new()
	controller.configure(config)
	controller.reset(state)
	return controller


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[SURFACE_GRIP_RUNTIME_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[SURFACE_GRIP_RUNTIME_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SURFACE_GRIP_RUNTIME_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[SURFACE_GRIP_RUNTIME_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[SURFACE_GRIP_RUNTIME_TEST] - %s" % failure_message)
	get_tree().quit(1)
