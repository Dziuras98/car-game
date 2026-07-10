extends SceneTree

const WATCHDOG_SECONDS: float = 5.0

var _checks: int = 0
var _failures: Array[String] = []
var _finished: bool = false


func _initialize() -> void:
	Callable(self, "_watchdog").call_deferred()

	var gate: TrackCheckpointGate = TrackCheckpointGate.new()
	gate.configure(2, Transform3D.IDENTITY, Vector3(12.0, 4.0, 6.0))
	root.add_child(gate)

	var forward: Vector3 = Vector3(0.0, 0.0, -10.0)
	var reverse: Vector3 = -forward
	_expect(
		gate.evaluate_segment_crossing_for_test(Vector3(0.0, 0.0, 2.0), Vector3(0.0, 0.0, -2.0), forward) == 1,
		"forward segment crossing is accepted"
	)
	_expect(
		gate.evaluate_segment_crossing_for_test(Vector3(0.0, 0.0, -2.0), Vector3(0.0, 0.0, 2.0), reverse) == -1,
		"reverse segment crossing is identified separately"
	)
	_expect(
		gate.evaluate_segment_crossing_for_test(Vector3(0.0, 0.0, 2.0), Vector3(0.0, 0.0, -2.0), reverse) == 0,
		"position crossing with contradictory velocity is rejected"
	)
	_expect(
		gate.evaluate_segment_crossing_for_test(Vector3(0.0, 0.0, 2.0), Vector3(0.0, 0.0, 1.0), forward) == 0,
		"entering the gate volume without crossing its plane is ignored"
	)
	_expect(
		gate.evaluate_segment_crossing_for_test(Vector3(0.0, 0.0, 0.01), Vector3(0.0, 0.0, -0.01), forward) == 0,
		"movement inside the plane epsilon cannot create duplicate crossings"
	)

	gate.free()
	_finish()


func _watchdog() -> void:
	await create_timer(WATCHDOG_SECONDS).timeout
	if _finished:
		return
	_failures.append("test did not finish before watchdog timeout")
	push_error("[TRACK_CHECKPOINT_GATE_PLANE_TEST][FAIL] watchdog timeout after %.1f seconds" % WATCHDOG_SECONDS)
	_finish()


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRACK_CHECKPOINT_GATE_PLANE_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRACK_CHECKPOINT_GATE_PLANE_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if _failures.is_empty():
		print("[TRACK_CHECKPOINT_GATE_PLANE_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[TRACK_CHECKPOINT_GATE_PLANE_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TRACK_CHECKPOINT_GATE_PLANE_TEST] - %s" % failure_message)
	quit(1)
