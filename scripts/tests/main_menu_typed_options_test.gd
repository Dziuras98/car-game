extends Node

const MAIN_MENU_SCENE: PackedScene = preload("res://scenes/ui/main_menu.tscn")

var _checks: int = 0
var _failures: Array[String] = []
var _selection_count: int = 0
var _selected_mode: StringName = &""
var _selected_track: StringName = &""
var _selected_variant: StringName = &""
var _original_locale: String = ""


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_original_locale = TranslationServer.get_locale()
	var localization_errors: PackedStringArray = LocalizationCatalogLoader.ensure_loaded()
	_expect(localization_errors.is_empty(), "menu localization catalogs load for the isolated scene test")
	TranslationServer.set_locale("pl")

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

	menu._on_mode_pressed(&"unsupported")
	await get_tree().process_frame
	_expect(_selection_count == 0, "unsupported mode does not emit a selection")
	_expect(_get_option_buttons(menu).is_empty(), "unsupported mode cannot advance to track selection")
	_expect(
		_get_subtitle(menu).text == "Wybrany tryb nie jest dostępny",
		"unsupported mode reports an explicit configuration error"
	)
	_expect(menu._get_mode_label(&"unsupported") == "Nieznany tryb", "unknown mode label has no free-drive fallback")
	menu.reset_menu()
	await get_tree().process_frame

	mode_buttons = _get_option_buttons(menu)
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
	_expect(menu.is_loading_screen_visible(), "valid selection immediately opens the blocking loading screen")
	_expect(not _get_selection_panel(menu).visible, "selection controls are hidden while loading")
	_expect(_get_loading_details(menu).text.contains("Tor testowy"), "loading screen identifies the selected track")
	_expect(_get_loading_details(menu).text.contains("Wariant testowy"), "loading screen identifies the selected car variant")
	_expect(menu.get_loading_progress() == MainMenu.LOADING_PROGRESS_INITIAL, "loading screen begins at the explicit initial progress")
	await get_tree().process_frame
	_expect(menu.is_loading_screen_visible(), "loading screen remains visible for a rendered frame before session startup")
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(_selection_count == 1, "valid typed selection emits exactly once")
	_expect(_selected_mode == GameModes.FREE_DRIVE, "selection preserves the chosen StringName mode id")
	_expect(_selected_track == &"test_track", "selection preserves the chosen track id")
	_expect(_selected_variant == &"test_variant", "selection preserves the chosen variant id")
	_expect(menu.is_loading_screen_visible(), "loading remains active until the session owner completes it")

	menu.set_loading_progress(0.35, "Przygotowywanie toru")
	_expect(is_equal_approx(menu.get_loading_progress(), 35.0), "loading progress accepts a real stage value")
	_expect(_get_loading_subtitle(menu).text == "Przygotowywanie toru", "loading status follows the current startup stage")
	menu.set_loading_progress(0.20, "Nieaktualny etap")
	_expect(is_equal_approx(menu.get_loading_progress(), 35.0), "loading progress never moves backwards")
	menu.set_loading_progress(1.0, "Gotowe")
	_expect(is_equal_approx(menu.get_loading_progress(), 100.0), "loading progress reaches completion")
	menu.complete_loading(false)
	_expect(not menu.is_loading_screen_visible(), "failed session admission restores the selection menu explicitly")
	_expect(menu.visible, "failed session admission keeps the menu visible")

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
	TranslationServer.set_locale(_original_locale)
	await get_tree().process_frame
	_finish()


func _get_option_buttons(menu: MainMenu) -> Array[Button]:
	var result: Array[Button] = []
	var container: Node = menu.get_node("Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Options")
	for child: Node in container.get_children():
		if child is Button:
			result.append(child as Button)
	return result


func _get_selection_panel(menu: MainMenu) -> PanelContainer:
	return menu.get_node("Root/CenterContainer/PanelContainer") as PanelContainer


func _get_loading_details(menu: MainMenu) -> Label:
	return menu.get_node(
		"Root/CenterContainer/LoadingPanelContainer/MarginContainer/VBoxContainer/DetailsLabel"
	) as Label


func _get_loading_subtitle(menu: MainMenu) -> Label:
	return menu.get_node(
		"Root/CenterContainer/LoadingPanelContainer/MarginContainer/VBoxContainer/SubtitleLabel"
	) as Label


func _get_subtitle(menu: MainMenu) -> Label:
	return menu.get_node("Root/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SubtitleLabel") as Label


func _find_button(buttons: Array[Button], text: String) -> Button:
	for button: Button in buttons:
		if button.text == text:
			return button
	return null


func _on_selection_completed(mode_id: StringName, track_id: StringName, variant_id: StringName) -> void:
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
