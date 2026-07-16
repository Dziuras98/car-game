extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_shift_retains_source_gear_until_handover()
	_test_shift_completes_all_phases()
	_test_converter_speed_ratio_and_multiplication()
	_test_progressive_lockup()
	_test_lockup_releases_for_shift_and_throttle()
	_test_multigear_kickdown()
	_test_fixed_step_determinism()
	_finish()


func _configured_model() -> PlanetaryAutomaticModel:
	var model := PlanetaryAutomaticModel.new()
	model.configure(
		0.04,
		0.06,
		0.08,
		0.07,
		1.85,
		0.90,
		7.0,
		2,
		0.70,
		4.0,
		10.0,
		35.0,
		4
	)
	return model


func _test_shift_retains_source_gear_until_handover() -> void:
	var model := _configured_model()
	var runtime := PlanetaryAutomaticRuntimeState.new()
	model.reset(runtime, 2)
	_expect(model.request_gear(runtime, 4, 8), "2-to-4 request starts a shift")
	_expect(runtime.selected_gear == 4, "selected gear changes immediately")
	_expect(runtime.engaged_gear == 2, "engaged gear remains the source during torque reduction")
	model.update(runtime, 3000.0, 2500.0, 0.5, 20.0, 0.04)
	_expect(runtime.shift_phase == PlanetaryAutomaticRuntimeState.ShiftPhase.HANDOVER, "torque-reduction phase advances to handover")
	_expect(runtime.engaged_gear == 2, "source gear remains torque-carrying at handover start")
	model.update(runtime, 3000.0, 2500.0, 0.5, 20.0, 0.06)
	_expect(runtime.engaged_gear == 4, "target gear becomes torque-carrying after handover")
	_expect(runtime.shift_phase == PlanetaryAutomaticRuntimeState.ShiftPhase.INERTIA, "handover advances to inertia phase")


func _test_shift_completes_all_phases() -> void:
	var model := _configured_model()
	var runtime := PlanetaryAutomaticRuntimeState.new()
	model.reset(runtime, 3)
	model.request_gear(runtime, 5, 8)
	var minimum_transfer: float = 1.0
	for _index: int in range(80):
		model.update(runtime, 3200.0, 2900.0, 0.45, 24.0, 0.005)
		minimum_transfer = minf(minimum_transfer, runtime.torque_transfer_factor)
	_expect(not runtime.is_shifting(), "phased shift reaches idle")
	_expect(runtime.engaged_gear == 5, "completed shift engages requested gear")
	_expect(is_equal_approx(runtime.shift_progress, 1.0), "completed shift reports full progress")
	_expect(is_equal_approx(runtime.torque_transfer_factor, 1.0), "completed shift restores full torque")
	_expect(minimum_transfer < 0.40, "shift contains a real torque-reduction phase")


func _test_converter_speed_ratio_and_multiplication() -> void:
	var model := _configured_model()
	var runtime := PlanetaryAutomaticRuntimeState.new()
	model.reset(runtime, 1)
	model.update(runtime, 2500.0, 0.0, 1.0, 0.0, 0.0)
	_expect(is_equal_approx(runtime.converter_speed_ratio, 0.0), "stalled turbine reports zero speed ratio")
	_expect(runtime.converter_torque_multiplier > 1.80, "stalled converter applies multiplication")
	model.update(runtime, 2500.0, 2250.0, 0.5, 12.0, 0.0)
	_expect(runtime.converter_speed_ratio >= 0.89, "coupled converter reports high speed ratio")
	_expect(runtime.converter_torque_multiplier <= 1.02, "coupled converter approaches unity multiplication")


func _test_progressive_lockup() -> void:
	var model := _configured_model()
	var runtime := PlanetaryAutomaticRuntimeState.new()
	model.reset(runtime, 4)
	model.update(runtime, 2500.0, 2300.0, 0.35, 25.0, 0.10)
	_expect(runtime.lockup_target == 1.0, "eligible cruise requests lock-up")
	_expect(runtime.lockup_engagement > 0.0 and runtime.lockup_engagement < 1.0, "lock-up engages progressively")
	for _index: int in range(30):
		model.update(runtime, 2500.0, 2470.0, 0.35, 25.0, 0.02)
	_expect(runtime.lockup_engagement > 0.99, "lock-up reaches full engagement")
	_expect(runtime.converter_slip_rpm <= 35.1, "locked converter respects commanded residual slip")


func _test_lockup_releases_for_shift_and_throttle() -> void:
	var model := _configured_model()
	var runtime := PlanetaryAutomaticRuntimeState.new()
	model.reset(runtime, 5)
	for _index: int in range(30):
		model.update(runtime, 2200.0, 2100.0, 0.30, 28.0, 0.02)
	_expect(runtime.lockup_engagement > 0.95, "precondition obtains locked converter")
	model.update(runtime, 3600.0, 2300.0, 0.95, 28.0, 0.05)
	_expect(runtime.lockup_target == 0.0, "high throttle requests unlock")
	_expect(runtime.lockup_engagement < 0.60, "unlock rate reduces lock-up promptly")
	model.request_gear(runtime, 3, 8)
	model.update(runtime, 3600.0, 2300.0, 0.4, 28.0, 0.01)
	_expect(runtime.lockup_target == 0.0, "active shift keeps converter unlocked")


func _test_multigear_kickdown() -> void:
	var model := _configured_model()
	var ratios: Array[float] = [4.714, 3.143, 2.106, 1.667, 1.285, 1.0, 0.839, 0.667]
	var target: int = model.choose_kickdown_gear(8, 8, 700.0, ratios, 3.154, 7000.0)
	_expect(target < 7, "kickdown can skip more than one gear")
	_expect(target >= 4, "kickdown obeys configured maximum skip")
	var protected_target: int = model.choose_kickdown_gear(4, 8, 1300.0, ratios, 3.154, 6500.0)
	_expect(protected_target >= 3, "kickdown rejects over-rev targets")


func _test_fixed_step_determinism() -> void:
	var model_a := _configured_model()
	var model_b := _configured_model()
	var state_a := PlanetaryAutomaticRuntimeState.new()
	var state_b := PlanetaryAutomaticRuntimeState.new()
	model_a.reset(state_a, 2)
	model_b.reset(state_b, 2)
	model_a.request_gear(state_a, 6, 8)
	model_b.request_gear(state_b, 6, 8)
	model_a.update(state_a, 3400.0, 2600.0, 0.55, 22.0, 0.25)
	for _index: int in range(25):
		model_b.update(state_b, 3400.0, 2600.0, 0.55, 22.0, 0.01)
	_expect(state_a.shift_phase == state_b.shift_phase, "substepped phase is deterministic")
	_expect(state_a.engaged_gear == state_b.engaged_gear, "substepped engaged gear is deterministic")
	_expect(is_equal_approx(state_a.torque_transfer_factor, state_b.torque_transfer_factor), "substepped torque factor is deterministic")
	_expect(is_equal_approx(state_a.lockup_engagement, state_b.lockup_engagement), "substepped lock-up is deterministic")


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRAFFIC_RIDER_PLANETARY_AUTOMATIC_MODEL_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRAFFIC_RIDER_PLANETARY_AUTOMATIC_MODEL_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRAFFIC_RIDER_PLANETARY_AUTOMATIC_MODEL_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRAFFIC_RIDER_PLANETARY_AUTOMATIC_MODEL_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	quit(1)
