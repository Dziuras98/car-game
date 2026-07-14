extends Node

const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_longitudinal_grip_budget()
	_test_engine_braking_uses_tire_budget()
	_test_longitudinal_slip_curve()
	_test_contact_capacity_scaling()
	_test_lateral_grip_budget()
	await _test_generated_surface_contract()
	_finish()


func _test_longitudinal_grip_budget() -> void:
	var config: CarDriveConfig = _build_direct_drive_config()
	var dry_state: CarRuntimeState = _make_state(config)
	var grass_state: CarRuntimeState = _make_state(config)
	grass_state.surface_grip_multiplier = 0.5
	var sliding_state: CarRuntimeState = _make_state(config)
	sliding_state.lateral_slip_intensity = 0.8

	var dry_powertrain: CarPowertrainController = _make_powertrain(config, dry_state)
	var grass_powertrain: CarPowertrainController = _make_powertrain(config, grass_state)
	var sliding_powertrain: CarPowertrainController = _make_powertrain(config, sliding_state)
	dry_powertrain.update(dry_state, 1.0, 0.0, false, false, false, 0.1)
	grass_powertrain.update(grass_state, 1.0, 0.0, false, false, false, 0.1)
	sliding_powertrain.update(sliding_state, 1.0, 0.0, false, false, false, 0.1)
	_expect(dry_state.forward_speed > grass_state.forward_speed, "lower surface grip reduces drive acceleration")
	_expect(dry_state.forward_speed > sliding_state.forward_speed, "lateral slip consumes longitudinal acceleration budget")
	_expect(dry_state.longitudinal_slip_ratio > config.longitudinal_peak_slip_ratio, "excess drive demand creates positive longitudinal slip")
	_expect(dry_state.longitudinal_slip_intensity > 0.0, "wheelspin contributes to the tire slip signal")

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
	_expect(dry_brake_state.longitudinal_slip_ratio < -config.longitudinal_peak_slip_ratio, "excess brake demand creates negative longitudinal slip")
	_expect(dry_brake_state.forward_speed > 12.0 - config.brake_deceleration * 0.1, "locked-wheel braking is limited below raw brake demand")


func _test_engine_braking_uses_tire_budget() -> void:
	var config: CarDriveConfig = _build_direct_drive_config()
	config.engine_brake_force = 20.0
	config.coast_deceleration = 0.0
	var dry_state: CarRuntimeState = _make_state(config)
	dry_state.forward_speed = 12.0
	var grass_state: CarRuntimeState = _make_state(config)
	grass_state.forward_speed = 12.0
	grass_state.surface_grip_multiplier = 0.5
	var sliding_state: CarRuntimeState = _make_state(config)
	sliding_state.forward_speed = 12.0
	sliding_state.lateral_slip_intensity = 0.8

	var dry_powertrain: CarPowertrainController = _make_powertrain(config, dry_state)
	var grass_powertrain: CarPowertrainController = _make_powertrain(config, grass_state)
	var sliding_powertrain: CarPowertrainController = _make_powertrain(config, sliding_state)
	dry_powertrain.update(dry_state, 0.0, 0.0, false, false, false, 0.1)
	grass_powertrain.update(grass_state, 0.0, 0.0, false, false, false, 0.1)
	sliding_powertrain.update(sliding_state, 0.0, 0.0, false, false, false, 0.1)

	_expect(dry_state.forward_speed < grass_state.forward_speed, "low-grip surfaces reduce engine-braking deceleration")
	_expect(dry_state.forward_speed < sliding_state.forward_speed, "lateral tire load reduces engine-braking capacity")
	_expect(dry_state.longitudinal_slip_ratio < -config.longitudinal_peak_slip_ratio, "excess engine braking records negative longitudinal slip")
	_expect(dry_state.longitudinal_slip_intensity > 0.0, "engine-braking slip contributes to the tire signal")


func _test_longitudinal_slip_curve() -> void:
	var tire_model: TireModel = TireModel.new()
	var peak_capacity: float = tire_model.get_longitudinal_acceleration_capacity(
		0.0,
		1.0,
		1.0,
		1.0
	)
	var below_peak: Vector2 = tire_model.resolve_longitudinal_acceleration(
		peak_capacity * 0.5,
		0.0,
		1.0,
		1.0,
		1.0,
		0.12,
		0.78
	)
	var above_peak: Vector2 = tire_model.resolve_longitudinal_acceleration(
		peak_capacity * 3.0,
		0.0,
		1.0,
		1.0,
		1.0,
		0.12,
		0.78
	)
	var combined_load: Vector2 = tire_model.resolve_longitudinal_acceleration(
		peak_capacity,
		0.8,
		1.0,
		1.0,
		1.0,
		0.12,
		0.78
	)
	var locked_brake: Vector2 = tire_model.resolve_longitudinal_acceleration(
		-peak_capacity * 3.0,
		0.0,
		1.0,
		1.0,
		1.0,
		0.12,
		0.78
	)
	_expect(is_equal_approx(below_peak.x, peak_capacity * 0.5), "sub-peak longitudinal demand is transmitted without clipping")
	_expect(below_peak.y > 0.0 and below_peak.y < 0.12, "sub-peak traction produces elastic positive slip ratio")
	_expect(above_peak.x < peak_capacity, "wheelspin falls from peak grip toward sliding grip")
	_expect(above_peak.y > 0.12, "wheelspin exceeds configured peak slip ratio")
	_expect(combined_load.x < peak_capacity, "lateral load reduces the available longitudinal peak")
	_expect(locked_brake.x > -peak_capacity and locked_brake.y < -0.12, "wheel lock limits braking and produces negative slip ratio")
	_expect(
		tire_model.calculate_combined_slip_intensity(0.8, 0.8) == 1.0,
		"combined lateral and longitudinal slip is clamped to one"
	)


func _test_contact_capacity_scaling() -> void:
	var config: CarDriveConfig = _build_direct_drive_config()
	var acceleration_speeds: Array[float] = []
	var braking_speeds: Array[float] = []
	for contact_count: int in range(1, GroundContactModel.PROBE_COUNT + 1):
		var acceleration_state: CarRuntimeState = _make_state(config)
		acceleration_state.ground_contact_count = contact_count
		var acceleration_powertrain: CarPowertrainController = _make_powertrain(config, acceleration_state)
		acceleration_powertrain.update(acceleration_state, 1.0, 0.0, false, false, false, 0.1)
		acceleration_speeds.append(acceleration_state.forward_speed)

		var braking_state: CarRuntimeState = _make_state(config)
		braking_state.ground_contact_count = contact_count
		braking_state.forward_speed = 12.0
		var braking_powertrain: CarPowertrainController = _make_powertrain(config, braking_state)
		braking_powertrain.update(braking_state, 0.0, 1.0, false, false, false, 0.1)
		braking_speeds.append(braking_state.forward_speed)

	for index: int in range(1, acceleration_speeds.size()):
		_expect(
			acceleration_speeds[index] > acceleration_speeds[index - 1],
			"drive acceleration increases monotonically with active contact count %d -> %d"
			% [index, index + 1]
		)
		_expect(
			braking_speeds[index] < braking_speeds[index - 1],
			"service braking increases monotonically with active contact count %d -> %d"
			% [index, index + 1]
		)

	var chassis: CarChassisController = CarChassisController.new()
	chassis.configure(config)
	var one_contact_lateral: CarRuntimeState = _make_state(config)
	one_contact_lateral.ground_contact_count = 1
	one_contact_lateral.lateral_speed = 5.0
	var full_contact_lateral: CarRuntimeState = _make_state(config)
	full_contact_lateral.ground_contact_count = GroundContactModel.PROBE_COUNT
	full_contact_lateral.lateral_speed = 5.0
	chassis.update_tire_dynamics(one_contact_lateral, 0.0, false, 0.1)
	chassis.update_tire_dynamics(full_contact_lateral, 0.0, false, 0.1)
	_expect(
		absf(full_contact_lateral.lateral_speed) < absf(one_contact_lateral.lateral_speed),
		"lateral recovery is weaker when only one support point remains"
	)


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
	config.front_lateral_grip = 10.0
	config.rear_lateral_grip = 10.0
	config.front_tire_width_m = 0.225
	config.rear_tire_width_m = 0.245
	config.longitudinal_grip_coefficient = 1.0
	config.longitudinal_peak_slip_ratio = 0.12
	config.longitudinal_slide_grip_multiplier = 0.78
	config.slip_speed_threshold = 2.2
	config.sanitize()
	return config


func _make_state(config: CarDriveConfig) -> CarRuntimeState:
	var state: CarRuntimeState = CarRuntimeState.new()
	state.reset_drive_state(config.idle_rpm)
	state.ground_contact_count = GroundContactModel.PROBE_COUNT
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
