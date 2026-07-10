extends Node

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")

var _checks: int = 0
var _failures: Array[String] = []
var _selection_count: int = 0
var _selected_mode: String = ""
var _selected_track: String = ""
var _selected_variant: StringName = &""


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var menu: MainMenu = MAIN_MENU_SCENE.instantiate() as MainMenu
	var track_options: Array[TrackMenuOption] = [
		TrackMenuOption.new(&"test_track", "Tor testowy", 4),
	]
	var variant_options: Array[CarVariantMenuOption] = [
		CarVariantMenuOption.new(&"test_variant", "Wariant testowy"),
	]
	var model_options: Array[CarModelMenuOption] = [
		CarModelMenuOption.new(&"test_model", "Model testowy", variant_options),
	]
	menu.set_track_options(track_options)
	menu.set_car_models(model_options)
	menu.selection_completed.connect(_on_selection_completed)
	add_child(menu)
	await get_tree().process_frame

	_expect(menu.has_valid_options(), "menu accepts complete typed content options")
	var mode_buttons: Array[Button] = _get_option_buttons(menu)
	_expect(mode_buttons.size() == 2, "mode step exposes two choices")
	_expect(_find_button(mode_buttons, "Wyścig") != null, "mode label uses the correct Polish spelling")
	_expect(mode_buttons[0].has_focus(), "first mode option receives keyboard/gamepad focus")

	mode_buttons[0].pressed.emit()
	await get_tree().process_frame
	var track_buttons: Array[Button] = _get_option_buttons(menu)
	_expect(track_buttons.size() == 1 and track_buttons[0].text == "Tor testowy", "track step renders typed track data")
	track_buttons[0].pressed.emit()
	await get_tree().process_frame

	var model_buttons: Array[Button] = _get_option_buttons(menu)
	_expect(model_buttons.size() == 1 and model_buttons[0].text == "Model testowy", "model step renders typed model data")
	model_buttons[0].pressed.emit()
	await get_tree().process_frame

	var variant_buttons: Array[Button] = _get_option_buttons(menu)
	_expect(variant_buttons.size() == 1 and variant_buttons[0].text == "Wariant testowy", "variant step renders typed variant data")
	variant_buttons[0].pressed.emit()
	await get_tree().process_frame
	_expect(_selection_count == 1, "valid typed selection emits exactly once")
	_expect(_selected_mode == "free_drive", "selection preserves the chosen mode id")
	_expect(_selected_track == "test_track", "selection preserves the chosen track id")
	_expect(_selected_variant == &"test_variant", "selection preserves the chosen variant id")

	var invalid_menu: MainMenu = MAIN_MENU_SCENE.instantiate() as MainMenu
	add_child(invalid_menu)
	await get_tree().process_frame
	_expect(not invalid_menu.has_valid_options(), "menu rejects missing content options")
	var invalid_mode_buttons: Array[Button] = _get_option_buttons(invalid_menu)
	invalid_mode_buttons[0].pressed.emit()
	await get_tree().process_frame
	_expect(_get_option_buttons(invalid_menu).is_empty(), "invalid content cannot advance into an empty selection step")

	invalid_menu.queue_free()
	menu.queue_free()
	await get_tree().process_frame
	_finish()


func _get_option_buttons(menu: MainMenu) -> Array[Button]:
	var result: Array[Button] = []
	var container: Node = menu.get_node("Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Options")
	for child: Node in container.get_children():
		if child is Button:
			result.append(child as Button)
	return result


func _find_button(buttons: Array[Button], text: String) -> Button:
	for button: Button in buttons:
		if button.text == text:
			return button
	return null


func _on_selection_completed(mode_id: String, track_id: String, variant_id: StringName) -> void:
	_selection_count += 1
	_selected_mode = mode_id
	_selected_track = track_id
	_selected_variant = variant_id


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[MAIN_MENU_TYPED_OPTIONS_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[MAIN_MENU_TYPED_OPTIONS_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[MAIN_MENU_TYPED_OPTIONS_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[MAIN_MENU_TYPED_OPTIONS_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[MAIN_MENU_TYPED_OPTIONS_TEST] - %s" % failure_message)
	get_tree().quit(1)
