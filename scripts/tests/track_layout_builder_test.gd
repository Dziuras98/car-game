extends Node

const EPSILON: float = 0.001
const EXPECTED_POINT_COUNT: int = 108

var _checks: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_default_layout_topology()
	_test_edge_and_shoulder_geometry()
	_test_width_profile_and_index_wrapping()
	_test_invalid_config_is_sanitized()
	_test_build_is_deterministic()
	_finish()


func _test_default_layout_topology() -> void:
	var geometry: TrackGeometryData = TrackLayoutBuilder.new().build({})
	_expect(geometry != null, "layout builder returns geometry")
	if geometry == null:
		return

	var point_count: int = geometry.center_points.size()
	_expect(point_count == EXPECTED_POINT_COUNT, "layout samples 18 control points into 108 points")
	_expect(geometry.racing_line_points.size() == point_count, "racing line has one point per center point")
	_expect(geometry.forward_vectors.size() == point_count, "layout has one forward vector per point")
	_expect(geometry.right_vectors.size() == point_count, "layout has one right vector per point")
	_expect(geometry.half_widths.size() == point_count, "layout has one half-width per point")
	_expect(geometry.left_edge_points.size() == point_count, "layout has one left edge point per center point")
	_expect(geometry.right_edge_points.size() == point_count, "layout has one right edge point per center point")
	_expect(geometry.left_shoulder_outer_points.size() == point_count, "layout has one left shoulder point per center point")
	_expect(geometry.right_shoulder_outer_points.size() == point_count, "layout has one right shoulder point per center point")
	_expect(_packed_vector3_array_equal_approx(geometry.racing_line_points, geometry.center_points), "current racing line follows the sampled center line")
	_expect(_vector3_equal_approx(geometry.center, _calculate_center(geometry.center_points)), "layout center is the arithmetic mean of sampled points")

	if point_count < 2:
		return

	var closure_distance: float = geometry.center_points[point_count - 1].distance_to(geometry.center_points[0])
	var max_regular_segment: float = 0.0
	var minimum_segment: float = INF
	var maximum_elevation: float = -INF
	for index: int in range(point_count - 1):
		var segment_length: float = geometry.center_points[index].distance_to(geometry.center_points[index + 1])
		minimum_segment = minf(minimum_segment, segment_length)
		max_regular_segment = maxf(max_regular_segment, segment_length)
		maximum_elevation = maxf(maximum_elevation, geometry.center_points[index].y)
	maximum_elevation = maxf(maximum_elevation, geometry.center_points[point_count - 1].y)

	_expect(minimum_segment > 0.01, "sampled layout has no duplicate consecutive points")
	_expect(closure_distance > 0.01, "closed layout does not duplicate its first point at the end")
	_expect(closure_distance <= max_regular_segment * 1.5, "implicit closing segment is continuous with regular sampling")
	_expect(maximum_elevation > 1.0, "layout preserves the configured elevation profile")


func _test_edge_and_shoulder_geometry() -> void:
	var shoulder_width: float = 10.0
	var geometry: TrackGeometryData = TrackLayoutBuilder.new().build({
		"track_width": 14.0,
		"width_variation": 0.28,
		"shoulder_width": shoulder_width,
	})
	var minimum_half_width: float = INF
	var maximum_half_width: float = 0.0
	var forward_vectors_normalized: bool = true
	var right_vectors_normalized: bool = true
	var frames_perpendicular: bool = true
	var edges_centered: bool = true
	var left_edges_match_width: bool = true
	var right_edges_match_width: bool = true
	var left_shoulders_match_width: bool = true
	var right_shoulders_match_width: bool = true

	for index: int in range(geometry.center_points.size()):
		var center_point: Vector3 = geometry.center_points[index]
		var forward: Vector3 = geometry.forward_vectors[index]
		var right: Vector3 = geometry.right_vectors[index]
		var half_width: float = geometry.half_widths[index]
		var left_edge: Vector3 = geometry.left_edge_points[index]
		var right_edge: Vector3 = geometry.right_edge_points[index]
		var midpoint: Vector3 = (left_edge + right_edge) * 0.5

		minimum_half_width = minf(minimum_half_width, half_width)
		maximum_half_width = maxf(maximum_half_width, half_width)
		forward_vectors_normalized = forward_vectors_normalized and absf(forward.length() - 1.0) <= EPSILON
		right_vectors_normalized = right_vectors_normalized and absf(right.length() - 1.0) <= EPSILON
		frames_perpendicular = frames_perpendicular and absf(forward.dot(right)) <= EPSILON
		edges_centered = edges_centered and _vector3_equal_approx(midpoint, center_point)
		left_edges_match_width = left_edges_match_width and absf(center_point.distance_to(left_edge) - half_width) <= EPSILON
		right_edges_match_width = right_edges_match_width and absf(center_point.distance_to(right_edge) - half_width) <= EPSILON
		left_shoulders_match_width = left_shoulders_match_width and absf(left_edge.distance_to(geometry.left_shoulder_outer_points[index]) - shoulder_width) <= EPSILON
		right_shoulders_match_width = right_shoulders_match_width and absf(right_edge.distance_to(geometry.right_shoulder_outer_points[index]) - shoulder_width) <= EPSILON

	_expect(forward_vectors_normalized, "all forward vectors are normalized")
	_expect(right_vectors_normalized, "all right vectors are normalized")
	_expect(frames_perpendicular, "all forward and right vectors are perpendicular")
	_expect(edges_centered, "all road-edge pairs are centered on the sampled line")
	_expect(left_edges_match_width, "all left edges use the generated half-width")
	_expect(right_edges_match_width, "all right edges use the generated half-width")
	_expect(left_shoulders_match_width, "all left shoulders use the configured width")
	_expect(right_shoulders_match_width, "all right shoulders use the configured width")
	_expect(minimum_half_width >= 7.0 - EPSILON, "default road never becomes narrower than the base width")
	_expect(maximum_half_width > minimum_half_width, "width variation widens designated turn sections")


func _test_width_profile_and_index_wrapping() -> void:
	var builder: TrackLayoutBuilder = TrackLayoutBuilder.new()
	var point_count: int = EXPECTED_POINT_COUNT
	var base_half_width: float = builder.get_half_width(0, point_count, 14.0, 0.0)

	_expect(absf(base_half_width - 7.0) <= EPSILON, "zero variation returns half of track width")
	_expect(absf(builder.get_half_width(40, point_count, 14.0, 0.0) - base_half_width) <= EPSILON, "zero variation is constant around the track")
	_expect(absf(builder.get_half_width(-1, point_count, 14.0, 0.28) - builder.get_half_width(point_count - 1, point_count, 14.0, 0.28)) <= EPSILON, "negative width-profile index wraps around")
	_expect(absf(builder.get_half_width(point_count + 1, point_count, 14.0, 0.28) - builder.get_half_width(1, point_count, 14.0, 0.28)) <= EPSILON, "overflow width-profile index wraps around")
	_expect(absf(builder.get_half_width(0, 0, 14.0, 0.28) - 7.0) <= EPSILON, "zero point count returns a safe base half-width")
	_expect(absf(builder.get_half_width(31, point_count, 14.0, -5.0) - builder.get_half_width(31, point_count, 14.0, 0.0)) <= EPSILON, "negative width variation is clamped to zero")
	_expect(absf(builder.get_half_width(31, point_count, 14.0, 5.0) - builder.get_half_width(31, point_count, 14.0, 0.45)) <= EPSILON, "excessive width variation is clamped to the supported maximum")


func _test_invalid_config_is_sanitized() -> void:
	var geometry: TrackGeometryData = TrackLayoutBuilder.new().build({
		"track_width": -20.0,
		"width_variation": 8.0,
		"shoulder_width": -4.0,
	})
	var widths_are_positive: bool = true
	var left_shoulders_are_zero: bool = true
	var right_shoulders_are_zero: bool = true

	for index: int in range(geometry.center_points.size()):
		widths_are_positive = widths_are_positive and geometry.half_widths[index] >= 0.05 - EPSILON
		left_shoulders_are_zero = left_shoulders_are_zero and geometry.left_edge_points[index].distance_to(geometry.left_shoulder_outer_points[index]) <= EPSILON
		right_shoulders_are_zero = right_shoulders_are_zero and geometry.right_edge_points[index].distance_to(geometry.right_shoulder_outer_points[index]) <= EPSILON

	_expect(widths_are_positive, "invalid track width is clamped for the full layout")
	_expect(left_shoulders_are_zero, "negative left shoulder width is clamped to zero")
	_expect(right_shoulders_are_zero, "negative right shoulder width is clamped to zero")


func _test_build_is_deterministic() -> void:
	var config: Dictionary = {
		"track_width": 17.5,
		"width_variation": 0.2,
		"shoulder_width": 6.0,
	}
	var builder: TrackLayoutBuilder = TrackLayoutBuilder.new()
	var first: TrackGeometryData = builder.build(config)
	var second: TrackGeometryData = builder.build(config)

	_expect(_packed_vector3_array_equal_approx(first.center_points, second.center_points), "repeated builds produce identical center points")
	_expect(_packed_vector3_array_equal_approx(first.left_edge_points, second.left_edge_points), "repeated builds produce identical left edges")
	_expect(_packed_vector3_array_equal_approx(first.right_edge_points, second.right_edge_points), "repeated builds produce identical right edges")
	_expect(_packed_float_array_equal_approx(first.half_widths, second.half_widths), "repeated builds produce identical width profiles")
	_expect(_vector3_equal_approx(first.center, second.center), "repeated builds produce the same layout center")


func _calculate_center(points: PackedVector3Array) -> Vector3:
	var result: Vector3 = Vector3.ZERO
	for point: Vector3 in points:
		result += point
	return result / float(points.size())


func _packed_vector3_array_equal_approx(a: PackedVector3Array, b: PackedVector3Array) -> bool:
	if a.size() != b.size():
		return false
	for index: int in range(a.size()):
		if not _vector3_equal_approx(a[index], b[index]):
			return false
	return true


func _packed_float_array_equal_approx(a: PackedFloat32Array, b: PackedFloat32Array) -> bool:
	if a.size() != b.size():
		return false
	for index: int in range(a.size()):
		if absf(a[index] - b[index]) > EPSILON:
			return false
	return true


func _vector3_equal_approx(a: Vector3, b: Vector3) -> bool:
	return a.distance_to(b) <= EPSILON


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[TRACK_LAYOUT_BUILDER_TEST][PASS] %s" % message)
		return

	_failures.append(message)
	push_error("[TRACK_LAYOUT_BUILDER_TEST][FAIL] %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("[TRACK_LAYOUT_BUILDER_TEST] Passed: %d checks" % _checks)
		get_tree().quit(0)
		return

	push_error("[TRACK_LAYOUT_BUILDER_TEST] Failed: %d failure(s), %d checks" % [_failures.size(), _checks])
	for failure_message: String in _failures:
		push_error("[TRACK_LAYOUT_BUILDER_TEST] - %s" % failure_message)
	get_tree().quit(1)
