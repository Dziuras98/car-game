extends SceneTree

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var localization_errors: PackedStringArray = LocalizationCatalogLoader.ensure_loaded()
	_expect(localization_errors.is_empty(), "localization loads before free-drive input test")
	TranslationServer.set_locale("pl")
	var main: Node = MAIN_SCENE.instantiate()
	root.add_child(main)
	await _frames(8)

	for label: String in ["Jazda swobodna", "Prosty owal"]:
		var button: Button = _find_visible_button(main, label)
		_expect(button != null, "menu exposes %s" % label)
		if button == null:
			main.queue_free()
			await process_frame
			_finish()
			return
		button.emit_signal("pressed")
		await _frames(3)

	var automatic_button: Button = _find_visible_button(main, "370Z automat")
	_expect(automatic_button != null, "flat car browser exposes 370Z automat without a model step")
	if automatic_button == null:
		main.queue_free()
		await process_frame
		_finish()
		return
	var dpi_label: Label = automatic_button.get_node_or_null("Content/Footer/PerformanceIndex") as Label
	_expect(
		dpi_label != null and dpi_label.visible and dpi_label.text.begins_with("DPI "),
		"automatic car thumbnail visibly exposes its DPI"
	)
	automatic_button.emit_signal("pressed")
	await _frames(2)
	var choose_button: Button = _find_visible_button(main, "Wybierz")
	_expect(choose_button != null, "flat car browser exposes an explicit selection action")
	if choose_button == null:
		main.queue_free()
		await process_frame
		_finish()
		return
	choose_button.emit_signal("pressed")
	await _frames(3)
	await _frames(8)

	var car: PlayerCarController = main.call("get_current_car") as PlayerCarController
	_expect(car != null, "free-drive automatic car spawns through the complete menu flow")
	if car == null:
		main.queue_free()
		await process_frame
		_finish()
		return
	var car_input: CarInput = car._car_input
	print(
		"[GAME_FREE_DRIVE_INPUT_TEST] player_enabled=%s external_enabled=%s"
		% [str(car_input._player_input_enabled), str(car_input._external_input_enabled)]
	)
	_expect(car_input._player_input_enabled, "free-drive car owns player input")
	_expect(not car_input._external_input_enabled, "free-drive car does not retain external AI input ownership")

	Input.action_press("accelerate")
	await create_timer(1.0).timeout
	var telemetry: CarTelemetrySnapshot = car.get_telemetry_snapshot()
	Input.action_release("accelerate")
	await _frames(2)
	print(
		"[GAME_FREE_DRIVE_INPUT_TEST] speed=%.3f gear=%d throttle=%.2f contacts=%d position=%s"
		% [
			telemetry.get_forward_speed(),
			telemetry.get_current_gear(),
			telemetry.get_throttle_input(),
			telemetry.get_ground_contact_count(),
			str(car.global_position),
		]
	)
	_expect(telemetry.get_throttle_input() > 0.9, "free-drive car samples the player accelerate action")
	_expect(telemetry.get_ground_contact_count() > 0, "free-drive car retains ground contact")
	_expect(telemetry.get_forward_speed() > 0.1, "free-drive automatic car accelerates through player input")

	main.queue_free()
	await process_frame
	_finish()


func _find_visible_button(node: Node, label: String) -> Button:
	if node is Button:
		var button: Button = node as Button
		if button.is_visible_in_tree() and button.text == label:
			return button
	for child: Node in node.get_children():
		var found: Button = _find_visible_button(child, label)
		if found != null:
			return found
	return null


func _frames(count: int) -> void:
	for _frame_index: int in range(count):
		await process_frame


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[GAME_FREE_DRIVE_INPUT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[GAME_FREE_DRIVE_INPUT_TEST][FAIL] %s" % message)


func _finish() -> void:
	Input.action_release("accelerate")
	if _failures.is_empty():
		print("[GAME_FREE_DRIVE_INPUT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[GAME_FREE_DRIVE_INPUT_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[GAME_FREE_DRIVE_INPUT_TEST] - %s" % failure_message)
	quit(1)
