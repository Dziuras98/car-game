extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const MODE_FREE: String = "free_drive"
const MODE_RACE: String = "race"
const TRACK_SIMPLE_OVAL: String = "simple_oval"
const TEST_ACTIONS: Array[String] = [
	"accelerate",
	"brake",
	"steer-left",
	"steer-right",
	"handbrake",
	"reset-car",
	"camera-back",
	"switch-car",
	"gear-up",
	"gear-down"
]

var _main: Node
var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _exit_tree() -> void:
	_release_test_actions()


func _run() -> void:
	print("[SMOKE] Starting full program smoke test")
	await _load_main_scene()
	await _test_free_drive_automatic()
	await _return_to_main_menu()
	await _test_free_drive_manual()
	await _return_to_main_menu()
	await _test_race_mode()
	_finish()


func _load_main_scene() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	await _frames(6)

	_expect(_main != null, "main scene instantiates")
	_expect(_get_menu() != null, "main menu exists")
	_expect(_current_car() == null, "no player car is spawned before menu selection")


func _test_free_drive_automatic() -> void:
	print("[SMOKE] Testing free drive automatic flow")
	await _select_menu_path("Dowolny", "370Z automat")

	_expect(_selected_mode_id() == MODE_FREE, "free-drive mode is selected")
	_expect(_selected_track_id() == TRACK_SIMPLE_OVAL, "simple oval track is selected")
	_expect(_current_car() != null, "automatic car is spawned")
	_expect(_is_child_visible("Speedometer"), "speedometer is visible after free-drive spawn")
	_expect(_is_child_visible("Minimap"), "minimap is visible after free-drive spawn")

	var automatic_car: PlayerCarController = _current_car()
	if automatic_car == null:
		return

	await _expect_car_accelerates(automatic_car, "automatic car accelerates from touch/input action")
	await _tap_action("reset-car")
	await _frames(6)
	_expect(absf(float(automatic_car.call("get_forward_speed"))) < 0.75, "reset clears automatic car forward speed")

	var before_switch: PlayerCarController = _current_car()
	await _tap_action("switch-car")
	await _frames(8)
	_expect(_current_car() != null and _current_car() != before_switch, "switch-car changes car in free-drive mode")


func _test_free_drive_manual() -> void:
	print("[SMOKE] Testing free drive manual flow")
	await _select_menu_path("Dowolny", "370Z manual")

	_expect(_selected_mode_id() == MODE_FREE, "free-drive mode is selected for manual car")
	_expect(_current_car() != null, "manual car is spawned")

	var manual_car: PlayerCarController = _current_car()
	if manual_car == null:
		return

	_expect(str(manual_car.call("get_gear_text")) == "1", "manual car starts in first gear")
	await _tap_action("gear-up")
	await _frames(4)
	_expect(str(manual_car.call("get_gear_text")) == "2", "manual gear-up changes display to second gear")

	await _tap_action("gear-down")
	await _frames(4)
	_expect(str(manual_car.call("get_gear_text")) == "1", "manual gear-down changes display back to first gear")

	await _seconds(0.35)
	await _expect_car_accelerates(manual_car, "manual car accelerates after gear input")


func _test_race_mode() -> void:
	print("[SMOKE] Testing race flow")
	await _select_menu_path("Wyscig", "370Z automat")

	_expect(_selected_mode_id() == MODE_RACE, "race mode is selected")
	_expect(_current_car() != null, "race player car is spawned")
	_expect(_opponents().size() == int(_main.get("opponent_count")), "race opponents are spawned")
	_expect(_is_child_visible("Speedometer"), "speedometer is visible in race mode")
	_expect(_is_child_visible("Minimap"), "minimap is visible in race mode")

	var race_car: PlayerCarController = _current_car()
	await _tap_action("switch-car")
	await _frames(8)
	_expect(_current_car() == race_car, "switch-car is blocked during race countdown")

	await _seconds(3.35)
	await _tap_action("switch-car")
	await _frames(8)
	_expect(_current_car() == race_car, "switch-car is blocked after race start")

	await _seconds(1.0)
	_expect(_has_moving_opponent(), "at least one AI opponent starts moving after countdown")

	if race_car != null:
		_main.call("_on_lap_tracker_participant_finished", race_car)
		await _frames(8)
		var results_button: Button = _find_visible_button_with_text(_main, "Powrot do menu glownego")
		_expect(results_button != null, "results screen is shown after simulated player finish")
		if results_button != null:
			results_button.emit_signal("pressed")
			await _frames(10)
			_expect(_current_car() == null, "return-to-menu clears current car")
			_expect(_selected_mode_id() == "", "return-to-menu clears selected mode")


func _select_menu_path(mode_label: String, car_label: String) -> void:
	await _press_button_with_text(mode_label)
	await _press_button_with_text("Prosty owal")
	await _press_button_with_text(car_label)
	await _frames(8)


func _press_button_with_text(label_text: String) -> void:
	var button: Button = _find_visible_button_with_text(_main, label_text)
	_expect(button != null, "visible menu button exists: %s" % label_text)
	if button == null:
		return

	button.emit_signal("pressed")
	await _frames(3)


func _expect_car_accelerates(car: PlayerCarController, message: String) -> void:
	var start_speed: float = float(car.call("get_forward_speed"))
	await _hold_action("accelerate", 0.65)
	var speed_after_acceleration: float = float(car.call("get_forward_speed"))
	_expect(speed_after_acceleration > start_speed + 0.1, message)
	_release_test_actions()
	await _frames(2)


func _hold_action(action_name: String, duration_seconds: float) -> void:
	Input.action_press(action_name)
	await _seconds(duration_seconds)
	Input.action_release(action_name)
	await _frames(2)


func _tap_action(action_name: String) -> void:
	Input.action_press(action_name)
	await _frames(1)
	Input.action_release(action_name)
	await _frames(2)


func _return_to_main_menu() -> void:
	_release_test_actions()
	if _main != null and _main.has_method("_return_to_main_menu"):
		_main.call("_return_to_main_menu")
	await _frames(8)


func _frames(count: int) -> void:
	for _frame_index: int in range(count):
		await get_tree().process_frame


func _seconds(duration_seconds: float) -> void:
	await get_tree().create_timer(duration_seconds).timeout


func _current_car() -> PlayerCarController:
	if _main == null:
		return null

	return _main.get("_current_car") as PlayerCarController


func _opponents() -> Array:
	if _main == null:
		return []

	var opponents: Variant = _main.get("_opponents")
	if opponents is Array:
		return opponents

	return []


func _selected_mode_id() -> String:
	if _main == null:
		return ""

	return str(_main.get("selected_mode_id"))


func _selected_track_id() -> String:
	if _main == null:
		return ""

	return str(_main.get("selected_track_id"))


func _get_menu() -> Node:
	if _main == null:
		return null

	return _main.get_node_or_null("MainMenu")


func _is_child_visible(node_name: String) -> bool:
	if _main == null:
		return false

	var target: CanvasItem = _main.get_node_or_null(node_name) as CanvasItem
	return target != null and target.visible


func _has_moving_opponent() -> bool:
	for opponent_variant: Variant in _opponents():
		var opponent: PlayerCarController = opponent_variant as PlayerCarController
		if opponent != null and absf(float(opponent.call("get_forward_speed"))) > 0.05:
			return true

	return false


func _find_visible_button_with_text(root_node: Node, label_text: String) -> Button:
	if root_node == null:
		return null

	if root_node is Button:
		var button: Button = root_node as Button
		if button.text == label_text and button.is_visible_in_tree():
			return button

	for child: Node in root_node.get_children():
		var found_button: Button = _find_visible_button_with_text(child, label_text)
		if found_button != null:
			return found_button

	return null


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[SMOKE][PASS] %s" % message)
		return

	_failures.append(message)
	push_error("[SMOKE][FAIL] %s" % message)


func _release_test_actions() -> void:
	for action_name: String in TEST_ACTIONS:
		Input.action_release(action_name)


func _finish() -> void:
	_release_test_actions()
	if _failures.is_empty():
		print("[SMOKE] Full program smoke test passed: %d checks" % _checks)
		get_tree().quit(0)
		return

	push_error("[SMOKE] Full program smoke test failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[SMOKE] - %s" % failure_message)
	get_tree().quit(1)
