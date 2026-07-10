extends Node

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const GAME_TEST_ADAPTER_SCRIPT: Script = preload("res://scripts/tests/game_test_adapter.gd")
const MODE_FREE: String = "free_drive"
const MODE_RACE: String = "race"
const TRACK_SIMPLE_OVAL: String = "simple_oval"
const MODEL_NISSAN_370Z: String = "Nissan 370Z"
const VARIANT_7AT: StringName = &"nissan_370z_7at"
const VARIANT_6MT: StringName = &"nissan_370z_6mt"
const TEST_ACTIONS: Array[String] = [
	"accelerate",
	"brake",
	"reset-car",
	"switch-car",
	"gear-up",
	"gear-down",
]

var _main: Node
var _adapter: GameTestAdapter
var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _exit_tree() -> void:
	_release_actions()


func _run() -> void:
	print("[SMOKE_V2] Starting deterministic full-program smoke test")
	await _load_main_scene()
	await _test_menu_back_navigation()
	await _test_automatic_free_drive()
	await _return_to_menu()
	await _test_manual_free_drive()
	await _return_to_menu()
	await _test_race_lifecycle()
	await _test_post_race_reentry()
	await _cleanup()
	_finish()


func _load_main_scene() -> void:
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	_adapter = GAME_TEST_ADAPTER_SCRIPT.new() as GameTestAdapter
	_adapter.configure(_main)
	await _frames(6)
	_expect(_main != null, "main scene instantiates")
	_expect(_adapter.get_menu() != null, "main menu exists")
	_expect(_current_car() == null, "no player car exists before selection")


func _test_menu_back_navigation() -> void:
	await _press_button("Dowolny")
	await _press_button("Prosty owal")
	await _press_button(MODEL_NISSAN_370Z)
	await _press_button("Wstecz")
	_expect(_find_button(MODEL_NISSAN_370Z) != null, "back restores model selection")
	await _press_button("Wstecz")
	_expect(_find_button("Prosty owal") != null, "back restores track selection")
	await _press_button("Wstecz")
	_expect(_find_button("Dowolny") != null, "back restores mode selection")
	_expect(_find_button("Wyscig") != null, "race mode remains available")


func _test_automatic_free_drive() -> void:
	await _select_car("Dowolny", "370Z automat")
	_expect(_adapter.get_selected_mode_id() == MODE_FREE, "free-drive mode is selected")
	_expect(_adapter.get_selected_track_id() == TRACK_SIMPLE_OVAL, "simple oval is selected")
	_expect(_adapter.get_selected_car_variant_id() == VARIANT_7AT, "automatic variant is selected")
	_expect(_adapter.is_child_visible("Speedometer"), "speedometer is visible")
	_expect(_adapter.is_child_visible("Minimap"), "minimap is visible")

	var car: PlayerCarController = _current_car()
	_expect(car != null, "automatic car is spawned")
	if car == null:
		return
	await _expect_acceleration(car, "automatic car accelerates from player input")
	_expect(car.get_engine_rpm() > 900.0, "automatic engine RPM rises above idle")
	_expect(car.get_engine_load() >= 0.0, "automatic engine load remains valid")

	var speed_before_brake: float = car.get_forward_speed()
	await _hold_action("brake", 0.8)
	_expect(car.get_forward_speed() < speed_before_brake, "automatic car slows under braking")
	await _tap_action("reset-car")
	_expect(absf(car.get_forward_speed()) < 0.75, "reset clears automatic speed")
	await _hold_action("brake", 1.2)
	_expect(car.get_forward_speed() < -0.05, "automatic car reverses from rest")
	await _tap_action("reset-car")

	var previous_car: PlayerCarController = _current_car()
	await _tap_action("switch-car")
	_expect(_current_car() != null and _current_car() != previous_car, "switch-car replaces the free-drive car")


func _test_manual_free_drive() -> void:
	await _select_car("Dowolny", "370Z manual")
	_expect(_adapter.get_selected_mode_id() == MODE_FREE, "manual car starts in free drive")
	_expect(_adapter.get_selected_car_variant_id() == VARIANT_6MT, "manual variant is selected")
	var car: PlayerCarController = _current_car()
	_expect(car != null, "manual car is spawned")
	if car == null:
		return
	_expect(car.get_gear_text() == "1", "manual car starts in first gear")
	await _tap_action("gear-up")
	_expect(car.get_gear_text() == "2", "manual gear-up selects second gear")
	await _tap_action("gear-down")
	_expect(car.get_gear_text() == "1", "manual gear-down returns to first gear")
	await _seconds(0.35)
	await _expect_acceleration(car, "manual car accelerates after clutch engagement")
	await _tap_action("reset-car")
	_expect(absf(car.get_forward_speed()) < 0.75, "reset clears manual speed")


func _test_race_lifecycle() -> void:
	await _select_car("Wyscig", "370Z automat")
	_expect(_adapter.get_selected_mode_id() == MODE_RACE, "race mode is selected")
	_expect(_adapter.get_selected_car_variant_id() == VARIANT_7AT, "race automatic variant is selected")
	var race_car: PlayerCarController = _current_car()
	_expect(race_car != null, "race player car is spawned")
	_expect(_adapter.get_opponents().size() == _adapter.get_configured_opponent_count(), "configured opponents are spawned")
	await _tap_action("switch-car")
	_expect(_current_car() == race_car, "switch-car is blocked during countdown")
	await _seconds(3.35)
	await _tap_action("switch-car")
	_expect(_current_car() == race_car, "switch-car remains blocked after race start")
	await _seconds(1.0)
	_expect(_adapter.get_moving_opponent_count() > 0, "at least one AI opponent moves after countdown")

	_adapter.simulate_player_finish()
	await _frames(8)
	var results_button: Button = _find_button("Powrot do menu glownego")
	_expect(results_button != null, "results screen appears after player finish")
	if results_button == null:
		return
	results_button.emit_signal("pressed")
	await _frames(12)
	_expect(_current_car() == null, "results return clears player car")
	_expect(_adapter.get_selected_mode_id() == "", "results return clears selected mode")
	_expect(_adapter.get_opponents().is_empty(), "results return clears opponents")


func _test_post_race_reentry() -> void:
	await _select_car("Dowolny", "370Z automat")
	_expect(_adapter.get_selected_mode_id() == MODE_FREE, "free drive can be selected after race cleanup")
	var car: PlayerCarController = _current_car()
	_expect(car != null, "car respawns after race cleanup")
	if car != null:
		await _expect_acceleration(car, "car accelerates after race cleanup")


func _select_car(mode_label: String, variant_label: String) -> void:
	await _press_button(mode_label)
	await _press_button("Prosty owal")
	await _press_button(MODEL_NISSAN_370Z)
	await _press_button(variant_label)
	await _frames(8)


func _press_button(label_text: String) -> void:
	var button: Button = _find_button(label_text)
	_expect(button != null, "visible button exists: %s" % label_text)
	if button == null:
		return
	button.emit_signal("pressed")
	await _frames(3)


func _expect_acceleration(car: PlayerCarController, message: String) -> void:
	var start_speed: float = car.get_forward_speed()
	await _hold_action("accelerate", 0.85)
	_expect(car.get_forward_speed() > start_speed + 0.1, message)


func _hold_action(action_name: String, duration_seconds: float) -> void:
	Input.action_press(action_name)
	await _seconds(duration_seconds)
	Input.action_release(action_name)
	await _frames(2)


func _tap_action(action_name: String) -> void:
	Input.action_press(action_name)
	await get_tree().process_frame
	await get_tree().physics_frame
	Input.action_release(action_name)
	await _frames(3)


func _return_to_menu() -> void:
	_release_actions()
	_adapter.return_to_main_menu()
	await _frames(10)
	_expect(_current_car() == null, "return-to-menu clears player car")
	_expect(_adapter.get_selected_mode_id() == "", "return-to-menu clears selected mode")


func _cleanup() -> void:
	_release_actions()
	if _adapter != null:
		_adapter.return_to_main_menu()
	if is_instance_valid(_main):
		_main.queue_free()
	await _frames(3)


func _current_car() -> PlayerCarController:
	return _adapter.get_current_car() if _adapter != null else null


func _find_button(label_text: String) -> Button:
	return _adapter.find_visible_button_with_text(_main, label_text) if _adapter != null else null


func _frames(frame_count: int) -> void:
	for _frame_index: int in range(maxi(frame_count, 1)):
		await get_tree().process_frame


func _seconds(duration_seconds: float) -> void:
	await get_tree().create_timer(maxf(duration_seconds, 0.001)).timeout


func _release_actions() -> void:
	for action_name: String in TEST_ACTIONS:
		Input.action_release(action_name)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[SMOKE_V2][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[SMOKE_V2][FAIL] %s" % message)


func _finish() -> void:
	_release_actions()
	if _failures.is_empty():
		print("[SMOKE_V2] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[SMOKE_V2] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[SMOKE_V2] - %s" % failure_message)
	get_tree().quit(1)
