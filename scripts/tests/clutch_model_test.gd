extends SceneTree

const MANUAL_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_6mt_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_clutch_targets()
	_test_manual_powertrain_integration()
	_finish()


func _test_clutch_targets() -> void:
	var clutch: ClutchModel = ClutchModel.new()
	_expect(is_zero_approx(clutch.get_target_engagement(0, 10.0, 1.0, 0.0)), "neutral gear keeps the clutch disengaged")
	_expect(is_zero_approx(clutch.get_target_engagement(2, 10.0, 1.0, 0.1)), "active shift timer disengages the clutch")
	var launch_target: float = clutch.get_target_engagement(1, 0.0, 1.0, 0.0)
	_expect(launch_target > 0.0 and launch_target < 1.0, "standing launch uses controlled clutch slip")
	_expect(is_equal_approx(clutch.get_target_engagement(1, 5.0, 0.2, 0.0), 1.0), "moving vehicle reaches full clutch engagement")
	_expect(clutch.get_transmitted_torque_factor(0.5) < 0.5, "partial engagement transmits reduced torque non-linearly")
	var first_step: float = clutch.update_engagement(0.0, 1, 0.0, 1.0, 0.0, 0.05)
	_expect(first_step > 0.0 and first_step < launch_target, "clutch engagement ramps instead of snapping")


func _test_manual_powertrain_integration() -> void:
	var config: CarDriveConfig = CarDriveConfigBuilder.build_from_specs(MANUAL_SPECS)
	var state: CarRuntimeState = CarRuntimeState.new()
	state.reset_drive_state(config.idle_rpm)
	var controller: CarPowertrainController = CarPowertrainController.new()
	controller.configure(config)
	controller.reset(state)
	_expect(is_zero_approx(state.clutch_engagement), "manual reset starts with clutch disengaged at standstill")

	for update_index: int in range(30):
		controller.update(state, 1.0, 0.0, false, false, false, 1.0 / 60.0)
	_expect(state.clutch_engagement > 0.2 and state.clutch_engagement < 1.0, "launch progressively engages the clutch")
	_expect(state.forward_speed > 0.0, "partial clutch engagement transmits launch torque")

	var speed_before_shift: float = state.forward_speed
	controller.update(state, 1.0, 0.0, false, true, false, 1.0 / 60.0)
	_expect(state.current_gear == 2, "manual gear request changes the selected gear")
	_expect(state.clutch_engagement < 0.05, "manual gear change immediately disengages the clutch")
	controller.update(state, 1.0, 0.0, false, false, false, config.shift_delay * 0.5)
	_expect(state.forward_speed <= speed_before_shift + 0.5, "disengaged clutch blocks unrealistic shift torque spikes")

	for update_index: int in range(60):
		controller.update(state, 0.7, 0.0, false, false, false, 1.0 / 60.0)
	_expect(state.shift_timer <= 0.001, "shift timer completes")
	_expect(state.clutch_engagement > 0.8, "clutch re-engages after the shift")

	controller.update(state, 0.0, 0.0, false, false, true, 1.0 / 60.0)
	controller.update(state, 0.0, 0.0, false, false, true, 1.0 / 60.0)
	_expect(state.current_gear == 0, "manual transmission can select neutral")
	for update_index: int in range(10):
		controller.update(state, 1.0, 0.0, false, false, false, 1.0 / 60.0)
	_expect(state.clutch_engagement <= 0.001, "neutral keeps the engine disconnected from the wheels")
	_expect(state.engine_rpm > config.idle_rpm, "engine can free-rev while the manual transmission is in neutral")


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[CLUTCH_MODEL_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[CLUTCH_MODEL_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[CLUTCH_MODEL_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[CLUTCH_MODEL_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[CLUTCH_MODEL_TEST] - %s" % failure_message)
	quit(1)
