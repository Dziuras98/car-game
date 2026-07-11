extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var seen_actions: Dictionary = {}
	for action_name: StringName in GameInputActions.REQUIRED_ACTIONS:
		_expect(not seen_actions.has(action_name), "input action '%s' is listed once" % action_name)
		seen_actions[action_name] = true
		_validate_action(action_name)

	for analog_action: StringName in GameInputActions.ANALOG_ACTIONS:
		_expect(
			GameInputActions.REQUIRED_ACTIONS.has(analog_action),
			"analog action '%s' belongs to the required action contract" % analog_action
		)

	if (
		InputMap.has_action(GameInputActions.STEER_LEFT)
		and InputMap.has_action(GameInputActions.STEER_RIGHT)
	):
		_expect(
			is_equal_approx(
				InputMap.action_get_deadzone(GameInputActions.STEER_LEFT),
				InputMap.action_get_deadzone(GameInputActions.STEER_RIGHT)
			),
			"left and right steering actions use the same deadzone"
		)

	_finish()


func _validate_action(action_name: StringName) -> void:
	var action_exists: bool = InputMap.has_action(action_name)
	_expect(action_exists, "input map defines action '%s'" % action_name)
	if not action_exists:
		return

	var has_keyboard_event: bool = false
	var has_gamepad_event: bool = false
	var has_gamepad_motion: bool = false
	for event: InputEvent in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			has_keyboard_event = true
		elif event is InputEventJoypadMotion:
			has_gamepad_event = true
			has_gamepad_motion = true
		elif event is InputEventJoypadButton:
			has_gamepad_event = true

	_expect(has_keyboard_event, "action '%s' has a keyboard binding" % action_name)
	_expect(has_gamepad_event, "action '%s' has a gamepad binding" % action_name)

	var deadzone: float = InputMap.action_get_deadzone(action_name)
	_expect(
		deadzone >= 0.0 and deadzone <= 1.0,
		"action '%s' has a normalized deadzone" % action_name
	)
	if GameInputActions.is_analog_action(action_name):
		_expect(has_gamepad_motion, "analog action '%s' has an axis binding" % action_name)
		_expect(
			deadzone <= GameInputActions.MAX_ANALOG_DEADZONE,
			"analog action '%s' deadzone does not exceed %.2f" % [
				action_name,
				GameInputActions.MAX_ANALOG_DEADZONE,
			]
		)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[INPUT_MAPPING_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[INPUT_MAPPING_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[INPUT_MAPPING_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[INPUT_MAPPING_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[INPUT_MAPPING_TEST] - %s" % failure_message)
	quit(1)
