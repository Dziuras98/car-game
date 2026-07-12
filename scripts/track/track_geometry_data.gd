extends RefCounted
class_name TrackGeometryData

const MIN_SEGMENT_LENGTH_SQUARED: float = 0.0001
const MIN_TRACK_LENGTH: float = 1.0
const MIN_HALF_WIDTH: float = 0.05
const MIN_CURVE_RADIUS: float = 1.0
const CURVE_RADIUS_WIDTH_MULTIPLIER: float = 1.10
const MIN_NON_ADJACENT_CLEARANCE: float = 0.25
const GEOMETRY_EPSILON: float = 0.0001

var center_points: PackedVector3Array = PackedVector3Array()
var left_edge_points: PackedVector3Array = PackedVector3Array()
var right_edge_points: PackedVector3Array = PackedVector3Array()
var left_shoulder_outer_points: PackedVector3Array = PackedVector3Array()
var right_shoulder_outer_points: PackedVector3Array = PackedVector3Array()
var racing_line_points: PackedVector3Array = PackedVector3Array()
var forward_vectors: PackedVector3Array = PackedVector3Array()
var right_vectors: PackedVector3Array = PackedVector3Array()
var half_widths: PackedFloat32Array = PackedFloat32Array()
var center: Vector3 = Vector3.ZERO


func validate() -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	var point_count: int = center_points.size()
	if point_count < 3:
		errors.append("center_points must contain at least three points")
		return errors

	_append_size_error(errors, "left_edge_points", left_edge_points.size(), point_count)
	_append_size_error(errors, "right_edge_points", right_edge_points.size(), point_count)
	_append_size_error(errors, "left_shoulder_outer_points", left_shoulder_outer_points.size(), point_count)
	_append_size_error(errors, "right_shoulder_outer_points", right_shoulder_outer_points.size(), point_count)
	_append_size_error(errors, "racing_line_points", racing_line_points.size(), point_count)
	_append_size_error(errors, "forward_vectors", forward_vectors.size(), point_count)
	_append_size_error(errors, "right_vectors", right_vectors.size(), point_count)
	_append_size_error(errors, "half_widths", half_widths.size(), point_count)
	if not errors.is_empty():
		return errors
	if not _is_finite_vector3(center):
		errors.append("center must be finite")

	var track_length: float = 0.0
	for point_index: int in range(point_count):
		var next_index: int = (point_index + 1) % point_count
		var center_point: Vector3 = center_points[point_index]
		var next_center_point: Vector3 = center_points[next_index]
		if not _is_finite_vector3(center_point):
			errors.append("center_points[%d] must be finite" % point_index)
			continue
		if not _is_finite_vector3(next_center_point):
			continue
		var segment_length_squared: float = center_point.distance_squared_to(next_center_point)
		if segment_length_squared < MIN_SEGMENT_LENGTH_SQUARED:
			errors.append("center segment %d must not be degenerate" % point_index)
		else:
			track_length += sqrt(segment_length_squared)

		var left_edge: Vector3 = left_edge_points[point_index]
		var right_edge: Vector3 = right_edge_points[point_index]
		var left_shoulder: Vector3 = left_shoulder_outer_points[point_index]
		var right_shoulder: Vector3 = right_shoulder_outer_points[point_index]
		var racing_point: Vector3 = racing_line_points[point_index]
		var forward: Vector3 = forward_vectors[point_index]
		var right: Vector3 = right_vectors[point_index]
		var half_width: float = half_widths[point_index]

		if not _is_finite_vector3(left_edge):
			errors.append("left_edge_points[%d] must be finite" % point_index)
		if not _is_finite_vector3(right_edge):
			errors.append("right_edge_points[%d] must be finite" % point_index)
		if not _is_finite_vector3(left_shoulder):
			errors.append("left_shoulder_outer_points[%d] must be finite" % point_index)
		if not _is_finite_vector3(right_shoulder):
			errors.append("right_shoulder_outer_points[%d] must be finite" % point_index)
		if not _is_finite_vector3(racing_point):
			errors.append("racing_line_points[%d] must be finite" % point_index)
		if not _is_finite_vector3(forward) or forward.length_squared() < 0.25:
			errors.append("forward_vectors[%d] must be finite and non-zero" % point_index)
		if not _is_finite_vector3(right) or right.length_squared() < 0.25:
			errors.append("right_vectors[%d] must be finite and non-zero" % point_index)
		if (
			_is_finite_vector3(forward)
			and _is_finite_vector3(right)
			and forward.length_squared() >= 0.25
			and right.length_squared() >= 0.25
			and absf(forward.normalized().dot(right.normalized())) > 0.15
		):
			errors.append("forward_vectors[%d] and right_vectors[%d] must be approximately orthogonal" % [point_index, point_index])
		if not is_finite(half_width) or half_width < MIN_HALF_WIDTH:
			errors.append("half_widths[%d] must be finite and positive" % point_index)
		elif _is_finite_vector3(left_edge) and _is_finite_vector3(right_edge):
			var edge_span: Vector3 = right_edge - left_edge
			if edge_span.length() < half_width:
				errors.append("track edges at point %d must preserve a positive road width" % point_index)
			elif _is_finite_vector3(right) and right.length_squared() >= 0.25 and edge_span.dot(right.normalized()) <= 0.0:
				errors.append("track edges at point %d are reversed relative to the right vector" % point_index)

	if track_length < MIN_TRACK_LENGTH:
		errors.append("generated track loop must have a positive finite length")
	if errors.is_empty():
		_append_curve_radius_errors(errors)
		_append_non_adjacent_segment_errors(errors)
	return errors


func is_valid() -> bool:
	return validate().is_empty()


func get_racing_line_points_array() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for point: Vector3 in racing_line_points:
		points.append(point)
	return points


func get_center_points_array() -> Array[Vector3]:
	var points: Array[Vector3] = []
	for point: Vector3 in center_points:
		points.append(point)
	return points


func _append_curve_radius_errors(errors: PackedStringArray) -> void:
	var point_count: int = center_points.size()
	for point_index: int in range(point_count):
		var previous: Vector2 = _to_xz(center_points[(point_index - 1 + point_count) % point_count])
		var current: Vector2 = _to_xz(center_points[point_index])
		var next: Vector2 = _to_xz(center_points[(point_index + 1) % point_count])
		var radius: float = _get_curve_radius(previous, current, next)
		if not is_finite(radius):
			continue
		var minimum_radius: float = maxf(
			MIN_CURVE_RADIUS,
			half_widths[point_index] * CURVE_RADIUS_WIDTH_MULTIPLIER
		)
		if radius < minimum_radius:
			errors.append(
				"curve radius at point %d is %.3f m but must be at least %.3f m"
				% [point_index, radius, minimum_radius]
			)
			return


func _append_non_adjacent_segment_errors(errors: PackedStringArray) -> void:
	var point_count: int = center_points.size()
	for first_index: int in range(point_count):
		var first_next: int = (first_index + 1) % point_count
		for second_index: int in range(first_index + 1, point_count):
			var second_next: int = (second_index + 1) % point_count
			if _segments_are_adjacent(first_index, second_index, point_count):
				continue

			var first_center_start: Vector2 = _to_xz(center_points[first_index])
			var first_center_end: Vector2 = _to_xz(center_points[first_next])
			var second_center_start: Vector2 = _to_xz(center_points[second_index])
			var second_center_end: Vector2 = _to_xz(center_points[second_next])
			if _segments_intersect(
				first_center_start,
				first_center_end,
				second_center_start,
				second_center_end
			):
				errors.append(
					"center line self-intersects between segments %d and %d"
					% [first_index, second_index]
				)
				return

			if _edge_segments_intersect(first_index, second_index, first_next, second_next):
				errors.append(
					"road edges self-intersect between segments %d and %d"
					% [first_index, second_index]
				)
				return

			var first_segment_half_width: float = maxf(
				half_widths[first_index],
				half_widths[first_next]
			)
			var second_segment_half_width: float = maxf(
				half_widths[second_index],
				half_widths[second_next]
			)
			var required_clearance: float = (
				first_segment_half_width
				+ second_segment_half_width
				+ MIN_NON_ADJACENT_CLEARANCE
			)
			var actual_clearance_squared: float = _segment_distance_squared(
				first_center_start,
				first_center_end,
				second_center_start,
				second_center_end
			)
			if actual_clearance_squared < required_clearance * required_clearance:
				errors.append(
					"non-adjacent center segments %d and %d do not preserve road clearance"
					% [first_index, second_index]
				)
				return


func _edge_segments_intersect(
	first_index: int,
	second_index: int,
	first_next: int,
	second_next: int
) -> bool:
	var first_left_start: Vector2 = _to_xz(left_edge_points[first_index])
	var first_left_end: Vector2 = _to_xz(left_edge_points[first_next])
	var second_left_start: Vector2 = _to_xz(left_edge_points[second_index])
	var second_left_end: Vector2 = _to_xz(left_edge_points[second_next])
	var first_right_start: Vector2 = _to_xz(right_edge_points[first_index])
	var first_right_end: Vector2 = _to_xz(right_edge_points[first_next])
	var second_right_start: Vector2 = _to_xz(right_edge_points[second_index])
	var second_right_end: Vector2 = _to_xz(right_edge_points[second_next])
	return (
		_segments_intersect(first_left_start, first_left_end, second_left_start, second_left_end)
		or _segments_intersect(first_right_start, first_right_end, second_right_start, second_right_end)
		or _segments_intersect(first_left_start, first_left_end, second_right_start, second_right_end)
		or _segments_intersect(first_right_start, first_right_end, second_left_start, second_left_end)
	)


func _segments_are_adjacent(first_index: int, second_index: int, point_count: int) -> bool:
	return (
		first_index == second_index
		or (first_index + 1) % point_count == second_index
		or (second_index + 1) % point_count == first_index
	)


func _get_curve_radius(previous: Vector2, current: Vector2, next: Vector2) -> float:
	var previous_to_current: float = previous.distance_to(current)
	var current_to_next: float = current.distance_to(next)
	var previous_to_next: float = previous.distance_to(next)
	var double_area: float = absf((current - previous).cross(next - previous))
	if double_area <= GEOMETRY_EPSILON:
		return INF
	return (
		previous_to_current
		* current_to_next
		* previous_to_next
		/ (2.0 * double_area)
	)


func _segments_intersect(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var ab_c: float = _orientation(a, b, c)
	var ab_d: float = _orientation(a, b, d)
	var cd_a: float = _orientation(c, d, a)
	var cd_b: float = _orientation(c, d, b)
	if (
		((ab_c > GEOMETRY_EPSILON and ab_d < -GEOMETRY_EPSILON) or (ab_c < -GEOMETRY_EPSILON and ab_d > GEOMETRY_EPSILON))
		and ((cd_a > GEOMETRY_EPSILON and cd_b < -GEOMETRY_EPSILON) or (cd_a < -GEOMETRY_EPSILON and cd_b > GEOMETRY_EPSILON))
	):
		return true
	return (
		(absf(ab_c) <= GEOMETRY_EPSILON and _point_is_on_segment(a, b, c))
		or (absf(ab_d) <= GEOMETRY_EPSILON and _point_is_on_segment(a, b, d))
		or (absf(cd_a) <= GEOMETRY_EPSILON and _point_is_on_segment(c, d, a))
		or (absf(cd_b) <= GEOMETRY_EPSILON and _point_is_on_segment(c, d, b))
	)


func _orientation(a: Vector2, b: Vector2, c: Vector2) -> float:
	return (b - a).cross(c - a)


func _point_is_on_segment(start: Vector2, end: Vector2, point: Vector2) -> bool:
	return (
		point.x >= minf(start.x, end.x) - GEOMETRY_EPSILON
		and point.x <= maxf(start.x, end.x) + GEOMETRY_EPSILON
		and point.y >= minf(start.y, end.y) - GEOMETRY_EPSILON
		and point.y <= maxf(start.y, end.y) + GEOMETRY_EPSILON
	)


func _segment_distance_squared(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> float:
	if _segments_intersect(a, b, c, d):
		return 0.0
	return minf(
		minf(_point_segment_distance_squared(a, c, d), _point_segment_distance_squared(b, c, d)),
		minf(_point_segment_distance_squared(c, a, b), _point_segment_distance_squared(d, a, b))
	)


func _point_segment_distance_squared(point: Vector2, start: Vector2, end: Vector2) -> float:
	var segment: Vector2 = end - start
	var segment_length_squared: float = segment.length_squared()
	if segment_length_squared <= GEOMETRY_EPSILON:
		return point.distance_squared_to(start)
	var projection: float = clampf((point - start).dot(segment) / segment_length_squared, 0.0, 1.0)
	return point.distance_squared_to(start + segment * projection)


func _append_size_error(
	errors: PackedStringArray,
	property_name: String,
	actual_size: int,
	expected_size: int
) -> void:
	if actual_size != expected_size:
		errors.append("%s must contain exactly %d values" % [property_name, expected_size])


func _to_xz(value: Vector3) -> Vector2:
	return Vector2(value.x, value.z)


func _is_finite_vector3(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)
