extends SceneTree

var _checks: int = 0
var _failures: Array[String] = []


func _initialize() -> void:
	_test_centerline_self_intersection_is_rejected()
	_test_tight_curve_is_rejected()
	_test_non_adjacent_clearance_is_rejected()
	_finish()


func _test_centerline_self_intersection_is_rejected() -> void:
	var geometry: TrackGeometryData = _make_geometry(
		PackedVector3Array([
			Vector3(-10.0, 0.0, -10.0),
			Vector3(10.0, 0.0, 10.0),
			Vector3(-10.0, 0.0, 10.0),
			Vector3(10.0, 0.0, -10.0),
		]),
		0.1
	)
	var errors: PackedStringArray = geometry.validate()
	_expect(
		_contains_error(errors, "center line self-intersects"),
		"generated centerline self-intersections are rejected"
	)


func _test_tight_curve_is_rejected() -> void:
	var geometry: TrackGeometryData = _make_geometry(
		PackedVector3Array([
			Vector3(0.0, 0.0, 0.0),
			Vector3(2.0, 0.0, 0.0),
			Vector3(2.0, 0.0, 2.0),
			Vector3(0.0, 0.0, 2.0),
		]),
		2.0
	)
	var errors: PackedStringArray = geometry.validate()
	_expect(
		_contains_error(errors, "curve radius"),
		"generated curves tighter than the road width are rejected"
	)


func _test_non_adjacent_clearance_is_rejected() -> void:
	var geometry: TrackGeometryData = _make_geometry(
		PackedVector3Array([
			Vector3(0.0, 0.0, 0.0),
			Vector3(30.0, 0.0, 0.0),
			Vector3(30.0, 0.0, 30.0),
			Vector3(0.0, 0.0, 30.0),
			Vector3(0.0, 0.0, 20.0),
			Vector3(28.0, 0.0, 20.0),
			Vector3(28.0, 0.0, 10.0),
			Vector3(0.0, 0.0, 10.0),
		]),
		0.9
	)
	var errors: PackedStringArray = geometry.validate()
	_expect(
		_contains_error(errors, "do not preserve road clearance"),
		"non-local road segments must preserve width-aware clearance"
	)


func _make_geometry(points: PackedVector3Array, half_width: float) -> TrackGeometryData:
	var geometry: TrackGeometryData = TrackGeometryData.new()
	geometry.center_points = points
	geometry.racing_line_points = points
	var center: Vector3 = Vector3.ZERO
	for point: Vector3 in points:
		center += point
	geometry.center = center / float(points.size())

	for point_index: int in range(points.size()):
		var previous: Vector3 = points[(point_index - 1 + points.size()) % points.size()]
		var current: Vector3 = points[point_index]
		var next: Vector3 = points[(point_index + 1) % points.size()]
		var forward: Vector3 = (next - previous).normalized()
		var right: Vector3 = Vector3(-forward.z, 0.0, forward.x).normalized()
		var left_edge: Vector3 = current - right * half_width
		var right_edge: Vector3 = current + right * half_width
		geometry.forward_vectors.append(forward)
		geometry.right_vectors.append(right)
		geometry.half_widths.append(half_width)
		geometry.left_edge_points.append(left_edge)
		geometry.right_edge_points.append(right_edge)
		geometry.left_shoulder_outer_points.append(left_edge)
		geometry.right_shoulder_outer_points.append(right_edge)
	return geometry


func _contains_error(errors: PackedStringArray, fragment: String) -> bool:
	for error_text: String in errors:
		if fragment in error_text:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRACK_GEOMETRY_TOPOLOGY_VALIDATION_TEST][PASS] %s" % message)
		return
	_failures.append(message)
	push_error("[TRACK_GEOMETRY_TOPOLOGY_VALIDATION_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRACK_GEOMETRY_TOPOLOGY_VALIDATION_TEST] Passed: %d checks" % _checks)
		quit(0)
		return
	push_error(
		"[TRACK_GEOMETRY_TOPOLOGY_VALIDATION_TEST] Failed: %d failure(s), %d checks"
		% [_failures.size(), _checks]
	)
	for failure_message: String in _failures:
		push_error("[TRACK_GEOMETRY_TOPOLOGY_VALIDATION_TEST] - %s" % failure_message)
	quit(1)
