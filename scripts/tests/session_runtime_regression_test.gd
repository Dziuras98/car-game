extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const VALID_TRACK_ID: StringName = &"simple_oval"
const VALID_VARIANT_ID: StringName = &"nissan_370z_7at"

var _checks: int = 0
var _failures: Array[String] = []
var _saw_spawned_car_locked_during_start: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	_expect(
		int(game.call("get_session_phase")) == GameSessionState.Phase.MENU,
		"main scene initializes in the menu phase"
	)
	var transaction: GameSessionStartTransaction = game.get("_session_start_transaction") as GameSessionStartTransaction
	_expect(transaction != null, "main scene configures the session transaction")
	if transaction != null:
		transaction.progress_changed.connect(
			Callable(self, "_on_session_start_progress").bind(game)
		)

	game.call(
		"_on_menu_selection_completed",
		GameModes.FREE_DRIVE,
		VALID_TRACK_ID,
		VALID_VARIANT_ID
	)
	await process_frame
	game.call(
		"_on_menu_selection_completed",
		GameModes.FREE_DRIVE,
		VALID_TRACK_ID,
		VALID_VARIANT_ID
	)
	await _wait_for_phase(game, GameSessionState.Phase.FREE_DRIVE, 60)

	_expect(
		_saw_spawned_car_locked_during_start,
		"spawned player car remains input-locked while the session is STARTING"
	)
	var free_drive_car: PlayerCarController = game.call("get_current_car") as PlayerCarController
	_expect(is_instance_valid(free_drive_car), "free-drive startup creates the player car")
	if is_instance_valid(free_drive_car):
		var free_drive_input: CarInput = free_drive_car.get("_car_input") as CarInput
		_expect(
			free_drive_input != null and bool(free_drive_input.get("_player_input_enabled")),
			"free-drive input is enabled only after startup commits"
		)
	var menu: MainMenu = game.get_node_or_null("MainMenu") as MainMenu
	_expect(menu != null and not menu.visible, "duplicate startup does not reset the menu after the first transaction succeeds")
	_expect(
		transaction != null and not transaction.is_execution_in_progress(),
		"session transaction releases its execution guard after completion"
	)

	game.call("_reset_to_main_menu")
	await process_frame
	_expect(
		int(game.call("get_session_phase")) == GameSessionState.Phase.MENU,
		"free-drive cleanup returns to menu"
	)

	game.call(
		"_on_menu_selection_completed",
		GameModes.RACE,
		VALID_TRACK_ID,
		VALID_VARIANT_ID
	)
	await _wait_for_phase(game, GameSessionState.Phase.RACE, 90)
	var opponents: Array[PlayerCarController] = game.call("get_opponents")
	var car_spawner: CarSpawner = game.get("_car_spawner") as CarSpawner
	var ai_drivers: Array[AiRaceDriver] = car_spawner.get_ai_drivers() if car_spawner != null else []
	_expect(not opponents.is_empty(), "race startup creates opponents")
	_expect(ai_drivers.size() == opponents.size(), "race startup creates one AI driver per opponent")
	if not opponents.is_empty() and not ai_drivers.is_empty():
		var opponent: PlayerCarController = opponents[0]
		var driver: AiRaceDriver = ai_drivers[0]
		driver.set_driver_enabled(true)
		_expect(driver.is_physics_processing(), "opponent AI can be enabled before finish handling")
		var race_session: RaceSessionController = game.get("_race_session") as RaceSessionController
		if race_session != null:
			race_session._stop_participant_car(opponent)
		_expect(not driver.is_physics_processing(), "finished opponent AI is disabled")
		var opponent_input: CarInput = opponent.get("_car_input") as CarInput
		_expect(
			opponent_input != null and bool(opponent_input.get("_external_handbrake")),
			"finished opponent remains stopped with the external handbrake"
		)
		_expect(
			opponent_input != null and is_zero_approx(float(opponent_input.get("_external_throttle"))),
			"finished opponent receives no replacement throttle input"
		)

	game.queue_free()
	await process_frame
	_finish()


func _on_session_start_progress(
	_progress: float,
	stage: GameSessionStartTransaction.ProgressStage,
	game: Node
) -> void:
	if stage != GameSessionStartTransaction.ProgressStage.FINALIZING:
		return
	var car: PlayerCarController = game.call("get_current_car") as PlayerCarController
	if not is_instance_valid(car):
		return
	var car_input: CarInput = car.get("_car_input") as CarInput
	_saw_spawned_car_locked_during_start = (
		car_input != null and not bool(car_input.get("_player_input_enabled"))
	)


func _wait_for_phase(game: Node, expected_phase: GameSessionState.Phase, frame_limit: int) -> void:
	for _frame_index: int in range(frame_limit):
		if int(game.call("get_session_phase")) == expected_phase:
			return
		await process_frame
	_expect(false, "session reaches phase %d within %d frames" % [expected_phase, frame_limit])


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[SESSION_RUNTIME_REGRESSION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[SESSION_RUNTIME_REGRESSION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SESSION_RUNTIME_REGRESSION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[SESSION_RUNTIME_REGRESSION_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[SESSION_RUNTIME_REGRESSION_TEST] - %s" % failure_message)
	quit(1)
