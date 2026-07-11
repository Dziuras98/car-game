extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_unknown_lap_participant_contract()
	_test_race_session_encapsulation_contract()
	_test_transactional_rng_contract()
	_test_ai_fault_contract()
	_test_initialization_failure_contract()
	_finish()


func _test_unknown_lap_participant_contract() -> void:
	var tracker: LapTracker = LapTracker.new()
	var car: PlayerCarController = PlayerCarController.new()
	_expect(not tracker.has_participant(car), "unknown car is not reported as a race participant")
	_expect(tracker.get_current_lap(car) == 0, "unknown car has no current lap")
	_expect(tracker.get_race_position(car) == 0, "unknown car has no race position")
	_expect(tracker.get_completed_laps(car) == -1, "unknown car has no completed-lap value")
	_expect(tracker.get_progress_distance(car) < 0.0, "unknown car has no progress distance")
	car.free()


func _test_race_session_encapsulation_contract() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/game/race_session_controller.gd")
	_expect(not source.contains("func get_lap_tracker()"), "race session does not expose the mutable LapTracker")
	_expect(not source.contains("func get_race_manager()"), "race session does not expose the mutable RaceManager")
	_expect(not source.contains("func clear_tracking()"), "race session has no public partial tracking cleanup")
	_expect(not source.contains("func clear_opponents()"), "race session has no public partial opponent cleanup")
	_expect(source.contains("signal runtime_fault(message: String)"), "race session publishes a typed runtime-fault boundary")
	_expect(source.contains("_lap_tracker.has_participant(_current_car)"), "race HUD validates player registration before displaying telemetry")
	var manager_source: String = FileAccess.get_file_as_string("res://scripts/game/game_manager.gd")
	_expect(manager_source.contains("next_race_session.runtime_fault.connect(runtime_fault_callback)"), "game manager routes race faults to the session reset boundary")


func _test_transactional_rng_contract() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 123456
	var factory: CarInstanceFactory = CarInstanceFactory.new()
	var variants: Array[CarVariantDefinition] = []
	factory.configure(variants, rng)
	var state_before: int = factory.capture_random_state()
	var first_value: int = rng.randi()
	factory.restore_random_state(state_before)
	var replayed_value: int = rng.randi()
	_expect(first_value == replayed_value, "restoring factory RNG state reproduces the next random value")
	var spawner_source: String = FileAccess.get_file_as_string("res://scripts/game/opponent_participant_spawner.gd")
	_expect(spawner_source.contains("_rollback_preparation(staged_cars, staged_drivers, random_state_before)"), "every staged-opponent failure rolls back the random stream")


func _test_ai_fault_contract() -> void:
	var driver_source: String = FileAccess.get_file_as_string("res://scripts/race/ai_race_driver.gd")
	_expect(driver_source.contains("signal driver_fault(message: String)"), "AI driver publishes a typed fault signal")
	_expect(driver_source.contains("_car.set_external_drive_inputs(0.0, 0.85, 0.0, false)"), "AI fault applies controlled braking instead of neutral coasting")
	_expect(driver_source.contains("if _fault_reported:"), "AI driver suppresses duplicate fault publication")
	_expect(driver_source.contains("driver_fault.emit(message)"), "AI driver emits the first fault to its owner")
	var spawner_source: String = FileAccess.get_file_as_string("res://scripts/game/opponent_participant_spawner.gd")
	_expect(spawner_source.contains("ai_driver.driver_fault.connect(fault_callback)"), "opponent spawner connects every committed AI fault")
	var race_source: String = FileAccess.get_file_as_string("res://scripts/game/race_session_controller.gd")
	_expect(race_source.contains("_report_runtime_fault(\"AI driver fault: %s\" % message)"), "race session escalates AI faults to the complete reset boundary")


func _test_initialization_failure_contract() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/game/game_manager.gd")
	_expect(source.contains("func _build_pause_menu() -> bool"), "pause-menu construction participates in initialization admission")
	_expect(source.contains("func _fail_initialization(message: String)"), "game initialization uses one fatal failure path")
	_expect(source.contains("get_tree().call_deferred(\"quit\", 1)"), "packaged smoke builds fail with a non-zero exit on initialization failure")
	_expect(source.contains("_show_fatal_error(message)"), "fatal initialization displays a blocking user-visible error")


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[AUDIT_MEDIUM_PRIORITY_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[AUDIT_MEDIUM_PRIORITY_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[AUDIT_MEDIUM_PRIORITY_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[AUDIT_MEDIUM_PRIORITY_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[AUDIT_MEDIUM_PRIORITY_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
