extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	var full: Vector4 = SafeAreaLayout.calculate_fullscreen_offsets(
		Vector2(1920.0, 1080.0),
		Rect2(Vector2.ZERO, Vector2(1920.0, 1080.0)),
		12.0
	)
	_expect(full == Vector4(12.0, 12.0, 12.0, 12.0), "full desktop area applies only the configured margin")

	var notched: Vector4 = SafeAreaLayout.calculate_fullscreen_offsets(
		Vector2(1080.0, 2400.0),
		Rect2(Vector2(40.0, 90.0), Vector2(1000.0, 2220.0)),
		8.0
	)
	_expect(notched == Vector4(48.0, 98.0, 48.0, 98.0), "portrait cutouts add symmetric safe insets and margins")

	var gesture_bar: Vector4 = SafeAreaLayout.calculate_fullscreen_offsets(
		Vector2(2400.0, 1080.0),
		Rect2(Vector2(0.0, 0.0), Vector2(2320.0, 1030.0)),
		0.0
	)
	_expect(gesture_bar == Vector4(0.0, 0.0, 80.0, 50.0), "landscape system bars are converted to right and bottom insets")

	var invalid: Vector4 = SafeAreaLayout.calculate_fullscreen_offsets(
		Vector2(800.0, 600.0),
		Rect2(),
		5.0
	)
	_expect(invalid == Vector4(5.0, 5.0, 5.0, 5.0), "missing platform safe area falls back to the complete viewport")

	var clamped: Vector4 = SafeAreaLayout.calculate_fullscreen_offsets(
		Vector2(800.0, 600.0),
		Rect2(Vector2(-50.0, -20.0), Vector2(1000.0, 900.0)),
		0.0
	)
	_expect(clamped == Vector4(0.0, 0.0, 0.0, 0.0), "out-of-bounds platform rectangles are clamped to the viewport")
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[SAFE_AREA_LAYOUT_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[SAFE_AREA_LAYOUT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[SAFE_AREA_LAYOUT_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[SAFE_AREA_LAYOUT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[SAFE_AREA_LAYOUT_TEST] - %s" % failure_message)
	quit(1)
