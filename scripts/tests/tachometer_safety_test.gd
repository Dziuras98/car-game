extends SceneTree

const WATCHDOG_SECONDS: float = 5.0

var _checks: int = 0
var _failures: Array[String] = []
var _finished: bool = false


func _initialize() -> void:
	Callable(self, "_watchdog").call_deferred()

	var gauge: TachometerGauge = TachometerGauge.new()
	root.add_child(gauge)
	gauge.min_rpm = 0.0
	gauge.max_rpm = 9000.0

	gauge.major_tick_rpm = 0.0
	gauge.minor_tick_rpm = 0.0
	var zero_step_counts: Vector2i = gauge.get_tick_counts()
	_expect(zero_step_counts.x >= 1 and zero_step_counts.x <= TachometerGauge.MAX_TICK_COUNT, "zero minor tick step is clamped to a bounded count")
	_expect(zero_step_counts.y >= 1 and zero_step_counts.y <= TachometerGauge.MAX_TICK_COUNT, "zero major tick step is clamped to a bounded count")

	gauge.major_tick_rpm = -100.0
	gauge.minor_tick_rpm = -50.0
	var negative_step_counts: Vector2i = gauge.get_tick_counts()
	_expect(negative_step_counts.x <= TachometerGauge.MAX_TICK_COUNT, "negative minor tick step cannot create an unbounded loop")
	_expect(negative_step_counts.y <= TachometerGauge.MAX_TICK_COUNT, "negative major tick step cannot create an unbounded loop")

	gauge.major_tick_rpm = 1000.0
	gauge.minor_tick_rpm = 500.0
	var normal_counts: Vector2i = gauge.get_tick_counts()
	_expect(normal_counts == Vector2i(19, 10), "normal 0-9000 RPM range produces deterministic tick counts")

	gauge.configure_range(7500.0, 7000.0)
	_expect(is_equal_approx(gauge.max_rpm, 7500.0), "configured tachometer range remains valid")
	_expect(is_equal_approx(gauge.redline_rpm, 7000.0), "configured redline remains within the range")
	gauge.free()
	_finish()


func _watchdog() -> void:
	await create_timer(WATCHDOG_SECONDS).timeout
	if _finished:
		return
	_failures.append("test did not finish before watchdog timeout")
	push_error("[TACHOMETER_SAFETY_TEST][FAIL] watchdog timeout after %.1f seconds" % WATCHDOG_SECONDS)
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TACHOMETER_SAFETY_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TACHOMETER_SAFETY_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _failures.is_empty():
		print("[TACHOMETER_SAFETY_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TACHOMETER_SAFETY_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TACHOMETER_SAFETY_TEST] - %s" % failure_message)
	quit(1)
