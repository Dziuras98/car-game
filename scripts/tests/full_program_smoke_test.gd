extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const GAME_TEST_ADAPTER_SCRIPT: Script = preload("res://scripts/tests/game_test_adapter.gd")
const MODE_FREE: String = "free_drive"
const MODE_RACE: String = "race"
const TRACK_SIMPLE_OVAL: String = "simple_oval"
const VARIANT_NISSAN_370Z_7AT: StringName = &"nissan_370z_7at"
const VARIANT_NISSAN_370Z_6MT: StringName = &"nissan_370z_6mt"
const SHORT_DRIVE_DURATION: float = 0.85
const LONG_DRIVE_DURATION: float = 2.4
const STEERING_DURATION: float = 1.0
const BRAKE_DURATION: float = 1.0
const REVERSE_DURATION: float = 1.2
const RACE_SOAK_DURATION: float = 8.0
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
var _test_adapter: GameTestAdapter
var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _exit_tree() -> void:
	_release_test_actions()


func _run() -> void:
	print("[SMOKE] Starting extended full program smoke test")
	var localization_errors: PackedStringArray = LocalizationCatalogLoader.ensure_loaded()
	_expect(localization_errors.is_empty(), "localization catalogs load for the full program smoke test")
	TranslationServer.set_locale("pl")
	await _load_main_scene()
	await _test_menu_back_navigation()
	await _test_free_drive_automatic()
	await _return_to_main_menu()
	await _test_free_drive_manual()
	await _return_to_main_menu()
	await _test_race_mode()
	await _test_post_race_free_drive_reentry()
	_finish()


func _load_main_scene() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	_test_adapter = GAME_TEST_ADAPTER_SCRIPT.new() as GameTestAdapter
	_test_adapter.configure(_main)
	await _frames(6)

	_expect(_main != null, "main scene instantiates")
	_expect(_get_menu() != null, "main menu exists")
	_expect(_current_car() == null, "no player car is spawned before menu selection")


func _test_menu_back_navigation() -> void:
	print("[SMOKE] Testing menu back navigation")
	await _press_button_with_text(tr("Jazda swobodna"))
	await _press_button_with_text(tr("Prosty owal"))
	_expect(
		_find_visible_button_with_text(_main, tr("370Z automat")) != null,
		"flat car browser exposes variants immediately after track selection"
	)

	await _press_button_with_text(tr("Wstecz"))
	_expect(
		_find_visible_button_with_text(_main, tr("Prosty owal")) != null,
		"back from flat car browser returns to track selection"
	)

	await _press_button_with_text(tr("Wstecz"))
	_expect(
		_find_visible_button_with_text(_main, tr("Jazda swobodna")) != null,
		"back from track selection returns to mode selection"
	)
	_expect(
		_find_visible_button_with_text(_main, tr("Wyścig")) != null,
		"race mode remains visible after backing to mode selection"
	)


func _test_free_drive_automatic() -> void:
	print("[SMOKE] Testing extended free drive automatic flow")
	await _select_menu_path(tr("Jazda swobodna"), tr("370Z automat"))

	_expect(_selected_mode_id() == MODE_FREE, "free-drive mode is selected")
	_expect(_selected_track_id() == TRACK_SIMPLE_OVAL, "simple oval track is selected")
	_expect(_selected_car_variant_id() == VARIANT_NISSAN_370Z_7AT, "automatic variant id is selected")
	_expect(_current_car() != null, "automatic car is spawned")
	_expect(_is_child_visible("Speedometer"), "speedometer is visible after free-drive spawn")
	_expect(_is_child_visible("Minimap"), "minimap is visible after free-drive spawn")

	var automatic_car: PlayerCarController = _current_car()
	if automatic_car == null:
		return

	await _expect_car_accelerates_for(automatic_car, SHORT_DRIVE_DURATION, "automatic car accelerates from input action")
	_expect(float(automatic_car.call("get_engine_rpm")) > 900.0, "automatic car reports RPM above idle after acceleration")
	_expect(float(automatic_car.call("get_engine_load")) >= 0.0, "automatic car reports non-negative engine load")

	var speed_before_long_drive: float = float(automatic_car.call("get_forward_speed"))
	await _hold_action("accelerate", LONG_DRIVE_DURATION)
	var speed_after_long_drive: float = float(automatic_car.call("get_forward_speed"))
	_expect(
		speed_after_long_drive > 0.5,
		"automatic car remains in sustained forward motion during longer drive segment (%.2f -> %.2f m/s)" % [
			speed_before_long_drive,
			speed_after_long_drive,
		]
	)

	await _hold_actions(["accelerate", "steer-left"], STEERING_DURATION)
	_expect(absf(float(automatic_car.call("get_forward_speed"))) > 0.5, "automatic car keeps moving while steering left")

	await _hold_actions(["accelerate", "steer-right"], STEERING_DURATION)
	_expect(absf(float(automatic_car.call("get_forward_speed"))) > 0.5, "automatic car keeps moving while steering right")

	await _hold_actions(["accelerate", "steer-left", "handbrake"], STEERING_DURATION)
	_expect(float(automatic_car.call("get_tire_slip_intensity")) >= 0.0, "automatic car reports valid tire slip during handbrake segment")

	var speed_before_brake: float = float(automatic_car.call("get_forward_speed"))
	await _hold_action("brake", BRAKE_DURATION)
	var speed_after_brake: float = float(automatic_car.call("get_forward_speed"))
	_expect(speed_after_brake < speed_before_brake, "automatic car slows down under braking")

	await _tap_action("reset-car")
	await _frames(8)
	_expect(absf(float(automatic_car.call("get_forward_speed"))) < 0.75, "reset clears automatic car forward speed")

	await _hold_action("brake", REVERSE_DURATION)
	_expect(float(automatic_car.call("get_forward_speed")) < -0.05, "automatic car reverses when braking from near stop")
	await _tap_action("reset-car")
	await _frames(8)

	var before_switch: PlayerCarController = _current_car()
	await _tap_action("switch-car")
	await _frames(8)
	_expect(_current_car() != null and _current_car() != before_switch, "switch-car changes car in free-drive mode")


func _test_free_drive_manual() -> void:
	print("[SMOKE] Testing extended free drive manual flow")
	await _select_menu_path(tr("Jazda swobodna"), tr("370Z manual"))

	_expect(_selected_mode_id() == MODE_FREE, "free-drive mode is selected for manual car")
	_expect(_selected_car_variant_id() == VARIANT_NISSAN_370Z_6MT, "manual variant id is selected")
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

	await _tap_action("gear-down")
	await _frames(4)
	_expect(str(manual_car.call("get_gear_text")) == "N", "manual gear-down from first selects neutral")

	await _tap_action("gear-down")
	await _frames(4)
	_expect(str(manual_car.call("get_gear_text")) == "R", "manual gear-down from neutral selects reverse")

	await _tap_action("gear-up")
	await _frames(4)
	_expect(str(manual_car.call("get_gear_text")) == "N", "manual gear-up from reverse selects neutral")

	await _tap_action("gear-up")
	await _frames(4)
	_expect(str(manual_car.call("get_gear_text")) == "1", "manual gear-up from neutral selects first")

	await _seconds(0.35)
	await _expect_car_accelerates_for(manual_car, LONG_DRIVE_DURATION, "manual car accelerates during longer drive segment")
	await _hold_actions(["accelerate", "steer-left"], STEERING_DURATION)
	_expect(absf(float(manual_car.call("get_forward_speed"))) > 0.5, "manual car keeps moving while steering")
	await _tap_action("reset-car")
	await _frames(8)
	_expect(absf(float(manual_car.call("get_forward_speed"))) < 0.75, "reset clears manual car forward speed")


func _test_race_mode() -> void:
	print("[SMOKE] Testing extended race flow")
	await _select_menu_path(tr("Wyścig"), tr("370Z automat"))

	_expect(_selected_mode_id() == MODE_RACE, "race mode is selected")
	_expect(_selected_car_variant_id() == VARIANT_NISSAN_370Z_7AT, "race automatic variant id is selected")
	_expect(_current_car() != null, "race player car is spawned")
	_expect(_opponents().size() == _configured_opponent_count(), "race opponents are spawned")
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
	var moving_opponent_count_after_start: int = _moving_opponent_count()
	_expect(moving_opponent_count_after_start > 0, "moving opponent count is greater than zero after start")

	await _seconds(RACE_SOAK_DURATION)
	_expect(_current_car() == race_car, "player car remains stable during longer race soak")
	_expect(_moving_opponent_count() > 0, "AI opponents keep moving during longer race soak")
	_expect(_selected_mode_id() == MODE_RACE, "race mode remains selected during longer race soak")

	if race_car != null:
		_test_adapter.simulate_player_finish()
		await _frames(8)
		var results_button: Button = _find_visible_button_with_text(_main, tr("Wróć do menu"))
		_expect(results_button != null, "results screen is shown after simulated player finish")
		if results_button != null:
			results_button.emit_signal("pressed")
			await _frames(12)
			_expect(_current_car() == null, "return-to-menu clears current car")
			_expect(_selected_mode_id() == "", "return-to-menu clears selected mode")
			_expect(_opponents().is_empty(), "return-to-menu clears opponents")


func _test_post_race_free_drive_reentry() -> void:
	print("[SMOKE] Testing post-race free-drive reentry")
	await _select_menu_path(tr("Jazda swobodna"), tr("370Z automat"))
	_expect(_selected_mode_id() == MODE_FREE, "free-drive mode can be selected again after race cleanup")
	_expect(_current_car() != null, "player car respawns after race cleanup")
	var car_after_reentry: PlayerCarController = _current_car()
	if car_after_reentry != null:
		await _expect_car_accelerates_for(car_after_reentry, SHORT_DRIVE_DURATION, "car accelerates after post-race free-drive reentry")


func _select_menu_path(mode_label: String, car_label: String) -> void:
	await _press_button_with_text(mode_label)
	await _press_button_with_text(tr("Prosty owal"))
	await _press_button_with_text(car_label)
	await _press_button_with_text(tr("Wybierz"))
	await _frames(8)


func _press_button_with_text(label_text: String) -> void:
	var button: Button = _find_visible_button_with_text(_main, label_text)
	_expect(button != null, "visible menu button exists: %s" % label_text)
	if button == null:
		return

	button.emit_signal("pressed")
	await _frames(3)


func _expect_car_accelerates_for(car: PlayerCarController, duration_seconds: float, message: String) -> void:
	var start_speed: float = float(car.call("get_forward_speed"))
	await _hold_action("accelerate", duration_seconds)
	var speed_after_acceleration: float = float(car.call("get_forward_speed"))
	_expect(speed_after_acceleration > start_speed + 0.1, message)
	_release_test_actions()
	await _frames(2)


func _hold_action(action_name: String, duration_seconds: float) -> void:
	await _hold_actions([action_name], duration_seconds)


func _hold_actions(action_names: Array[String], duration_seconds: float) -> void:
	for action_name: String in action_names:
		Input.action_press(action_name)

	await _seconds(duration_seconds)

	for action_name: String in action_names:
		Input.action_release(action_name)
	await _frames(2)


func _tap_action(action_name: String) -> void:
	Input.action_press(action_name)
	await get_tree().process_frame
	await get_tree().physics_frame
	Input.action_release(action_name)
	await _frames(2)


func _return_to_main_menu() -> void:
	_release_test_actions()
	if _test_adapter != null:
		_test_adapter.return_to_main_menu()
	await _frames(8)


func _frames(count: int) -> void:
	for _frame_index: int in range(count):
		await get_tree().process_frame


func _seconds(duration_seconds: float) -> void:
	await get_tree().create_timer(duration_seconds).timeout


func _current_car() -> PlayerCarController:
	if _test_adapter == null:
		return null

	return _test_adapter.get_current_car()


func _opponents() -> Array:
	if _test_adapter == null:
		return []

	return _test_adapter.get_opponents()


func _configured_opponent_count() -> int:
	if _test_adapter == null:
		return 0

	return _test_adapter.get_configured_opponent_count()


func _selected_mode_id() -> String:
	if _test_adapter == null:
		return ""

	return _test_adapter.get_selected_mode_id()


func _selected_track_id() -> String:
	if _test_adapter == null:
		return ""

	return _test_adapter.get_selected_track_id()


func _selected_car_variant_id() -> StringName:
	if _test_adapter == null:
		return &""

	return _test_adapter.get_selected_car_variant_id()


func _get_menu() -> Node:
	if _test_adapter == null:
		return null

	return _test_adapter.get_menu()


func _is_child_visible(node_name: String) -> bool:
	if _test_adapter == null:
		return false

	return _test_adapter.is_child_visible(node_name)


func _has_moving_opponent() -> bool:
	if _test_adapter == null:
		return false

	return _test_adapter.has_moving_opponent()


func _moving_opponent_count() -> int:
	if _test_adapter == null:
		return 0

	return _test_adapter.get_moving_opponent_count()


func _find_visible_button_with_text(root_node: Node, label_text: String) -> Button:
	if _test_adapter == null:
		return null

	return _test_adapter.find_visible_button_with_text(root_node, label_text)


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
		print("[SMOKE] Extended full program smoke test passed: %d checks" % _checks)
		get_tree().quit(0)
		return

	push_error("[SMOKE] Extended full program smoke test failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[SMOKE] - %s" % failure_message)
	get_tree().quit(1)
