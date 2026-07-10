extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_initial_projection_scans_the_loop()
	_test_local_projection_preserves_track_continuity()
	_test_teleport_reacquires_globally()
	_test_large_loop_uses_a_bounded_window()
	_finish()


func _test_initial_projection_scans_the_loop() -> void:
	var points: Array[Vector3] = _build_parallel_loop()
	var projector: RacingLineProjector = _make_projector(points)
	var projection: RacingLineProjection = projector.project(Vector3(7.0, 0.0, 2.0))
	_expect(projection != null and projection.is_valid(), "initial projection resolves a valid segment")
	if projection == null:
		return
	_expect(projection.used_global_search, "initial projection performs a global acquisition")
	_expect(projection.segment_checks == points.size(), "global acquisition checks every racing-line segment once")


func _test_local_projection_preserves_track_continuity() -> void:
	var points: Array[Vector3] = _build_parallel_loop()
	var projector: RacingLineProjector = _make_projector(points)
	var projection: RacingLineProjection = projector.project(
		Vector3(7.0, 0.0, 1.1),
		1,
		Vector3(7.0, 0.0, 0.0),
		true
	)
	_expect(projection != null and projection.is_valid(), "local projection resolves a valid nearby segment")
	if projection == null:
		return
	_expect(not projection.used_global_search, "normal movement remains on the bounded local search path")
	_expect(projection.segment_index == 1, "local continuity prevents a jump to the closer parallel return straight")
	_expect(projection.segment_checks <= 7, "local continuity inspects only the dynamic segment window")


func _test_teleport_reacquires_globally() -> void:
	var points: Array[Vector3] = _build_parallel_loop()
	var projector: RacingLineProjector = _make_projector(points)
	var projection: RacingLineProjection = projector.project(
		Vector3(7.0, 0.0, 2.0),
		1,
		Vector3(100.0, 0.0, 100.0),
		true
	)
	_expect(projection != null and projection.is_valid(), "teleport projection resolves a valid segment")
	if projection == null:
		return
	_expect(projection.used_global_search, "large displacement triggers global reacquisition")
	_expect(projection.segment_index == 7, "global reacquisition selects the teleported-to return straight")
	_expect(projection.segment_checks == points.size(), "teleport fallback scans the complete loop exactly once")


func _test_large_loop_uses_a_bounded_window() -> void:
	var points: Array[Vector3] = []
	var point_count: int = 200
	var radius: float = 50.0
	for point_index: int in range(point_count):
		var angle: float = TAU * float(point_index) / float(point_count)
		points.append(Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))

	var projector: RacingLineProjector = _make_projector(points)
	var previous_position: Vector3 = points[50].lerp(points[51], 0.5)
	var current_position: Vector3 = points[51].lerp(points[52], 0.5)
	var projection: RacingLineProjection = projector.project(
		current_position,
		50,
		previous_position,
		true
	)
	_expect(projection != null and projection.is_valid(), "large-loop local projection remains valid")
	if projection == null:
		return
	_expect(not projection.used_global_search, "ordinary large-loop movement avoids a full scan")
	_expect(projection.segment_index == 51, "bounded search follows the next large-loop segment")
	_expect(projection.segment_checks < point_count / 10, "bounded search cost is independent of the complete sample count")


func _build_parallel_loop() -> Array[Vector3]:
	return [
		Vector3(0.0, 0.0, 0.0),
		Vector3(5.0, 0.0, 0.0),
		Vector3(10.0, 0.0, 0.0),
		Vector3(15.0, 0.0, 0.0),
		Vector3(20.0, 0.0, 0.0),
		Vector3(20.0, 0.0, 2.0),
		Vector3(15.0, 0.0, 2.0),
		Vector3(10.0, 0.0, 2.0),
		Vector3(5.0, 0.0, 2.0),
		Vector3(0.0, 0.0, 2.0),
	]


func _make_projector(points: Array[Vector3]) -> RacingLineProjector:
	var cumulative_distances: PackedFloat32Array = PackedFloat32Array()
	var track_length: float = 0.0
	for point_index: int in range(points.size()):
		cumulative_distances.append(track_length)
		var next_index: int = (point_index + 1) % points.size()
		track_length += points[point_index].distance_to(points[next_index])
	var projector: RacingLineProjector = RacingLineProjector.new()
	projector.configure(points, cumulative_distances, track_length)
	return projector


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[RACING_LINE_PROJECTOR_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[RACING_LINE_PROJECTOR_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[RACING_LINE_PROJECTOR_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error("[RACING_LINE_PROJECTOR_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[RACING_LINE_PROJECTOR_TEST] - %s" % failure_message)
	quit(1)
