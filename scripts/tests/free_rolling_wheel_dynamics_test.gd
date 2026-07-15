extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_unloaded_contact_tracks_road_speed()
	_test_unloaded_contact_stops_with_vehicle()
	_test_airborne_wheel_is_not_constrained_to_road_speed()
	_test_rwd_front_wheels_are_prepared_before_slip_resolution()
	_test_external_speed_discontinuity_does_not_impulse_vehicle()
	_test_turning_free_wheel_uses_contact_patch_road_speed()
	_finish()


func _test_unloaded_contact_tracks_road_speed() -> void:
	var model := WheelRotationalDynamicsModel.new()
	var wheel := WheelTireState.new(WheelTireState.Position.FRONT_LEFT)
	wheel.configure_rotation(0.30, 1.5)
	wheel.set_contact(1.0, Vector3.UP, 9.81)
	wheel.angular_velocity_rad_s = 0.0
	model.integrate_wheel(wheel, 0.0, 0.0, 8.0, 1400.0, 0.15, 12.0, 1.0 / 120.0)
	_expect(
		is_equal_approx(wheel.get_circumferential_speed_mps(), 12.0),
		"an unloaded contacted wheel follows road speed instead of accumulating fictitious slip"
	)
	_expect(is_zero_approx(wheel.tire_torque_nm), "pure rolling does not retain a fictitious tire torque")


func _test_unloaded_contact_stops_with_vehicle() -> void:
	var model := WheelRotationalDynamicsModel.new()
	var wheel := WheelTireState.new(WheelTireState.Position.FRONT_RIGHT)
	wheel.configure_rotation(0.32, 1.7)
	wheel.set_contact(1.0, Vector3.UP, 9.81)
	wheel.set_rolling_speed(18.0)
	model.integrate_wheel(wheel, 0.0, 0.0, -5.0, 1500.0, 0.15, 0.0, 1.0 / 120.0)
	_expect(is_zero_approx(wheel.angular_velocity_rad_s), "an unloaded contacted wheel stops when vehicle road speed reaches zero")


func _test_airborne_wheel_is_not_constrained_to_road_speed() -> void:
	var model := WheelRotationalDynamicsModel.new()
	var wheel := WheelTireState.new(WheelTireState.Position.FRONT_LEFT)
	wheel.configure_rotation(0.30, 1.5)
	wheel.angular_velocity_rad_s = 20.0
	model.integrate_wheel(wheel, 0.0, 0.0, 0.0, 1400.0, 0.0, 12.0, 1.0 / 120.0)
	_expect(
		is_equal_approx(wheel.angular_velocity_rad_s, 20.0),
		"an airborne unloaded wheel retains independent angular velocity"
	)


func _test_rwd_front_wheels_are_prepared_before_slip_resolution() -> void:
	var config := CarDriveConfig.new()
	config.drive_layout = CarSpecs.DriveLayout.REAR_WHEEL_DRIVE
	config.wheel_radius = 0.30
	config.sanitize()
	var state := CarRuntimeState.new()
	state.forward_speed = 12.0
	state.ground_contact_count = WheelTireState.WHEEL_COUNT
	state.surface_grip_multiplier = 1.0
	state.synchronize_wheel_contacts_from_aggregate()
	state.configure_wheel_rotation(config, false)
	var front_left: WheelTireState = state.get_wheel_state(WheelTireState.Position.FRONT_LEFT)
	var front_right: WheelTireState = state.get_wheel_state(WheelTireState.Position.FRONT_RIGHT)
	front_left.set_rolling_speed(11.5)
	front_left.drive_torque_nm = 0.0
	front_left.brake_torque_nm = 0.0

	var radius: float = front_left.wheel_radius_m
	var left_equivalent_mass: float = front_left.moment_of_inertia_kg_m2 / (radius * radius)
	var right_equivalent_mass: float = front_right.moment_of_inertia_kg_m2 / (radius * radius)
	var expected_coupled_speed: float = (
		config.vehicle_mass * state.forward_speed
		+ left_equivalent_mass * front_left.get_circumferential_speed_mps()
		+ right_equivalent_mass * front_right.get_circumferential_speed_mps()
	) / (config.vehicle_mass + left_equivalent_mass + right_equivalent_mass)

	state.configure_wheel_rotation(config, true)
	var slip_ratio: float = WheelRotationalDynamicsModel.new().calculate_slip_ratio(
		front_left.angular_velocity_rad_s,
		front_left.wheel_radius_m,
		state.forward_speed,
		config.wheel_slip_reference_speed_mps
	)
	_expect(
		is_equal_approx(front_left.get_circumferential_speed_mps(), state.forward_speed),
		"an RWD front wheel is synchronized before longitudinal tire force is resolved"
	)
	_expect(
		absf(slip_ratio) <= 0.0001,
		"a free-rolling RWD front wheel enters slip resolution with zero artificial slip"
	)
	_expect(
		absf(state.forward_speed - expected_coupled_speed) <= 0.0001,
		"small free-wheel speed corrections conserve generalized longitudinal momentum"
	)
	_expect(
		state.forward_speed > 11.5 and state.forward_speed < 12.0,
		"spinning up a slightly lagging free wheel consumes vehicle kinetic momentum"
	)


func _test_external_speed_discontinuity_does_not_impulse_vehicle() -> void:
	var config := CarDriveConfig.new()
	config.drive_layout = CarSpecs.DriveLayout.REAR_WHEEL_DRIVE
	config.wheel_radius = 0.30
	config.sanitize()
	var state := CarRuntimeState.new()
	state.forward_speed = 0.0
	state.ground_contact_count = WheelTireState.WHEEL_COUNT
	state.surface_grip_multiplier = 1.0
	state.synchronize_wheel_contacts_from_aggregate()
	state.configure_wheel_rotation(config, false)

	state.forward_speed = 20.0
	state.configure_wheel_rotation(config, true)
	var front_left: WheelTireState = state.get_wheel_state(WheelTireState.Position.FRONT_LEFT)
	var front_right: WheelTireState = state.get_wheel_state(WheelTireState.Position.FRONT_RIGHT)
	_expect(
		is_equal_approx(state.forward_speed, 20.0),
		"an authoritative speed jump does not apply a fictitious chassis impulse"
	)
	_expect(
		is_equal_approx(front_left.get_circumferential_speed_mps(), 20.0)
		and is_equal_approx(front_right.get_circumferential_speed_mps(), 20.0),
		"free wheels follow the new authoritative road speed after a discontinuity"
	)


func _test_turning_free_wheel_uses_contact_patch_road_speed() -> void:
	var config := CarDriveConfig.new()
	config.drive_layout = CarSpecs.DriveLayout.REAR_WHEEL_DRIVE
	config.wheel_radius = 0.30
	config.wheel_base = 2.70
	config.front_axle_track_width = 1.50
	config.sanitize()
	var state := CarRuntimeState.new()
	state.forward_speed = 5.0
	state.lateral_speed = 2.0
	state.yaw_rate_rad_s = 1.0
	state.ground_contact_count = WheelTireState.WHEEL_COUNT
	state.surface_grip_multiplier = 1.0
	state.synchronize_wheel_contacts_from_aggregate()
	state.configure_wheel_rotation(config, false)
	var wheel: WheelTireState = state.get_wheel_state(WheelTireState.Position.FRONT_LEFT)
	wheel.steering_angle_rad = 0.45
	wheel.set_rolling_speed(0.0)
	var initial_forward_speed: float = state.forward_speed
	var initial_lateral_speed: float = state.lateral_speed
	var forward_offset: float = config.wheel_base * (1.0 - config.front_static_load_fraction)
	var lateral_offset: float = -config.front_axle_track_width * 0.5
	var wheel_forward_speed: float = state.forward_speed - state.yaw_rate_rad_s * lateral_offset
	var wheel_lateral_speed: float = state.lateral_speed + state.yaw_rate_rad_s * forward_offset
	var expected_road_speed: float = (
		wheel_forward_speed * cos(wheel.steering_angle_rad)
		+ wheel_lateral_speed * sin(wheel.steering_angle_rad)
	)

	state.configure_wheel_rotation(config, true)
	_expect(
		absf(wheel.get_circumferential_speed_mps() - expected_road_speed) <= 0.0001,
		"a turning free wheel follows its own contact-patch speed along the steered plane"
	)
	_expect(
		is_equal_approx(state.forward_speed, initial_forward_speed)
		and is_equal_approx(state.lateral_speed, initial_lateral_speed),
		"turning wheel synchronization does not apply a fictitious impulse to center motion"
	)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[FREE_ROLLING_WHEEL_DYNAMICS_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[FREE_ROLLING_WHEEL_DYNAMICS_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[FREE_ROLLING_WHEEL_DYNAMICS_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[FREE_ROLLING_WHEEL_DYNAMICS_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[FREE_ROLLING_WHEEL_DYNAMICS_TEST] - %s" % failure_message)
	quit(1)
