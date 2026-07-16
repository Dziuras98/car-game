extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_coast_releases_coupling()
	_test_launch_preload()
	_test_rear_axle_overspeed_increases_transfer()
	_test_engagement_is_rate_limited()
	_test_high_speed_release()
	_test_thermal_derating()
	_test_torque_capacity_limit()
	_test_fixed_step_determinism()
	_finish()


func _configured_model() -> OnDemandAwdCouplingModel:
	var model := OnDemandAwdCouplingModel.new()
	model.configure(
		0.0,
		0.50,
		0.65,
		0.45,
		0.025,
		0.70,
		5.0,
		2.5,
		900.0,
		45.0,
		60.0,
		18000.0,
		65.0,
		135.0,
		180.0
	)
	return model


func _test_coast_releases_coupling() -> void:
	var model := _configured_model()
	var state := OnDemandAwdCouplingState.new()
	model.reset(state)
	model.update(state, 0.0, 20.0, 80.0, 80.0, 0.0, 0.0, 0.5)
	_expect(is_equal_approx(state.clutch_command, 0.0), "steady coast requests an open coupling")
	_expect(is_equal_approx(state.front_torque_fraction, 0.0), "steady coast keeps rear-biased base split")


func _test_launch_preload() -> void:
	var model := _configured_model()
	var state := OnDemandAwdCouplingState.new()
	model.reset(state)
	model.update(state, 1.0, 0.0, 0.0, 0.0, 0.0, 600.0, 0.10)
	_expect(state.clutch_command >= 0.64, "full-throttle launch requests pre-emptive engagement")
	_expect(state.clutch_engagement > 0.0, "launch starts closing the transfer clutch")
	_expect(state.front_torque_fraction > 0.0, "launch sends torque to the front axle")


func _test_rear_axle_overspeed_increases_transfer() -> void:
	var model := _configured_model()
	var state := OnDemandAwdCouplingState.new()
	model.reset(state)
	model.update(state, 0.20, 15.0, 70.0, 110.0, 0.0, 700.0, 0.25)
	_expect(state.axle_speed_difference_rad_s > 39.0, "rear overspeed is measured")
	_expect(state.clutch_command > 0.85, "rear overspeed requests strong coupling")
	_expect(state.front_torque_fraction > 0.20, "slip response transfers meaningful front torque")


func _test_engagement_is_rate_limited() -> void:
	var model := _configured_model()
	var state := OnDemandAwdCouplingState.new()
	model.reset(state)
	model.update(state, 1.0, 0.0, 0.0, 80.0, 1.0, 800.0, 0.02)
	_expect(state.clutch_engagement <= 0.101, "clutch engagement respects close-rate limit")
	var first_engagement: float = state.clutch_engagement
	model.update(state, 0.0, 20.0, 80.0, 80.0, 0.0, 0.0, 0.02)
	_expect(state.clutch_engagement < first_engagement, "released command opens the clutch progressively")
	_expect(state.clutch_engagement > 0.0, "release is not an instantaneous torque-path deletion")


func _test_high_speed_release() -> void:
	var model := _configured_model()
	var state := OnDemandAwdCouplingState.new()
	model.reset(state)
	model.update(state, 1.0, 70.0, 80.0, 120.0, 1.0, 800.0, 0.2)
	_expect(is_equal_approx(state.clutch_command, 0.0), "speed above release range opens coupling command")
	_expect(is_equal_approx(state.front_torque_fraction, 0.0), "fully released high-speed state returns to base split")


func _test_thermal_derating() -> void:
	var model := _configured_model()
	model.thermal_mass_j_per_c = 100.0
	model.cooling_w_per_c = 0.0
	model.derate_start_c = 35.0
	model.shutdown_temperature_c = 45.0
	var state := OnDemandAwdCouplingState.new()
	model.reset(state)
	for _index: int in range(120):
		model.update(state, 1.0, 5.0, 0.0, 150.0, 0.0, 900.0, 0.02)
	_expect(state.temperature_c > model.derate_start_c, "sustained clutch slip creates heat")
	_expect(state.thermal_capacity_factor < 1.0, "hot clutch derates available capacity")
	_expect(state.clutch_capacity_nm < model.maximum_clutch_capacity_nm, "thermal derating reduces clutch torque capacity")


func _test_torque_capacity_limit() -> void:
	var model := _configured_model()
	model.maximum_clutch_capacity_nm = 200.0
	var state := OnDemandAwdCouplingState.new()
	model.reset(state)
	for _index: int in range(40):
		model.update(state, 1.0, 0.0, 0.0, 100.0, 1.0, 2000.0, 0.02)
	_expect(absf(state.transferred_torque_nm) <= 200.01, "transferred torque never exceeds clutch capacity")
	_expect(state.front_torque_fraction <= 0.101, "input torque fraction reflects capacity limit")


func _test_fixed_step_determinism() -> void:
	var model_a := _configured_model()
	var model_b := _configured_model()
	var state_a := OnDemandAwdCouplingState.new()
	var state_b := OnDemandAwdCouplingState.new()
	model_a.reset(state_a)
	model_b.reset(state_b)
	model_a.update(state_a, 0.75, 12.0, 65.0, 100.0, 0.20, 700.0, 0.30)
	for _index: int in range(30):
		model_b.update(state_b, 0.75, 12.0, 65.0, 100.0, 0.20, 700.0, 0.01)
	_expect(is_equal_approx(state_a.clutch_engagement, state_b.clutch_engagement), "substepped engagement is deterministic")
	_expect(is_equal_approx(state_a.front_torque_fraction, state_b.front_torque_fraction), "substepped axle split is deterministic")
	_expect(is_equal_approx(state_a.temperature_c, state_b.temperature_c), "substepped thermal state is deterministic")


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRAFFIC_RIDER_ON_DEMAND_AWD_COUPLING_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRAFFIC_RIDER_ON_DEMAND_AWD_COUPLING_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRAFFIC_RIDER_ON_DEMAND_AWD_COUPLING_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRAFFIC_RIDER_ON_DEMAND_AWD_COUPLING_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	quit(1)
