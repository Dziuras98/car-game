extends SceneTree

const CAR_CATALOG: CarCatalog = preload("res://resources/cars/catalog.tres")
const TRACK_CATALOG: TrackCatalog = preload("res://resources/tracks/catalog.tres")
const VALID_TRACK_ID: StringName = &"simple_oval"
const VALID_VARIANT_ID: StringName = &"nissan_370z_7at"

var _checks: int = 0
var _failures: Array[String] = []


class TransactionHarness:
	extends RefCounted

	var session_state: GameSessionState
	var fail_step: StringName = &""
	var reset_count: int = 0
	var call_order: Array[StringName] = []
	var spawned_car_index: int = -1
	var activated_track_id: StringName = &""
	var phase_at_first_reset: GameSessionState.Phase = GameSessionState.Phase.MENU
	var track_committed: bool = false
	var track_finalized: bool = false

	func _init(state: GameSessionState) -> void:
		session_state = state

	func reset_runtime() -> void:
		reset_count += 1
		call_order.append(&"reset")
		if reset_count == 1:
			phase_at_first_reset = session_state.get_phase()
		track_committed = false
		track_finalized = false

	func stage_track(definition: TrackDefinition) -> bool:
		call_order.append(&"stage")
		activated_track_id = definition.track_id if definition != null else &""
		return fail_step != &"stage"

	func configure_runtime() -> bool:
		call_order.append(&"configure")
		return fail_step != &"configure"

	func spawn_player(car_index: int, _spawn_transform: Transform3D) -> bool:
		call_order.append(&"spawn")
		spawned_car_index = car_index
		return fail_step != &"spawn"

	func start_race() -> bool:
		call_order.append(&"race")
		return fail_step != &"race"

	func commit_track() -> bool:
		call_order.append(&"track_commit")
		if fail_step == &"track_commit":
			return false
		track_committed = true
		if fail_step == &"session_commit":
			session_state.reset()
		return true

	func finalize_track_commit() -> void:
		call_order.append(&"track_finalize")
		track_finalized = true


class TransactionCase:
	extends RefCounted

	var state: GameSessionState
	var selection: CarSelectionState
	var harness: TransactionHarness
	var transaction: GameSessionStartTransaction
	var progress_values: Array[float] = []
	var progress_stages: Array[GameSessionStartTransaction.ProgressStage] = []

	func record_progress(
		progress: float,
		stage: GameSessionStartTransaction.ProgressStage
	) -> void:
		progress_values.append(progress)
		progress_stages.append(stage)

	func has_monotonic_progress() -> bool:
		var previous: float = 0.0
		for progress: float in progress_values:
			if progress < previous:
				return false
			previous = progress
		return true


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await _test_unconfigured_transaction()
	await _test_validation_failures()
	await _test_successful_free_drive_transaction()
	await _test_successful_race_transaction()
	await _test_stage_failures()
	await _test_session_begin_rejection()
	await _test_commit_rejection()
	_finish()


func _test_unconfigured_transaction() -> void:
	var transaction: GameSessionStartTransaction = GameSessionStartTransaction.new()
	var result: GameSessionStartTransaction.Result = await transaction.execute(
		GameModes.FREE_DRIVE,
		VALID_TRACK_ID,
		VALID_VARIANT_ID,
		Transform3D.IDENTITY
	)
	_expect(result == GameSessionStartTransaction.Result.NOT_CONFIGURED, "unconfigured transaction reports a distinct result")


func _test_validation_failures() -> void:
	var invalid_mode_case: TransactionCase = _build_case()
	var invalid_mode_result: GameSessionStartTransaction.Result = await invalid_mode_case.transaction.execute(
		&"unsupported",
		VALID_TRACK_ID,
		VALID_VARIANT_ID,
		Transform3D.IDENTITY
	)
	_expect(invalid_mode_result == GameSessionStartTransaction.Result.UNSUPPORTED_MODE, "unsupported mode is rejected before runtime setup")
	_expect(invalid_mode_case.harness.reset_count == 0, "unsupported mode does not clear an existing runtime")
	_expect(invalid_mode_case.state.is_menu(), "unsupported mode leaves lifecycle unchanged")

	var invalid_car_case: TransactionCase = _build_case()
	var invalid_car_result: GameSessionStartTransaction.Result = await invalid_car_case.transaction.execute(
		GameModes.FREE_DRIVE,
		VALID_TRACK_ID,
		&"missing_variant",
		Transform3D.IDENTITY
	)
	_expect(invalid_car_result == GameSessionStartTransaction.Result.UNAVAILABLE_CAR_VARIANT, "unavailable car variant has a distinct result")
	_expect(invalid_car_case.harness.call_order.is_empty(), "invalid car selection does not clear or stage runtime")

	var invalid_track_case: TransactionCase = _build_case()
	var invalid_track_result: GameSessionStartTransaction.Result = await invalid_track_case.transaction.execute(
		GameModes.FREE_DRIVE,
		&"missing_track",
		VALID_VARIANT_ID,
		Transform3D.IDENTITY
	)
	_expect(invalid_track_result == GameSessionStartTransaction.Result.UNAVAILABLE_TRACK, "unavailable track has a distinct result")
	_expect(invalid_track_case.harness.call_order.is_empty(), "invalid track selection does not clear or configure runtime")


func _test_successful_free_drive_transaction() -> void:
	var test_case: TransactionCase = _build_case()
	var result: GameSessionStartTransaction.Result = await test_case.transaction.execute(
		GameModes.FREE_DRIVE,
		VALID_TRACK_ID,
		VALID_VARIANT_ID,
		Transform3D.IDENTITY
	)
	_expect(result == GameSessionStartTransaction.Result.OK, "free-drive transaction completes")
	_expect(test_case.state.is_free_drive(), "free-drive transaction commits the lifecycle phase")
	_expect(test_case.state.get_mode_id() == GameModes.FREE_DRIVE, "free-drive transaction commits mode id")
	_expect(test_case.state.get_track_id() == VALID_TRACK_ID, "free-drive transaction commits track id")
	_expect(test_case.state.get_car_variant_id() == VALID_VARIANT_ID, "free-drive transaction commits resolved variant id")
	_expect(
		test_case.harness.call_order == [&"reset", &"stage", &"configure", &"spawn", &"track_commit", &"track_finalize"],
		"free-drive stages execute in deterministic order"
	)
	_expect(test_case.harness.phase_at_first_reset == GameSessionState.Phase.STARTING, "runtime clearing occurs only after entering STARTING")
	_expect(test_case.harness.activated_track_id == VALID_TRACK_ID, "transaction stages the exact selected track")
	_expect(test_case.harness.spawned_car_index >= 0, "transaction resolves an exact catalog car index")
	_expect(test_case.harness.track_committed and test_case.harness.track_finalized, "successful transaction commits and finalizes the staged track")
	_expect(test_case.has_monotonic_progress(), "free-drive loading progress is monotonic")
	_expect(
		test_case.progress_stages == [
			GameSessionStartTransaction.ProgressStage.VALIDATING,
			GameSessionStartTransaction.ProgressStage.CLEARING_RUNTIME,
			GameSessionStartTransaction.ProgressStage.PREPARING_TRACK,
			GameSessionStartTransaction.ProgressStage.CONFIGURING_RUNTIME,
			GameSessionStartTransaction.ProgressStage.SPAWNING_PLAYER,
			GameSessionStartTransaction.ProgressStage.FINALIZING,
			GameSessionStartTransaction.ProgressStage.COMPLETE,
		],
		"free-drive transaction reports each real startup stage"
	)
	_expect(not test_case.progress_values.is_empty() and is_equal_approx(test_case.progress_values[-1], 1.0), "free-drive progress reaches completion")


func _test_successful_race_transaction() -> void:
	var test_case: TransactionCase = _build_case()
	var result: GameSessionStartTransaction.Result = await test_case.transaction.execute(
		GameModes.RACE,
		VALID_TRACK_ID,
		VALID_VARIANT_ID,
		Transform3D.IDENTITY
	)
	_expect(result == GameSessionStartTransaction.Result.OK, "race transaction completes")
	_expect(test_case.state.is_race(), "race transaction commits race phase")
	_expect(
		test_case.harness.call_order == [&"reset", &"stage", &"configure", &"spawn", &"race", &"track_commit", &"track_finalize"],
		"race startup completes before track and lifecycle finalization"
	)
	_expect(GameSessionStartTransaction.ProgressStage.STARTING_RACE in test_case.progress_stages, "race progress includes opponent and race preparation")
	_expect(test_case.has_monotonic_progress(), "race loading progress is monotonic")


func _test_stage_failures() -> void:
	await _run_stage_failure(&"stage", GameSessionStartTransaction.Result.TRACK_STAGE_FAILED)
	await _run_stage_failure(&"configure", GameSessionStartTransaction.Result.RUNTIME_CONFIGURATION_FAILED)
	await _run_stage_failure(&"spawn", GameSessionStartTransaction.Result.PLAYER_SPAWN_FAILED)
	await _run_stage_failure(&"race", GameSessionStartTransaction.Result.RACE_START_FAILED, GameModes.RACE)
	await _run_stage_failure(&"track_commit", GameSessionStartTransaction.Result.TRACK_COMMIT_FAILED)


func _run_stage_failure(
	fail_step: StringName,
	expected_result: GameSessionStartTransaction.Result,
	mode_id: StringName = GameModes.FREE_DRIVE
) -> void:
	var test_case: TransactionCase = _build_case(fail_step)
	var result: GameSessionStartTransaction.Result = await test_case.transaction.execute(
		mode_id,
		VALID_TRACK_ID,
		VALID_VARIANT_ID,
		Transform3D.IDENTITY
	)
	_expect(result == expected_result, "%s stage returns its dedicated transaction result" % fail_step)
	_expect(test_case.state.is_menu(), "%s failure rolls lifecycle back to menu" % fail_step)
	_expect(test_case.state.get_mode_id() == &"", "%s failure clears committed mode state" % fail_step)
	_expect(test_case.harness.reset_count == 2, "%s failure performs prepare reset and rollback reset" % fail_step)
	_expect(not test_case.harness.track_committed, "%s failure leaves no committed replacement track" % fail_step)
	_expect(test_case.has_monotonic_progress(), "%s failure never reverses reported progress" % fail_step)


func _test_session_begin_rejection() -> void:
	var test_case: TransactionCase = _build_case()
	_expect(test_case.state.begin_start() == GameSessionState.Result.OK, "begin-rejection fixture enters starting phase")
	_expect(
		test_case.state.commit(GameModes.FREE_DRIVE, VALID_TRACK_ID, VALID_VARIANT_ID) == GameSessionState.Result.OK,
		"begin-rejection fixture commits an active session"
	)
	var result: GameSessionStartTransaction.Result = await test_case.transaction.execute(
		GameModes.FREE_DRIVE,
		VALID_TRACK_ID,
		VALID_VARIANT_ID,
		Transform3D.IDENTITY
	)
	_expect(result == GameSessionStartTransaction.Result.SESSION_BEGIN_REJECTED, "invalid lifecycle start maps to a transaction result")
	_expect(test_case.harness.reset_count == 0, "begin rejection preserves the active runtime")
	_expect(test_case.state.is_free_drive(), "begin rejection preserves the active lifecycle phase")
	_expect(test_case.state.get_track_id() == VALID_TRACK_ID, "begin rejection preserves committed selection state")


func _test_commit_rejection() -> void:
	var test_case: TransactionCase = _build_case(&"session_commit")
	var result: GameSessionStartTransaction.Result = await test_case.transaction.execute(
		GameModes.RACE,
		VALID_TRACK_ID,
		VALID_VARIANT_ID,
		Transform3D.IDENTITY
	)
	_expect(result == GameSessionStartTransaction.Result.SESSION_COMMIT_REJECTED, "commit lifecycle failure maps to a transaction result")
	_expect(test_case.state.is_menu(), "commit rejection rolls back partial race runtime")
	_expect(test_case.harness.reset_count == 2, "commit rejection invokes runtime rollback")
	_expect(not test_case.harness.track_committed, "commit rejection rolls back the promoted track")
	_expect(not test_case.harness.track_finalized, "commit rejection does not finalize the promoted track")


func _build_case(fail_step: StringName = &"") -> TransactionCase:
	var test_case: TransactionCase = TransactionCase.new()
	test_case.state = GameSessionState.new()
	test_case.selection = CarSelectionState.new()
	test_case.selection.configure(CAR_CATALOG)
	test_case.harness = TransactionHarness.new(test_case.state)
	test_case.harness.fail_step = fail_step
	test_case.transaction = GameSessionStartTransaction.new()
	var configured: bool = test_case.transaction.configure(
		test_case.state,
		test_case.selection,
		TRACK_CATALOG,
		Callable(test_case.harness, "reset_runtime"),
		Callable(test_case.harness, "stage_track"),
		Callable(test_case.harness, "configure_runtime"),
		Callable(test_case.harness, "spawn_player"),
		Callable(test_case.harness, "start_race"),
		Callable(test_case.harness, "commit_track"),
		Callable(test_case.harness, "finalize_track_commit")
	)
	_expect(configured, "transaction fixture configures")
	test_case.transaction.progress_changed.connect(test_case.record_progress)
	return test_case


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[GAME_SESSION_START_TRANSACTION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[GAME_SESSION_START_TRANSACTION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[GAME_SESSION_START_TRANSACTION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[GAME_SESSION_START_TRANSACTION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[GAME_SESSION_START_TRANSACTION_TEST] - %s" % failure_message)
	quit(1)
