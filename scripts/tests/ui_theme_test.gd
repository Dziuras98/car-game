extends SceneTree

const THEME_PATH: String = "res://resources/ui/default_theme.tres"

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var theme: Theme = load(THEME_PATH) as Theme
	_expect(theme != null, "shared UI theme resource loads")
	if theme != null:
		_expect(theme.default_font_size >= 16, "default font size remains readable")
		_expect(theme.has_stylebox("normal", "Button"), "buttons define a normal style")
		_expect(theme.has_stylebox("hover", "Button"), "buttons define a hover style")
		_expect(theme.has_stylebox("pressed", "Button"), "buttons define a pressed style")
		_expect(theme.has_stylebox("focus", "Button"), "keyboard and gamepad focus has a dedicated visible style")
		_expect(theme.has_stylebox("panel", "PanelContainer"), "panels share one project style")
		var focus: StyleBox = theme.get_stylebox("focus", "Button")
		_expect(focus is StyleBoxFlat and (focus as StyleBoxFlat).border_width_left >= 2, "focus outline is thick enough to remain visible")

	_expect(
		str(ProjectSettings.get_setting("gui/theme/custom", "")) == THEME_PATH,
		"project settings apply the shared theme globally"
	)
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[UI_THEME_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[UI_THEME_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[UI_THEME_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[UI_THEME_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[UI_THEME_TEST] - %s" % failure_message)
	quit(1)
