extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []
var _phase_history: Array[int] = []


func _initialize() -> void:
	_run()
	_finish()


func _run() -> void:
	var state: GameSessionState = GameSessionState.new()
	state.phase_changed.connect(_on_phase_changed)
	_expect(state.is_menu(), "new session state starts in menu")
	_expect(typeof(state.get_mode_id()) == TYPE_STRING_NAME, "mode identifiers use StringName")
	_expect(typeof(state.get_track_id()) == TYPE_STRING_NAME, "track identifiers use StringName")
	_expect(state.get_mode_id() == &"", "new session state has no mode selection")
	_expect(state.get_track_id() == &"", "new session state has no track selection")
	_expect(state.get_car_variant_id() == &"", "new session state has no car selection")

	_expect(
		state.commit(GameModes.FREE_DRIVE, &"simple_oval", &"car") == GameSessionState.Result.INVALID_PHASE,
		"session cannot commit before startup begins"
	)
	_expect(
		state.update_free_drive_car_variant(&"car") == GameSessionState.Result.INVALID_PHASE,
		"menu state rejects car switching"
	)
	_expect(_phase_history.is_empty(), "rejected menu operations do not emit phase changes")

	_expect(state.begin_start() == GameSessionState.Result.OK, "menu state can begin session startup")
	_expect(state.is_starting(), "begin_start enters starting phase")
	_expect(_phase_history == [GameSessionState.Phase.STARTING], "starting transition emits exactly once")
	_expect(
		state.begin_start() == GameSessionState.Result.INVALID_PHASE,
		"starting phase rejects a second startup transition"
	)
	_expect(
		state.commit(&"unsupported", &"simple_oval", &"car") == GameSessionState.Result.UNSUPPORTED_MODE,
		"unsupported mode has a distinct result"
	)
	_expect(
		state.commit(GameModes.FREE_DRIVE, &"", &"car") == GameSessionState.Result.EMPTY_TRACK_ID,
		"empty track id has a distinct result"
	)
	_expect(
		state.commit(GameModes.FREE_DRIVE, &"simple_oval", &"") == GameSessionState.Result.EMPTY_CAR_VARIANT_ID,
		"empty car variant id has a distinct result"
	)
	_expect(state.is_starting(), "failed commits preserve starting phase for explicit rollback")
	_expect(state.get_mode_id() == &"", "failed commits preserve empty mode state")
	_expect(state.get_track_id() == &"", "failed commits preserve empty track state")
	_expect(state.get_car_variant_id() == &"", "failed commits preserve empty variant state")
	_expect(_phase_history.size() == 1, "failed commits do not emit phase changes")

	state.reset()
	_expect(state.is_menu(), "reset returns failed startup to menu")
	_expect(_phase_history[-1] == GameSessionState.Phase.MENU, "rollback emits menu phase")
	var history_size_after_reset: int = _phase_history.size()
	state.reset()
	_expect(_phase_history.size() == history_size_after_reset, "idempotent menu reset emits no duplicate phase")

	_expect(state.begin_start() == GameSessionState.Result.OK, "reset state can begin another startup")
	_expect(
		state.commit(GameModes.FREE_DRIVE, &"simple_oval", &"automatic") == GameSessionState.Result.OK,
		"valid free-drive session commits"
	)
	_expect(state.is_free_drive(), "free-drive commit enters free-drive phase")
	_expect(state.get_mode_id() == GameModes.FREE_DRIVE, "free-drive commit records mode id")
	_expect(state.get_track_id() == &"simple_oval", "free-drive commit records track id")
	_expect(state.get_car_variant_id() == &"automatic", "free-drive commit records variant id")
	_expect(
		state.update_free_drive_car_variant(&"") == GameSessionState.Result.EMPTY_CAR_VARIANT_ID,
		"free-drive session rejects an empty switched variant"
	)
	_expect(state.get_car_variant_id() == &"automatic", "rejected switch preserves the committed variant")
	var phase_count_before_switch: int = _phase_history.size()
	_expect(
		state.update_free_drive_car_variant(&"manual") == GameSessionState.Result.OK,
		"free-drive session accepts car switching"
	)
	_expect(state.get_car_variant_id() == &"manual", "car switching updates only the selected variant")
	_expect(state.get_mode_id() == GameModes.FREE_DRIVE, "car switching preserves free-drive mode")
	_expect(state.get_track_id() == &"simple_oval", "car switching preserves selected track")
	_expect(_phase_history.size() == phase_count_before_switch, "car switching does not emit a phase transition")
	_expect(
		state.begin_start() == GameSessionState.Result.INVALID_PHASE,
		"active free-drive session rejects direct restart"
	)

	state.reset()
	_expect(state.begin_start() == GameSessionState.Result.OK, "menu can begin race startup")
	_expect(
		state.commit(GameModes.RACE, &"simple_oval", &"automatic") == GameSessionState.Result.OK,
		"valid race session commits"
	)
	_expect(state.is_race(), "race commit enters race phase")
	_expect(_phase_history[-1] == GameSessionState.Phase.RACE, "race commit emits race phase")
	_expect(
		state.update_free_drive_car_variant(&"manual") == GameSessionState.Result.INVALID_PHASE,
		"race session rejects free-drive car switching"
	)
	_expect(state.get_car_variant_id() == &"automatic", "rejected race switch preserves variant state")

	state.reset()
	_expect(state.is_menu(), "active race reset returns to menu")
	_expect(state.get_mode_id() == &"", "reset clears mode selection")
	_expect(state.get_track_id() == &"", "reset clears track selection")
	_expect(state.get_car_variant_id() == &"", "reset clears car selection")
	_expect(GameSessionState.is_success(GameSessionState.Result.OK), "success helper accepts only the OK result")
	_expect(not GameSessionState.is_success(GameSessionState.Result.INVALID_PHASE), "success helper rejects error results")


func _on_phase_changed(phase: GameSessionState.Phase) -> void:
	_phase_history.append(phase)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[GAME_SESSION_STATE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[GAME_SESSION_STATE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[GAME_SESSION_STATE_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[GAME_SESSION_STATE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[GAME_SESSION_STATE_TEST] - %s" % failure_message)
	quit(1)
