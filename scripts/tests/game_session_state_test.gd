extends SceneTree


var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run()
	_finish()


func _run() -> void:
	var state: GameSessionState = GameSessionState.new()
	_expect(state.is_menu(), "new session state starts in menu")
	_expect(state.get_mode_id().is_empty(), "new session state has no mode selection")
	_expect(not state.commit(GameModes.FREE_DRIVE, "simple_oval", &"car"), "session cannot commit before startup begins")

	_expect(state.begin_start(), "menu state can begin session startup")
	_expect(state.is_starting(), "begin_start enters starting phase")
	_expect(not state.begin_start(), "starting phase rejects a second startup transition")
	_expect(not state.commit("unsupported", "simple_oval", &"car"), "unsupported mode cannot be committed")
	_expect(state.is_starting(), "failed commit preserves starting phase for explicit rollback")

	state.reset()
	_expect(state.is_menu(), "reset returns failed startup to menu")
	_expect(state.begin_start(), "reset state can begin another startup")
	_expect(state.commit(GameModes.FREE_DRIVE, "simple_oval", &"automatic"), "valid free-drive session commits")
	_expect(state.is_free_drive(), "free-drive commit enters free-drive phase")
	_expect(state.get_mode_id() == GameModes.FREE_DRIVE, "free-drive commit records mode id")
	_expect(state.get_track_id() == "simple_oval", "free-drive commit records track id")
	_expect(state.get_car_variant_id() == &"automatic", "free-drive commit records variant id")
	_expect(not state.begin_start(), "active free-drive session rejects direct restart")

	state.reset()
	_expect(state.begin_start(), "menu can begin race startup")
	_expect(state.commit(GameModes.RACE, "simple_oval", &"automatic"), "valid race session commits")
	_expect(state.is_race(), "race commit enters race phase")

	state.reset()
	_expect(state.is_menu(), "active race reset returns to menu")
	_expect(state.get_track_id().is_empty(), "reset clears track selection")
	_expect(state.get_car_variant_id() == &"", "reset clears car selection")


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
