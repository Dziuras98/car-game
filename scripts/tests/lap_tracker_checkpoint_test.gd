extends Node

const SIMPLE_OVAL_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")
const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")
const TEST_CAR_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_6mt_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []
var _finished_signal_count: int = 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_checkpoint_resource_validation()
	_test_checkpoint_gate_direction()
	await _test_generated_gates_and_lap_sequence()
	_finish()


func _test_checkpoint_resource_validation() -> void:
	_expect(SIMPLE_OVAL_LAYOUT.has_valid_checkpoint_sequence(), "simple oval has a valid ordered checkpoint sequence")
	_expect(SIMPLE_OVAL_LAYOUT.get_checkpoint_count() == 3, "simple oval defines three intermediate checkpoints")
	_expect(SIMPLE_OVAL_LAYOUT.get_checkpoint_gate_count() == 4, "checkpoint gate count includes the finish line")

	var invalid_layout: TrackLayoutResource = TrackLayoutResource.new()
	invalid_layout.control_points = SIMPLE_OVAL_LAYOUT.control_points
	invalid_layout.checkpoint_progresses = PackedFloat32Array([0.5, 0.25])
	_expect(not invalid_layout.has_valid_checkpoint_sequence(), "descending checkpoint progress is rejected")
	invalid_layout.checkpoint_progresses = PackedFloat32Array([0.25, 1.0])
	_expect(not invalid_layout.has_valid_checkpoint_sequence(), "checkpoint progress at the finish boundary is rejected")


func _test_checkpoint_gate_direction() -> void:
	var gate: TrackCheckpointGate = TrackCheckpointGate.new()
	gate.configure(0, Transform3D.IDENTITY, Vector3(18.0, 4.0, 8.0))
	add_child(gate)

	var car: PlayerCarController = PlayerCarController.new()
	car.car_specs = TEST_CAR_SPECS
	add_child(car)

	car.velocity = Vector3(0.0, 0.0, -10.0)
	_expect(gate.is_body_moving_forward(car), "gate accepts motion along its forward direction")
	car.velocity = Vector3(0.0, 0.0, 10.0)
	_expect(not gate.is_body_moving_forward(car), "gate rejects reverse-direction motion")
	car.velocity = Vector3.ZERO
	_expect(not gate.is_body_moving_forward(car), "gate rejects stationary overlap")

	car.free()
	gate.free()


func _test_generated_gates_and_lap_sequence() -> void:
	var track: Node3D = SIMPLE_OVAL_SCENE.instantiate() as Node3D
	_expect(track != null, "simple oval scene instantiates for checkpoint testing")
	if track == null:
		return

	add_child(track)
	await get_tree().process_frame

	_expect(track.has_signal("checkpoint_crossed"), "generated track exposes checkpoint crossing signal")
	_expect(int(track.call("get_checkpoint_count")) == 3, "generated track exposes three intermediate checkpoints")
	_expect(int(track.call("get_checkpoint_gate_count")) == 4, "generated track builds finish and checkpoint areas")

	var car: PlayerCarController = PlayerCarController.new()
	car.car_specs = TEST_CAR_SPECS
	add_child(car)
	await get_tree().process_frame

	var opponents: Array[PlayerCarController] = []
	var tracker: LapTracker = LapTracker.new()
	tracker.participant_finished.connect(_on_participant_finished)
	tracker.prepare(track, 2, car, opponents)

	_expect(tracker.get_expected_checkpoint_index(car) == 1, "participant starts by expecting checkpoint one")

	var racing_line: Array = track.call("get_racing_line_points")
	if racing_line.size() > 90:
		car.global_position = track.to_global(racing_line[90])
		tracker.update_positions()
		car.global_position = track.to_global(racing_line[0])
		tracker.update_positions()
	_expect(tracker.get_completed_laps(car) == 0, "racing-line index wrap does not count a lap")

	_emit_checkpoint(track, car, 0, true)
	_expect(tracker.get_completed_laps(car) == 0, "finish crossing before checkpoints is rejected")
	_expect(tracker.get_expected_checkpoint_index(car) == 1, "invalid finish crossing resets expectation to checkpoint one")

	_emit_checkpoint(track, car, 1, true)
	_emit_checkpoint(track, car, 3, true)
	_expect(tracker.get_expected_checkpoint_index(car) == 2, "skipping checkpoint two does not advance the sequence")
	_emit_checkpoint(track, car, 0, true)
	_expect(tracker.get_completed_laps(car) == 0, "track cut cannot complete a lap")
	_expect(tracker.get_expected_checkpoint_index(car) == 1, "finish after a track cut starts a fresh sequence")

	_emit_checkpoint(track, car, 1, true)
	_emit_checkpoint(track, car, 2, true)
	_emit_checkpoint(track, car, 3, true)
	_expect(tracker.get_expected_checkpoint_index(car) == 0, "complete checkpoint sequence arms the finish line")
	_emit_checkpoint(track, car, 0, false)
	_expect(tracker.get_completed_laps(car) == 0, "reverse finish crossing does not count")
	_expect(tracker.get_expected_checkpoint_index(car) == 0, "reverse finish crossing keeps the valid sequence armed")
	_emit_checkpoint(track, car, 0, true)
	_expect(tracker.get_completed_laps(car) == 1, "forward finish crossing after all checkpoints completes lap one")

	_emit_checkpoint(track, car, 0, true)
	_expect(tracker.get_completed_laps(car) == 1, "duplicate finish crossing cannot complete another lap")

	_emit_checkpoint(track, car, 1, true)
	_emit_checkpoint(track, car, 2, true)
	_emit_checkpoint(track, car, 3, true)
	_emit_checkpoint(track, car, 0, true)
	_expect(tracker.get_completed_laps(car) == 2, "second complete sequence reaches the target lap count")
	_expect(_finished_signal_count == 1, "participant finished signal is emitted once")

	_emit_checkpoint(track, car, 1, true)
	_emit_checkpoint(track, car, 2, true)
	_emit_checkpoint(track, car, 3, true)
	_emit_checkpoint(track, car, 0, true)
	_expect(tracker.get_completed_laps(car) == 2, "finished participant ignores later checkpoint crossings")
	_expect(_finished_signal_count == 1, "finished participant cannot emit a second finish signal")
	_expect(tracker.get_rejected_crossing_count(car) >= 4, "wrong-way and out-of-order crossings are recorded as rejected")

	tracker.clear()
	car.queue_free()
	track.queue_free()
	await get_tree().process_frame


func _emit_checkpoint(
	track: Node3D,
	car: PlayerCarController,
	checkpoint_index: int,
	is_forward: bool
) -> void:
	track.emit_signal("checkpoint_crossed", car, checkpoint_index, is_forward)


func _on_participant_finished(_car: PlayerCarController) -> void:
	_finished_signal_count += 1


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[LAP_TRACKER_CHECKPOINT_TEST][PASS] %s" % message)
		return

	_failures.append(message)
	push_error("[LAP_TRACKER_CHECKPOINT_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[LAP_TRACKER_CHECKPOINT_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return

	push_error("[LAP_TRACKER_CHECKPOINT_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[LAP_TRACKER_CHECKPOINT_TEST] - %s" % failure_message)
	get_tree().quit(1)
