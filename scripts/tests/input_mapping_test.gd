extends SceneTree

const REQUIRED_ACTIONS: PackedStringArray = [
	"accelerate",
	"brake",
	"steer-left",
	"steer-right",
	"handbrake",
	"reset-car",
	"camera-back",
	"pause",
	"switch-car",
	"gear-up",
	"gear-down",
]

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	for action_name: String in REQUIRED_ACTIONS:
		_expect(InputMap.has_action(action_name), "input map defines action '%s'" % action_name)
		if not InputMap.has_action(action_name):
			continue

		var has_keyboard_event: bool = false
		var has_gamepad_event: bool = false
		for event: InputEvent in InputMap.action_get_events(action_name):
			if event is InputEventKey:
				has_keyboard_event = true
			elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
				has_gamepad_event = true

		_expect(has_keyboard_event, "action '%s' has a keyboard binding" % action_name)
		_expect(has_gamepad_event, "action '%s' has a gamepad binding" % action_name)

	_finish()


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
