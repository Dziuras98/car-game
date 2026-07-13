extends RefCounted
class_name TrackLayoutBuilder

const DEFAULT_TRACK_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")
const MIN_TRACK_WIDTH: float = 0.1
const MAX_WIDTH_VARIATION: float = 0.45
const MIN_CURVATURE_SEGMENT_LENGTH: float = 0.01
const CURVATURE_FOR_FULL_WIDTH_VARIATION: float = 0.04
const MAX_RACING_LINE_OFFSET_RATIO: float = 0.8


func build(config: TrackGenerationConfig) -> TrackGeometryData:
	var geometry: TrackGeometryData = TrackGeometryData.new()
	var safe_config: TrackGenerationConfig = (
		config.duplicate_config() if config != null else TrackGenerationConfig.from_layout(DEFAULT_TRACK_LAYOUT)
	)
	var layout: TrackLayoutResource = safe_config.track_layout
	if layout == null:
		layout = DEFAULT_TRACK_LAYOUT
	if layout == null or layout.control_points.size() < 4:
		return geometry

	var points: PackedVector3Array = _sample_track_points(
		layout.control_points,
		maxi(layout.samples_per_segment, 1)
	)
	var point_count: int = points.size()
	var track_width: float = maxf(safe_config.track_width, MIN_TRACK_WIDTH)
	var width_variation: float = clampf(safe_config.width_variation, 0.0, MAX_WIDTH_VARIATION)
	var shoulder_width: float = maxf(safe_config.shoulder_width, 0.0)

	geometry.center_points = points
	geometry.center = _get_points_center(points)

	for index: int in range(point_count):
		var previous: Vector3 = points[(index - 1 + point_count) % point_count]
		var current: Vector3 = points[index]
		var next: Vector3 = points[(index + 1) % point_count]
		var tangent: Vector3 = (next - previous).normalized()
		var side: Vector3 = Vector3(-tangent.z, 0.0, tangent.x).normalized()
		var progress: float = float(index) / float(point_count)
		var banking_radians: float = deg_to_rad(layout.get_banking_degrees_at(progress))
		if not is_zero_approx(banking_radians):
			side = side.rotated(tangent, banking_radians).normalized()

		var curvature: float = _calculate_curvature(previous, current, next)
		var local_track_width: float = maxf(layout.get_track_width_at(progress), MIN_TRACK_WIDTH)
		if layout.track_width_profile.is_empty():
			local_track_width = track_width
		var half_width: float = get_half_width_for_curvature(
			local_track_width,
			width_variation,
			curvature
		)
		var local_shoulder_width: float = maxf(layout.get_shoulder_width_at(progress), 0.0)
		if layout.shoulder_width_profile.is_empty():
			local_shoulder_width = shoulder_width
		var maximum_racing_line_offset: float = half_width * MAX_RACING_LINE_OFFSET_RATIO
		var racing_line_offset: float = clampf(
			layout.get_racing_line_offset_at(progress),
			-maximum_racing_line_offset,
			maximum_racing_line_offset
		)

		geometry.forward_vectors.append(tangent)
		geometry.right_vectors.append(side)
		geometry.half_widths.append(half_width)
		geometry.left_edge_points.append(current - side * half_width)
		geometry.right_edge_points.append(current + side * half_width)
		geometry.left_shoulder_outer_points.append(
			current - side * (half_width + local_shoulder_width)
		)
		geometry.right_shoulder_outer_points.append(
			current + side * (half_width + local_shoulder_width)
		)
		geometry.racing_line_points.append(current + side * racing_line_offset)

	return geometry


func get_half_width_for_curvature(
	track_width: float,
	width_variation: float,
	curvature: float
) -> float:
	var safe_track_width: float = maxf(track_width, MIN_TRACK_WIDTH)
	var safe_width_variation: float = clampf(width_variation, 0.0, MAX_WIDTH_VARIATION)
	var safe_curvature: float = maxf(curvature, 0.0) if is_finite(curvature) else 0.0
	var curvature_ratio: float = clampf(
		safe_curvature / CURVATURE_FOR_FULL_WIDTH_VARIATION,
		0.0,
		1.0
	)
	var turn_blend: float = curvature_ratio * curvature_ratio * (3.0 - 2.0 * curvature_ratio)
	var width_scale: float = 1.0 + turn_blend * safe_width_variation
	return safe_track_width * clampf(width_scale, 0.7, 1.45) * 0.5


func _calculate_curvature(previous: Vector3, current: Vector3, next: Vector3) -> float:
	var incoming: Vector3 = current - previous
	var outgoing: Vector3 = next - current
	incoming.y = 0.0
	outgoing.y = 0.0
	var incoming_length: float = incoming.length()
	var outgoing_length: float = outgoing.length()
	if incoming_length < MIN_CURVATURE_SEGMENT_LENGTH or outgoing_length < MIN_CURVATURE_SEGMENT_LENGTH:
		return 0.0
	var direction_dot: float = clampf(
		incoming.normalized().dot(outgoing.normalized()),
		-1.0,
		1.0
	)
	var turn_angle: float = acos(direction_dot)
	var average_segment_length: float = (incoming_length + outgoing_length) * 0.5
	return turn_angle / maxf(average_segment_length, MIN_CURVATURE_SEGMENT_LENGTH)


func _sample_track_points(
	control_points: PackedVector3Array,
	samples_per_segment: int
) -> PackedVector3Array:
	var sampled_points: PackedVector3Array = PackedVector3Array()
	var control_point_count: int = control_points.size()
	if control_point_count < 4:
		return sampled_points

	var safe_sample_count: int = maxi(samples_per_segment, 1)
	for index: int in range(control_point_count):
		var p0: Vector3 = control_points[(index - 1 + control_point_count) % control_point_count]
		var p1: Vector3 = control_points[index]
		var p2: Vector3 = control_points[(index + 1) % control_point_count]
		var p3: Vector3 = control_points[(index + 2) % control_point_count]

		for step: int in range(safe_sample_count):
			var t: float = float(step) / float(safe_sample_count)
			sampled_points.append(_catmull_rom(p0, p1, p2, p3, t))

	return sampled_points


func _get_points_center(points: PackedVector3Array) -> Vector3:
	if points.is_empty():
		return Vector3.ZERO

	var center: Vector3 = Vector3.ZERO
	for point: Vector3 in points:
		center += point
	return center / float(points.size())


func _catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2: float = t * t
	var t3: float = t2 * t
	return 0.5 * (
		(2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)
