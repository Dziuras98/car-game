extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_unloaded_contact_tracks_road_speed()
	_test_unloaded_contact_stops_with_vehicle()
	_test_airborne_wheel_is_not_constrained_to_road_speed()
	_test_effective_drivetrain_inertia_is_applied()
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


func _test_effective_drivetrain_inertia_is_applied() -> void:
	var model := WheelRotationalDynamicsModel.new()
	var light_system := WheelTireState.new(WheelTireState.Position.REAR_LEFT)
	var heavy_system := WheelTireState.new(WheelTireState.Position.REAR_RIGHT)
	light_system.configure_rotation(0.30, 1.0)
	heavy_system.configure_rotation(0.30, 1.0)
	model.integrate_wheel(light_system, 120.0, 0.0, 0.0, 1000.0, 0.0, 0.0, 0.10, 1.0)
	model.integrate_wheel(heavy_system, 120.0, 0.0, 0.0, 1000.0, 0.0, 0.0, 0.10, 4.0)
	_expect(
		light_system.angular_velocity_rad_s > heavy_system.angular_velocity_rad_s * 3.9,
		"reflected drivetrain inertia reduces driven-wheel angular acceleration"
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
