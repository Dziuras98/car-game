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
	var preserve_session_on_reset: bool = false
	var reset_count: int = 0
	var call_order: Array[StringName] = []
	var spawned_car_index: int = -1
	var activated_track_id: StringName = &""

	func _init(state: GameSessionState) -> void:
		session_state = state

	func reset_runtime() -> void:
		reset_count += 1
		call_order.append(&"reset")
		if not preserve_session_on_reset:
			session_state.reset()

	func activate_track(definition: TrackDefinition) -> bool:
		call_order.append(&"activate")
		activated_track_id = definition.track_id if definition != null else &""
		return fail_step != &"activate"

	func configure_runtime() -> bool:
		call_order.append(&"configure")
		return fail_step != &"configure"

	func spawn_player(car_index: int, _spawn_transform: Transform3D) -> bool:
		call_order.append(&"spawn")
		spawned_car_index = car_index
		return fail_step != &"spawn"

	func start_race() -> bool:
		call_order.append(&"race")
		if fail_step == &"commit":
			session_state.reset()
			return true
		return fail_step != &"race"


class TransactionCase:
	extends RefCounted

	var state: GameSessionState
	var selection: CarSelectionState
	var harness: TransactionHarness
	var transaction: GameSessionStartTransaction


func _initialize() -> void:
	_test_unconfigured_transaction()
	_test_validation_failures()
	_test_successful_free_drive_transaction()
	_test_successful_race_transaction()
	_test_stage_failures()
	_test_session_begin_rejection()
	_test_commit_rejection()
	_finish()


func _test_unconfigured_transaction() -> void:
	var transaction: GameSessionStartTransaction = GameSessionStartTransaction.new()
	var result: GameSessionStartTransaction.Result = transaction.execute(
		GameModes.FREE_DRIVE,
		VALID_TRACK_ID,
		VALID_VARIANT_ID,
		Transform3D.IDENTITY
	)
	_expect(result == GameSessionStartTransaction.Result.NOT_CONFIGURED, "unconfigured transaction reports a distinct result")


func _test_validation_failures() -> void:
	var invalid_mode_case: TransactionCase = _build_case()
	var invalid_mode_result: GameSessionStartTransaction.Result = invalid_mode_case.transaction.execute(
		&"unsupported",
		VALID_TRACK_ID,
		VALID_VARIANT_ID,
		Transform3D.IDENTITY
	)
	_expect(invalid_mode_result == GameSessionStartTransaction.Result.UNSUPPORTED_MODE, "unsupported mode is rejected before runtime setup")
	_expect(invalid_mode_case.harness.reset_count == 1, "unsupported mode restores the runtime once")
	_expect(invalid_mode_case.state.is_menu(), "unsupported mode leaves lifecycle in menu")

	var invalid_car_case: TransactionCase = _build_case()
	var invalid_car_result: GameSessionStartTransaction.Result = invalid_car_case.transaction.execute(
		GameModes.FREE_DRIVE,
		VALID_TRACK_ID,
		&"missing_variant",
		Transform3D.IDENTITY
	)
	_expect(invalid_car_result == GameSessionStartTransaction.Result.UNAVAILABLE_CAR_VARIANT, "unavailable car variant has a distinct result")
	_expect(invalid_car_case.harness.call_order == [&"reset"], "invalid car selection does not activate track or runtime")

	var invalid_track_case: TransactionCase = _build_case()
	var invalid_track_result: GameSessionStartTransaction.Result = invalid_track_case.transaction.execute(
		GameModes.FREE_DRIVE,
		&"missing_track",
		VALID_VARIANT_ID,
		Transform3D.IDENTITY
	)
	_expect(invalid_track_result == GameSessionStartTransaction.Result.UNAVAILABLE_TRACK, "unavailable track has a distinct result")
	_expect(invalid_track_case.harness.call_order == [&"reset"], "invalid track selection does not configure runtime")


func _test_successful_free_drive_transaction() -> void:
	var test_case: TransactionCase = _build_case()
	var result: GameSessionStartTransaction.Result = test_case.transaction.execute(
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
	_expect(test_case.harness.call_order == [&"reset", &"activate", &"configure", &"spawn"], "free-drive stages execute in deterministic order")
	_expect(test_case.harness.activated_track_id == VALID_TRACK_ID, "transaction activates the exact selected track")
	_expect(test_case.harness.spawned_car_index >= 0, "transaction resolves an exact catalog car index")


func _test_successful_race_transaction() -> void:
	var test_case: TransactionCase = _build_case()
	var result: GameSessionStartTransaction.Result = test_case.transaction.execute(
		GameModes.RACE,
		VALID_TRACK_ID,
		VALID_VARIANT_ID,
		Transform3D.IDENTITY
	)
	_expect(result == GameSessionStartTransaction.Result.OK, "race transaction completes")
	_expect(test_case.state.is_race(), "race transaction commits race phase")
	_expect(test_case.harness.call_order == [&"reset", &"activate", &"configure", &"spawn", &"race"], "race startup runs only after player spawn")


func _test_stage_failures() -> void:
	_run_stage_failure(&"activate", GameSessionStartTransaction.Result.TRACK_ACTIVATION_FAILED)
	_run_stage_failure(&"configure", GameSessionStartTransaction.Result.RUNTIME_CONFIGURATION_FAILED)
	_run_stage_failure(&"spawn", GameSessionStartTransaction.Result.PLAYER_SPAWN_FAILED)
	_run_stage_failure(&"race", GameSessionStartTransaction.Result.RACE_START_FAILED, GameModes.RACE)


func _run_stage_failure(
	fail_step: StringName,
	expected_result: GameSessionStartTransaction.Result,
	mode_id: StringName = GameModes.FREE_DRIVE
) -> void:
	var test_case: TransactionCase = _build_case(fail_step)
	var result: GameSessionStartTransaction.Result = test_case.transaction.execute(
		mode_id,
		VALID_TRACK_ID,
		VALID_VARIANT_ID,
		Transform3D.IDENTITY
	)
	_expect(result == expected_result, "%s stage returns its dedicated transaction result" % fail_step)
	_expect(test_case.state.is_menu(), "%s failure rolls lifecycle back to menu" % fail_step)
	_expect(test_case.state.get_mode_id() == &"", "%s failure clears committed mode state" % fail_step)
	_expect(test_case.harness.reset_count == 2, "%s failure performs prepare reset and rollback reset" % fail_step)


func _test_session_begin_rejection() -> void:
	var test_case: TransactionCase = _build_case()
	_expect(test_case.state.begin_start() == GameSessionState.Result.OK, "begin-rejection fixture enters starting phase")
	_expect(
		test_case.state.commit(GameModes.FREE_DRIVE, VALID_TRACK_ID, VALID_VARIANT_ID) == GameSessionState.Result.OK,
		"begin-rejection fixture commits an active session"
	)
	test_case.harness.preserve_session_on_reset = true
	var result: GameSessionStartTransaction.Result = test_case.transaction.execute(
		GameModes.FREE_DRIVE,
		VALID_TRACK_ID,
		VALID_VARIANT_ID,
		Transform3D.IDENTITY
	)
	_expect(result == GameSessionStartTransaction.Result.SESSION_BEGIN_REJECTED, "invalid lifecycle start maps to a transaction result")
	_expect(test_case.harness.reset_count == 2, "begin rejection still invokes rollback")


func _test_commit_rejection() -> void:
	var test_case: TransactionCase = _build_case(&"commit")
	var result: GameSessionStartTransaction.Result = test_case.transaction.execute(
		GameModes.RACE,
		VALID_TRACK_ID,
		VALID_VARIANT_ID,
		Transform3D.IDENTITY
	)
	_expect(result == GameSessionStartTransaction.Result.SESSION_COMMIT_REJECTED, "commit lifecycle failure maps to a transaction result")
	_expect(test_case.state.is_menu(), "commit rejection rolls back partial race runtime")


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
		Callable(test_case.harness, "activate_track"),
		Callable(test_case.harness, "configure_runtime"),
		Callable(test_case.harness, "spawn_player"),
		Callable(test_case.harness, "start_race")
	)
	_expect(configured, "transaction fixture configures")
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
