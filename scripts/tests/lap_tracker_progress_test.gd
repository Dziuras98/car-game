extends Node

const SIMPLE_OVAL_SCENE: PackedScene = preload("res://scenes/tracks/simple_oval.tscn")
const TEST_SPECS: CarSpecs = preload("res://resources/cars/nissan/370z/specs/370z_7at_specs.tres")

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var track: Node3D = SIMPLE_OVAL_SCENE.instantiate() as Node3D
	add_child(track)
	await get_tree().process_frame

	var player: PlayerCarController = _make_car("Player")
	var opponent: PlayerCarController = _make_car("Opponent")
	add_child(player)
	add_child(opponent)
	await get_tree().process_frame

	var points: Array = track.call("get_racing_line_points")
	_expect(points.size() >= 2, "progress fixture exposes at least two racing-line points")
	if points.size() < 2:
		_finish()
		return

	var segment_start: Vector3 = track.to_global(points[0])
	var segment_end: Vector3 = track.to_global(points[1])
	player.global_position = segment_start.lerp(segment_end, 0.25)
	opponent.global_position = segment_start.lerp(segment_end, 0.75)

	var opponents: Array[PlayerCarController] = [opponent]
	var tracker: LapTracker = LapTracker.new()
	_expect(tracker.prepare(track, 3, player, opponents), "valid track contract prepares race tracking")
	tracker.update_positions()

	var player_progress: float = tracker.get_progress_distance(player)
	var opponent_progress: float = tracker.get_progress_distance(opponent)
	_expect(player_progress > 0.0, "projection records sub-segment player progress")
	_expect(opponent_progress > player_progress, "projection distinguishes positions inside the same sampled segment")
	_expect(tracker.get_race_position(opponent) == 1, "participant farther along the same segment is classified first")
	_expect(tracker.get_race_position(player) == 2, "participant earlier on the same segment is classified second")
	_expect(tracker.get_track_length() > segment_start.distance_to(segment_end), "tracker caches the full loop length")

	player.global_position = segment_start.lerp(segment_end, 0.95)
	tracker.update_positions()
	_expect(tracker.get_race_position(player) == 1, "classification updates when the player advances continuously")

	opponent.queue_free()
	await get_tree().process_frame
	tracker.update_positions()
	_expect(tracker.get_participant_count() == 1, "freed participants are removed from structured race state")
	_expect(tracker.get_result_order() == [player], "result ordering excludes freed participants")

	tracker.clear()
	player.queue_free()
	track.queue_free()
	await get_tree().process_frame
	_finish()


func _make_car(node_name: String) -> PlayerCarController:
	var car: PlayerCarController = PlayerCarController.new()
	car.name = node_name
	car.car_specs = TEST_SPECS
	return car


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[LAP_TRACKER_PROGRESS_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[LAP_TRACKER_PROGRESS_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[LAP_TRACKER_PROGRESS_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return
	push_error("[LAP_TRACKER_PROGRESS_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[LAP_TRACKER_PROGRESS_TEST] - %s" % failure_message)
	get_tree().quit(1)
