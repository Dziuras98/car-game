extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_expect(GameModes.ALL.size() == 2, "exactly two gameplay modes are declared")
	_expect(GameModes.ALL.has(GameModes.FREE_DRIVE), "free drive is declared")
	_expect(GameModes.ALL.has(GameModes.RACE), "race is declared")
	_expect(GameModes.FREE_DRIVE != GameModes.RACE, "mode identifiers are unique")
	_expect(GameModes.is_supported(GameModes.FREE_DRIVE), "free drive is supported")
	_expect(GameModes.is_supported(GameModes.RACE), "race is supported")
	_expect(not GameModes.is_supported("unsupported"), "unknown modes are rejected")
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[GAME_MODES_CONTRACT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[GAME_MODES_CONTRACT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[GAME_MODES_CONTRACT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[GAME_MODES_CONTRACT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[GAME_MODES_CONTRACT_TEST] - %s" % failure_message)
	quit(1)
