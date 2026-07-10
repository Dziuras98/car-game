extends Node

const TEST_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []
var _state_history: Array[int] = []
var _countdown_history: Array[String] = []
var _player_input_history: Array[bool] = []
var _ai_history: Array[bool] = []
var _race_finished_count: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var manager: RaceManager = RaceManager.new()
	manager.configure(0.01, 0.01)
	manager.state_changed.connect(_on_state_changed)
	manager.countdown_changed.connect(_countdown_history.append)
	manager.player_input_enabled_changed.connect(_player_input_history.append)
	manager.ai_enabled_changed.connect(_ai_history.append)
	manager.race_finished.connect(_on_race_finished)

	var player: PlayerCarController = PlayerCarController.new()
	player.car_specs = TEST_SPECS
	add_child(player)

	_expect(manager.get_state() == RaceManager.State.IDLE, "race manager starts in IDLE")
	_expect(not manager.are_player_controls_locked(), "idle state leaves player controls unlocked")

	manager.start_race(player, get_tree())
	_expect(manager.get_state() == RaceManager.State.COUNTDOWN, "start request enters COUNTDOWN immediately")
	_expect(manager.are_player_controls_locked(), "countdown locks player controls")
	await get_tree().create_timer(0.06).timeout
	_expect(manager.get_state() == RaceManager.State.RUNNING, "completed countdown enters RUNNING")
	_expect(not manager.are_player_controls_locked(), "running state unlocks player controls")
	_expect(_countdown_history == ["3", "2", "1", "START"], "countdown emits the complete ordered sequence")
	_expect(_player_input_history[0] == false and _player_input_history[-1] == true, "countdown disables and then restores player input")
	_expect(_ai_history[0] == false and _ai_history[-1] == true, "countdown disables and then enables AI")

	var opponents: Array[PlayerCarController] = []
	manager.finish_race(player, opponents)
	_expect(manager.get_state() == RaceManager.State.FINISHED, "finish request enters FINISHED")
	_expect(manager.are_player_controls_locked(), "finished state locks player controls")
	_expect(_race_finished_count == 1, "finish signal is emitted once")
	manager.finish_race(player, opponents)
	_expect(_race_finished_count == 1, "duplicate finish requests are ignored")

	manager.reset_to_idle()
	_expect(manager.get_state() == RaceManager.State.IDLE, "reset returns the manager to IDLE")
	_expect(not manager.are_player_controls_locked(), "reset unlocks controls")
	_expect(_ai_history[-1] == false, "reset leaves AI disabled")

	_countdown_history.clear()
	manager.start_race(player, get_tree())
	await get_tree().create_timer(0.005).timeout
	manager.reset_to_idle()
	await get_tree().create_timer(0.06).timeout
	_expect(manager.get_state() == RaceManager.State.IDLE, "reset cancels an in-flight countdown")
	_expect(not _countdown_history.has("START"), "cancelled countdown cannot emit START")

	_expect(
		_state_history.has(RaceManager.State.COUNTDOWN)
		and _state_history.has(RaceManager.State.RUNNING)
		and _state_history.has(RaceManager.State.FINISHED),
		"state_changed reports all active race states"
	)

	player.queue_free()
	await get_tree().process_frame
	_finish()


func _on_state_changed(state: int) -> void:
	_state_history.append(state)


func _on_race_finished() -> void:
	_race_finished_count += 1


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[RACE_MANAGER_STATE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[RACE_MANAGER_STATE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[RACE_MANAGER_STATE_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[RACE_MANAGER_STATE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[RACE_MANAGER_STATE_TEST] - %s" % failure_message)
	get_tree().quit(1)
