extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_physical_slip_ratio()
	_test_wheel_inertia_response()
	_test_drivetrain_and_brake_distribution()
	_test_airborne_wheelspin()
	_test_grounded_wheelspin_generates_vehicle_force()
	_test_braking_reduces_wheel_and_vehicle_speed()
	_test_rotational_telemetry_snapshot()
	_finish()


func _test_physical_slip_ratio() -> void:
	var model := WheelRotationalDynamicsModel.new()
	var radius: float = 0.30
	var rolling_omega: float = 10.0 / radius
	_expect(
		absf(model.calculate_slip_ratio(rolling_omega, radius, 10.0, 1.0)) <= 0.0001,
		"pure rolling produces zero longitudinal slip"
	)
	_expect(
		model.calculate_slip_ratio(rolling_omega * 1.25, radius, 10.0, 1.0) > 0.0,
		"wheel circumferential speed above vehicle speed produces positive wheelspin slip"
	)
	_expect(
		model.calculate_slip_ratio(0.0, radius, 10.0, 1.0) < 0.0,
		"a locked wheel on a moving vehicle produces negative braking slip"
	)


func _test_wheel_inertia_response() -> void:
	var model := WheelRotationalDynamicsModel.new()
	var light_wheel := WheelTireState.new(WheelTireState.Position.REAR_LEFT)
	var heavy_wheel := WheelTireState.new(WheelTireState.Position.REAR_RIGHT)
	light_wheel.configure_rotation(0.30, 1.0)
	heavy_wheel.configure_rotation(0.30, 4.0)
	model.integrate_wheel(light_wheel, 120.0, 0.0, 0.0, 1000.0, 0.0, 0.0, 0.10)
	model.integrate_wheel(heavy_wheel, 120.0, 0.0, 0.0, 1000.0, 0.0, 0.0, 0.10)
	_expect(
		light_wheel.angular_velocity_rad_s > heavy_wheel.angular_velocity_rad_s,
		"the same torque accelerates a lower-inertia wheel more strongly"
	)
	_expect(
		is_equal_approx(light_wheel.angular_acceleration_rad_s2, 120.0),
		"wheel angular acceleration follows torque divided by moment of inertia"
	)


func _test_drivetrain_and_brake_distribution() -> void:
	var config := _build_direct_drive_config()
	config.drive_layout = CarSpecs.DriveLayout.FRONT_WHEEL_DRIVE
	config.sanitize()
	_expect(
		is_equal_approx(config.get_drive_torque_fraction(WheelTireState.Position.FRONT_LEFT), 0.5)
		and is_zero_approx(config.get_drive_torque_fraction(WheelTireState.Position.REAR_LEFT)),
		"FWD sends drive torque only to the front axle"
	)
	config.drive_layout = CarSpecs.DriveLayout.REAR_WHEEL_DRIVE
	_expect(
		is_zero_approx(config.get_drive_torque_fraction(WheelTireState.Position.FRONT_RIGHT))
		and is_equal_approx(config.get_drive_torque_fraction(WheelTireState.Position.REAR_RIGHT), 0.5),
		"RWD sends drive torque only to the rear axle"
	)
	config.drive_layout = CarSpecs.DriveLayout.ALL_WHEEL_DRIVE
	config.awd_front_torque_fraction = 0.40
	_expect(
		is_equal_approx(config.get_drive_torque_fraction(WheelTireState.Position.FRONT_LEFT), 0.20)
		and is_equal_approx(config.get_drive_torque_fraction(WheelTireState.Position.REAR_LEFT), 0.30),
		"AWD splits torque between both axles using the configured centre split"
	)
	var brake_fraction_sum: float = 0.0
	for wheel_index: int in range(WheelTireState.WHEEL_COUNT):
		brake_fraction_sum += config.get_service_brake_fraction(wheel_index)
	_expect(is_equal_approx(brake_fraction_sum, 1.0), "service brake fractions sum to the complete vehicle brake demand")
	_expect(
		config.get_service_brake_fraction(WheelTireState.Position.FRONT_LEFT)
		> config.get_service_brake_fraction(WheelTireState.Position.REAR_LEFT),
		"default service braking is front biased"
	)
	_expect(
		is_zero_approx(config.get_handbrake_fraction(WheelTireState.Position.FRONT_LEFT))
		and is_equal_approx(config.get_handbrake_fraction(WheelTireState.Position.REAR_LEFT), 0.5),
		"handbrake torque acts only on the rear wheels"
	)


func _test_airborne_wheelspin() -> void:
	var config := _build_direct_drive_config()
	config.drive_layout = CarSpecs.DriveLayout.REAR_WHEEL_DRIVE
	config.sanitize()
	var state := CarRuntimeState.new()
	state.reset_drive_state(config.idle_rpm)
	state.ground_contact_count = 0
	var powertrain := _build_powertrain(config, state)
	powertrain.update(state, 1.0, 0.0, false, false, false, 0.10)
	_expect(is_zero_approx(state.forward_speed), "airborne drive torque cannot accelerate vehicle translation")
	_expect(
		state.get_wheel_state(WheelTireState.Position.REAR_LEFT).angular_velocity_rad_s > 0.0
		and state.get_wheel_state(WheelTireState.Position.REAR_RIGHT).angular_velocity_rad_s > 0.0,
		"airborne driven wheels gain angular velocity"
	)
	_expect(
		is_zero_approx(state.get_wheel_state(WheelTireState.Position.FRONT_LEFT).drive_torque_nm),
		"airborne non-driven wheels receive no drivetrain torque"
	)


func _test_grounded_wheelspin_generates_vehicle_force() -> void:
	var config := _build_direct_drive_config()
	config.drive_layout = CarSpecs.DriveLayout.REAR_WHEEL_DRIVE
	config.longitudinal_grip_coefficient = 0.75
	config.engine_force = 40.0
	config.sanitize()
	var state := CarRuntimeState.new()
	state.reset_drive_state(config.idle_rpm)
	state.ground_contact_count = WheelTireState.WHEEL_COUNT
	var powertrain := _build_powertrain(config, state)
	powertrain.update(state, 1.0, 0.0, false, false, false, 0.10)
	_expect(state.forward_speed > 0.0, "physical driven-wheel slip generates forward tire force")
	_expect(
		state.get_wheel_state(WheelTireState.Position.REAR_LEFT).longitudinal_slip_ratio > 0.0,
		"driven rear wheel records positive physical slip during launch"
	)
	_expect(
		absf(state.get_wheel_state(WheelTireState.Position.REAR_LEFT).angular_velocity_rad_s)
		> absf(state.get_wheel_state(WheelTireState.Position.FRONT_LEFT).angular_velocity_rad_s),
		"driven wheels rotate faster than free-rolling wheels during wheelspin"
	)


func _test_braking_reduces_wheel_and_vehicle_speed() -> void:
	var config := _build_direct_drive_config()
	config.sanitize()
	var state := CarRuntimeState.new()
	state.reset_drive_state(config.idle_rpm)
	state.forward_speed = 12.0
	state.ground_contact_count = WheelTireState.WHEEL_COUNT
	var powertrain := _build_powertrain(config, state)
	var initial_omega: float = state.get_wheel_state(WheelTireState.Position.FRONT_LEFT).angular_velocity_rad_s
	powertrain.update(state, 0.0, 1.0, false, false, false, 0.10)
	_expect(state.forward_speed < 12.0, "service braking reduces vehicle speed through tire force")
	_expect(
		state.get_wheel_state(WheelTireState.Position.FRONT_LEFT).angular_velocity_rad_s < initial_omega,
		"service brake torque reduces front wheel angular velocity"
	)
	_expect(
		state.longitudinal_slip_ratio < 0.0,
		"braking records negative physical longitudinal slip"
	)


func _test_rotational_telemetry_snapshot() -> void:
	var state := CarRuntimeState.new()
	state.get_wheel_state(WheelTireState.Position.FRONT_LEFT).angular_velocity_rad_s = 12.5
	state.get_wheel_state(WheelTireState.Position.REAR_RIGHT).angular_position_rad = 1.75
	state.get_wheel_state(WheelTireState.Position.REAR_LEFT).longitudinal_slip_ratio = 0.22
	var snapshot := CarTelemetrySnapshot.capture(state)
	_expect(
		is_equal_approx(snapshot.get_wheel_angular_velocities()[WheelTireState.Position.FRONT_LEFT], 12.5),
		"telemetry captures each wheel angular velocity"
	)
	_expect(
		is_equal_approx(snapshot.get_wheel_angular_positions()[WheelTireState.Position.REAR_RIGHT], 1.75),
		"telemetry captures each wheel angular position"
	)
	_expect(
		is_equal_approx(snapshot.get_wheel_slip_ratios()[WheelTireState.Position.REAR_LEFT], 0.22),
		"telemetry captures each wheel physical slip ratio"
	)


func _build_direct_drive_config() -> CarDriveConfig:
	var config := CarDriveConfig.new()
	config.transmission_type = CarSpecs.TransmissionType.DIRECT_DRIVE
	config.engine_force = 30.0
	config.brake_deceleration = 12.0
	config.reverse_acceleration = 8.0
	config.coast_deceleration = 0.0
	config.engine_brake_force = 0.0
	config.handbrake_deceleration = 16.0
	config.max_forward_speed = 60.0
	config.max_reverse_speed = 12.0
	config.vehicle_mass = 1000.0
	config.drag_coefficient = 0.0
	config.frontal_area = 2.0
	config.air_density = 1.225
	config.rolling_resistance_coefficient = 0.0
	config.wheel_radius = 0.30
	config.front_wheel_inertia_kg_m2 = 1.8
	config.rear_wheel_inertia_kg_m2 = 1.8
	config.wheel_angular_damping_nm_per_rad_s = 0.0
	config.wheel_slip_reference_speed_mps = 0.5
	config.front_brake_bias = 0.62
	config.longitudinal_grip_coefficient = 1.0
	config.longitudinal_peak_slip_ratio = 0.12
	config.longitudinal_slide_grip_multiplier = 0.78
	config.front_lateral_grip = 10.0
	config.rear_lateral_grip = 10.0
	config.front_tire_width_m = 0.225
	config.rear_tire_width_m = 0.225
	config.sanitize()
	return config


func _build_powertrain(config: CarDriveConfig, state: CarRuntimeState) -> CarPowertrainController:
	var powertrain := CarPowertrainController.new()
	powertrain.configure(config)
	powertrain.reset(state)
	return powertrain


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[WHEEL_ROTATIONAL_DYNAMICS_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[WHEEL_ROTATIONAL_DYNAMICS_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[WHEEL_ROTATIONAL_DYNAMICS_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[WHEEL_ROTATIONAL_DYNAMICS_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[WHEEL_ROTATIONAL_DYNAMICS_TEST] - %s" % failure_message)
	quit(1)
