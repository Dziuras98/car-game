extends SceneTree

const RACE_SESSION_CONTROLLER_PATH: String = "res://scripts/game/race_session_controller.gd"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_authoritative_grid_values()
	_test_initialization_uses_authoritative_grid_validation()
	_finish()


func _test_authoritative_grid_values() -> void:
	_expect(
		not CarSpawner.validate_configuration_values(
			CarSpawner.MAX_OPPONENT_COUNT + 1,
			4.2,
			7.0,
			-1
		).is_empty(),
		"opponent counts above the supported fleet size are rejected"
	)
	_expect(
		not CarSpawner.validate_configuration_values(2, 0.0, 7.0, -1).is_empty(),
		"multi-opponent grids require positive lateral spacing"
	)
	_expect(
		not CarSpawner.validate_configuration_values(2, 4.2, 0.0, -1).is_empty(),
		"multi-opponent grids require positive row spacing"
	)
	_expect(
		not CarSpawner.validate_configuration_values(1, 4.2, 7.0, -2).is_empty(),
		"random seeds below -1 are rejected"
	)


func _test_initialization_uses_authoritative_grid_validation() -> void:
	var source_file: FileAccess = FileAccess.open(RACE_SESSION_CONTROLLER_PATH, FileAccess.READ)
	_expect(source_file != null, "race-session controller source is readable")
	if source_file == null:
		return
	var source_text: String = source_file.get_as_text()
	source_file.close()
	var validation_index: int = source_text.find("validate_opponent_spawn_request(opponent_count)")
	var configured_index: int = source_text.find("_configured = true")
	_expect(validation_index >= 0, "race-session initialization invokes the CarSpawner grid validator")
	_expect(
		configured_index >= 0 and validation_index < configured_index,
		"opponent-grid validation runs before the race session becomes configured"
	)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[RACE_GRID_INITIALIZATION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[RACE_GRID_INITIALIZATION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[RACE_GRID_INITIALIZATION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[RACE_GRID_INITIALIZATION_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[RACE_GRID_INITIALIZATION_TEST] - %s" % failure_message)
	quit(1)
