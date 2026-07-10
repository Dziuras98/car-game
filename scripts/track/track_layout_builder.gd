extends RefCounted
class_name TrackLayoutBuilder

const DEFAULT_TRACK_LAYOUT: TrackLayoutResource = preload("res://resources/tracks/simple_oval.tres")
const MIN_TRACK_WIDTH: float = 0.1
const MAX_WIDTH_VARIATION: float = 0.45


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
	geometry.racing_line_points = points
	geometry.center = _get_points_center(points)

	for index in point_count:
		var previous: Vector3 = points[(index - 1 + point_count) % point_count]
		var current: Vector3 = points[index]
		var next: Vector3 = points[(index + 1) % point_count]
		var tangent: Vector3 = (next - previous).normalized()
		var side: Vector3 = Vector3(-tangent.z, 0.0, tangent.x).normalized()
		var half_width: float = get_half_width(index, point_count, track_width, width_variation)

		geometry.forward_vectors.append(tangent)
		geometry.right_vectors.append(side)
		geometry.half_widths.append(half_width)
		geometry.left_edge_points.append(current - side * half_width)
		geometry.right_edge_points.append(current + side * half_width)
		geometry.left_shoulder_outer_points.append(current - side * (half_width + shoulder_width))
		geometry.right_shoulder_outer_points.append(current + side * (half_width + shoulder_width))

	return geometry


func get_half_width(index: int, point_count: int, track_width: float, width_variation: float) -> float:
	var safe_track_width: float = maxf(track_width, MIN_TRACK_WIDTH)
	var safe_width_variation: float = clampf(width_variation, 0.0, MAX_WIDTH_VARIATION)
	if point_count <= 0:
		return safe_track_width * 0.5

	var safe_index: int = ((index % point_count) + point_count) % point_count
	var progress: float = float(safe_index) / float(point_count)
	var turn_blend: float = maxf(
		clampf(1.0 - absf(progress - 0.29) / 0.16, 0.0, 1.0),
		clampf(1.0 - absf(progress - 0.79) / 0.16, 0.0, 1.0)
	)
	var width_scale: float = 1.0 + turn_blend * safe_width_variation
	return safe_track_width * clampf(width_scale, 0.7, 1.45) * 0.5


func _sample_track_points(
	control_points: PackedVector3Array,
	samples_per_segment: int
) -> PackedVector3Array:
	var sampled_points: PackedVector3Array = PackedVector3Array()
	var control_point_count: int = control_points.size()
	if control_point_count < 4:
		return sampled_points

	var safe_sample_count: int = maxi(samples_per_segment, 1)
	for index in control_point_count:
		var p0: Vector3 = control_points[(index - 1 + control_point_count) % control_point_count]
		var p1: Vector3 = control_points[index]
		var p2: Vector3 = control_points[(index + 1) % control_point_count]
		var p3: Vector3 = control_points[(index + 2) % control_point_count]

		for step in safe_sample_count:
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
