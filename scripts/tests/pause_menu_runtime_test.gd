extends Node

const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/ui/pause_menu.tscn")

var _checks: int = 0
var _failures: Array[String] = []
var _pause_events: Array[bool] = []
var _menu_requests: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _run() -> void:
	var pause_menu: PauseMenu = PAUSE_MENU_SCENE.instantiate() as PauseMenu
	pause_menu.pause_state_changed.connect(_on_pause_state_changed)
	pause_menu.main_menu_requested.connect(_on_menu_requested)
	add_child(pause_menu)
	pause_menu.set_pause_enabled(true)
	await get_tree().process_frame

	pause_menu.pause_game()
	await get_tree().process_frame
	_expect(get_tree().paused, "pause menu pauses the SceneTree")
	_expect(pause_menu.is_pause_visible(), "pause overlay becomes visible")
	var resume_button: Button = pause_menu.get_node("Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResumeButton") as Button
	_expect(resume_button.has_focus(), "pause overlay gives keyboard/gamepad focus to resume")
	_expect(_pause_events == [true], "pause transition emits exactly one state event")

	var manager: RaceManager = RaceManager.new()
	manager.configure(0.02, 0.02)
	var player: PlayerCarController = PlayerCarController.new()
	add_child(player)
	var start_result: RaceManager.Result = manager.start_race(player, get_tree())
	_expect(start_result == RaceManager.Result.OK, "pause fixture starts a race with a valid player")
	await get_tree().create_timer(0.08, true).timeout
	_expect(manager.get_state() == RaceManager.State.COUNTDOWN, "race countdown cannot advance while the tree is paused")

	pause_menu.resume_game()
	_expect(not get_tree().paused, "resume clears SceneTree pause state immediately")
	_expect(not pause_menu.is_pause_visible(), "resume hides the overlay")
	await get_tree().create_timer(0.12, true).timeout
	_expect(manager.get_state() == RaceManager.State.RUNNING, "race countdown resumes after unpausing")
	_expect(_pause_events == [true, false], "resume transition emits one matching state event")

	pause_menu.pause_game()
	var menu_button: Button = pause_menu.get_node("Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/MenuButton") as Button
	menu_button.pressed.emit()
	_expect(not get_tree().paused, "return-to-menu action always unpauses the tree")
	_expect(_menu_requests == 1, "return-to-menu action emits exactly one request")

	pause_menu.pause_game()
	pause_menu.set_pause_enabled(false)
	_expect(not get_tree().paused and not pause_menu.is_pause_visible(), "disabling pause for the main menu clears any active pause")

	manager.reset_to_idle()
	player.queue_free()
	pause_menu.queue_free()
	await get_tree().process_frame
	_finish()


func _on_pause_state_changed(paused: bool) -> void:
	_pause_events.append(paused)


func _on_menu_requested() -> void:
	_menu_requests += 1


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[PAUSE_MENU_RUNTIME_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[PAUSE_MENU_RUNTIME_TEST][FAIL] %s" % message)


func _finish() -> void:
	get_tree().paused = false
	if _failures.is_empty():
		print("[PAUSE_MENU_RUNTIME_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[PAUSE_MENU_RUNTIME_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[PAUSE_MENU_RUNTIME_TEST] - %s" % failure_message)
	get_tree().quit(1)
