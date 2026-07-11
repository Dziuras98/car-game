extends RefCounted
class_name TrackGeometryData

const MIN_SEGMENT_LENGTH_SQUARED: float = 0.0001
const MIN_TRACK_LENGTH: float = 1.0
const MIN_HALF_WIDTH: float = 0.05

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


func _append_size_error(
	errors: PackedStringArray,
	property_name: String,
	actual_size: int,
	expected_size: int
) -> void:
	if actual_size != expected_size:
		errors.append("%s must contain exactly %d values" % [property_name, expected_size])


func _is_finite_vector3(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)
